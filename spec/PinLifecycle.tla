---------------------------- MODULE PinLifecycle ----------------------------
(* tla-kit's pin and release process, as ADR-0005, ADR-0013, ADR-0014 and ADR-0017 describe it (ADR-0015).

   The parties act each at its own time, and each action names the record item it comes from:
     upstream          stops serving a pin value                            ADR-0005 Context; ADR-0013 item 4
     the custodian     opens a pull request that moves one pin, merges it,  ADR-0013 item 2; ADR-0014 items 1, 2
                       pushes a release tag, uploads a kept copy            ADR-0005 item 2; ADR-0017 item 1
     CI                builds a pull request's candidate and runs its       ADR-0013 item 3; ADR-0014 item 1
                       evidence
     the release       builds from the tag, publishes, attaches the kept    ADR-0005 item 2; ADR-0014 items 3, 4;
     workflow          copies                                               ADR-0017 item 2
     the weekly check  reports what upstream stopped serving, and opens a   ADR-0013 items 4 and 7
                       served-state pull request for a pin's current value
     the registry      holds every published digest; withdraws one only     ADR-0014 item 5
                       with a record
     a project         pins a published digest and keeps it in its history ADR-0014 items 5 and 6

   Abstracted (ADR-0015 item 3): an image is the tuple of its pin values; time is not modelled, and the weekly
   cadence is fairness; a version is the kind of move a release holds; the scan, the SBOM, the attestation, the
   licence notices and the copyleft parts' source are left out. Four pins: "prover", "jar" and "smt" are checker
   pins, and "base" is the runtime pin (the base digest and the apt snapshot move together, ADR-0013 item 2).
   "smt" is cvc5, ethos and cvc5's CPC signature, which move together (ADR-0017 item 4). The prover and smt have
   kept copies here (ADR-0005 item 2; ADR-0017 items 1 and 2); the jar and the base do not. Each pin has two
   values: 1, pinned when the process starts, and 2, a later build upstream already serves. Upstream may stop
   serving a pin's value 1, once and for good; that is also what a rolling tag rebuilt under the same name does to
   the build it named. The kept pins' value 1 is kept from the start.

   Mut = "none" is the records with ADR-0015's four fixes. Each mutation removes one fix, and must break the
   property beside it and no other:
     M_NOF1  F1 removed: a pull request merges on a pass against any main, not the main it merges into.
                                                                              EvidenceFitsRelease (gap 1)
     M_NOF2  F2 removed: a move of a kept pin is opened before its kept copy is uploaded; the copy is kept only
             when a release attaches it.                                      BuildsFromKept (gap 2)
     M_NOF3  F3 removed: no upstream is named as keeping what it serves, so the base's and the jar's upstreams
             may stop serving too. (With F3 only the kept pins' upstreams may.)
                                                                              ReleasesRebuildable (gap 3)
     M_NOF4  F4 removed: a served-state log entry is filed under its pin's value at the merge, not the value it
             is about. With F4 the entry names its value, and when that value is no longer the pin's current
             one, nothing is filed (ADR-0013 item 7).                         LogFiledRight (gap 4)
     M_ASWRITTEN  the records as they stand, with none of the four fixes. This is the one mutation that removes
             more than one guard: ADR-0015 item 5 asks for a row of the records as written, and that row is
             four removals at once. It must break all four properties.
   The fixes are F1 to F4 of ADR-0015 item 5: a pull request tested against the main it merges into; the kept
   copy uploaded before the pull request that names it; Durable naming Docker Hub, Ubuntu's snapshot archive and
   GitHub's releases; a log entry that names its value. Each is now written in its record: F1 in ADR-0014 item 1,
   F2 in ADR-0005 item 2, F3 in ADR-0013 item 8, F4 in ADR-0013 item 7.

   Properties:
     EvidenceFitsRelease   every release's evidence was run on the image it publishes             gap 1
     BuildsFromKept        no build of a kept pin's value takes it from upstream                  gap 2
                           (ADR-0005 item 2; ADR-0017 item 2)
     ReleasesRebuildable   every release's pins are still served, or kept here                   gap 3
     LogFiledRight         every served-state log entry is filed under the value it is about     gap 4
     CitationsResolve      every digest a project pinned is in the registry, or was withdrawn
                           with a record (ADR-0014 item 5)
     VersionFitsMove       a release's kind is the kind of its move from the previous release
                           (ADR-0014 item 2): checker pins moved, major; the runtime, minor
   and three action properties: TagsDoNotMove (a released tag keeps its image), LogAppendOnly (no log entry
   changes or goes), OneMovePerPR (a merge moves at most one pin). CitationsResolve, VersionFitsMove and the
   action properties hold under every mutation, by construction at this abstraction: the records give the rule
   and the model applies it. VersionFitsMove holds only because the custodian applies ADR-0013's kinds strictly
   (ADR-0014's Consequences); nothing in the records checks that, and the model does not test it.

   Liveness, under weak fairness of the weekly check and of merging its pull request: whatever upstream stops
   serving is eventually reported (UpstreamReported).

   Witnesses, each to be VIOLATED under none: NeverTwoOpen, NeverBothMerged, NeverProverMoved, NeverSmtMoved,
   NeverTwoReleases, NeverMajor, NeverUpstreamGone, NeverLogged, NeverPinned, NeverRegistryWithdrawn, NeverDropped (F4's closing of a
   served-state pull request whose value is no longer current happens).

   Without F2, CI that finds no kept copy of a kept pin's value builds it from upstream: the Dockerfile has no copy
   to build from, and BuildsFromKept records that the build used another source. *)
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Mut
ASSUME MutKnown == Mut \in {"none", "M_NOF1", "M_NOF2", "M_NOF3", "M_NOF4", "M_ASWRITTEN"}

\* The four fixes, each removed by its own mutation and all of them by M_ASWRITTEN.
F1 == Mut \notin {"M_NOF1", "M_ASWRITTEN"}
F2 == Mut \notin {"M_NOF2", "M_ASWRITTEN"}
F3 == Mut \notin {"M_NOF3", "M_ASWRITTEN"}
F4 == Mut \notin {"M_NOF4", "M_ASWRITTEN"}

Pins  == {"prover", "jar", "base", "smt"}
KeptPins == {"prover", "smt"}           \* kept here: ADR-0005 item 2; ADR-0017 item 1
CheckerPins == {"prover", "jar", "smt"} \* ADR-0013 item 1
Vals  == {1, 2}
Ids   == {1, 2}            \* two pull requests that move a pin, open at once if the custodian likes
Images == [Pins -> Vals]
Start == [p \in Pins |-> 1]
MaxReleases == 2

\* F3: the upstreams taken to keep what they serve. The kept pins' are never among them.
DurablePins == IF F3 THEN {"jar", "base"} ELSE {}

VARIABLES gone,        \* pins whose value 1 upstream no longer serves
          reported,    \* the pins in gone that the weekly check has reported
          kept,        \* for each kept pin, the values with a kept copy here
          main,        \* the pins on main
          prs,         \* pin-moving pull requests
          evidence,    \* the image the evidence of the last merge to main was run on
          fromUpstream,\* a build took a kept pin's value from upstream, not from its kept copy
          releases,    \* the releases, in order
          registry,    \* published images still in the registry
          withdrawn,   \* images withdrawn from the registry, each with a record
          pinned,      \* every image the project has pinned
          logPR,       \* the open served-state pull request, if any
          log,         \* the served-state log entries filed
          dropped      \* a served-state pull request was closed with nothing filed, its value no longer current

vars == <<gone, reported, kept, main, prs, evidence, fromUpstream, releases, registry, withdrawn, pinned, logPR, log,
          dropped>>

NoPR  == [status |-> "none", pin |-> "prover", tested |-> FALSE, on |-> Start]
NoLog == [open |-> FALSE, pin |-> "prover", observed |-> 1]
PRRec  == [status : {"none", "open", "merged"}, pin : Pins, tested : BOOLEAN, on : Images]
LogPRRec == [open : BOOLEAN, pin : Pins, observed : Vals]
LogRec == [pin : Pins, val : Vals, observed : Vals]
Kinds == {"initial", "major", "minor", "patch"}
RelRec == [image : Images, evidence : Images, kind : Kinds]

TypeOK ==
  /\ gone \subseteq Pins
  /\ reported \subseteq gone
  /\ kept \in [KeptPins -> SUBSET Vals]
  /\ main \in Images
  /\ prs \in [Ids -> PRRec]
  /\ evidence \in Images
  /\ fromUpstream \in BOOLEAN
  /\ releases \in Seq(RelRec)
  /\ registry \subseteq Images
  /\ withdrawn \subseteq Images
  /\ pinned \subseteq Images
  /\ logPR \in LogPRRec
  /\ log \subseteq LogRec
  /\ dropped \in BOOLEAN

Served(p, v) == v = 2 \/ p \notin gone
\* A value can be built when upstream serves it, or, for a kept pin, when it is kept here.
Available(p, v) == Served(p, v) \/ (p \in KeptPins /\ v \in kept[p])
\* Some kept pin's value in img has no kept copy, so a build takes it from upstream.
NotKept(img) == \E p \in KeptPins : img[p] \notin kept[p]
Buildable(img) == \A p \in Pins : Available(p, img[p])
Moved(img, p) == [img EXCEPT ![p] = 2]

KindOf(old, new) ==
  IF \E p \in CheckerPins : old[p] # new[p] THEN "major"
  ELSE IF old["base"] # new["base"] THEN "minor" ELSE "patch"

Init ==
  /\ gone = {}
  /\ reported = {}
  /\ kept = [p \in KeptPins |-> {1}]
  /\ main = Start
  /\ prs = [i \in Ids |-> NoPR]
  /\ evidence = Start           \* the starting image's evidence is taken as run (Phase 1c's first release)
  /\ fromUpstream = FALSE
  /\ releases = << >>
  /\ registry = {}
  /\ withdrawn = {}
  /\ pinned = {}
  /\ logPR = NoLog
  /\ log = {}
  /\ dropped = FALSE

(* ---- upstream: ADR-0005 Context; ADR-0013 item 4 ---- *)
StopServing(p) ==
  /\ p \notin gone
  /\ p \notin DurablePins
  /\ gone' = gone \cup {p}
  /\ UNCHANGED <<reported, kept, main, prs, evidence, fromUpstream, releases, registry, withdrawn, pinned, logPR, log, dropped>>

(* ---- the custodian: ADR-0005 item 2; ADR-0013 item 2; ADR-0014 items 1 and 2; ADR-0017 item 1 ---- *)
\* F2: the kept copy is uploaded before the pull request that names it. Without F2, a copy is kept only when a
\* release attaches it (Release).
KeepCopy(p) ==
  /\ F2
  /\ 2 \notin kept[p]
  /\ kept' = [kept EXCEPT ![p] = @ \cup {2}]
  /\ UNCHANGED <<gone, reported, main, prs, evidence, fromUpstream, releases, registry, withdrawn, pinned, logPR, log, dropped>>

OpenPR(i, p) ==
  /\ prs[i].status = "none"
  /\ main[p] = 1
  /\ \A j \in Ids : prs[j].status = "open" => prs[j].pin # p
  /\ (F2 /\ p \in KeptPins) => 2 \in kept[p]
  /\ prs' = [prs EXCEPT ![i] = [status |-> "open", pin |-> p, tested |-> FALSE, on |-> Start]]
  /\ UNCHANGED <<gone, reported, kept, main, evidence, fromUpstream, releases, registry, withdrawn, pinned, logPR, log, dropped>>

\* CI builds the candidate, main as it is now with the pull request's move, and runs its evidence on it. It may
\* run again on a later main. Without a kept copy of a kept pin's value, it builds that value from upstream.
CI(i) ==
  LET cand == Moved(main, prs[i].pin) IN
  /\ prs[i].status = "open"
  /\ ~(prs[i].tested /\ prs[i].on = cand)
  /\ Buildable(cand)
  /\ prs' = [prs EXCEPT ![i].tested = TRUE, ![i].on = cand]
  /\ fromUpstream' = (fromUpstream \/ NotKept(cand))
  /\ UNCHANGED <<gone, reported, kept, main, evidence, releases, registry, withdrawn, pinned, logPR, log, dropped>>

\* main merges only on a pass (ADR-0014 item 1). F1: the pass was against main as it is now.
Merge(i) ==
  /\ prs[i].status = "open"
  /\ prs[i].tested
  /\ F1 => prs[i].on = Moved(main, prs[i].pin)
  /\ main' = Moved(main, prs[i].pin)
  /\ evidence' = prs[i].on
  /\ prs' = [prs EXCEPT ![i].status = "merged"]
  /\ UNCHANGED <<gone, reported, kept, fromUpstream, releases, registry, withdrawn, pinned, logPR, log, dropped>>

(* ---- the release workflow: ADR-0005 item 2; ADR-0014 items 2 to 4; ADR-0017 item 2 ---- *)
\* A tag on main: build main, publish it, record the evidence of what was merged, attach the kept copies.
Release ==
  /\ Len(releases) < MaxReleases
  /\ IF releases = << >> THEN TRUE ELSE releases[Len(releases)].image # main
  /\ Buildable(main)
  /\ fromUpstream' = (fromUpstream \/ NotKept(main))
  /\ kept' = [p \in KeptPins |-> kept[p] \cup {main[p]}]
  /\ releases' = Append(releases, [image |-> main, evidence |-> evidence,
                                   kind |-> IF releases = << >> THEN "initial"
                                            ELSE KindOf(releases[Len(releases)].image, main)])
  /\ registry' = registry \cup {main}
  /\ UNCHANGED <<gone, reported, main, prs, evidence, withdrawn, pinned, logPR, log, dropped>>

