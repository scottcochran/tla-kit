;; Proof obligation:
;;	ASSUME NEW CONSTANT CONSTANT_Mut_,
;;	       NEW CONSTANT CONSTANT_Ops_,
;;	       NEW CONSTANT CONSTANT_MaxRound_,
;;	       NEW VARIABLE VARIABLE_seating_,
;;	       NEW VARIABLE VARIABLE_inForce_,
;;	       NEW VARIABLE VARIABLE_lease_,
;;	       NEW VARIABLE VARIABLE_vouched_,
;;	       NEW VARIABLE VARIABLE_adds_,
;;	       NEW VARIABLE VARIABLE_stops_,
;;	       NEW VARIABLE VARIABLE_fenced_,
;;	       CONSTANT_Mut_ # "M_NOSEAT" ,
;;	       /\ VARIABLE_seating_ \in [CONSTANT_Principals_ -> 0..CONSTANT_MaxW_]
;;	       /\ VARIABLE_inForce_ \in [CONSTANT_Principals_ -> BOOLEAN]
;;	       /\ VARIABLE_lease_
;;	          \in [CONSTANT_Principals_ ->
;;	                 [live : BOOLEAN, width : 0..CONSTANT_MaxW_, round : Nat,
;;	                  root : {"none", "quorum"}, attested : BOOLEAN]]
;;	       /\ VARIABLE_vouched_ \in [CONSTANT_Ops_ -> BOOLEAN] ,
;;	       (\A CONSTANT_p_ \in CONSTANT_Principals_ :
;;	           VARIABLE_lease_[CONSTANT_p_].round > 0
;;	           => VARIABLE_lease_[CONSTANT_p_].root = "quorum")
;;	       /\ (\A CONSTANT_p_ \in CONSTANT_Principals_ :
;;	              VARIABLE_lease_[CONSTANT_p_].live
;;	              => VARIABLE_lease_[CONSTANT_p_].round > 0) ,
;;	       ACTION_Next_ \/ ?hN65KUIMHSNQTEPSC2KGVDJJ2VM = STATE_vars_ ,
;;	       CONSTANT_Mut_ = "M_ANON" ,
;;	       ?VARIABLE_lease_#prime
;;	       = [CONSTANT_p_ \in CONSTANT_Principals_ |->
;;	            [VARIABLE_lease_[CONSTANT_p_] EXCEPT !.live = FALSE]] ,
;;	       ?VARIABLE_stops_#prime
;;	       = {[kind |-> "fence", by |-> "nobody", byLive |-> TRUE,
;;	           vouched |-> TRUE, inForce |-> TRUE]} ,
;;	       ?VARIABLE_fenced_#prime = TRUE ,
;;	       ?VARIABLE_seating_#prime = VARIABLE_seating_ ,
;;	       ?VARIABLE_inForce_#prime = VARIABLE_inForce_ ,
;;	       ?VARIABLE_vouched_#prime = VARIABLE_vouched_ ,
;;	       ?VARIABLE_adds_#prime = VARIABLE_adds_ 
;;	PROVE  (\A CONSTANT_p_ \in CONSTANT_Principals_ :
;;	           ?VARIABLE_lease_#prime[CONSTANT_p_].round > 0
;;	           => ?VARIABLE_lease_#prime[CONSTANT_p_].root = "quorum")
;;	       /\ (\A CONSTANT_p_ \in CONSTANT_Principals_ :
;;	              ?VARIABLE_lease_#prime[CONSTANT_p_].live
;;	              => ?VARIABLE_lease_#prime[CONSTANT_p_].round > 0)
;; TLA+ Proof Manager 9a52faf
;; Proof obligation #81
;; Generated from file "./Operators_proof.tla", line 134, characters 5-6

(set-logic UFNIA)

;; Sorts

(declare-sort Idv 0)

;; Hypotheses

(declare-fun smt__TLA____Anon__OPAQUE__hN65KUIMHSNQTEPSC2KGVDJJ2VM () Idv)

(declare-fun smt__TLA____BoolSet () Idv)

(declare-fun smt__TLA____Cast__Bool (Bool) Idv)

(declare-fun smt__TLA____Cast__Int (Int) Idv)

(declare-fun smt__TLA____FunApp (Idv Idv) Idv)

(declare-fun smt__TLA____FunDom (Idv) Idv)

(declare-fun smt__TLA____FunExcept (Idv Idv Idv) Idv)

; omitted declaration of 'TLA__FunFcn' (second-order)

(declare-fun smt__TLA____FunIsafcn (Idv) Bool)

(declare-fun smt__TLA____FunSet (Idv Idv) Idv)

(declare-fun smt__TLA____IntLteq (Idv Idv) Bool)

(declare-fun smt__TLA____IntRange (Idv Idv) Idv)

(declare-fun smt__TLA____IntSet () Idv)

(declare-fun smt__TLA____Mem (Idv Idv) Bool)

(declare-fun smt__TLA____NatSet () Idv)

(declare-fun smt__TLA____Proj__Int (Idv) Int)

(declare-fun smt__TLA____RecordSet__attested__live__root__round__width (Idv
  Idv Idv Idv Idv) Idv)

(declare-fun smt__TLA____Record__attested__live__root__round__width (Idv Idv
  Idv Idv Idv) Idv)

(declare-fun smt__TLA____Record__by__byLive__inForce__kind__vouched (Idv Idv
  Idv Idv Idv) Idv)

(declare-fun smt__TLA____SetEnum__1 (Idv) Idv)

(declare-fun smt__TLA____SetEnum__2 (Idv Idv) Idv)

(declare-fun smt__TLA____SetEnum__5 (Idv Idv Idv Idv Idv) Idv)

(declare-fun smt__TLA____SetExtTrigger (Idv Idv) Bool)

(declare-fun smt__TLA____StrLit__M__ANON () Idv)

(declare-fun smt__TLA____StrLit__M__NOSEAT () Idv)

(declare-fun smt__TLA____StrLit__attested () Idv)

(declare-fun smt__TLA____StrLit__by () Idv)

(declare-fun smt__TLA____StrLit__byLive () Idv)

(declare-fun smt__TLA____StrLit__fence () Idv)

(declare-fun smt__TLA____StrLit__inForce () Idv)

(declare-fun smt__TLA____StrLit__kind () Idv)

(declare-fun smt__TLA____StrLit__live () Idv)

(declare-fun smt__TLA____StrLit__nobody () Idv)

(declare-fun smt__TLA____StrLit__none () Idv)

(declare-fun smt__TLA____StrLit__quorum () Idv)

(declare-fun smt__TLA____StrLit__root () Idv)

(declare-fun smt__TLA____StrLit__round () Idv)

(declare-fun smt__TLA____StrLit__vouched () Idv)

(declare-fun smt__TLA____StrLit__width () Idv)

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

;; Axiom: IntRangeDef
(assert
  (!
    (forall ((smt__a Idv) (smt__b Idv) (smt__x Idv))
      (!
        (= (smt__TLA____Mem smt__x (smt__TLA____IntRange smt__a smt__b))
          (and (smt__TLA____Mem smt__x smt__TLA____IntSet)
            (smt__TLA____IntLteq smt__a smt__x)
            (smt__TLA____IntLteq smt__x smt__b)))
        :pattern ((smt__TLA____Mem smt__x
                    (smt__TLA____IntRange smt__a smt__b)))))
    :named |IntRangeDef|))

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

;; Axiom: FunExceptIsafcn
(assert
  (!
    (forall ((smt__f Idv) (smt__x Idv) (smt__y Idv))
      (! (smt__TLA____FunIsafcn (smt__TLA____FunExcept smt__f smt__x smt__y))
        :pattern ((smt__TLA____FunExcept smt__f smt__x smt__y))))
    :named |FunExceptIsafcn|))

;; Axiom: FunExceptDomDef
(assert
  (!
    (forall ((smt__f Idv) (smt__x Idv) (smt__y Idv))
      (!
        (= (smt__TLA____FunDom (smt__TLA____FunExcept smt__f smt__x smt__y))
          (smt__TLA____FunDom smt__f))
        :pattern ((smt__TLA____FunExcept smt__f smt__x smt__y))))
    :named |FunExceptDomDef|))

;; Axiom: FunExceptAppDef1
(assert
  (!
    (forall ((smt__f Idv) (smt__x Idv) (smt__y Idv))
      (!
        (=> (smt__TLA____Mem smt__x (smt__TLA____FunDom smt__f))
          (=
            (smt__TLA____FunApp (smt__TLA____FunExcept smt__f smt__x smt__y)
              smt__x) smt__y))
        :pattern ((smt__TLA____FunExcept smt__f smt__x smt__y))))
    :named |FunExceptAppDef1|))

;; Axiom: FunExceptAppDef2
(assert
  (!
    (forall ((smt__f Idv) (smt__x Idv) (smt__y Idv) (smt__z Idv))
      (!
        (=> (smt__TLA____Mem smt__z (smt__TLA____FunDom smt__f))
          (and
            (=> (= smt__z smt__x)
              (=
                (smt__TLA____FunApp
                  (smt__TLA____FunExcept smt__f smt__x smt__y) smt__z) 
                smt__y))
            (=> (distinct smt__z smt__x)
              (=
                (smt__TLA____FunApp
                  (smt__TLA____FunExcept smt__f smt__x smt__y) smt__z)
                (smt__TLA____FunApp smt__f smt__z)))))
        :pattern ((smt__TLA____FunApp
                    (smt__TLA____FunExcept smt__f smt__x smt__y) smt__z))
        :pattern ((smt__TLA____FunExcept smt__f smt__x smt__y)
                   (smt__TLA____FunApp smt__f smt__z))))
    :named |FunExceptAppDef2|))

;; Axiom: EnumDefIntro 1
(assert
  (!
    (forall ((smt__a1 Idv))
      (! (smt__TLA____Mem smt__a1 (smt__TLA____SetEnum__1 smt__a1))
        :pattern ((smt__TLA____SetEnum__1 smt__a1)))) :named |EnumDefIntro 1|))

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

;; Axiom: EnumDefIntro 5
(assert
  (!
    (forall
      ((smt__a1 Idv) (smt__a2 Idv) (smt__a3 Idv) (smt__a4 Idv) (smt__a5 Idv))
      (!
        (and
          (smt__TLA____Mem smt__a1
            (smt__TLA____SetEnum__5 smt__a1 smt__a2 smt__a3 smt__a4 smt__a5))
          (smt__TLA____Mem smt__a2
            (smt__TLA____SetEnum__5 smt__a1 smt__a2 smt__a3 smt__a4 smt__a5))
          (smt__TLA____Mem smt__a3
            (smt__TLA____SetEnum__5 smt__a1 smt__a2 smt__a3 smt__a4 smt__a5))
          (smt__TLA____Mem smt__a4
            (smt__TLA____SetEnum__5 smt__a1 smt__a2 smt__a3 smt__a4 smt__a5))
          (smt__TLA____Mem smt__a5
            (smt__TLA____SetEnum__5 smt__a1 smt__a2 smt__a3 smt__a4 smt__a5)))
        :pattern ((smt__TLA____SetEnum__5 smt__a1 smt__a2 smt__a3 smt__a4
                    smt__a5)))) :named |EnumDefIntro 5|))

;; Axiom: EnumDefElim 1
(assert
  (!
    (forall ((smt__a1 Idv) (smt__x Idv))
      (!
        (=> (smt__TLA____Mem smt__x (smt__TLA____SetEnum__1 smt__a1))
          (= smt__x smt__a1))
        :pattern ((smt__TLA____Mem smt__x (smt__TLA____SetEnum__1 smt__a1)))))
    :named |EnumDefElim 1|))

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

;; Axiom: EnumDefElim 5
(assert
  (!
    (forall
      ((smt__a1 Idv) (smt__a2 Idv) (smt__a3 Idv) (smt__a4 Idv) (smt__a5 Idv)
        (smt__x Idv))
      (!
        (=>
          (smt__TLA____Mem smt__x
            (smt__TLA____SetEnum__5 smt__a1 smt__a2 smt__a3 smt__a4 smt__a5))
          (or (= smt__x smt__a1) (= smt__x smt__a2) (= smt__x smt__a3)
            (= smt__x smt__a4) (= smt__x smt__a5)))
        :pattern ((smt__TLA____Mem smt__x
                    (smt__TLA____SetEnum__5 smt__a1 smt__a2 smt__a3 smt__a4
                      smt__a5))))) :named |EnumDefElim 5|))

;; Axiom: StrLitIsstr M_ANON
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__M__ANON smt__TLA____StrSet)
    :named |StrLitIsstr M_ANON|))

