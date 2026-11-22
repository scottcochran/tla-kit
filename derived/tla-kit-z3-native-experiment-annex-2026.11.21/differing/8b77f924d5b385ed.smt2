;; Proof obligation:
;;	ASSUME NEW CONSTANT CONSTANT_Mut_,
;;	       NEW CONSTANT CONSTANT_K_,
;;	       NEW CONSTANT CONSTANT_R_,
;;	       NEW CONSTANT CONSTANT_MaxRound_,
;;	       NEW VARIABLE VARIABLE_round_,
;;	       NEW VARIABLE VARIABLE_tLive_,
;;	       NEW VARIABLE VARIABLE_seq_,
;;	       NEW VARIABLE VARIABLE_oLease_,
;;	       NEW VARIABLE VARIABLE_fresh_,
;;	       NEW VARIABLE VARIABLE_mark_,
;;	       NEW VARIABLE VARIABLE_seal_,
;;	       NEW VARIABLE VARIABLE_admittedUnlive_,
;;	       NEW VARIABLE VARIABLE_refusedForCorr_,
;;	       NEW VARIABLE VARIABLE_refused_,
;;	       CONSTANT_Mut_ # "M_MARK" ,
;;	       CONSTANT_Mut_ # "M_ROUNDS" ,
;;	       CONSTANT_Mut_ # "M_NOCOUPLE" ,
;;	       STATE_InvU_ ,
;;	       ACTION_Next_ \/ ?hN65KUIMHSNQTEPSC2KGVDJJ2VM = STATE_vars_ ,
;;	       VARIABLE_tLive_ /\ STATE_Allowed_ ,
;;	       ?VARIABLE_seq_#prime = VARIABLE_seq_ + 1 ,
;;	       ?VARIABLE_round_#prime = VARIABLE_round_ ,
;;	       ?VARIABLE_mark_#prime = VARIABLE_mark_ ,
;;	       ?VARIABLE_seal_#prime = VARIABLE_seal_ ,
;;	       VARIABLE_round_ >= 1
;;	       /\ VARIABLE_seq_ - VARIABLE_mark_[VARIABLE_round_] < CONSTANT_K_ ,
;;	       VARIABLE_mark_[VARIABLE_round_] \in Nat /\ VARIABLE_seq_ \in Nat ,
;;	       CONSTANT_K_ \in Nat 
;;	PROVE  ?VARIABLE_round_#prime >= 1
;;	       => ?VARIABLE_seq_#prime
;;	          - ?VARIABLE_mark_#prime[?VARIABLE_round_#prime] =< CONSTANT_K_
;; TLA+ Proof Manager 9a52faf
;; Proof obligation #170
;; Generated from file "./Coupling_proof.tla", line 144, characters 9-10

(set-logic UFNIA)

;; Sorts

(declare-sort Idv 0)

;; Hypotheses

(declare-fun smt__TLA____Anon__OPAQUE__hN65KUIMHSNQTEPSC2KGVDJJ2VM () Idv)

(declare-fun smt__TLA____Cast__Int (Int) Idv)

(declare-fun smt__TLA____FunApp (Idv Idv) Idv)

(declare-fun smt__TLA____FunDom (Idv) Idv)

; omitted declaration of 'TLA__FunFcn' (second-order)

(declare-fun smt__TLA____FunIsafcn (Idv) Bool)

(declare-fun smt__TLA____IntLteq (Idv Idv) Bool)

(declare-fun smt__TLA____IntMinus (Idv Idv) Idv)

(declare-fun smt__TLA____IntPlus (Idv Idv) Idv)

(declare-fun smt__TLA____IntSet () Idv)

(declare-fun smt__TLA____Mem (Idv Idv) Bool)

(declare-fun smt__TLA____NatSet () Idv)

(declare-fun smt__TLA____Proj__Int (Idv) Int)

(declare-fun smt__TLA____SetExtTrigger (Idv Idv) Bool)

(declare-fun smt__TLA____StrLit__M__MARK () Idv)

(declare-fun smt__TLA____StrLit__M__NOCOUPLE () Idv)

(declare-fun smt__TLA____StrLit__M__ROUNDS () Idv)

(declare-fun smt__TLA____StrSet () Idv)

(declare-fun smt__TLA____Tt__Idv () Idv)