(* ---- the registry and the project: ADR-0014 items 5 and 6 ---- *)
Withdraw(d) ==
  /\ d \in registry
  /\ registry' = registry \ {d}
  /\ withdrawn' = withdrawn \cup {d}
  /\ UNCHANGED <<gone, reported, kept, main, prs, evidence, fromUpstream, releases, pinned, logPR, log, dropped>>

ProjectPins(d) ==
  /\ d \in registry
  /\ d \notin pinned
  /\ pinned' = pinned \cup {d}
  /\ UNCHANGED <<gone, reported, kept, main, prs, evidence, fromUpstream, releases, registry, withdrawn, logPR, log, dropped>>

(* ---- the weekly check: ADR-0013 items 4 and 7 ---- *)
\* It reports what upstream stopped serving. When that is a pin's current value, it also opens a served-state
\* pull request, which moves no pin; it waits while another is open.
Observe(p) ==
  /\ p \in gone \ reported
  /\ main[p] = 1 => ~logPR.open
  /\ reported' = reported \cup {p}
  /\ logPR' = IF main[p] = 1 THEN [open |-> TRUE, pin |-> p, observed |-> 1] ELSE logPR
  /\ UNCHANGED <<gone, kept, main, prs, evidence, fromUpstream, releases, registry, withdrawn, pinned, log, dropped>>