;; Axiom: StrLitIsstr M_NOSEAT
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__M__NOSEAT smt__TLA____StrSet)
    :named |StrLitIsstr M_NOSEAT|))

;; Axiom: StrLitIsstr attested
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__attested smt__TLA____StrSet)
    :named |StrLitIsstr attested|))

;; Axiom: StrLitIsstr by
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__by smt__TLA____StrSet)
    :named |StrLitIsstr by|))

;; Axiom: StrLitIsstr byLive
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__byLive smt__TLA____StrSet)
    :named |StrLitIsstr byLive|))

;; Axiom: StrLitIsstr fence
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__fence smt__TLA____StrSet)
    :named |StrLitIsstr fence|))

;; Axiom: StrLitIsstr inForce
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__inForce smt__TLA____StrSet)
    :named |StrLitIsstr inForce|))

;; Axiom: StrLitIsstr kind
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__kind smt__TLA____StrSet)
    :named |StrLitIsstr kind|))

;; Axiom: StrLitIsstr live
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__live smt__TLA____StrSet)
    :named |StrLitIsstr live|))

;; Axiom: StrLitIsstr nobody
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__nobody smt__TLA____StrSet)
    :named |StrLitIsstr nobody|))

;; Axiom: StrLitIsstr none
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__none smt__TLA____StrSet)
    :named |StrLitIsstr none|))

;; Axiom: StrLitIsstr quorum
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__quorum smt__TLA____StrSet)
    :named |StrLitIsstr quorum|))

;; Axiom: StrLitIsstr root
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__root smt__TLA____StrSet)
    :named |StrLitIsstr root|))