;; Axiom: SetExt
(assert
  (!
    (forall ((smt__x Idv) (smt__y Idv))
      (!
        (=>
          (forall ((smt__z Idv))
            (= (smt__TLA____Mem smt__z smt__x)
              (smt__TLA____Mem smt__z smt__y))) (= smt__x smt__y))
        :pattern ((smt__TLA____SetExtTrigger smt__x smt__y))))
    :named |SetExt|))

;; Axiom: NatSetDef
(assert
  (!
    (forall ((smt__x Idv))
      (!
        (= (smt__TLA____Mem smt__x smt__TLA____NatSet)
          (and (smt__TLA____Mem smt__x smt__TLA____IntSet)
            (smt__TLA____IntLteq (smt__TLA____Cast__Int 0) smt__x)))
        :pattern ((smt__TLA____Mem smt__x smt__TLA____NatSet))))
    :named |NatSetDef|))

;; Axiom: FunExt
(assert
  (!
    (forall ((smt__f Idv) (smt__g Idv))
      (!
        (=>
          (and (smt__TLA____FunIsafcn smt__f) (smt__TLA____FunIsafcn smt__g)
            (= (smt__TLA____FunDom smt__f) (smt__TLA____FunDom smt__g))
            (forall ((smt__x Idv))
              (=> (smt__TLA____Mem smt__x (smt__TLA____FunDom smt__f))
                (= (smt__TLA____FunApp smt__f smt__x)
                  (smt__TLA____FunApp smt__g smt__x))))) (= smt__f smt__g))
        :pattern ((smt__TLA____FunIsafcn smt__f)
                   (smt__TLA____FunIsafcn smt__g)))) :named |FunExt|))

; omitted fact (second-order)

; omitted fact (second-order)

; omitted fact (second-order)

;; Axiom: StrLitIsstr M_MARK
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__M__MARK smt__TLA____StrSet)
    :named |StrLitIsstr M_MARK|))

;; Axiom: StrLitIsstr M_NOCOUPLE
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__M__NOCOUPLE smt__TLA____StrSet)
    :named |StrLitIsstr M_NOCOUPLE|))

;; Axiom: StrLitIsstr M_ROUNDS
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__M__ROUNDS smt__TLA____StrSet)
    :named |StrLitIsstr M_ROUNDS|))

;; Axiom: StrLitDistinct M_NOCOUPLE M_MARK
(assert
  (! (distinct smt__TLA____StrLit__M__NOCOUPLE smt__TLA____StrLit__M__MARK)
    :named |StrLitDistinct M_NOCOUPLE M_MARK|))

;; Axiom: StrLitDistinct M_NOCOUPLE M_ROUNDS
(assert
  (! (distinct smt__TLA____StrLit__M__NOCOUPLE smt__TLA____StrLit__M__ROUNDS)
    :named |StrLitDistinct M_NOCOUPLE M_ROUNDS|))

;; Axiom: StrLitDistinct M_ROUNDS M_MARK
(assert
  (! (distinct smt__TLA____StrLit__M__ROUNDS smt__TLA____StrLit__M__MARK)
    :named |StrLitDistinct M_ROUNDS M_MARK|))

;; Axiom: CastInjAlt Int
(assert
  (!
    (forall ((smt__x Int))
      (! (= smt__x (smt__TLA____Proj__Int (smt__TLA____Cast__Int smt__x)))
        :pattern ((smt__TLA____Cast__Int smt__x)))) :named |CastInjAlt Int|))

;; Axiom: TypeGuardIntro Int
(assert
  (!
    (forall ((smt__z Int))
      (! (smt__TLA____Mem (smt__TLA____Cast__Int smt__z) smt__TLA____IntSet)
        :pattern ((smt__TLA____Cast__Int smt__z))))
    :named |TypeGuardIntro Int|))

;; Axiom: TypeGuardElim Int
(assert
  (!
    (forall ((smt__x Idv))
      (!
        (=> (smt__TLA____Mem smt__x smt__TLA____IntSet)
          (= smt__x (smt__TLA____Cast__Int (smt__TLA____Proj__Int smt__x))))
        :pattern ((smt__TLA____Mem smt__x smt__TLA____IntSet))))
    :named |TypeGuardElim Int|))