\* Without F4, the entry is filed under its pin's value at the merge (ADR-0013 item 7 starts a new log when a pin
\* moves). F4: the entry names the value it is about, and when the pin has moved past that value the pull request
\* is closed with nothing filed.
MergeLog ==
  /\ logPR.open
  /\ log' = IF ~F4 THEN log \cup {[pin |-> logPR.pin, val |-> main[logPR.pin], observed |-> logPR.observed]}
            ELSE IF main[logPR.pin] = logPR.observed
                 THEN log \cup {[pin |-> logPR.pin, val |-> logPR.observed, observed |-> logPR.observed]}
                 ELSE log
  /\ dropped' = (dropped \/ (F4 /\ main[logPR.pin] # logPR.observed))
  /\ logPR' = NoLog
  /\ UNCHANGED <<gone, reported, kept, main, prs, evidence, fromUpstream, releases, registry, withdrawn, pinned>>

Next ==
  \/ \E p \in Pins : StopServing(p)
  \/ \E p \in KeptPins : KeepCopy(p)
  \/ \E i \in Ids, p \in Pins : OpenPR(i, p)
  \/ \E i \in Ids : CI(i) \/ Merge(i)
  \/ Release
  \/ \E d \in Images : Withdraw(d) \/ ProjectPins(d)
  \/ \E p \in Pins : Observe(p)
  \/ MergeLog