;; Axiom: StrLitIsstr round
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__round smt__TLA____StrSet)
    :named |StrLitIsstr round|))

;; Axiom: StrLitIsstr vouched
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__vouched smt__TLA____StrSet)
    :named |StrLitIsstr vouched|))

;; Axiom: StrLitIsstr width
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__width smt__TLA____StrSet)
    :named |StrLitIsstr width|))

;; Axiom: StrLitDistinct M_ANON M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__M__ANON smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct M_ANON M_NOSEAT|))

;; Axiom: StrLitDistinct M_ANON attested
(assert
  (! (distinct smt__TLA____StrLit__M__ANON smt__TLA____StrLit__attested)
    :named |StrLitDistinct M_ANON attested|))

;; Axiom: StrLitDistinct M_ANON live
(assert
  (! (distinct smt__TLA____StrLit__M__ANON smt__TLA____StrLit__live)
    :named |StrLitDistinct M_ANON live|))

;; Axiom: StrLitDistinct M_ANON none
(assert
  (! (distinct smt__TLA____StrLit__M__ANON smt__TLA____StrLit__none)
    :named |StrLitDistinct M_ANON none|))

;; Axiom: StrLitDistinct M_ANON quorum
(assert
  (! (distinct smt__TLA____StrLit__M__ANON smt__TLA____StrLit__quorum)
    :named |StrLitDistinct M_ANON quorum|))

;; Axiom: StrLitDistinct M_ANON root
(assert
  (! (distinct smt__TLA____StrLit__M__ANON smt__TLA____StrLit__root)
    :named |StrLitDistinct M_ANON root|))

;; Axiom: StrLitDistinct M_ANON round
(assert
  (! (distinct smt__TLA____StrLit__M__ANON smt__TLA____StrLit__round)
    :named |StrLitDistinct M_ANON round|))

;; Axiom: StrLitDistinct M_ANON width
(assert
  (! (distinct smt__TLA____StrLit__M__ANON smt__TLA____StrLit__width)
    :named |StrLitDistinct M_ANON width|))

;; Axiom: StrLitDistinct attested M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__attested smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct attested M_NOSEAT|))

;; Axiom: StrLitDistinct by M_ANON
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__M__ANON)
    :named |StrLitDistinct by M_ANON|))

;; Axiom: StrLitDistinct by M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct by M_NOSEAT|))

;; Axiom: StrLitDistinct by attested
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__attested)
    :named |StrLitDistinct by attested|))

;; Axiom: StrLitDistinct by live
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__live)
    :named |StrLitDistinct by live|))

;; Axiom: StrLitDistinct by none
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__none)
    :named |StrLitDistinct by none|))

;; Axiom: StrLitDistinct by quorum
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__quorum)
    :named |StrLitDistinct by quorum|))

;; Axiom: StrLitDistinct by root
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__root)
    :named |StrLitDistinct by root|))

;; Axiom: StrLitDistinct by round
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__round)
    :named |StrLitDistinct by round|))

;; Axiom: StrLitDistinct by width
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__width)
    :named |StrLitDistinct by width|))

;; Axiom: StrLitDistinct byLive M_ANON
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__M__ANON)
    :named |StrLitDistinct byLive M_ANON|))

;; Axiom: StrLitDistinct byLive M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct byLive M_NOSEAT|))

;; Axiom: StrLitDistinct byLive attested
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__attested)
    :named |StrLitDistinct byLive attested|))

;; Axiom: StrLitDistinct byLive by
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__by)
    :named |StrLitDistinct byLive by|))

;; Axiom: StrLitDistinct byLive live
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__live)
    :named |StrLitDistinct byLive live|))

;; Axiom: StrLitDistinct byLive none
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__none)
    :named |StrLitDistinct byLive none|))

;; Axiom: StrLitDistinct byLive quorum
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__quorum)
    :named |StrLitDistinct byLive quorum|))

;; Axiom: StrLitDistinct byLive root
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__root)
    :named |StrLitDistinct byLive root|))

;; Axiom: StrLitDistinct byLive round
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__round)
    :named |StrLitDistinct byLive round|))

;; Axiom: StrLitDistinct byLive width
(assert
  (! (distinct smt__TLA____StrLit__byLive smt__TLA____StrLit__width)
    :named |StrLitDistinct byLive width|))

;; Axiom: StrLitDistinct fence M_ANON
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__M__ANON)
    :named |StrLitDistinct fence M_ANON|))

;; Axiom: StrLitDistinct fence M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct fence M_NOSEAT|))

;; Axiom: StrLitDistinct fence attested
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__attested)
    :named |StrLitDistinct fence attested|))

;; Axiom: StrLitDistinct fence by
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__by)
    :named |StrLitDistinct fence by|))

;; Axiom: StrLitDistinct fence byLive
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__byLive)
    :named |StrLitDistinct fence byLive|))

;; Axiom: StrLitDistinct fence inForce
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__inForce)
    :named |StrLitDistinct fence inForce|))

;; Axiom: StrLitDistinct fence kind
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__kind)
    :named |StrLitDistinct fence kind|))

;; Axiom: StrLitDistinct fence live
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__live)
    :named |StrLitDistinct fence live|))

;; Axiom: StrLitDistinct fence nobody
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__nobody)
    :named |StrLitDistinct fence nobody|))

;; Axiom: StrLitDistinct fence none
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__none)
    :named |StrLitDistinct fence none|))

;; Axiom: StrLitDistinct fence quorum
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__quorum)
    :named |StrLitDistinct fence quorum|))

;; Axiom: StrLitDistinct fence root
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__root)
    :named |StrLitDistinct fence root|))

;; Axiom: StrLitDistinct fence round
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__round)
    :named |StrLitDistinct fence round|))

;; Axiom: StrLitDistinct fence vouched
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__vouched)
    :named |StrLitDistinct fence vouched|))

;; Axiom: StrLitDistinct fence width
(assert
  (! (distinct smt__TLA____StrLit__fence smt__TLA____StrLit__width)
    :named |StrLitDistinct fence width|))

;; Axiom: StrLitDistinct inForce M_ANON
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__M__ANON)
    :named |StrLitDistinct inForce M_ANON|))

;; Axiom: StrLitDistinct inForce M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct inForce M_NOSEAT|))

;; Axiom: StrLitDistinct inForce attested
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__attested)
    :named |StrLitDistinct inForce attested|))

;; Axiom: StrLitDistinct inForce by
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__by)
    :named |StrLitDistinct inForce by|))

;; Axiom: StrLitDistinct inForce byLive
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__byLive)
    :named |StrLitDistinct inForce byLive|))

;; Axiom: StrLitDistinct inForce live
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__live)
    :named |StrLitDistinct inForce live|))

;; Axiom: StrLitDistinct inForce none
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__none)
    :named |StrLitDistinct inForce none|))

;; Axiom: StrLitDistinct inForce quorum
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__quorum)
    :named |StrLitDistinct inForce quorum|))

;; Axiom: StrLitDistinct inForce root
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__root)
    :named |StrLitDistinct inForce root|))

;; Axiom: StrLitDistinct inForce round
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__round)
    :named |StrLitDistinct inForce round|))

