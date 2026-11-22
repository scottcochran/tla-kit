;; Proof obligation:
;;	ASSUME NEW CONSTANT CONSTANT_Mut_,
;;	       NEW CONSTANT CONSTANT_MaxActs_,
;;	       NEW CONSTANT CONSTANT_MaxTick_,
;;	       NEW CONSTANT CONSTANT_FreshT_,
;;	       NEW VARIABLE VARIABLE_relLive_,
;;	       NEW VARIABLE VARIABLE_contact_,
;;	       NEW VARIABLE VARIABLE_tick_,
;;	       NEW VARIABLE VARIABLE_obsLive_,
;;	       NEW VARIABLE VARIABLE_agentBusy_,
;;	       NEW VARIABLE VARIABLE_nextId_,
;;	       NEW VARIABLE VARIABLE_acts_,
;;	       NEW VARIABLE VARIABLE_delivered_,
;;	       NEW VARIABLE VARIABLE_relayRefused_,
;;	       NEW VARIABLE VARIABLE_used_,
;;	       NEW VARIABLE VARIABLE_firedIds_,
;;	       NEW VARIABLE VARIABLE_standing_,
;;	       NEW VARIABLE VARIABLE_findings_,
;;	       NEW VARIABLE VARIABLE_notPerson_,
;;	       NEW VARIABLE VARIABLE_notCommanded_,
;;	       NEW VARIABLE VARIABLE_replayed_,
;;	       NEW VARIABLE VARIABLE_stale_,
;;	       NEW VARIABLE VARIABLE_noContact_,
;;	       NEW VARIABLE VARIABLE_seen_,
;;	       /\ VARIABLE_relLive_ \in BOOLEAN
;;	       /\ VARIABLE_contact_ \in BOOLEAN
;;	       /\ VARIABLE_obsLive_ \in BOOLEAN
;;	       /\ VARIABLE_agentBusy_ \in BOOLEAN
;;	       /\ VARIABLE_tick_ \in Nat
;;	       /\ VARIABLE_nextId_ \in Nat
;;	       /\ VARIABLE_nextId_ >= 1
;;	       /\ VARIABLE_acts_ \in [CONSTANT_Ids_ -> CONSTANT_ActRec_]
;;	       /\ VARIABLE_delivered_ \subseteq CONSTANT_Ids_
;;	       /\ VARIABLE_relayRefused_ \subseteq CONSTANT_Ids_
;;	       /\ VARIABLE_used_ \in [CONSTANT_Vehicles_ -> SUBSET CONSTANT_Ids_]
;;	       /\ VARIABLE_firedIds_ \subseteq CONSTANT_Ids_
;;	       /\ VARIABLE_standing_ \subseteq CONSTANT_Ids_
;;	       /\ VARIABLE_findings_ \subseteq CONSTANT_Ids_
;;	       /\ VARIABLE_notPerson_ \in BOOLEAN
;;	       /\ VARIABLE_notCommanded_ \in BOOLEAN
;;	       /\ VARIABLE_replayed_ \in BOOLEAN
;;	       /\ VARIABLE_stale_ \in BOOLEAN
;;	       /\ VARIABLE_noContact_ \in BOOLEAN ,
;;	       ACTION_AdmitRelease_ \/ ACTION_AdmitAgent_
;;	       \/ (\E CONSTANT_s_ \in {"person", "agent"} :
;;	              ACTION_LiteOriginate_(CONSTANT_s_)) ,
;;	       NEW CONSTANT CONSTANT_v_ \in CONSTANT_Vehicles_,
;;	       ASSUME NEW CONSTANT CONSTANT_s_ \in {"person", "agent"},
;;	              NEW CONSTANT CONSTANT_pl_ \in {"cmd", "lite"},
;;	              NEW CONSTANT CONSTANT_v__1 \in CONSTANT_Vehicles_,
;;	              VARIABLE_tick_ \in Nat 
;;	       PROVE  /\ STATE_Act_(CONSTANT_s_, CONSTANT_pl_, CONSTANT_v__1)
;;	                 \in CONSTANT_ActRec_
;;	              /\ STATE_Act_(CONSTANT_s_, CONSTANT_pl_, CONSTANT_v__1)
;;	                 # CONSTANT_NoAct_
;;	              /\ STATE_Act_(CONSTANT_s_, CONSTANT_pl_, CONSTANT_v__1).vehicle
;;	                 \in CONSTANT_Vehicles_ 
;;	PROVE  /\ STATE_Act_("agent", "cmd", CONSTANT_v_) \in CONSTANT_ActRec_
;;	          /\ STATE_Act_("agent", "cmd", CONSTANT_v_) # CONSTANT_NoAct_
;;	       /\ STATE_Act_("agent", "cmd", CONSTANT_v_).vehicle
;;	          \in CONSTANT_Vehicles_
;; TLA+ Proof Manager 9a52faf
;; Proof obligation #28
;; Generated from file "./Release_proof.tla", line 112, characters 5-6