;; Axiom: Typing TIntPlus
(assert
  (!
    (forall ((smt__x1 Int) (smt__x2 Int))
      (!
        (=
          (smt__TLA____IntPlus (smt__TLA____Cast__Int smt__x1)
            (smt__TLA____Cast__Int smt__x2))
          (smt__TLA____Cast__Int (+ smt__x1 smt__x2)))
        :pattern ((smt__TLA____IntPlus (smt__TLA____Cast__Int smt__x1)
                    (smt__TLA____Cast__Int smt__x2)))))
    :named |Typing TIntPlus|))

;; Axiom: Typing TIntMinus
(assert
  (!
    (forall ((smt__x1 Int) (smt__x2 Int))
      (!
        (=
          (smt__TLA____IntMinus (smt__TLA____Cast__Int smt__x1)
            (smt__TLA____Cast__Int smt__x2))
          (smt__TLA____Cast__Int (- smt__x1 smt__x2)))
        :pattern ((smt__TLA____IntMinus (smt__TLA____Cast__Int smt__x1)
                    (smt__TLA____Cast__Int smt__x2)))))
    :named |Typing TIntMinus|))

;; Axiom: Typing TIntLteq
(assert
  (!
    (forall ((smt__x1 Int) (smt__x2 Int))
      (!
        (=
          (smt__TLA____IntLteq (smt__TLA____Cast__Int smt__x1)
            (smt__TLA____Cast__Int smt__x2)) (<= smt__x1 smt__x2))
        :pattern ((smt__TLA____IntLteq (smt__TLA____Cast__Int smt__x1)
                    (smt__TLA____Cast__Int smt__x2)))))
    :named |Typing TIntLteq|))

(declare-fun smt__CONSTANT__Mut__ () Idv)

(declare-fun smt__CONSTANT__K__ () Idv)

(declare-fun smt__CONSTANT__R__ () Idv)

(declare-fun smt__CONSTANT__MaxRound__ () Idv)

(declare-fun smt__CONSTANT__Rounds__ () Idv)

(declare-fun smt__VARIABLE__round__ () Idv)

(declare-fun smt__VARIABLE__round____prime () Idv)

(declare-fun smt__VARIABLE__tLive__ () Idv)

(declare-fun smt__VARIABLE__tLive____prime () Idv)

(declare-fun smt__VARIABLE__seq__ () Idv)

(declare-fun smt__VARIABLE__seq____prime () Idv)

(declare-fun smt__VARIABLE__oLease__ () Idv)

(declare-fun smt__VARIABLE__oLease____prime () Idv)

(declare-fun smt__VARIABLE__fresh__ () Idv)

(declare-fun smt__VARIABLE__fresh____prime () Idv)

(declare-fun smt__VARIABLE__mark__ () Idv)

(declare-fun smt__VARIABLE__mark____prime () Idv)

(declare-fun smt__VARIABLE__seal__ () Idv)

(declare-fun smt__VARIABLE__seal____prime () Idv)

(declare-fun smt__VARIABLE__admittedUnlive__ () Idv)

(declare-fun smt__VARIABLE__admittedUnlive____prime () Idv)

(declare-fun smt__VARIABLE__refusedForCorr__ () Idv)

(declare-fun smt__VARIABLE__refusedForCorr____prime () Idv)

(declare-fun smt__VARIABLE__refused__ () Idv)

(declare-fun smt__VARIABLE__refused____prime () Idv)

(declare-fun smt__STATE__vars__ () Idv)

(declare-fun smt__STATE__Init__ () Idv)

(declare-fun smt__CONSTANT__Coupled__ () Idv)

(declare-fun smt__STATE__LiveO__ () Idv)

(declare-fun smt__STATE__LiveC__ () Idv)

(declare-fun smt__ACTION__GrantT__ () Idv)

(declare-fun smt__STATE__Allowed__ () Idv)

(declare-fun smt__ACTION__Admit__ () Idv)

(declare-fun smt__ACTION__Refuse__ () Idv)

(declare-fun smt__ACTION__EndRoundT__ () Idv)

(declare-fun smt__ACTION__Heartbeat__ (Idv Idv) Idv)

(declare-fun smt__ACTION__CorrBeat__ () Idv)

(declare-fun smt__ACTION__Stale__ (Idv) Idv)

(declare-fun smt__ACTION__GrantO__ () Idv)

(declare-fun smt__ACTION__EndO__ () Idv)

(declare-fun smt__ACTION__Next__ () Idv)