;; Axiom: StrLitDistinct inForce width
(assert
  (! (distinct smt__TLA____StrLit__inForce smt__TLA____StrLit__width)
    :named |StrLitDistinct inForce width|))

;; Axiom: StrLitDistinct kind M_ANON
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__M__ANON)
    :named |StrLitDistinct kind M_ANON|))

;; Axiom: StrLitDistinct kind M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct kind M_NOSEAT|))

;; Axiom: StrLitDistinct kind attested
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__attested)
    :named |StrLitDistinct kind attested|))

;; Axiom: StrLitDistinct kind by
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__by)
    :named |StrLitDistinct kind by|))

;; Axiom: StrLitDistinct kind byLive
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__byLive)
    :named |StrLitDistinct kind byLive|))

;; Axiom: StrLitDistinct kind inForce
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__inForce)
    :named |StrLitDistinct kind inForce|))

;; Axiom: StrLitDistinct kind live
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__live)
    :named |StrLitDistinct kind live|))

;; Axiom: StrLitDistinct kind none
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__none)
    :named |StrLitDistinct kind none|))

;; Axiom: StrLitDistinct kind quorum
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__quorum)
    :named |StrLitDistinct kind quorum|))

;; Axiom: StrLitDistinct kind root
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__root)
    :named |StrLitDistinct kind root|))

;; Axiom: StrLitDistinct kind round
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__round)
    :named |StrLitDistinct kind round|))

;; Axiom: StrLitDistinct kind width
(assert
  (! (distinct smt__TLA____StrLit__kind smt__TLA____StrLit__width)
    :named |StrLitDistinct kind width|))

;; Axiom: StrLitDistinct live M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__live smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct live M_NOSEAT|))

;; Axiom: StrLitDistinct live attested
(assert
  (! (distinct smt__TLA____StrLit__live smt__TLA____StrLit__attested)
    :named |StrLitDistinct live attested|))

;; Axiom: StrLitDistinct nobody M_ANON
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__M__ANON)
    :named |StrLitDistinct nobody M_ANON|))

;; Axiom: StrLitDistinct nobody M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct nobody M_NOSEAT|))

;; Axiom: StrLitDistinct nobody attested
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__attested)
    :named |StrLitDistinct nobody attested|))

;; Axiom: StrLitDistinct nobody by
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__by)
    :named |StrLitDistinct nobody by|))

;; Axiom: StrLitDistinct nobody byLive
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__byLive)
    :named |StrLitDistinct nobody byLive|))

;; Axiom: StrLitDistinct nobody inForce
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__inForce)
    :named |StrLitDistinct nobody inForce|))

;; Axiom: StrLitDistinct nobody kind
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__kind)
    :named |StrLitDistinct nobody kind|))

;; Axiom: StrLitDistinct nobody live
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__live)
    :named |StrLitDistinct nobody live|))

;; Axiom: StrLitDistinct nobody none
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__none)
    :named |StrLitDistinct nobody none|))

;; Axiom: StrLitDistinct nobody quorum
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__quorum)
    :named |StrLitDistinct nobody quorum|))

;; Axiom: StrLitDistinct nobody root
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__root)
    :named |StrLitDistinct nobody root|))

;; Axiom: StrLitDistinct nobody round
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__round)
    :named |StrLitDistinct nobody round|))

;; Axiom: StrLitDistinct nobody vouched
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__vouched)
    :named |StrLitDistinct nobody vouched|))

;; Axiom: StrLitDistinct nobody width
(assert
  (! (distinct smt__TLA____StrLit__nobody smt__TLA____StrLit__width)
    :named |StrLitDistinct nobody width|))

;; Axiom: StrLitDistinct none M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__none smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct none M_NOSEAT|))

;; Axiom: StrLitDistinct none attested
(assert
  (! (distinct smt__TLA____StrLit__none smt__TLA____StrLit__attested)
    :named |StrLitDistinct none attested|))

;; Axiom: StrLitDistinct none live
(assert
  (! (distinct smt__TLA____StrLit__none smt__TLA____StrLit__live)
    :named |StrLitDistinct none live|))

;; Axiom: StrLitDistinct none root
(assert
  (! (distinct smt__TLA____StrLit__none smt__TLA____StrLit__root)
    :named |StrLitDistinct none root|))

;; Axiom: StrLitDistinct none round
(assert
  (! (distinct smt__TLA____StrLit__none smt__TLA____StrLit__round)
    :named |StrLitDistinct none round|))

;; Axiom: StrLitDistinct none width
(assert
  (! (distinct smt__TLA____StrLit__none smt__TLA____StrLit__width)
    :named |StrLitDistinct none width|))

;; Axiom: StrLitDistinct quorum M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__quorum smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct quorum M_NOSEAT|))

;; Axiom: StrLitDistinct quorum attested
(assert
  (! (distinct smt__TLA____StrLit__quorum smt__TLA____StrLit__attested)
    :named |StrLitDistinct quorum attested|))

;; Axiom: StrLitDistinct quorum live
(assert
  (! (distinct smt__TLA____StrLit__quorum smt__TLA____StrLit__live)
    :named |StrLitDistinct quorum live|))

;; Axiom: StrLitDistinct quorum none
(assert
  (! (distinct smt__TLA____StrLit__quorum smt__TLA____StrLit__none)
    :named |StrLitDistinct quorum none|))

;; Axiom: StrLitDistinct quorum root
(assert
  (! (distinct smt__TLA____StrLit__quorum smt__TLA____StrLit__root)
    :named |StrLitDistinct quorum root|))

;; Axiom: StrLitDistinct quorum round
(assert
  (! (distinct smt__TLA____StrLit__quorum smt__TLA____StrLit__round)
    :named |StrLitDistinct quorum round|))

;; Axiom: StrLitDistinct quorum width
(assert
  (! (distinct smt__TLA____StrLit__quorum smt__TLA____StrLit__width)
    :named |StrLitDistinct quorum width|))

;; Axiom: StrLitDistinct root M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__root smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct root M_NOSEAT|))

;; Axiom: StrLitDistinct root attested
(assert
  (! (distinct smt__TLA____StrLit__root smt__TLA____StrLit__attested)
    :named |StrLitDistinct root attested|))

;; Axiom: StrLitDistinct root live
(assert
  (! (distinct smt__TLA____StrLit__root smt__TLA____StrLit__live)
    :named |StrLitDistinct root live|))

;; Axiom: StrLitDistinct round M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__round smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct round M_NOSEAT|))

;; Axiom: StrLitDistinct round attested
(assert
  (! (distinct smt__TLA____StrLit__round smt__TLA____StrLit__attested)
    :named |StrLitDistinct round attested|))

;; Axiom: StrLitDistinct round live
(assert
  (! (distinct smt__TLA____StrLit__round smt__TLA____StrLit__live)
    :named |StrLitDistinct round live|))

;; Axiom: StrLitDistinct round root
(assert
  (! (distinct smt__TLA____StrLit__round smt__TLA____StrLit__root)
    :named |StrLitDistinct round root|))

;; Axiom: StrLitDistinct vouched M_ANON
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__M__ANON)
    :named |StrLitDistinct vouched M_ANON|))