(set-logic UFNIA)

;; Sorts

(declare-sort Idv 0)

;; Hypotheses

(declare-fun smt__TLA____BoolSet () Idv)

(declare-fun smt__TLA____Cast__Int (Int) Idv)

(declare-fun smt__TLA____FunApp (Idv Idv) Idv)

(declare-fun smt__TLA____FunDom (Idv) Idv)

; omitted declaration of 'TLA__FunFcn' (second-order)

(declare-fun smt__TLA____FunIsafcn (Idv) Bool)

(declare-fun smt__TLA____FunSet (Idv Idv) Idv)

(declare-fun smt__TLA____IntLteq (Idv Idv) Bool)

(declare-fun smt__TLA____IntSet () Idv)

(declare-fun smt__TLA____Mem (Idv Idv) Bool)

(declare-fun smt__TLA____NatSet () Idv)

(declare-fun smt__TLA____Proj__Int (Idv) Int)

(declare-fun smt__TLA____SetEnum__2 (Idv Idv) Idv)

(declare-fun smt__TLA____SetExtTrigger (Idv Idv) Bool)

(declare-fun smt__TLA____StrLit__agent () Idv)

(declare-fun smt__TLA____StrLit__cmd () Idv)

(declare-fun smt__TLA____StrLit__lite () Idv)

(declare-fun smt__TLA____StrLit__person () Idv)

(declare-fun smt__TLA____StrLit__vehicle () Idv)

(declare-fun smt__TLA____StrSet () Idv)

(declare-fun smt__TLA____Subset (Idv) Idv)

(declare-fun smt__TLA____SubsetEq (Idv Idv) Bool)

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

;; Axiom: SubsetEqIntro
(assert
  (!
    (forall ((smt__x Idv) (smt__y Idv))
      (!
        (=>
          (forall ((smt__z Idv))
            (=> (smt__TLA____Mem smt__z smt__x)
              (smt__TLA____Mem smt__z smt__y)))
          (smt__TLA____SubsetEq smt__x smt__y))
        :pattern ((smt__TLA____SubsetEq smt__x smt__y))))
    :named |SubsetEqIntro|))

;; Axiom: SubsetEqElim
(assert
  (!
    (forall ((smt__x Idv) (smt__y Idv) (smt__z Idv))
      (!
        (=>
          (and (smt__TLA____SubsetEq smt__x smt__y)
            (smt__TLA____Mem smt__z smt__x)) (smt__TLA____Mem smt__z smt__y))
        :pattern ((smt__TLA____SubsetEq smt__x smt__y)
                   (smt__TLA____Mem smt__z smt__x)))) :named |SubsetEqElim|))

;; Axiom: SubsetDefAlt
(assert
  (!
    (forall ((smt__a Idv) (smt__x Idv))
      (!
        (= (smt__TLA____Mem smt__x (smt__TLA____Subset smt__a))
          (smt__TLA____SubsetEq smt__x smt__a))
        :pattern ((smt__TLA____Mem smt__x (smt__TLA____Subset smt__a)))
        :pattern ((smt__TLA____SubsetEq smt__x smt__a)
                   (smt__TLA____Subset smt__a)))) :named |SubsetDefAlt|))

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

;; Axiom: FunSetIntro
(assert
  (!
    (forall ((smt__a Idv) (smt__b Idv) (smt__f Idv))
      (!
        (=>
          (and (smt__TLA____FunIsafcn smt__f)
            (= (smt__TLA____FunDom smt__f) smt__a)
            (forall ((smt__x Idv))
              (=> (smt__TLA____Mem smt__x smt__a)
                (smt__TLA____Mem (smt__TLA____FunApp smt__f smt__x) smt__b))))
          (smt__TLA____Mem smt__f (smt__TLA____FunSet smt__a smt__b)))
        :pattern ((smt__TLA____Mem smt__f (smt__TLA____FunSet smt__a smt__b)))))
    :named |FunSetIntro|))