(declare-fun smt__TEMPORAL__Spec__ () Idv)

(declare-fun smt__STATE__NoAdmitWithoutLiveObserver__ () Idv)

(declare-fun smt__STATE__Unread__ () Idv)

(declare-fun smt__STATE__PriorUnread__ () Idv)

(declare-fun smt__STATE__UnreadBounded__ () Idv)

(declare-fun smt__STATE__CorrelatorNeverGates__ () Idv)

(declare-fun smt__STATE__Safe__ () Idv)

(declare-fun smt__STATE__NeverRoundTwo__ () Idv)

(declare-fun smt__STATE__NeverRefused__ () Idv)

(declare-fun smt__STATE__NeverStaleRefusal__ () Idv)

(declare-fun smt__STATE__NeverBacklogRefusal__ () Idv)

; hidden fact

; hidden fact

; omitted declaration of 'CONSTANT_EnabledWrapper_' (second-order)

; omitted declaration of 'CONSTANT_CdotWrapper_' (second-order)

; hidden fact

; hidden fact

; hidden fact

(declare-fun smt__STATE__TypeOK__ () Idv)

(declare-fun smt__STATE__Future__ () Idv)

(declare-fun smt__STATE__MarkLeSeq__ () Idv)

(declare-fun smt__STATE__SealedIdle__ () Idv)

(declare-fun smt__STATE__Shape__ () Idv)

(declare-fun smt__STATE__Past__ () Idv)

(declare-fun smt__STATE__InvU__ () Idv)

; hidden fact

; hidden fact

; hidden fact

; hidden fact

(assert (distinct smt__CONSTANT__Mut__ smt__TLA____StrLit__M__MARK))

(assert (distinct smt__CONSTANT__Mut__ smt__TLA____StrLit__M__ROUNDS))

(assert (distinct smt__CONSTANT__Mut__ smt__TLA____StrLit__M__NOCOUPLE))

(assert (= smt__STATE__InvU__ smt__TLA____Tt__Idv))

(assert
  (or (= smt__ACTION__Next__ smt__TLA____Tt__Idv)
    (= smt__TLA____Anon__OPAQUE__hN65KUIMHSNQTEPSC2KGVDJJ2VM
      smt__STATE__vars__)))

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

(assert
  (and (= smt__VARIABLE__tLive__ smt__TLA____Tt__Idv)
    (= smt__STATE__Allowed__ smt__TLA____Tt__Idv)))

(assert
  (= smt__VARIABLE__seq____prime
    (smt__TLA____IntPlus smt__VARIABLE__seq__ (smt__TLA____Cast__Int 1))))

(assert (= smt__VARIABLE__round____prime smt__VARIABLE__round__))

(assert (= smt__VARIABLE__mark____prime smt__VARIABLE__mark__))

(assert (= smt__VARIABLE__seal____prime smt__VARIABLE__seal__))

(assert
  (and (smt__TLA____IntLteq (smt__TLA____Cast__Int 1) smt__VARIABLE__round__)
    (and
      (smt__TLA____IntLteq
        (smt__TLA____IntMinus smt__VARIABLE__seq__
          (smt__TLA____FunApp smt__VARIABLE__mark__ smt__VARIABLE__round__))
        smt__CONSTANT__K__)
      (distinct
        (smt__TLA____IntMinus smt__VARIABLE__seq__
          (smt__TLA____FunApp smt__VARIABLE__mark__ smt__VARIABLE__round__))
        smt__CONSTANT__K__))))

(assert
  (and
    (smt__TLA____Mem
      (smt__TLA____FunApp smt__VARIABLE__mark__ smt__VARIABLE__round__)
      smt__TLA____NatSet)
    (smt__TLA____Mem smt__VARIABLE__seq__ smt__TLA____NatSet)))

(assert (smt__TLA____Mem smt__CONSTANT__K__ smt__TLA____NatSet))

;; Goal
(assert
  (!
    (not
      (=>
        (smt__TLA____IntLteq (smt__TLA____Cast__Int 1)
          smt__VARIABLE__round____prime)
        (smt__TLA____IntLteq
          (smt__TLA____IntMinus smt__VARIABLE__seq____prime
            (smt__TLA____FunApp smt__VARIABLE__mark____prime
              smt__VARIABLE__round____prime)) smt__CONSTANT__K__)))
    :named |Goal|))

(check-sat)
(exit)