;; Axiom: StrLitDistinct vouched M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct vouched M_NOSEAT|))

;; Axiom: StrLitDistinct vouched attested
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__attested)
    :named |StrLitDistinct vouched attested|))

;; Axiom: StrLitDistinct vouched by
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__by)
    :named |StrLitDistinct vouched by|))

;; Axiom: StrLitDistinct vouched byLive
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__byLive)
    :named |StrLitDistinct vouched byLive|))

;; Axiom: StrLitDistinct vouched inForce
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__inForce)
    :named |StrLitDistinct vouched inForce|))

;; Axiom: StrLitDistinct vouched kind
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__kind)
    :named |StrLitDistinct vouched kind|))

;; Axiom: StrLitDistinct vouched live
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__live)
    :named |StrLitDistinct vouched live|))

;; Axiom: StrLitDistinct vouched none
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__none)
    :named |StrLitDistinct vouched none|))

;; Axiom: StrLitDistinct vouched quorum
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__quorum)
    :named |StrLitDistinct vouched quorum|))

;; Axiom: StrLitDistinct vouched root
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__root)
    :named |StrLitDistinct vouched root|))

;; Axiom: StrLitDistinct vouched round
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__round)
    :named |StrLitDistinct vouched round|))

;; Axiom: StrLitDistinct vouched width
(assert
  (! (distinct smt__TLA____StrLit__vouched smt__TLA____StrLit__width)
    :named |StrLitDistinct vouched width|))

;; Axiom: StrLitDistinct width M_NOSEAT
(assert
  (! (distinct smt__TLA____StrLit__width smt__TLA____StrLit__M__NOSEAT)
    :named |StrLitDistinct width M_NOSEAT|))

;; Axiom: StrLitDistinct width attested
(assert
  (! (distinct smt__TLA____StrLit__width smt__TLA____StrLit__attested)
    :named |StrLitDistinct width attested|))

;; Axiom: StrLitDistinct width live
(assert
  (! (distinct smt__TLA____StrLit__width smt__TLA____StrLit__live)
    :named |StrLitDistinct width live|))

;; Axiom: StrLitDistinct width root
(assert
  (! (distinct smt__TLA____StrLit__width smt__TLA____StrLit__root)
    :named |StrLitDistinct width root|))

;; Axiom: StrLitDistinct width round
(assert
  (! (distinct smt__TLA____StrLit__width smt__TLA____StrLit__round)
    :named |StrLitDistinct width round|))

;; Axiom: RecIsafcn attested live root round width
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv))
      (!
        (smt__TLA____FunIsafcn
          (smt__TLA____Record__attested__live__root__round__width smt__x1
            smt__x2 smt__x3 smt__x4 smt__x5))
        :pattern ((smt__TLA____Record__attested__live__root__round__width
                    smt__x1 smt__x2 smt__x3 smt__x4 smt__x5))))
    :named |RecIsafcn attested live root round width|))

;; Axiom: RecIsafcn by byLive inForce kind vouched
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv))
      (!
        (smt__TLA____FunIsafcn
          (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
            smt__x2 smt__x3 smt__x4 smt__x5))
        :pattern ((smt__TLA____Record__by__byLive__inForce__kind__vouched
                    smt__x1 smt__x2 smt__x3 smt__x4 smt__x5))))
    :named |RecIsafcn by byLive inForce kind vouched|))

;; Axiom: RecDomDef attested live root round width
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv))
      (!
        (=
          (smt__TLA____FunDom
            (smt__TLA____Record__attested__live__root__round__width smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5))
          (smt__TLA____SetEnum__5 smt__TLA____StrLit__attested
            smt__TLA____StrLit__live smt__TLA____StrLit__root
            smt__TLA____StrLit__round smt__TLA____StrLit__width))
        :pattern ((smt__TLA____Record__attested__live__root__round__width
                    smt__x1 smt__x2 smt__x3 smt__x4 smt__x5))))
    :named |RecDomDef attested live root round width|))

;; Axiom: RecDomDef by byLive inForce kind vouched
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv))
      (!
        (=
          (smt__TLA____FunDom
            (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5))
          (smt__TLA____SetEnum__5 smt__TLA____StrLit__by
            smt__TLA____StrLit__byLive smt__TLA____StrLit__inForce
            smt__TLA____StrLit__kind smt__TLA____StrLit__vouched))
        :pattern ((smt__TLA____Record__by__byLive__inForce__kind__vouched
                    smt__x1 smt__x2 smt__x3 smt__x4 smt__x5))))
    :named |RecDomDef by byLive inForce kind vouched|))

;; Axiom: RecAppDef attested live root round width
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv))
      (!
        (and
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__attested__live__root__round__width 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__attested) smt__x1)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__attested__live__root__round__width 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__live) smt__x2)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__attested__live__root__round__width 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__root) smt__x3)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__attested__live__root__round__width 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__round) smt__x4)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__attested__live__root__round__width 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__width) smt__x5))
        :pattern ((smt__TLA____Record__attested__live__root__round__width
                    smt__x1 smt__x2 smt__x3 smt__x4 smt__x5))))
    :named |RecAppDef attested live root round width|))

;; Axiom: RecAppDef by byLive inForce kind vouched
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv))
      (!
        (and
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__by__byLive__inForce__kind__vouched 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__by) smt__x1)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__by__byLive__inForce__kind__vouched 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__byLive) smt__x2)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__by__byLive__inForce__kind__vouched 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__inForce) smt__x3)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__by__byLive__inForce__kind__vouched 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__kind) smt__x4)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__by__byLive__inForce__kind__vouched 
                smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
              smt__TLA____StrLit__vouched) smt__x5))
        :pattern ((smt__TLA____Record__by__byLive__inForce__kind__vouched
                    smt__x1 smt__x2 smt__x3 smt__x4 smt__x5))))
    :named |RecAppDef by byLive inForce kind vouched|))

;; Axiom: RecExcept attested live root round width 1
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__attested__live__root__round__width smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__attested
            smt__x)
          (smt__TLA____Record__attested__live__root__round__width smt__x
            smt__x2 smt__x3 smt__x4 smt__x5))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__attested__live__root__round__width
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__attested smt__x))))
    :named |RecExcept attested live root round width 1|))

;; Axiom: RecExcept attested live root round width 2
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__attested__live__root__round__width smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__live
            smt__x)
          (smt__TLA____Record__attested__live__root__round__width smt__x1
            smt__x smt__x3 smt__x4 smt__x5))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__attested__live__root__round__width
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__live smt__x))))
    :named |RecExcept attested live root round width 2|))

;; Axiom: RecExcept attested live root round width 3
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__attested__live__root__round__width smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__root
            smt__x)
          (smt__TLA____Record__attested__live__root__round__width smt__x1
            smt__x2 smt__x smt__x4 smt__x5))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__attested__live__root__round__width
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__root smt__x))))
    :named |RecExcept attested live root round width 3|))

;; Axiom: RecExcept attested live root round width 4
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__attested__live__root__round__width smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__round
            smt__x)
          (smt__TLA____Record__attested__live__root__round__width smt__x1
            smt__x2 smt__x3 smt__x smt__x5))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__attested__live__root__round__width
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__round smt__x))))
    :named |RecExcept attested live root round width 4|))