;; Axiom: FunSetElim1
(assert
  (!
    (forall ((smt__a Idv) (smt__b Idv) (smt__f Idv))
      (!
        (=> (smt__TLA____Mem smt__f (smt__TLA____FunSet smt__a smt__b))
          (and (smt__TLA____FunIsafcn smt__f)
            (= (smt__TLA____FunDom smt__f) smt__a)))
        :pattern ((smt__TLA____Mem smt__f (smt__TLA____FunSet smt__a smt__b)))))
    :named |FunSetElim1|))

;; Axiom: FunSetElim2
(assert
  (!
    (forall ((smt__a Idv) (smt__b Idv) (smt__f Idv) (smt__x Idv))
      (!
        (=>
          (and (smt__TLA____Mem smt__f (smt__TLA____FunSet smt__a smt__b))
            (smt__TLA____Mem smt__x smt__a))
          (smt__TLA____Mem (smt__TLA____FunApp smt__f smt__x) smt__b))
        :pattern ((smt__TLA____Mem smt__f (smt__TLA____FunSet smt__a smt__b))
                   (smt__TLA____Mem smt__x smt__a))
        :pattern ((smt__TLA____Mem smt__f (smt__TLA____FunSet smt__a smt__b))
                   (smt__TLA____FunApp smt__f smt__x)))) :named |FunSetElim2|))

; omitted fact (second-order)

; omitted fact (second-order)

; omitted fact (second-order)

;; Axiom: EnumDefIntro 2
(assert
  (!
    (forall ((smt__a1 Idv) (smt__a2 Idv))
      (!
        (and
          (smt__TLA____Mem smt__a1 (smt__TLA____SetEnum__2 smt__a1 smt__a2))
          (smt__TLA____Mem smt__a2 (smt__TLA____SetEnum__2 smt__a1 smt__a2)))
        :pattern ((smt__TLA____SetEnum__2 smt__a1 smt__a2))))
    :named |EnumDefIntro 2|))

;; Axiom: EnumDefElim 2
(assert
  (!
    (forall ((smt__a1 Idv) (smt__a2 Idv) (smt__x Idv))
      (!
        (=> (smt__TLA____Mem smt__x (smt__TLA____SetEnum__2 smt__a1 smt__a2))
          (or (= smt__x smt__a1) (= smt__x smt__a2)))
        :pattern ((smt__TLA____Mem smt__x
                    (smt__TLA____SetEnum__2 smt__a1 smt__a2)))))
    :named |EnumDefElim 2|))

;; Axiom: StrLitIsstr agent
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__agent smt__TLA____StrSet)
    :named |StrLitIsstr agent|))

;; Axiom: StrLitIsstr cmd
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__cmd smt__TLA____StrSet)
    :named |StrLitIsstr cmd|))

;; Axiom: StrLitIsstr lite
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__lite smt__TLA____StrSet)
    :named |StrLitIsstr lite|))

;; Axiom: StrLitIsstr person
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__person smt__TLA____StrSet)
    :named |StrLitIsstr person|))

;; Axiom: StrLitIsstr vehicle
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__vehicle smt__TLA____StrSet)
    :named |StrLitIsstr vehicle|))

;; Axiom: StrLitDistinct agent person
(assert
  (! (distinct smt__TLA____StrLit__agent smt__TLA____StrLit__person)
    :named |StrLitDistinct agent person|))

;; Axiom: StrLitDistinct cmd agent
(assert
  (! (distinct smt__TLA____StrLit__cmd smt__TLA____StrLit__agent)
    :named |StrLitDistinct cmd agent|))

;; Axiom: StrLitDistinct cmd person
(assert
  (! (distinct smt__TLA____StrLit__cmd smt__TLA____StrLit__person)
    :named |StrLitDistinct cmd person|))

;; Axiom: StrLitDistinct lite agent
(assert
  (! (distinct smt__TLA____StrLit__lite smt__TLA____StrLit__agent)
    :named |StrLitDistinct lite agent|))

;; Axiom: StrLitDistinct lite cmd
(assert
  (! (distinct smt__TLA____StrLit__lite smt__TLA____StrLit__cmd)
    :named |StrLitDistinct lite cmd|))

;; Axiom: StrLitDistinct lite person
(assert
  (! (distinct smt__TLA____StrLit__lite smt__TLA____StrLit__person)
    :named |StrLitDistinct lite person|))