Spec == Init /\ [][Next]_vars
SpecLive == Spec /\ (\A p \in Pins : WF_vars(Observe(p))) /\ WF_vars(MergeLog)

(* ---- properties ---- *)
EvidenceFitsRelease == \A n \in 1..Len(releases) : releases[n].evidence = releases[n].image
BuildsFromKept == ~fromUpstream
ReleasesRebuildable == \A n \in 1..Len(releases) : Buildable(releases[n].image)
LogFiledRight == \A e \in log : e.val = e.observed
CitationsResolve == \A d \in pinned : d \in registry \/ d \in withdrawn
VersionFitsMove == \A n \in 2..Len(releases) : releases[n].kind = KindOf(releases[n - 1].image, releases[n].image)

Safe == TypeOK /\ EvidenceFitsRelease /\ BuildsFromKept /\ ReleasesRebuildable /\ LogFiledRight
        /\ CitationsResolve /\ VersionFitsMove

TagsDoNotMove == [][\A n \in 1..Len(releases) : Len(releases') >= n /\ releases'[n] = releases[n]]_vars
LogAppendOnly == [][log \subseteq log']_vars
OneMovePerPR == [][Cardinality({p \in Pins : main'[p] # main[p]}) <= 1]_vars

UpstreamReported == \A p \in Pins : (p \in gone) ~> (p \in reported)
NoBehaviour == <>FALSE

(* ---- witnesses: each must be VIOLATED ---- *)
NeverTwoOpen == ~(\A i \in Ids : prs[i].status = "open")
NeverBothMerged == ~(\A i \in Ids : prs[i].status = "merged")
NeverProverMoved == main["prover"] = 1
NeverSmtMoved == main["smt"] = 1
NeverTwoReleases == Len(releases) < 2
NeverMajor == \A n \in 1..Len(releases) : releases[n].kind # "major"
NeverUpstreamGone == gone = {}
NeverLogged == log = {}
NeverPinned == pinned = {}
NeverRegistryWithdrawn == withdrawn = {}
NeverDropped == ~dropped
=============================================================================