;; Axiom: RecExcept attested live root round width 5
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__attested__live__root__round__width smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__width
            smt__x)
          (smt__TLA____Record__attested__live__root__round__width smt__x1
            smt__x2 smt__x3 smt__x4 smt__x))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__attested__live__root__round__width
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__width smt__x))))
    :named |RecExcept attested live root round width 5|))

;; Axiom: RecExcept by byLive inForce kind vouched 1
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__by 
            smt__x)
          (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x
            smt__x2 smt__x3 smt__x4 smt__x5))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__by__byLive__inForce__kind__vouched
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__by smt__x))))
    :named |RecExcept by byLive inForce kind vouched 1|))

;; Axiom: RecExcept by byLive inForce kind vouched 2
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__byLive
            smt__x)
          (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
            smt__x smt__x3 smt__x4 smt__x5))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__by__byLive__inForce__kind__vouched
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__byLive smt__x))))
    :named |RecExcept by byLive inForce kind vouched 2|))

;; Axiom: RecExcept by byLive inForce kind vouched 3
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__inForce
            smt__x)
          (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
            smt__x2 smt__x smt__x4 smt__x5))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__by__byLive__inForce__kind__vouched
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__inForce smt__x))))
    :named |RecExcept by byLive inForce kind vouched 3|))

;; Axiom: RecExcept by byLive inForce kind vouched 4
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__kind
            smt__x)
          (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
            smt__x2 smt__x3 smt__x smt__x5))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__by__byLive__inForce__kind__vouched
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__kind smt__x))))
    :named |RecExcept by byLive inForce kind vouched 4|))

;; Axiom: RecExcept by byLive inForce kind vouched 5
(assert
  (!
    (forall
      ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv)
        (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5) smt__TLA____StrLit__vouched
            smt__x)
          (smt__TLA____Record__by__byLive__inForce__kind__vouched smt__x1
            smt__x2 smt__x3 smt__x4 smt__x))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__by__byLive__inForce__kind__vouched
                      smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                    smt__TLA____StrLit__vouched smt__x))))
    :named |RecExcept by byLive inForce kind vouched 5|))

;; Axiom: RecSetIntro attested live root round width
(assert
  (!
    (forall
      ((smt__s1 Idv) (smt__s2 Idv) (smt__s3 Idv) (smt__s4 Idv) (smt__s5 Idv)
        (smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x4 Idv) (smt__x5 Idv))
      (!
        (=>
          (and (smt__TLA____Mem smt__x1 smt__s1)
            (smt__TLA____Mem smt__x2 smt__s2)
            (smt__TLA____Mem smt__x3 smt__s3)
            (smt__TLA____Mem smt__x4 smt__s4)
            (smt__TLA____Mem smt__x5 smt__s5))
          (smt__TLA____Mem
            (smt__TLA____Record__attested__live__root__round__width smt__x1
              smt__x2 smt__x3 smt__x4 smt__x5)
            (smt__TLA____RecordSet__attested__live__root__round__width
              smt__s1 smt__s2 smt__s3 smt__s4 smt__s5)))
        :pattern ((smt__TLA____Record__attested__live__root__round__width
                    smt__x1 smt__x2 smt__x3 smt__x4 smt__x5)
                   (smt__TLA____RecordSet__attested__live__root__round__width
                     smt__s1 smt__s2 smt__s3 smt__s4 smt__s5))))
    :named |RecSetIntro attested live root round width|))

;; Axiom: RecSetElim attested live root round width
(assert
  (!
    (forall
      ((smt__s1 Idv) (smt__s2 Idv) (smt__s3 Idv) (smt__s4 Idv) (smt__s5 Idv)
        (smt__r Idv))
      (!
        (=>
          (smt__TLA____Mem smt__r
            (smt__TLA____RecordSet__attested__live__root__round__width
              smt__s1 smt__s2 smt__s3 smt__s4 smt__s5))
          (and
            (= smt__r
              (smt__TLA____Record__attested__live__root__round__width
                (smt__TLA____FunApp smt__r smt__TLA____StrLit__attested)
                (smt__TLA____FunApp smt__r smt__TLA____StrLit__live)
                (smt__TLA____FunApp smt__r smt__TLA____StrLit__root)
                (smt__TLA____FunApp smt__r smt__TLA____StrLit__round)
                (smt__TLA____FunApp smt__r smt__TLA____StrLit__width)))
            (smt__TLA____Mem
              (smt__TLA____FunApp smt__r smt__TLA____StrLit__attested)
              smt__s1)
            (smt__TLA____Mem
              (smt__TLA____FunApp smt__r smt__TLA____StrLit__live) smt__s2)
            (smt__TLA____Mem
              (smt__TLA____FunApp smt__r smt__TLA____StrLit__root) smt__s3)
            (smt__TLA____Mem
              (smt__TLA____FunApp smt__r smt__TLA____StrLit__round) smt__s4)
            (smt__TLA____Mem
              (smt__TLA____FunApp smt__r smt__TLA____StrLit__width) smt__s5)))
        :pattern ((smt__TLA____Mem smt__r
                    (smt__TLA____RecordSet__attested__live__root__round__width
                      smt__s1 smt__s2 smt__s3 smt__s4 smt__s5)))))
    :named |RecSetElim attested live root round width|))

;; Axiom: CastInjAlt Bool
(assert
  (!
    (and (= (smt__TLA____Cast__Bool true) smt__TLA____Tt__Idv)
      (distinct (smt__TLA____Cast__Bool false) smt__TLA____Tt__Idv))
    :named |CastInjAlt Bool|))

;; Axiom: CastInjAlt Int
(assert
  (!
    (forall ((smt__x Int))
      (! (= smt__x (smt__TLA____Proj__Int (smt__TLA____Cast__Int smt__x)))
        :pattern ((smt__TLA____Cast__Int smt__x)))) :named |CastInjAlt Int|))

;; Axiom: TypeGuardIntro Bool
(assert
  (!
    (forall ((smt__z Bool))
      (!
        (smt__TLA____Mem (smt__TLA____Cast__Bool smt__z) smt__TLA____BoolSet)
        :pattern ((smt__TLA____Cast__Bool smt__z))))
    :named |TypeGuardIntro Bool|))

;; Axiom: TypeGuardIntro Int
(assert
  (!
    (forall ((smt__z Int))
      (! (smt__TLA____Mem (smt__TLA____Cast__Int smt__z) smt__TLA____IntSet)
        :pattern ((smt__TLA____Cast__Int smt__z))))
    :named |TypeGuardIntro Int|))

;; Axiom: TypeGuardElim Bool
(assert
  (!
    (forall ((smt__x Idv))
      (!
        (=> (smt__TLA____Mem smt__x smt__TLA____BoolSet)
          (or (= smt__x (smt__TLA____Cast__Bool true))
            (= smt__x (smt__TLA____Cast__Bool false))))
        :pattern ((smt__TLA____Mem smt__x smt__TLA____BoolSet))))
    :named |TypeGuardElim Bool|))

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

(declare-fun smt__CONSTANT__IsFiniteSet__ (Idv) Idv)