;; Axiom: StrLitDistinct vehicle agent
(assert
  (! (distinct smt__TLA____StrLit__vehicle smt__TLA____StrLit__agent)
    :named |StrLitDistinct vehicle agent|))

;; Axiom: StrLitDistinct vehicle cmd
(assert
  (! (distinct smt__TLA____StrLit__vehicle smt__TLA____StrLit__cmd)
    :named |StrLitDistinct vehicle cmd|))

;; Axiom: StrLitDistinct vehicle lite
(assert
  (! (distinct smt__TLA____StrLit__vehicle smt__TLA____StrLit__lite)
    :named |StrLitDistinct vehicle lite|))

;; Axiom: StrLitDistinct vehicle person
(assert
  (! (distinct smt__TLA____StrLit__vehicle smt__TLA____StrLit__person)
    :named |StrLitDistinct vehicle person|))

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

(declare-fun smt__CONSTANT__MaxActs__ () Idv)

(declare-fun smt__CONSTANT__MaxTick__ () Idv)

(declare-fun smt__CONSTANT__FreshT__ () Idv)

(declare-fun smt__CONSTANT__Ids__ () Idv)

(declare-fun smt__CONSTANT__Vehicles__ () Idv)

(declare-fun smt__CONSTANT__NoAct__ () Idv)

(declare-fun smt__VARIABLE__relLive__ () Idv)

(declare-fun smt__VARIABLE__relLive____prime () Idv)

(declare-fun smt__VARIABLE__contact__ () Idv)

(declare-fun smt__VARIABLE__contact____prime () Idv)

(declare-fun smt__VARIABLE__tick__ () Idv)

(declare-fun smt__VARIABLE__tick____prime () Idv)

(declare-fun smt__VARIABLE__obsLive__ () Idv)

(declare-fun smt__VARIABLE__obsLive____prime () Idv)

(declare-fun smt__VARIABLE__agentBusy__ () Idv)

(declare-fun smt__VARIABLE__agentBusy____prime () Idv)

(declare-fun smt__VARIABLE__nextId__ () Idv)

(declare-fun smt__VARIABLE__nextId____prime () Idv)

(declare-fun smt__VARIABLE__acts__ () Idv)

(declare-fun smt__VARIABLE__acts____prime () Idv)

(declare-fun smt__VARIABLE__delivered__ () Idv)

(declare-fun smt__VARIABLE__delivered____prime () Idv)

(declare-fun smt__VARIABLE__relayRefused__ () Idv)

(declare-fun smt__VARIABLE__relayRefused____prime () Idv)

(declare-fun smt__VARIABLE__used__ () Idv)

(declare-fun smt__VARIABLE__used____prime () Idv)

(declare-fun smt__VARIABLE__firedIds__ () Idv)

(declare-fun smt__VARIABLE__firedIds____prime () Idv)

(declare-fun smt__VARIABLE__standing__ () Idv)

(declare-fun smt__VARIABLE__standing____prime () Idv)

(declare-fun smt__VARIABLE__findings__ () Idv)

(declare-fun smt__VARIABLE__findings____prime () Idv)

(declare-fun smt__VARIABLE__notPerson__ () Idv)

(declare-fun smt__VARIABLE__notPerson____prime () Idv)

(declare-fun smt__VARIABLE__notCommanded__ () Idv)

(declare-fun smt__VARIABLE__notCommanded____prime () Idv)

(declare-fun smt__VARIABLE__replayed__ () Idv)

(declare-fun smt__VARIABLE__replayed____prime () Idv)

(declare-fun smt__VARIABLE__stale__ () Idv)

(declare-fun smt__VARIABLE__stale____prime () Idv)

(declare-fun smt__VARIABLE__noContact__ () Idv)

(declare-fun smt__VARIABLE__noContact____prime () Idv)

(declare-fun smt__VARIABLE__seen__ () Idv)

(declare-fun smt__VARIABLE__seen____prime () Idv)

(declare-fun smt__STATE__vars__ () Idv)

(declare-fun smt__STATE__Act__ (Idv Idv Idv) Idv)

(declare-fun smt__STATE__Init__ () Idv)

(declare-fun smt__STATE__KeyOK__ (Idv) Idv)

(declare-fun smt__STATE__CertOK__ (Idv) Idv)

(declare-fun smt__STATE__VehicleOK__ (Idv Idv) Idv)

(declare-fun smt__STATE__UnusedOK__ (Idv Idv) Idv)

(declare-fun smt__STATE__FreshOK__ (Idv) Idv)

