---------------------------- MODULE ProveRequests ----------------------------
(* How the MCP server's `prove` tool handles its requests, processes and cache (ADR-0016), written before the
   tool's code.

   The parts, each from the record that sets it:
     requests      arrive over one stdio connection, may overlap, and may each be cancelled, the cancel
                   arriving at any point, after the response too (ADR-0016 Context; MCP 2025-06-18)
     tlapm         one process per request, started in a process group of its own, with a cache directory
                   the server names (ADR-0009 item 5, the custodian's choice of 2026.11.16)
     a backend     Z3, Zenon, Isabelle or LS4: one per request stands for all of them. It runs in tlapm's
                   process group, as every backend did in the tests of ADR-0016 item 6, unless M_ESCAPE lets it
                   leave
     the cache     one directory per module, as tlapm lays it out, or one for every module, which a constant
                   chooses (ADR-0016 item 5's bounds)
     the server    starts tlapm when its cache is free, kills the group on a timeout or a cancel, reaps every
                   child (the custodian's choice of 2026.11.16), and answers
     the project   the files the server may read and may not write (ADR-0006 item 3)

   Abstracted (ADR-0016 item 3): a request's scope (a step, a line range, a theorem or the module) is passed to
   tlapm as lines and comes back with the answer unchanged, so it is not modelled, and the answer's scope is its
   request's by construction. Time is not modelled: a timeout is an event that may happen while tlapm runs. How
   tlapm ends by itself is "proved", or "failed": exit 0 with a failed obligation, which the comparison of
   ADR-0009 item 5 saw. A run that is killed has no outcome, and its Toolbox output is cut off. When tlapm ends by
   itself its backend has ended too, as the tests of ADR-0016 item 6 saw, and a dead process stays a zombie until
   the server reaps it.

   Mut = "none" is the chosen design. Each mutation removes one rule of it, and must break the properties beside
   it and no other:
     M_NOLOCK         tlapm starts whatever else is writing its cache.        OneWriterPerCache
     M_KILLONE        a timeout or a cancel kills tlapm alone, and the
                      server waits only for tlapm, as in marco6/tlapm-mcp
                      v0.0.1. The backend it leaves keeps writing the cache
                      that the server has released, so it breaks both.        NoProcessOutlives, OneWriterPerCache
     M_EXITCODE       a run is a success when tlapm exits 0.                  SuccessOnlyComplete
     M_ANSWERCANCEL   a cancelled request is answered, with an error.         AtMostOneAnswer
     M_LATECANCEL     a cancel that arrives after the response is acted on,
                      with a second response.                                 AtMostOneAnswer
     M_NOREAP         the server answers before it has reaped.                AllReaped
     M_DEFAULTCACHE   tlapm is started without --cache-dir, so its cache
                      lands beside the module, as tlapm_lsp's did.            NothingInProject
     M_NAIVE          ADR-0016 item 5's naive design: M_NOLOCK and
                      M_KILLONE at once. It must break both of their
                      properties.                                             OneWriterPerCache, NoProcessOutlives
   and one that is not a fault of the server:
     M_ESCAPE         a backend may leave tlapm's process group. The server kills and waits for the group only,
                      so the backend can outlive its request, and keep writing a cache the server has released.
                      No backend did so in the tests of ADR-0016 item 6, and the server does not look for one:
                      that is the stated choice ADR-0016 item 5 asks for, and this row shows what it costs.
                                                                              NoProcessOutlives, OneWriterPerCache

   Properties (ADR-0016 item 4, and AllReaped for the custodian's choice of reaping):
     AtMostOneAnswer      each request gets at most one response, and a request the server cancelled gets none
     SuccessOnlyComplete  a success answers a run that ended by itself, proved, with no timeout
     NoProcessOutlives    when a request is answered or cancelled, none of its processes is alive
     OneWriterPerCache    no two requests have a live process writing the same cache
     NothingInProject     nothing is written into the project
     AllReaped            when a request is answered or cancelled, none of the processes the server waited for
                          is an unreaped zombie (a process that outlives its request is NoProcessOutlives')
   The answer's scope being its request's holds by construction, at this abstraction.

   Liveness, under weak fairness of the server's actions and of tlapm's ending, and strong fairness of starting
   a request whose cache another request holds now and then: every request is eventually answered or cancelled
   (EveryRequestEnds), and a waiting request eventually runs or is cancelled (WaitingRuns).

   Witnesses, each to be VIOLATED under none: NeverAnswered, NeverSuccess, NeverFailure, NeverTimeout,
   NeverCancelled, NeverLateCancel, NeverTwoRunning, NeverQueued, NeverZombie. *)
EXTENDS Naturals, FiniteSets

CONSTANTS Mut, NReq, CacheMode
ASSUME MutKnown == Mut \in {"none", "M_NOLOCK", "M_KILLONE", "M_EXITCODE", "M_ANSWERCANCEL", "M_LATECANCEL",
                            "M_NOREAP", "M_DEFAULTCACHE", "M_NAIVE", "M_ESCAPE"}
ASSUME NReqOK == NReq \in 1..3
ASSUME CacheModeKnown == CacheMode \in {"permodule", "shared"}

\* The rules of the chosen design, each removed by its mutation.
Lock      == Mut \notin {"M_NOLOCK", "M_NAIVE"}
GroupKill == Mut \notin {"M_KILLONE", "M_NAIVE"}
ByOutput  == Mut # "M_EXITCODE"
Silent    == Mut # "M_ANSWERCANCEL"
LateIgnored == Mut # "M_LATECANCEL"
ReapFirst == Mut # "M_NOREAP"
OwnCache  == Mut # "M_DEFAULTCACHE"
MayEscape == Mut = "M_ESCAPE"

Reqs == 1..NReq
Modules == {"m1", "m2"}
Statuses == {"idle", "waiting", "running", "cancelling", "answered", "cancelled"}
Answers == {"none", "success", "failure", "timeout"}

VARIABLES
    status,     \* each request's place in the server
    mod,        \* the module it asks about
    tl,         \* its tlapm: none, alive, exited (ended by itself) or killed
    outcome,    \* how its tlapm ended by itself: none, proved, or failed (exit 0 with a failed obligation)
    bk,         \* its backend: none, alive or dead
    inGroup,    \* whether its backend is in tlapm's process group
    zombie,     \* whether one of its processes is dead and not yet reaped
    timedOut,   \* whether its run was stopped by a timeout
    cancelIn,   \* whether the client's cancel for it has arrived
    resp,       \* how many responses it has had
    ans,        \* the response's kind
    leftUnreaped, \* whether, when it was answered or cancelled, one of its processes was an unreaped zombie
    projectWritten

vars == <<status, mod, tl, outcome, bk, inGroup, zombie, timedOut, cancelIn, resp, ans, leftUnreaped,
          projectWritten>>

TypeOK ==
    /\ status \in [Reqs -> Statuses]
    /\ mod \in [Reqs -> Modules \cup {"none"}]
    /\ tl \in [Reqs -> {"none", "alive", "exited", "killed"}]
    /\ outcome \in [Reqs -> {"none", "proved", "failed"}]
    /\ bk \in [Reqs -> {"none", "alive", "dead"}]
    /\ inGroup \in [Reqs -> BOOLEAN]
    /\ zombie \in [Reqs -> BOOLEAN]
    /\ timedOut \in [Reqs -> BOOLEAN]
    /\ cancelIn \in [Reqs -> BOOLEAN]
    /\ resp \in [Reqs -> 0..2]
    /\ ans \in [Reqs -> Answers]
    /\ leftUnreaped \in [Reqs -> BOOLEAN]
    /\ projectWritten \in BOOLEAN

CacheOf(r) == IF CacheMode = "shared" THEN "one" ELSE mod[r]
Writing(r) == tl[r] = "alive" \/ bk[r] = "alive"
\* What the server can see has ended: its whole group, or under M_KILLONE tlapm alone.
Ended(r) == /\ tl[r] # "alive"
            /\ GroupKill => (bk[r] = "alive" => ~inGroup[r])
Reaped(r) == ReapFirst => ~zombie[r]

Init ==
    /\ status = [r \in Reqs |-> "idle"]
    /\ mod = [r \in Reqs |-> "none"]
    /\ tl = [r \in Reqs |-> "none"]
    /\ outcome = [r \in Reqs |-> "none"]
    /\ bk = [r \in Reqs |-> "none"]
    /\ inGroup = [r \in Reqs |-> TRUE]
    /\ zombie = [r \in Reqs |-> FALSE]
    /\ timedOut = [r \in Reqs |-> FALSE]
    /\ cancelIn = [r \in Reqs |-> FALSE]
    /\ resp = [r \in Reqs |-> 0]
    /\ ans = [r \in Reqs |-> "none"]
    /\ leftUnreaped = [r \in Reqs |-> FALSE]
    /\ projectWritten = FALSE

\* The client sends a request about a module.
Arrive(r, m) ==
    /\ status[r] = "idle"
    /\ status' = [status EXCEPT ![r] = "waiting"]
    /\ mod' = [mod EXCEPT ![r] = m]
    /\ UNCHANGED <<tl, outcome, bk, inGroup, zombie, timedOut, cancelIn, resp, ans, leftUnreaped, projectWritten>>

\* The server starts tlapm in a group of its own, when no other request holds its cache. A request holds its cache
\* from its start until it is answered or cancelled: that is what the server knows, not which processes are alive.
Holds(o) == status[o] \in {"running", "cancelling"}
Start(r) ==
    /\ status[r] = "waiting"
    /\ Lock => \A o \in Reqs \ {r} : ~(Holds(o) /\ CacheOf(o) = CacheOf(r))
    /\ status' = [status EXCEPT ![r] = "running"]
    /\ tl' = [tl EXCEPT ![r] = "alive"]
    /\ projectWritten' = (projectWritten \/ ~OwnCache)
    /\ UNCHANGED <<mod, outcome, bk, inGroup, zombie, timedOut, cancelIn, resp, ans, leftUnreaped>>

\* tlapm starts a backend, in its group, or under M_ESCAPE perhaps outside it.
Spawn(r) ==
    /\ tl[r] = "alive" /\ bk[r] = "none"
    /\ bk' = [bk EXCEPT ![r] = "alive"]
    /\ \E g \in (IF MayEscape THEN BOOLEAN ELSE {TRUE}) : inGroup' = [inGroup EXCEPT ![r] = g]
    /\ UNCHANGED <<status, mod, tl, outcome, zombie, timedOut, cancelIn, resp, ans, leftUnreaped, projectWritten>>

\* A backend ends by itself.
BackendEnds(r) ==
    /\ bk[r] = "alive"
    /\ bk' = [bk EXCEPT ![r] = "dead"]
    /\ zombie' = [zombie EXCEPT ![r] = TRUE]
    /\ UNCHANGED <<status, mod, tl, outcome, inGroup, timedOut, cancelIn, resp, ans, leftUnreaped, projectWritten>>

\* tlapm ends by itself, proved or failed, and stops its backend as it does.
TlapmEnds(r) ==
    /\ tl[r] = "alive"
    /\ \E o \in {"proved", "failed"} : outcome' = [outcome EXCEPT ![r] = o]
    /\ tl' = [tl EXCEPT ![r] = "exited"]
    /\ bk' = [bk EXCEPT ![r] = IF @ = "alive" THEN "dead" ELSE @]
    /\ zombie' = [zombie EXCEPT ![r] = TRUE]
    /\ UNCHANGED <<status, mod, inGroup, timedOut, cancelIn, resp, ans, leftUnreaped, projectWritten>>

\* The server kills a request's run: its whole group, or under M_KILLONE tlapm alone.
KillRun(r) ==
    /\ tl' = [tl EXCEPT ![r] = IF @ = "alive" THEN "killed" ELSE @]
    /\ bk' = [bk EXCEPT ![r] = IF @ = "alive" /\ GroupKill /\ inGroup[r] THEN "dead" ELSE @]
    /\ zombie' = [zombie EXCEPT ![r] = @ \/ tl[r] = "alive" \/ (bk[r] = "alive" /\ GroupKill /\ inGroup[r])]

\* The run's time limit passes while tlapm runs.
Timeout(r) ==
    /\ status[r] = "running" /\ tl[r] = "alive"
    /\ timedOut' = [timedOut EXCEPT ![r] = TRUE]
    /\ KillRun(r)
    /\ UNCHANGED <<status, mod, outcome, inGroup, cancelIn, resp, ans, leftUnreaped, projectWritten>>

\* The server reaps every dead child, tlapm's orphans with it.
Reap(r) ==
    /\ zombie[r]
    /\ ReapFirst
    /\ zombie' = [zombie EXCEPT ![r] = FALSE]
    /\ UNCHANGED <<status, mod, tl, outcome, bk, inGroup, timedOut, cancelIn, resp, ans, leftUnreaped, projectWritten>>

\* The server answers, once what it waits for has ended and been reaped.
Answer(r) ==
    /\ status[r] = "running"
    /\ tl[r] \in {"exited", "killed"}
    /\ Ended(r) /\ Reaped(r)
    /\ status' = [status EXCEPT ![r] = "answered"]
    /\ resp' = [resp EXCEPT ![r] = @ + 1]
    /\ ans' = [ans EXCEPT ![r] =
                 IF timedOut[r] THEN "timeout"
                 ELSE IF (IF ByOutput THEN outcome[r] = "proved" ELSE tl[r] = "exited") THEN "success"
                 ELSE "failure"]
    /\ leftUnreaped' = [leftUnreaped EXCEPT ![r] = zombie[r]]
    /\ UNCHANGED <<mod, tl, outcome, bk, inGroup, zombie, timedOut, cancelIn, projectWritten>>

\* The client's cancel arrives: while the request waits or runs, or after its response, crossing it.
CancelArrives(r) ==
    /\ status[r] \in {"waiting", "running", "answered"}
    /\ ~cancelIn[r]
    /\ cancelIn' = [cancelIn EXCEPT ![r] = TRUE]
    /\ UNCHANGED <<status, mod, tl, outcome, bk, inGroup, zombie, timedOut, resp, ans, leftUnreaped, projectWritten>>

\* The server acts on a cancel for a request that waits or runs: it kills the run, and sends nothing.
Cancel(r) ==
    /\ cancelIn[r] /\ status[r] \in {"waiting", "running"}
    /\ status' = [status EXCEPT ![r] = "cancelling"]
    /\ KillRun(r)
    /\ UNCHANGED <<mod, outcome, inGroup, timedOut, cancelIn, resp, ans, leftUnreaped, projectWritten>>

\* The cancel is done once what the server waits for has ended and been reaped. Under M_ANSWERCANCEL it is
\* answered, with an error.
CancelDone(r) ==
    /\ status[r] = "cancelling"
    /\ Ended(r) /\ Reaped(r)
    /\ status' = [status EXCEPT ![r] = "cancelled"]
    /\ resp' = [resp EXCEPT ![r] = IF Silent THEN @ ELSE @ + 1]
    /\ leftUnreaped' = [leftUnreaped EXCEPT ![r] = zombie[r]]
    /\ UNCHANGED <<mod, tl, outcome, bk, inGroup, zombie, timedOut, cancelIn, ans, projectWritten>>

\* Under M_LATECANCEL, a cancel that arrives after the response is answered again.
LateCancel(r) ==
    /\ ~LateIgnored
    /\ cancelIn[r] /\ status[r] = "answered" /\ resp[r] = 1
    /\ resp' = [resp EXCEPT ![r] = 2]
    /\ UNCHANGED <<status, mod, tl, outcome, bk, inGroup, zombie, timedOut, cancelIn, ans, leftUnreaped,
                   projectWritten>>

Next ==
    \/ \E r \in Reqs, m \in Modules : Arrive(r, m)
    \/ \E r \in Reqs : \/ Start(r) \/ Spawn(r) \/ BackendEnds(r) \/ TlapmEnds(r) \/ Timeout(r) \/ Reap(r)
                       \/ Answer(r) \/ CancelArrives(r) \/ Cancel(r) \/ CancelDone(r) \/ LateCancel(r)

Spec == Init /\ [][Next]_vars
SpecLive == /\ Spec
            /\ \A r \in Reqs : /\ SF_vars(Start(r)) /\ WF_vars(TlapmEnds(r)) /\ WF_vars(BackendEnds(r))
                               /\ WF_vars(Reap(r)) /\ WF_vars(Answer(r)) /\ WF_vars(Cancel(r))
                               /\ WF_vars(CancelDone(r))

\* ADR-0016 item 4.
AtMostOneAnswer == \A r \in Reqs : resp[r] <= 1 /\ (status[r] = "cancelled" => resp[r] = 0)
SuccessOnlyComplete == \A r \in Reqs : ans[r] = "success" => (outcome[r] = "proved" /\ ~timedOut[r])
NoProcessOutlives == \A r \in Reqs : status[r] \in {"answered", "cancelled"} => ~Writing(r)
OneWriterPerCache == \A r, o \in Reqs : (r # o /\ Writing(r) /\ Writing(o)) => CacheOf(r) # CacheOf(o)
NothingInProject == ~projectWritten
AllReaped == \A r \in Reqs : ~leftUnreaped[r]

Safe == /\ TypeOK /\ AtMostOneAnswer /\ SuccessOnlyComplete /\ NoProcessOutlives /\ OneWriterPerCache
        /\ NothingInProject /\ AllReaped

EveryRequestEnds == \A r \in Reqs : (status[r] \in {"waiting", "running", "cancelling"})
                                        ~> (status[r] \in {"answered", "cancelled"})
WaitingRuns == \A r \in Reqs : (status[r] = "waiting") ~> (status[r] \in {"running", "cancelling", "cancelled"})
NoBehaviour == <>FALSE

\* Witnesses: each must be VIOLATED under none, so that what it denies can happen.
NeverAnswered == \A r \in Reqs : status[r] # "answered"
NeverSuccess == \A r \in Reqs : ans[r] # "success"
NeverFailure == \A r \in Reqs : ans[r] # "failure"
NeverTimeout == \A r \in Reqs : ans[r] # "timeout"
NeverCancelled == \A r \in Reqs : status[r] # "cancelled"
NeverLateCancel == \A r \in Reqs : ~(cancelIn[r] /\ status[r] = "answered")
NeverTwoRunning == Cardinality({r \in Reqs : tl[r] = "alive"}) < 2
NeverQueued == \A r \in Reqs : ~(status[r] = "waiting" /\ \E o \in Reqs \ {r} : Holds(o) /\ CacheOf(o) = CacheOf(r))
NeverZombie == \A r \in Reqs : ~zombie[r]
=============================================================================