(declare-fun smt__CONSTANT__Cardinality__ (Idv) Idv)

(declare-fun smt__CONSTANT__Mut__ () Idv)

(declare-fun smt__CONSTANT__Ops__ () Idv)

(declare-fun smt__CONSTANT__MaxRound__ () Idv)

(declare-fun smt__CONSTANT__Workers__ () Idv)

(declare-fun smt__CONSTANT__Principals__ () Idv)

(declare-fun smt__CONSTANT__MaxW__ () Idv)

(declare-fun smt__CONSTANT__NoLease__ () Idv)

(declare-fun smt__VARIABLE__seating__ () Idv)

(declare-fun smt__VARIABLE__seating____prime () Idv)

(declare-fun smt__VARIABLE__inForce__ () Idv)

(declare-fun smt__VARIABLE__inForce____prime () Idv)

(declare-fun smt__VARIABLE__lease__ () Idv)

(declare-fun smt__VARIABLE__lease____prime () Idv)

(declare-fun smt__VARIABLE__vouched__ () Idv)

(declare-fun smt__VARIABLE__vouched____prime () Idv)

(declare-fun smt__VARIABLE__adds__ () Idv)

(declare-fun smt__VARIABLE__adds____prime () Idv)

(declare-fun smt__VARIABLE__stops__ () Idv)

(declare-fun smt__VARIABLE__stops____prime () Idv)

(declare-fun smt__VARIABLE__fenced__ () Idv)

(declare-fun smt__VARIABLE__fenced____prime () Idv)

(declare-fun smt__STATE__vars__ () Idv)

(declare-fun smt__STATE__Init__ () Idv)

(declare-fun smt__STATE__PeerLive__ (Idv) Idv)

(declare-fun smt__STATE__Attests__ (Idv) Idv)

(declare-fun smt__STATE__VouchedAt__ (Idv) Idv)

(declare-fun smt__ACTION__Seat__ (Idv Idv) Idv)

(declare-fun smt__STATE__MayAdd__ (Idv Idv) Idv)

(declare-fun smt__STATE__AddRecord__ (Idv Idv Idv Idv Idv) Idv)

(declare-fun smt__ACTION__Regrant__ (Idv Idv Idv) Idv)

(declare-fun smt__ACTION__Renew__ (Idv Idv) Idv)

(declare-fun smt__ACTION__Grant__ (Idv Idv Idv) Idv)

(declare-fun smt__STATE__MayDeny__ (Idv) Idv)

(declare-fun smt__STATE__StopRecord__ (Idv Idv) Idv)

(declare-fun smt__ACTION__EndRound__ (Idv Idv) Idv)

(declare-fun smt__ACTION__Revoke__ (Idv Idv) Idv)

(declare-fun smt__ACTION__FenceEpoch__ (Idv) Idv)

(declare-fun smt__ACTION__Expire__ (Idv) Idv)

(declare-fun smt__ACTION__Unvouch__ (Idv) Idv)

(declare-fun smt__ACTION__Vouch__ (Idv) Idv)

(declare-fun smt__ACTION__Next__ () Idv)

(declare-fun smt__TEMPORAL__Spec__ () Idv)

(declare-fun smt__STATE__FirstLeaseHasAQuorum__ () Idv)

(declare-fun smt__STATE__LeaseWithinSeating__ () Idv)

(declare-fun smt__STATE__SuccessorNeverWidens__ () Idv)

(declare-fun smt__STATE__ExpiredOperatorOnlyDenies__ () Idv)

(declare-fun smt__STATE__NoAddWithoutLiveLeaseAndPeer__ () Idv)

(declare-fun smt__STATE__NoSelfRegrant__ () Idv)

(declare-fun smt__STATE__OperatorLeaseWasVouched__ () Idv)

(declare-fun smt__STATE__NoDenyOnAStaleKey__ () Idv)

(declare-fun smt__STATE__NoDenyByRevoked__ () Idv)

(declare-fun smt__STATE__EveryStopIsAttributed__ () Idv)

(declare-fun smt__STATE__RevokedStaysOut__ () Idv)

(declare-fun smt__STATE__FleetFenceNeedsLease__ () Idv)

(declare-fun smt__STATE__DenyAlwaysAvailable__ () Idv)

(declare-fun smt__STATE__Safe__ () Idv)

(declare-fun smt__STATE__NeverWorkerRegrant__ () Idv)

(declare-fun smt__STATE__NeverNarrowed__ () Idv)

(declare-fun smt__STATE__NeverLapsedDeny__ () Idv)

(declare-fun smt__STATE__NeverStaleKey__ () Idv)

(declare-fun smt__STATE__NeverPeerless__ () Idv)

(declare-fun smt__STATE__NeverRecovered__ () Idv)

(declare-fun smt__STATE__NeverOperatorRegranted__ () Idv)

(declare-fun smt__STATE__NeverFenced__ () Idv)

(declare-fun smt__STATE__NeverLapsedRevoke__ () Idv)

(declare-fun smt__STATE__NeverOperatorRenewed__ () Idv)

; hidden fact

; hidden fact

; omitted declaration of 'CONSTANT_EnabledWrapper_' (second-order)

; omitted declaration of 'CONSTANT_CdotWrapper_' (second-order)

(declare-fun smt__STATE__Within__ () Idv)

; hidden fact

; hidden fact

; hidden fact

; hidden fact

; hidden fact

(assert (distinct smt__CONSTANT__Mut__ smt__TLA____StrLit__M__NOSEAT))

(assert
  (and
    (smt__TLA____Mem smt__VARIABLE__seating__
      (smt__TLA____FunSet smt__CONSTANT__Principals__
        (smt__TLA____IntRange (smt__TLA____Cast__Int 0) smt__CONSTANT__MaxW__)))
    (smt__TLA____Mem smt__VARIABLE__inForce__
      (smt__TLA____FunSet smt__CONSTANT__Principals__ smt__TLA____BoolSet))
    (smt__TLA____Mem smt__VARIABLE__lease__
      (smt__TLA____FunSet smt__CONSTANT__Principals__
        (smt__TLA____RecordSet__attested__live__root__round__width
          smt__TLA____BoolSet smt__TLA____BoolSet
          (smt__TLA____SetEnum__2 smt__TLA____StrLit__none
            smt__TLA____StrLit__quorum) smt__TLA____NatSet
          (smt__TLA____IntRange (smt__TLA____Cast__Int 0)
            smt__CONSTANT__MaxW__))))
    (smt__TLA____Mem smt__VARIABLE__vouched__
      (smt__TLA____FunSet smt__CONSTANT__Ops__ smt__TLA____BoolSet))))