(declare-fun smt__STATE__Interlock__ (Idv Idv) Idv)

(declare-fun smt__STATE__LinkOK__ () Idv)

(declare-fun smt__STATE__Uncoupled__ () Idv)

(declare-fun smt__ACTION__Activate__ () Idv)

(declare-fun smt__ACTION__EndRelease__ () Idv)

(declare-fun smt__ACTION__LinkToggle__ () Idv)

(declare-fun smt__ACTION__ObsToggle__ () Idv)

(declare-fun smt__ACTION__AgentToggle__ () Idv)

(declare-fun smt__ACTION__Advance__ () Idv)

(declare-fun smt__ACTION__AdmitRelease__ () Idv)

(declare-fun smt__ACTION__AdmitAgent__ () Idv)

(declare-fun smt__ACTION__LiteOriginate__ (Idv) Idv)

(declare-fun smt__ACTION__Relay__ (Idv) Idv)

(declare-fun smt__ACTION__RelayRefuse__ (Idv) Idv)

(declare-fun smt__ACTION__Fire__ (Idv Idv) Idv)

(declare-fun smt__ACTION__RefuseAct__ (Idv Idv) Idv)

(declare-fun smt__ACTION__CheckFails__ (Idv) Idv)

(declare-fun smt__ACTION__Next__ () Idv)

(declare-fun smt__TEMPORAL__Spec__ () Idv)

(declare-fun smt__STATE__SignedByPerson__ () Idv)

(declare-fun smt__STATE__OrderedAtCommand__ () Idv)

(declare-fun smt__STATE__UsedOnce__ () Idv)

(declare-fun smt__STATE__NoOlderThanDeclared__ () Idv)

(declare-fun smt__STATE__IrreversibleIsAPersons__ () Idv)

(declare-fun smt__STATE__ConflictIsAFinding__ () Idv)

(declare-fun smt__STATE__OrderedInContact__ () Idv)

(declare-fun smt__STATE__Safe__ () Idv)

(declare-fun smt__STATE__ReleaseNeverCoupled__ () Idv)

(declare-fun smt__STATE__NeverFired__ () Idv)

(declare-fun smt__STATE__NeverFiredAfterCut__ () Idv)

(declare-fun smt__STATE__NeverRefusedKey__ () Idv)

(declare-fun smt__STATE__NeverRefusedCert__ () Idv)

(declare-fun smt__STATE__NeverRefusedVehicle__ () Idv)

(declare-fun smt__STATE__NeverRefusedReplay__ () Idv)

(declare-fun smt__STATE__NeverRefusedAged__ () Idv)

(declare-fun smt__STATE__NeverRelayRefused__ () Idv)

(declare-fun smt__STATE__NeverFinding__ () Idv)

(declare-fun smt__STATE__NeverSubtraction__ () Idv)

; hidden fact

; hidden fact

; omitted declaration of 'CONSTANT_EnabledWrapper_' (second-order)

; omitted declaration of 'CONSTANT_CdotWrapper_' (second-order)

; hidden fact

; hidden fact

; hidden fact

(declare-fun smt__CONSTANT__ActRec__ () Idv)

(declare-fun smt__STATE__NotYet__ () Idv)

(declare-fun smt__STATE__ActsWF__ () Idv)

(declare-fun smt__STATE__DeliveredActs__ () Idv)

(declare-fun smt__STATE__Shape__ () Idv)

(declare-fun smt__STATE__BindUsed__ () Idv)

; hidden fact

; hidden fact