(assert
  (and
    (forall ((smt__CONSTANT__p__ Idv))
      (=> (smt__TLA____Mem smt__CONSTANT__p__ smt__CONSTANT__Principals__)
        (=>
          (and
            (smt__TLA____IntLteq (smt__TLA____Cast__Int 0)
              (smt__TLA____FunApp
                (smt__TLA____FunApp smt__VARIABLE__lease__ smt__CONSTANT__p__)
                smt__TLA____StrLit__round))
            (distinct (smt__TLA____Cast__Int 0)
              (smt__TLA____FunApp
                (smt__TLA____FunApp smt__VARIABLE__lease__ smt__CONSTANT__p__)
                smt__TLA____StrLit__round)))
          (=
            (smt__TLA____FunApp
              (smt__TLA____FunApp smt__VARIABLE__lease__ smt__CONSTANT__p__)
              smt__TLA____StrLit__root) smt__TLA____StrLit__quorum))))
    (forall ((smt__CONSTANT__p__ Idv))
      (=> (smt__TLA____Mem smt__CONSTANT__p__ smt__CONSTANT__Principals__)
        (=>
          (=
            (smt__TLA____FunApp
              (smt__TLA____FunApp smt__VARIABLE__lease__ smt__CONSTANT__p__)
              smt__TLA____StrLit__live) smt__TLA____Tt__Idv)
          (and
            (smt__TLA____IntLteq (smt__TLA____Cast__Int 0)
              (smt__TLA____FunApp
                (smt__TLA____FunApp smt__VARIABLE__lease__ smt__CONSTANT__p__)
                smt__TLA____StrLit__round))
            (distinct (smt__TLA____Cast__Int 0)
              (smt__TLA____FunApp
                (smt__TLA____FunApp smt__VARIABLE__lease__ smt__CONSTANT__p__)
                smt__TLA____StrLit__round))))))))

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

; hidden fact

(assert (= smt__CONSTANT__Mut__ smt__TLA____StrLit__M__ANON))

(declare-fun smt__TLA____FunFcn__flatnd__1 (Idv) Idv)

;; Axiom: FunConstrIsafcn TLA__FunFcn_flatnd_1
(assert
  (!
    (forall ((smt__a Idv))
      (! (smt__TLA____FunIsafcn (smt__TLA____FunFcn__flatnd__1 smt__a))
        :pattern ((smt__TLA____FunFcn__flatnd__1 smt__a))))
    :named |FunConstrIsafcn TLA__FunFcn_flatnd_1|))

;; Axiom: FunDomDef TLA__FunFcn_flatnd_1
(assert
  (!
    (forall ((smt__a Idv))
      (!
        (= (smt__TLA____FunDom (smt__TLA____FunFcn__flatnd__1 smt__a)) smt__a)
        :pattern ((smt__TLA____FunFcn__flatnd__1 smt__a))))
    :named |FunDomDef TLA__FunFcn_flatnd_1|))

;; Axiom: FunAppDef TLA__FunFcn_flatnd_1
(assert
  (!
    (forall ((smt__a Idv) (smt__x Idv))
      (!
        (=> (smt__TLA____Mem smt__x smt__a)
          (=
            (smt__TLA____FunApp (smt__TLA____FunFcn__flatnd__1 smt__a) smt__x)
            (smt__TLA____FunExcept
              (smt__TLA____FunApp smt__VARIABLE__lease__ smt__x)
              smt__TLA____StrLit__live (smt__TLA____Cast__Bool false))))
        :pattern ((smt__TLA____FunApp (smt__TLA____FunFcn__flatnd__1 smt__a)
                    smt__x))
        :pattern ((smt__TLA____Mem smt__x smt__a)
                   (smt__TLA____FunFcn__flatnd__1 smt__a))))
    :named |FunAppDef TLA__FunFcn_flatnd_1|))

;; Axiom: FunTyping TLA__FunFcn_flatnd_1
(assert
  (!
    (forall ((smt__a Idv) (smt__b Idv))
      (!
        (=>
          (forall ((smt__x Idv))
            (=> (smt__TLA____Mem smt__x smt__a)
              (smt__TLA____Mem
                (smt__TLA____FunExcept
                  (smt__TLA____FunApp smt__VARIABLE__lease__ smt__x)
                  smt__TLA____StrLit__live (smt__TLA____Cast__Bool false))
                smt__b)))
          (smt__TLA____Mem (smt__TLA____FunFcn__flatnd__1 smt__a)
            (smt__TLA____FunSet smt__a smt__b)))
        :pattern ((smt__TLA____FunFcn__flatnd__1 smt__a)
                   (smt__TLA____FunSet smt__a smt__b))))
    :named |FunTyping TLA__FunFcn_flatnd_1|))

(assert
  (= smt__VARIABLE__lease____prime
    (smt__TLA____FunFcn__flatnd__1 smt__CONSTANT__Principals__)))

(assert
  (= smt__VARIABLE__stops____prime
    (smt__TLA____SetEnum__1
      (smt__TLA____Record__by__byLive__inForce__kind__vouched
        smt__TLA____StrLit__nobody (smt__TLA____Cast__Bool true)
        (smt__TLA____Cast__Bool true) smt__TLA____StrLit__fence
        (smt__TLA____Cast__Bool true)))))

(assert (= smt__VARIABLE__fenced____prime (smt__TLA____Cast__Bool true)))

(assert (= smt__VARIABLE__seating____prime smt__VARIABLE__seating__))

(assert (= smt__VARIABLE__inForce____prime smt__VARIABLE__inForce__))

(assert (= smt__VARIABLE__vouched____prime smt__VARIABLE__vouched__))

(assert (= smt__VARIABLE__adds____prime smt__VARIABLE__adds__))

;; Goal
(assert
  (!
    (not
      (and
        (forall ((smt__CONSTANT__p__ Idv))
          (=>
            (smt__TLA____Mem smt__CONSTANT__p__ smt__CONSTANT__Principals__)
            (=>
              (and
                (smt__TLA____IntLteq (smt__TLA____Cast__Int 0)
                  (smt__TLA____FunApp
                    (smt__TLA____FunApp smt__VARIABLE__lease____prime
                      smt__CONSTANT__p__) smt__TLA____StrLit__round))
                (distinct (smt__TLA____Cast__Int 0)
                  (smt__TLA____FunApp
                    (smt__TLA____FunApp smt__VARIABLE__lease____prime
                      smt__CONSTANT__p__) smt__TLA____StrLit__round)))
              (=
                (smt__TLA____FunApp
                  (smt__TLA____FunApp smt__VARIABLE__lease____prime
                    smt__CONSTANT__p__) smt__TLA____StrLit__root)
                smt__TLA____StrLit__quorum))))
        (forall ((smt__CONSTANT__p__ Idv))
          (=>
            (smt__TLA____Mem smt__CONSTANT__p__ smt__CONSTANT__Principals__)
            (=>
              (=
                (smt__TLA____FunApp
                  (smt__TLA____FunApp smt__VARIABLE__lease____prime
                    smt__CONSTANT__p__) smt__TLA____StrLit__live)
                smt__TLA____Tt__Idv)
              (and
                (smt__TLA____IntLteq (smt__TLA____Cast__Int 0)
                  (smt__TLA____FunApp
                    (smt__TLA____FunApp smt__VARIABLE__lease____prime
                      smt__CONSTANT__p__) smt__TLA____StrLit__round))
                (distinct (smt__TLA____Cast__Int 0)
                  (smt__TLA____FunApp
                    (smt__TLA____FunApp smt__VARIABLE__lease____prime
                      smt__CONSTANT__p__) smt__TLA____StrLit__round))))))))
    :named |Goal|))

(check-sat)
(exit)