(assert
  (and (smt__TLA____Mem smt__VARIABLE__relLive__ smt__TLA____BoolSet)
    (smt__TLA____Mem smt__VARIABLE__contact__ smt__TLA____BoolSet)
    (smt__TLA____Mem smt__VARIABLE__obsLive__ smt__TLA____BoolSet)
    (smt__TLA____Mem smt__VARIABLE__agentBusy__ smt__TLA____BoolSet)
    (smt__TLA____Mem smt__VARIABLE__tick__ smt__TLA____NatSet)
    (smt__TLA____Mem smt__VARIABLE__nextId__ smt__TLA____NatSet)
    (smt__TLA____IntLteq (smt__TLA____Cast__Int 1) smt__VARIABLE__nextId__)
    (smt__TLA____Mem smt__VARIABLE__acts__
      (smt__TLA____FunSet smt__CONSTANT__Ids__ smt__CONSTANT__ActRec__))
    (smt__TLA____SubsetEq smt__VARIABLE__delivered__ smt__CONSTANT__Ids__)
    (smt__TLA____SubsetEq smt__VARIABLE__relayRefused__ smt__CONSTANT__Ids__)
    (smt__TLA____Mem smt__VARIABLE__used__
      (smt__TLA____FunSet smt__CONSTANT__Vehicles__
        (smt__TLA____Subset smt__CONSTANT__Ids__)))
    (smt__TLA____SubsetEq smt__VARIABLE__firedIds__ smt__CONSTANT__Ids__)
    (smt__TLA____SubsetEq smt__VARIABLE__standing__ smt__CONSTANT__Ids__)
    (smt__TLA____SubsetEq smt__VARIABLE__findings__ smt__CONSTANT__Ids__)
    (smt__TLA____Mem smt__VARIABLE__notPerson__ smt__TLA____BoolSet)
    (smt__TLA____Mem smt__VARIABLE__notCommanded__ smt__TLA____BoolSet)
    (smt__TLA____Mem smt__VARIABLE__replayed__ smt__TLA____BoolSet)
    (smt__TLA____Mem smt__VARIABLE__stale__ smt__TLA____BoolSet)
    (smt__TLA____Mem smt__VARIABLE__noContact__ smt__TLA____BoolSet)))

(assert
  (or
    (or (= smt__ACTION__AdmitRelease__ smt__TLA____Tt__Idv)
      (= smt__ACTION__AdmitAgent__ smt__TLA____Tt__Idv))
    (exists ((smt__CONSTANT__s__ Idv))
      (and
        (smt__TLA____Mem smt__CONSTANT__s__
          (smt__TLA____SetEnum__2 smt__TLA____StrLit__person
            smt__TLA____StrLit__agent))
        (= (smt__ACTION__LiteOriginate__ smt__CONSTANT__s__)
          smt__TLA____Tt__Idv)))))

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

(declare-fun smt__CONSTANT__v__ () Idv)

(assert (smt__TLA____Mem smt__CONSTANT__v__ smt__CONSTANT__Vehicles__))

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

(assert
  (forall ((smt__CONSTANT__s__ Idv))
    (=>
      (smt__TLA____Mem smt__CONSTANT__s__
        (smt__TLA____SetEnum__2 smt__TLA____StrLit__person
          smt__TLA____StrLit__agent))
      (forall ((smt__CONSTANT__pl__ Idv))
        (=>
          (smt__TLA____Mem smt__CONSTANT__pl__
            (smt__TLA____SetEnum__2 smt__TLA____StrLit__cmd
              smt__TLA____StrLit__lite))
          (forall ((smt__CONSTANT__v___1 Idv))
            (=>
              (smt__TLA____Mem smt__CONSTANT__v___1 smt__CONSTANT__Vehicles__)
              (=> (smt__TLA____Mem smt__VARIABLE__tick__ smt__TLA____NatSet)
                (and
                  (smt__TLA____Mem
                    (smt__STATE__Act__ smt__CONSTANT__s__ smt__CONSTANT__pl__
                      smt__CONSTANT__v___1) smt__CONSTANT__ActRec__)
                  (distinct
                    (smt__STATE__Act__ smt__CONSTANT__s__ smt__CONSTANT__pl__
                      smt__CONSTANT__v___1) smt__CONSTANT__NoAct__)
                  (smt__TLA____Mem
                    (smt__TLA____FunApp
                      (smt__STATE__Act__ smt__CONSTANT__s__
                        smt__CONSTANT__pl__ smt__CONSTANT__v___1)
                      smt__TLA____StrLit__vehicle) smt__CONSTANT__Vehicles__))))))))))

;; Goal
(assert
  (!
    (not
      (and
        (and
          (smt__TLA____Mem
            (smt__STATE__Act__ smt__TLA____StrLit__agent
              smt__TLA____StrLit__cmd smt__CONSTANT__v__)
            smt__CONSTANT__ActRec__)
          (distinct
            (smt__STATE__Act__ smt__TLA____StrLit__agent
              smt__TLA____StrLit__cmd smt__CONSTANT__v__)
            smt__CONSTANT__NoAct__))
        (smt__TLA____Mem
          (smt__TLA____FunApp
            (smt__STATE__Act__ smt__TLA____StrLit__agent
              smt__TLA____StrLit__cmd smt__CONSTANT__v__)
            smt__TLA____StrLit__vehicle) smt__CONSTANT__Vehicles__)))
    :named |Goal|))

(check-sat)
(exit)
