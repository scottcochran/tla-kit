;; Proof obligation:
;;	ASSUME NEW CONSTANT CONSTANT_Mut_,
;;	       NEW CONSTANT CONSTANT_Thinkers_,
;;	       NEW CONSTANT CONSTANT_Stores_,
;;	       NEW CONSTANT CONSTANT_Corrs_,
;;	       NEW CONSTANT CONSTANT_Honest_,
;;	       NEW CONSTANT CONSTANT_MaxRound_,
;;	       NEW CONSTANT CONSTANT_MaxSends_,
;;	       NEW CONSTANT CONSTANT_MMiss_,
;;	       NEW VARIABLE VARIABLE_round_,
;;	       NEW VARIABLE VARIABLE_clearU_,
;;	       NEW VARIABLE VARIABLE_effU_,
;;	       NEW VARIABLE VARIABLE_tainted_,
;;	       NEW VARIABLE VARIABLE_lost_,
;;	       NEW VARIABLE VARIABLE_storeTaint_,
;;	       NEW VARIABLE VARIABLE_forgot_,
;;	       NEW VARIABLE VARIABLE_writes_,
;;	       NEW VARIABLE VARIABLE_delivered_,
;;	       NEW VARIABLE VARIABLE_erased_,
;;	       NEW VARIABLE VARIABLE_sends_,
;;	       NEW VARIABLE VARIABLE_found_,
;;	       NEW VARIABLE VARIABLE_marked_,
;;	       NEW VARIABLE VARIABLE_carriedF_,
;;	       NEW VARIABLE VARIABLE_sharedF_,
;;	       NEW VARIABLE VARIABLE_named_,
;;	       NEW VARIABLE VARIABLE_namedF_,
;;	       NEW VARIABLE VARIABLE_misses_,
;;	       CONSTANT_Mut_ = "M_BARE" ,
;;	       NEW CONSTANT CONSTANT_c_ \in CONSTANT_Corrs_,
;;	       NEW CONSTANT CONSTANT_s_ \in VARIABLE_sends_,
;;	       CONSTANT_s_ \notin VARIABLE_marked_[CONSTANT_c_] 
;;	PROVE  \E CONSTANT_writes#enabled#prime1_, CONSTANT_forgot#enabled#prime1_,
;;	          CONSTANT_named#enabled#prime1_, CONSTANT_found#enabled#prime1_,
;;	          CONSTANT_marked#enabled#prime1_, CONSTANT_lost#enabled#prime1_,
;;	          CONSTANT_round#enabled#prime1_, CONSTANT_namedF#enabled#prime1_,
;;	          CONSTANT_sends#enabled#prime1_, CONSTANT_tainted#enabled#prime1_,
;;	          CONSTANT_clearU#enabled#prime1_, CONSTANT_misses#enabled#prime1_,
;;	          CONSTANT_effU#enabled#prime1_, CONSTANT_carriedF#enabled#prime1_,
;;	          CONSTANT_delivered#enabled#prime1_,
;;	          CONSTANT_storeTaint#enabled#prime1_,
;;	          CONSTANT_erased#enabled#prime1_, CONSTANT_sharedF#enabled#prime1_ :
;;	          /\ CONSTANT_s_ \in VARIABLE_sends_
;;	             /\ CONSTANT_s_ \notin VARIABLE_marked_[CONSTANT_c_]
;;	          /\ CONSTANT_s_.eff \/ CONSTANT_Mut_ = "M_BARE"
;;	          /\ CONSTANT_carriedF#enabled#prime1_
;;	             = VARIABLE_carriedF_
;;	               \cup {[by |-> CONSTANT_c_, cite |-> CONSTANT_s_,
;;	                      cond |-> CONSTANT_s_.eff]}
;;	          /\ CONSTANT_marked#enabled#prime1_
;;	             = [VARIABLE_marked_ EXCEPT
;;	                  ![CONSTANT_c_] = VARIABLE_marked_[CONSTANT_c_]
;;	                                   \cup {CONSTANT_s_}]
;;	          /\ CONSTANT_misses#enabled#prime1_
;;	             = (IF CONSTANT_Mut_ = "M_SELF"
;;	                  THEN VARIABLE_misses_
;;	                  ELSE VARIABLE_misses_
;;	                       \cup {[obs |-> CONSTANT_c2_, tier |-> "correlation",
;;	                              cite |-> CONSTANT_s_] :
;;	                               CONSTANT_c2_
;;	                               \in {CONSTANT_q_ \in
;;	                                      CONSTANT_Corrs_ \ {CONSTANT_c_} :
;;	                                      CONSTANT_s_
;;	                                      \in VARIABLE_marked_[CONSTANT_q_]
;;	                                      /\ ~STATE_Has_(CONSTANT_q_,
;;	                                                     CONSTANT_s_)}})
;;	          /\ /\ CONSTANT_round#enabled#prime1_ = VARIABLE_round_
;;	             /\ CONSTANT_clearU#enabled#prime1_ = VARIABLE_clearU_
;;	             /\ CONSTANT_effU#enabled#prime1_ = VARIABLE_effU_
;;	             /\ CONSTANT_tainted#enabled#prime1_ = VARIABLE_tainted_
;;	             /\ CONSTANT_lost#enabled#prime1_ = VARIABLE_lost_
;;	             /\ CONSTANT_storeTaint#enabled#prime1_ = VARIABLE_storeTaint_
;;	             /\ CONSTANT_forgot#enabled#prime1_ = VARIABLE_forgot_
;;	             /\ CONSTANT_writes#enabled#prime1_ = VARIABLE_writes_
;;	             /\ CONSTANT_delivered#enabled#prime1_ = VARIABLE_delivered_
;;	             /\ CONSTANT_erased#enabled#prime1_ = VARIABLE_erased_
;;	             /\ CONSTANT_sends#enabled#prime1_ = VARIABLE_sends_
;;	             /\ CONSTANT_found#enabled#prime1_ = VARIABLE_found_
;;	             /\ CONSTANT_sharedF#enabled#prime1_ = VARIABLE_sharedF_
;;	             /\ CONSTANT_named#enabled#prime1_ = VARIABLE_named_
;;	             /\ CONSTANT_namedF#enabled#prime1_ = VARIABLE_namedF_
;; TLA+ Proof Manager 9a52faf
;; Proof obligation #449
;; Generated from file "./Correlator_proof.tla", line 518, characters 1-2

(set-logic UFNIA)

;; Sorts

(declare-sort Idv 0)

;; Hypotheses

(declare-fun smt__TLA____Cup (Idv Idv) Idv)

(declare-fun smt__TLA____FunApp (Idv Idv) Idv)

(declare-fun smt__TLA____FunDom (Idv) Idv)

(declare-fun smt__TLA____FunExcept (Idv Idv Idv) Idv)

; omitted declaration of 'TLA__FunFcn' (second-order)

(declare-fun smt__TLA____FunIsafcn (Idv) Bool)

(declare-fun smt__TLA____IsSetOf (Idv) Bool)

(declare-fun smt__TLA____Mem (Idv Idv) Bool)

(declare-fun smt__TLA____Record__by__cite__cond (Idv Idv Idv) Idv)

(declare-fun smt__TLA____Record__cite__obs__tier (Idv Idv Idv) Idv)

(declare-fun smt__TLA____SetEnum__0 () Idv)

(declare-fun smt__TLA____SetEnum__1 (Idv) Idv)

(declare-fun smt__TLA____SetEnum__3 (Idv Idv Idv) Idv)

(declare-fun smt__TLA____SetExtTrigger (Idv Idv) Bool)

(declare-fun smt__TLA____SetMinus (Idv Idv) Idv)

; omitted declaration of 'TLA__SetOf_1' (second-order)

; omitted declaration of 'TLA__SetSt' (second-order)

(declare-fun smt__TLA____StrLit__M__BARE () Idv)

(declare-fun smt__TLA____StrLit__M__SELF () Idv)

(declare-fun smt__TLA____StrLit__by () Idv)

(declare-fun smt__TLA____StrLit__cite () Idv)

(declare-fun smt__TLA____StrLit__cond () Idv)

(declare-fun smt__TLA____StrLit__correlation () Idv)

(declare-fun smt__TLA____StrLit__eff () Idv)

(declare-fun smt__TLA____StrLit__obs () Idv)

(declare-fun smt__TLA____StrLit__tier () Idv)

(declare-fun smt__TLA____StrSet () Idv)

(declare-fun smt__TLA____TrigEq__Setdollarsign__Idvdollarsign__ (Idv
  Idv) Bool)

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

;; Axiom: CupDef
(assert
  (!
    (forall ((smt__a Idv) (smt__b Idv) (smt__x Idv))
      (!
        (= (smt__TLA____Mem smt__x (smt__TLA____Cup smt__a smt__b))
          (or (smt__TLA____Mem smt__x smt__a) (smt__TLA____Mem smt__x smt__b)))
        :pattern ((smt__TLA____Mem smt__x (smt__TLA____Cup smt__a smt__b)))
        :pattern ((smt__TLA____Mem smt__x smt__a)
                   (smt__TLA____Cup smt__a smt__b))
        :pattern ((smt__TLA____Mem smt__x smt__b)
                   (smt__TLA____Cup smt__a smt__b)))) :named |CupDef|))

;; Axiom: SetMinusDef
(assert
  (!
    (forall ((smt__a Idv) (smt__b Idv) (smt__x Idv))
      (!
        (= (smt__TLA____Mem smt__x (smt__TLA____SetMinus smt__a smt__b))
          (and (smt__TLA____Mem smt__x smt__a)
            (not (smt__TLA____Mem smt__x smt__b))))
        :pattern ((smt__TLA____Mem smt__x
                    (smt__TLA____SetMinus smt__a smt__b)))
        :pattern ((smt__TLA____Mem smt__x smt__a)
                   (smt__TLA____SetMinus smt__a smt__b))
        :pattern ((smt__TLA____Mem smt__x smt__b)
                   (smt__TLA____SetMinus smt__a smt__b))))
    :named |SetMinusDef|))

; omitted fact (second-order)

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

; omitted fact (second-order)

;; Axiom: CompareSetOfTrigger
(assert
  (!
    (forall ((smt__a Idv) (smt__b Idv))
      (! (smt__TLA____SetExtTrigger smt__a smt__b)
        :pattern ((smt__TLA____IsSetOf smt__a) (smt__TLA____IsSetOf smt__b))))
    :named |CompareSetOfTrigger|))

;; Axiom: EnumDefIntro 1
(assert
  (!
    (forall ((smt__a1 Idv))
      (! (smt__TLA____Mem smt__a1 (smt__TLA____SetEnum__1 smt__a1))
        :pattern ((smt__TLA____SetEnum__1 smt__a1)))) :named |EnumDefIntro 1|))

;; Axiom: EnumDefIntro 3
(assert
  (!
    (forall ((smt__a1 Idv) (smt__a2 Idv) (smt__a3 Idv))
      (!
        (and
          (smt__TLA____Mem smt__a1
            (smt__TLA____SetEnum__3 smt__a1 smt__a2 smt__a3))
          (smt__TLA____Mem smt__a2
            (smt__TLA____SetEnum__3 smt__a1 smt__a2 smt__a3))
          (smt__TLA____Mem smt__a3
            (smt__TLA____SetEnum__3 smt__a1 smt__a2 smt__a3)))
        :pattern ((smt__TLA____SetEnum__3 smt__a1 smt__a2 smt__a3))))
    :named |EnumDefIntro 3|))

;; Axiom: EnumDefElim 0
(assert
  (!
    (forall ((smt__x Idv))
      (! (not (smt__TLA____Mem smt__x smt__TLA____SetEnum__0))
        :pattern ((smt__TLA____Mem smt__x smt__TLA____SetEnum__0))))
    :named |EnumDefElim 0|))

;; Axiom: EnumDefElim 1
(assert
  (!
    (forall ((smt__a1 Idv) (smt__x Idv))
      (!
        (=> (smt__TLA____Mem smt__x (smt__TLA____SetEnum__1 smt__a1))
          (= smt__x smt__a1))
        :pattern ((smt__TLA____Mem smt__x (smt__TLA____SetEnum__1 smt__a1)))))
    :named |EnumDefElim 1|))

;; Axiom: EnumDefElim 3
(assert
  (!
    (forall ((smt__a1 Idv) (smt__a2 Idv) (smt__a3 Idv) (smt__x Idv))
      (!
        (=>
          (smt__TLA____Mem smt__x
            (smt__TLA____SetEnum__3 smt__a1 smt__a2 smt__a3))
          (or (= smt__x smt__a1) (= smt__x smt__a2) (= smt__x smt__a3)))
        :pattern ((smt__TLA____Mem smt__x
                    (smt__TLA____SetEnum__3 smt__a1 smt__a2 smt__a3)))))
    :named |EnumDefElim 3|))

; omitted fact (second-order)

; omitted fact (second-order)

;; Axiom: StrLitIsstr M_BARE
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__M__BARE smt__TLA____StrSet)
    :named |StrLitIsstr M_BARE|))

;; Axiom: StrLitIsstr M_SELF
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__M__SELF smt__TLA____StrSet)
    :named |StrLitIsstr M_SELF|))

;; Axiom: StrLitIsstr by
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__by smt__TLA____StrSet)
    :named |StrLitIsstr by|))

;; Axiom: StrLitIsstr cite
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__cite smt__TLA____StrSet)
    :named |StrLitIsstr cite|))

;; Axiom: StrLitIsstr cond
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__cond smt__TLA____StrSet)
    :named |StrLitIsstr cond|))

;; Axiom: StrLitIsstr correlation
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__correlation smt__TLA____StrSet)
    :named |StrLitIsstr correlation|))

;; Axiom: StrLitIsstr eff
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__eff smt__TLA____StrSet)
    :named |StrLitIsstr eff|))

;; Axiom: StrLitIsstr obs
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__obs smt__TLA____StrSet)
    :named |StrLitIsstr obs|))

;; Axiom: StrLitIsstr tier
(assert
  (! (smt__TLA____Mem smt__TLA____StrLit__tier smt__TLA____StrSet)
    :named |StrLitIsstr tier|))

;; Axiom: StrLitDistinct M_SELF M_BARE
(assert
  (! (distinct smt__TLA____StrLit__M__SELF smt__TLA____StrLit__M__BARE)
    :named |StrLitDistinct M_SELF M_BARE|))

;; Axiom: StrLitDistinct M_SELF by
(assert
  (! (distinct smt__TLA____StrLit__M__SELF smt__TLA____StrLit__by)
    :named |StrLitDistinct M_SELF by|))

;; Axiom: StrLitDistinct M_SELF cite
(assert
  (! (distinct smt__TLA____StrLit__M__SELF smt__TLA____StrLit__cite)
    :named |StrLitDistinct M_SELF cite|))

;; Axiom: StrLitDistinct M_SELF cond
(assert
  (! (distinct smt__TLA____StrLit__M__SELF smt__TLA____StrLit__cond)
    :named |StrLitDistinct M_SELF cond|))

;; Axiom: StrLitDistinct M_SELF eff
(assert
  (! (distinct smt__TLA____StrLit__M__SELF smt__TLA____StrLit__eff)
    :named |StrLitDistinct M_SELF eff|))

;; Axiom: StrLitDistinct by M_BARE
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__M__BARE)
    :named |StrLitDistinct by M_BARE|))

;; Axiom: StrLitDistinct by eff
(assert
  (! (distinct smt__TLA____StrLit__by smt__TLA____StrLit__eff)
    :named |StrLitDistinct by eff|))

;; Axiom: StrLitDistinct cite M_BARE
(assert
  (! (distinct smt__TLA____StrLit__cite smt__TLA____StrLit__M__BARE)
    :named |StrLitDistinct cite M_BARE|))

;; Axiom: StrLitDistinct cite by
(assert
  (! (distinct smt__TLA____StrLit__cite smt__TLA____StrLit__by)
    :named |StrLitDistinct cite by|))

;; Axiom: StrLitDistinct cite eff
(assert
  (! (distinct smt__TLA____StrLit__cite smt__TLA____StrLit__eff)
    :named |StrLitDistinct cite eff|))

;; Axiom: StrLitDistinct cond M_BARE
(assert
  (! (distinct smt__TLA____StrLit__cond smt__TLA____StrLit__M__BARE)
    :named |StrLitDistinct cond M_BARE|))

;; Axiom: StrLitDistinct cond by
(assert
  (! (distinct smt__TLA____StrLit__cond smt__TLA____StrLit__by)
    :named |StrLitDistinct cond by|))

;; Axiom: StrLitDistinct cond cite
(assert
  (! (distinct smt__TLA____StrLit__cond smt__TLA____StrLit__cite)
    :named |StrLitDistinct cond cite|))

;; Axiom: StrLitDistinct cond eff
(assert
  (! (distinct smt__TLA____StrLit__cond smt__TLA____StrLit__eff)
    :named |StrLitDistinct cond eff|))

;; Axiom: StrLitDistinct correlation M_BARE
(assert
  (! (distinct smt__TLA____StrLit__correlation smt__TLA____StrLit__M__BARE)
    :named |StrLitDistinct correlation M_BARE|))

;; Axiom: StrLitDistinct correlation M_SELF
(assert
  (! (distinct smt__TLA____StrLit__correlation smt__TLA____StrLit__M__SELF)
    :named |StrLitDistinct correlation M_SELF|))

;; Axiom: StrLitDistinct correlation by
(assert
  (! (distinct smt__TLA____StrLit__correlation smt__TLA____StrLit__by)
    :named |StrLitDistinct correlation by|))

;; Axiom: StrLitDistinct correlation cite
(assert
  (! (distinct smt__TLA____StrLit__correlation smt__TLA____StrLit__cite)
    :named |StrLitDistinct correlation cite|))

;; Axiom: StrLitDistinct correlation cond
(assert
  (! (distinct smt__TLA____StrLit__correlation smt__TLA____StrLit__cond)
    :named |StrLitDistinct correlation cond|))

;; Axiom: StrLitDistinct correlation eff
(assert
  (! (distinct smt__TLA____StrLit__correlation smt__TLA____StrLit__eff)
    :named |StrLitDistinct correlation eff|))

;; Axiom: StrLitDistinct correlation obs
(assert
  (! (distinct smt__TLA____StrLit__correlation smt__TLA____StrLit__obs)
    :named |StrLitDistinct correlation obs|))

;; Axiom: StrLitDistinct correlation tier
(assert
  (! (distinct smt__TLA____StrLit__correlation smt__TLA____StrLit__tier)
    :named |StrLitDistinct correlation tier|))

;; Axiom: StrLitDistinct eff M_BARE
(assert
  (! (distinct smt__TLA____StrLit__eff smt__TLA____StrLit__M__BARE)
    :named |StrLitDistinct eff M_BARE|))

;; Axiom: StrLitDistinct obs M_BARE
(assert
  (! (distinct smt__TLA____StrLit__obs smt__TLA____StrLit__M__BARE)
    :named |StrLitDistinct obs M_BARE|))

;; Axiom: StrLitDistinct obs M_SELF
(assert
  (! (distinct smt__TLA____StrLit__obs smt__TLA____StrLit__M__SELF)
    :named |StrLitDistinct obs M_SELF|))

;; Axiom: StrLitDistinct obs by
(assert
  (! (distinct smt__TLA____StrLit__obs smt__TLA____StrLit__by)
    :named |StrLitDistinct obs by|))

;; Axiom: StrLitDistinct obs cite
(assert
  (! (distinct smt__TLA____StrLit__obs smt__TLA____StrLit__cite)
    :named |StrLitDistinct obs cite|))

;; Axiom: StrLitDistinct obs cond
(assert
  (! (distinct smt__TLA____StrLit__obs smt__TLA____StrLit__cond)
    :named |StrLitDistinct obs cond|))

;; Axiom: StrLitDistinct obs eff
(assert
  (! (distinct smt__TLA____StrLit__obs smt__TLA____StrLit__eff)
    :named |StrLitDistinct obs eff|))

;; Axiom: StrLitDistinct tier M_BARE
(assert
  (! (distinct smt__TLA____StrLit__tier smt__TLA____StrLit__M__BARE)
    :named |StrLitDistinct tier M_BARE|))

;; Axiom: StrLitDistinct tier M_SELF
(assert
  (! (distinct smt__TLA____StrLit__tier smt__TLA____StrLit__M__SELF)
    :named |StrLitDistinct tier M_SELF|))

;; Axiom: StrLitDistinct tier by
(assert
  (! (distinct smt__TLA____StrLit__tier smt__TLA____StrLit__by)
    :named |StrLitDistinct tier by|))

;; Axiom: StrLitDistinct tier cite
(assert
  (! (distinct smt__TLA____StrLit__tier smt__TLA____StrLit__cite)
    :named |StrLitDistinct tier cite|))

;; Axiom: StrLitDistinct tier cond
(assert
  (! (distinct smt__TLA____StrLit__tier smt__TLA____StrLit__cond)
    :named |StrLitDistinct tier cond|))

;; Axiom: StrLitDistinct tier eff
(assert
  (! (distinct smt__TLA____StrLit__tier smt__TLA____StrLit__eff)
    :named |StrLitDistinct tier eff|))

;; Axiom: StrLitDistinct tier obs
(assert
  (! (distinct smt__TLA____StrLit__tier smt__TLA____StrLit__obs)
    :named |StrLitDistinct tier obs|))

;; Axiom: RecIsafcn by cite cond
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv))
      (!
        (smt__TLA____FunIsafcn
          (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3))
        :pattern ((smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3))))
    :named |RecIsafcn by cite cond|))

;; Axiom: RecIsafcn cite obs tier
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv))
      (!
        (smt__TLA____FunIsafcn
          (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x3))
        :pattern ((smt__TLA____Record__cite__obs__tier smt__x1 smt__x2
                    smt__x3)))) :named |RecIsafcn cite obs tier|))

;; Axiom: RecDomDef by cite cond
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv))
      (!
        (=
          (smt__TLA____FunDom
            (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3))
          (smt__TLA____SetEnum__3 smt__TLA____StrLit__by
            smt__TLA____StrLit__cite smt__TLA____StrLit__cond))
        :pattern ((smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3))))
    :named |RecDomDef by cite cond|))

;; Axiom: RecDomDef cite obs tier
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv))
      (!
        (=
          (smt__TLA____FunDom
            (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x3))
          (smt__TLA____SetEnum__3 smt__TLA____StrLit__cite
            smt__TLA____StrLit__obs smt__TLA____StrLit__tier))
        :pattern ((smt__TLA____Record__cite__obs__tier smt__x1 smt__x2
                    smt__x3)))) :named |RecDomDef cite obs tier|))

;; Axiom: RecAppDef by cite cond
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv))
      (!
        (and
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3)
              smt__TLA____StrLit__by) smt__x1)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3)
              smt__TLA____StrLit__cite) smt__x2)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3)
              smt__TLA____StrLit__cond) smt__x3))
        :pattern ((smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3))))
    :named |RecAppDef by cite cond|))

;; Axiom: RecAppDef cite obs tier
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv))
      (!
        (and
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x3)
              smt__TLA____StrLit__cite) smt__x1)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x3)
              smt__TLA____StrLit__obs) smt__x2)
          (=
            (smt__TLA____FunApp
              (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x3)
              smt__TLA____StrLit__tier) smt__x3))
        :pattern ((smt__TLA____Record__cite__obs__tier smt__x1 smt__x2
                    smt__x3)))) :named |RecAppDef cite obs tier|))

;; Axiom: RecExcept by cite cond 1
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3)
            smt__TLA____StrLit__by smt__x)
          (smt__TLA____Record__by__cite__cond smt__x smt__x2 smt__x3))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__by__cite__cond smt__x1 smt__x2
                      smt__x3) smt__TLA____StrLit__by smt__x))))
    :named |RecExcept by cite cond 1|))

;; Axiom: RecExcept by cite cond 2
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3)
            smt__TLA____StrLit__cite smt__x)
          (smt__TLA____Record__by__cite__cond smt__x1 smt__x smt__x3))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__by__cite__cond smt__x1 smt__x2
                      smt__x3) smt__TLA____StrLit__cite smt__x))))
    :named |RecExcept by cite cond 2|))

;; Axiom: RecExcept by cite cond 3
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x3)
            smt__TLA____StrLit__cond smt__x)
          (smt__TLA____Record__by__cite__cond smt__x1 smt__x2 smt__x))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__by__cite__cond smt__x1 smt__x2
                      smt__x3) smt__TLA____StrLit__cond smt__x))))
    :named |RecExcept by cite cond 3|))

;; Axiom: RecExcept cite obs tier 1
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x3)
            smt__TLA____StrLit__cite smt__x)
          (smt__TLA____Record__cite__obs__tier smt__x smt__x2 smt__x3))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2
                      smt__x3) smt__TLA____StrLit__cite smt__x))))
    :named |RecExcept cite obs tier 1|))

;; Axiom: RecExcept cite obs tier 2
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x3)
            smt__TLA____StrLit__obs smt__x)
          (smt__TLA____Record__cite__obs__tier smt__x1 smt__x smt__x3))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2
                      smt__x3) smt__TLA____StrLit__obs smt__x))))
    :named |RecExcept cite obs tier 2|))

;; Axiom: RecExcept cite obs tier 3
(assert
  (!
    (forall ((smt__x1 Idv) (smt__x2 Idv) (smt__x3 Idv) (smt__x Idv))
      (!
        (=
          (smt__TLA____FunExcept
            (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x3)
            smt__TLA____StrLit__tier smt__x)
          (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2 smt__x))
        :pattern ((smt__TLA____FunExcept
                    (smt__TLA____Record__cite__obs__tier smt__x1 smt__x2
                      smt__x3) smt__TLA____StrLit__tier smt__x))))
    :named |RecExcept cite obs tier 3|))

;; Axiom: ExtTrigEqDef Set$Idv$
(assert
  (!
    (forall ((smt__x Idv) (smt__y Idv))
      (!
        (= (smt__TLA____TrigEq__Setdollarsign__Idvdollarsign__ smt__x smt__y)
          (= smt__x smt__y))
        :pattern ((smt__TLA____TrigEq__Setdollarsign__Idvdollarsign__ 
                    smt__x smt__y)))) :named |ExtTrigEqDef Set$Idv$|))

;; Axiom: ExtTrigEqTrigger Idv
(assert
  (!
    (forall ((smt__x Idv) (smt__y Idv))
      (! (smt__TLA____SetExtTrigger smt__x smt__y)
        :pattern ((smt__TLA____TrigEq__Setdollarsign__Idvdollarsign__ 
                    smt__x smt__y)))) :named |ExtTrigEqTrigger Idv|))

; omitted fact (second-order)

(declare-fun smt__CONSTANT__IsFiniteSet__ (Idv) Idv)

(declare-fun smt__CONSTANT__Cardinality__ (Idv) Idv)

(declare-fun smt__CONSTANT__Mut__ () Idv)

(declare-fun smt__CONSTANT__Thinkers__ () Idv)

(declare-fun smt__CONSTANT__Stores__ () Idv)

(declare-fun smt__CONSTANT__Corrs__ () Idv)

(declare-fun smt__CONSTANT__Honest__ () Idv)

(declare-fun smt__CONSTANT__MaxRound__ () Idv)

(declare-fun smt__CONSTANT__MaxSends__ () Idv)

(declare-fun smt__CONSTANT__MMiss__ () Idv)

(declare-fun smt__CONSTANT__Items__ () Idv)

(declare-fun smt__VARIABLE__round__ () Idv)

(declare-fun smt__VARIABLE__round____prime () Idv)

(declare-fun smt__VARIABLE__clearU__ () Idv)

(declare-fun smt__VARIABLE__clearU____prime () Idv)

(declare-fun smt__VARIABLE__effU__ () Idv)

(declare-fun smt__VARIABLE__effU____prime () Idv)

(declare-fun smt__VARIABLE__tainted__ () Idv)

(declare-fun smt__VARIABLE__tainted____prime () Idv)

(declare-fun smt__VARIABLE__lost__ () Idv)

(declare-fun smt__VARIABLE__lost____prime () Idv)

(declare-fun smt__VARIABLE__storeTaint__ () Idv)

(declare-fun smt__VARIABLE__storeTaint____prime () Idv)

(declare-fun smt__VARIABLE__forgot__ () Idv)

(declare-fun smt__VARIABLE__forgot____prime () Idv)

(declare-fun smt__VARIABLE__writes__ () Idv)

(declare-fun smt__VARIABLE__writes____prime () Idv)

(declare-fun smt__VARIABLE__delivered__ () Idv)

(declare-fun smt__VARIABLE__delivered____prime () Idv)

(declare-fun smt__VARIABLE__erased__ () Idv)

(declare-fun smt__VARIABLE__erased____prime () Idv)

(declare-fun smt__VARIABLE__sends__ () Idv)

(declare-fun smt__VARIABLE__sends____prime () Idv)

(declare-fun smt__VARIABLE__found__ () Idv)

(declare-fun smt__VARIABLE__found____prime () Idv)

(declare-fun smt__VARIABLE__marked__ () Idv)

(declare-fun smt__VARIABLE__marked____prime () Idv)

(declare-fun smt__VARIABLE__carriedF__ () Idv)

(declare-fun smt__VARIABLE__carriedF____prime () Idv)

(declare-fun smt__VARIABLE__sharedF__ () Idv)

(declare-fun smt__VARIABLE__sharedF____prime () Idv)

(declare-fun smt__VARIABLE__named__ () Idv)

(declare-fun smt__VARIABLE__named____prime () Idv)

(declare-fun smt__VARIABLE__namedF__ () Idv)

(declare-fun smt__VARIABLE__namedF____prime () Idv)

(declare-fun smt__VARIABLE__misses__ () Idv)

(declare-fun smt__VARIABLE__misses____prime () Idv)

(declare-fun smt__STATE__vars__ () Idv)

(declare-fun smt__STATE__Init__ () Idv)

(declare-fun smt__STATE__Carried__ (Idv) Idv)

(declare-fun smt__STATE__Blocked__ (Idv) Idv)

(declare-fun smt__STATE__Has__ (Idv Idv) Idv)

(declare-fun smt__STATE__Had__ (Idv) Idv)

(declare-fun smt__ACTION__Read__ (Idv Idv Idv) Idv)

(declare-fun smt__STATE__Out__ (Idv) Idv)

(declare-fun smt__ACTION__Touch__ (Idv Idv) Idv)

(declare-fun smt__ACTION__Send__ (Idv) Idv)

(declare-fun smt__ACTION__EndRound__ (Idv) Idv)

(declare-fun smt__ACTION__Erase__ (Idv Idv) Idv)

(declare-fun smt__ACTION__ObsFind__ (Idv Idv) Idv)

(declare-fun smt__ACTION__Pass__ (Idv Idv) Idv)

(declare-fun smt__ACTION__Propagate__ (Idv Idv) Idv)

(declare-fun smt__STATE__MissesOf__ (Idv) Idv)

(declare-fun smt__ACTION__Name__ (Idv Idv) Idv)

(declare-fun smt__ACTION__Next__ () Idv)

(declare-fun smt__TEMPORAL__Spec__ () Idv)

(declare-fun smt__STATE__CarriedCoversSplitPath__ () Idv)

(declare-fun smt__STATE__FindingHasEvidence__ () Idv)

(declare-fun smt__STATE__IngressReachIsShared__ () Idv)

(declare-fun smt__STATE__SilenceIsCounted__ () Idv)

(declare-fun smt__STATE__MissIsOnACorrelation__ () Idv)

(declare-fun smt__STATE__HonestNeverCharged__ () Idv)

(declare-fun smt__STATE__StoreWithinRecord__ () Idv)

(declare-fun smt__STATE__LagNeverGates__ () Idv)

(declare-fun smt__STATE__Safe__ () Idv)

(declare-fun smt__STATE__NeverSplitFound__ () Idv)

(declare-fun smt__STATE__NeverFoundClean__ () Idv)

(declare-fun smt__STATE__NeverSharedTwo__ () Idv)

(declare-fun smt__STATE__NeverMiss__ () Idv)

(declare-fun smt__STATE__NeverNamed__ () Idv)

(declare-fun smt__STATE__NeverLostTaint__ () Idv)

(declare-fun smt__STATE__NeverErasedARow__ () Idv)

; hidden fact

; hidden fact

; omitted declaration of 'CONSTANT_EnabledWrapper_' (second-order)

; omitted declaration of 'CONSTANT_CdotWrapper_' (second-order)

(declare-fun smt__STATE__TypeOK__ () Idv)

(declare-fun smt__STATE__StoreTracked__ () Idv)

(declare-fun smt__STATE__ContextTracked__ () Idv)

(declare-fun smt__STATE__SendTracked__ () Idv)

(declare-fun smt__STATE__Ghost__ () Idv)

(declare-fun smt__STATE__HonestFolded__ () Idv)

(declare-fun smt__STATE__CitedFired__ () Idv)

(declare-fun smt__STATE__ErasedArePast__ () Idv)

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

(assert (= smt__CONSTANT__Mut__ smt__TLA____StrLit__M__BARE))

(declare-fun smt__CONSTANT__c__ () Idv)

(assert (smt__TLA____Mem smt__CONSTANT__c__ smt__CONSTANT__Corrs__))

(declare-fun smt__CONSTANT__s__ () Idv)

(assert (smt__TLA____Mem smt__CONSTANT__s__ smt__VARIABLE__sends__))

(assert
  (not
    (smt__TLA____Mem smt__CONSTANT__s__
      (smt__TLA____FunApp smt__VARIABLE__marked__ smt__CONSTANT__c__))))

(declare-fun smt__TLA____SetSt__flatnd__1 (Idv) Idv)

;; Axiom: SetStDef TLA__SetSt_flatnd_1
(assert
  (!
    (forall ((smt__a Idv) (smt__x Idv))
      (!
        (= (smt__TLA____Mem smt__x (smt__TLA____SetSt__flatnd__1 smt__a))
          (and (smt__TLA____Mem smt__x smt__a)
            (and
              (smt__TLA____Mem smt__CONSTANT__s__
                (smt__TLA____FunApp smt__VARIABLE__marked__ smt__x))
              (not
                (= (smt__STATE__Has__ smt__x smt__CONSTANT__s__)
                  smt__TLA____Tt__Idv)))))
        :pattern ((smt__TLA____Mem smt__x
                    (smt__TLA____SetSt__flatnd__1 smt__a)))
        :pattern ((smt__TLA____Mem smt__x smt__a)
                   (smt__TLA____SetSt__flatnd__1 smt__a))))
    :named |SetStDef TLA__SetSt_flatnd_1|))

(declare-fun smt__TLA____SetOf__1__flatnd__2 (Idv) Idv)

;; Axiom: SetOfIntro 1 TLA__SetOf_1_flatnd_2
(assert
  (!
    (forall ((smt__a1 Idv) (smt__y1 Idv))
      (!
        (=> (smt__TLA____Mem smt__y1 smt__a1)
          (smt__TLA____Mem
            (smt__TLA____Record__cite__obs__tier smt__CONSTANT__s__ smt__y1
              smt__TLA____StrLit__correlation)
            (smt__TLA____SetOf__1__flatnd__2 smt__a1)))
        :pattern ((smt__TLA____Record__cite__obs__tier smt__CONSTANT__s__
                    smt__y1 smt__TLA____StrLit__correlation)
                   (smt__TLA____SetOf__1__flatnd__2 smt__a1))
        :pattern ((smt__TLA____SetOf__1__flatnd__2 smt__a1)
                   (smt__TLA____Mem smt__y1 smt__a1))))
    :named |SetOfIntro 1 TLA__SetOf_1_flatnd_2|))

;; Axiom: SetOfElim 1 TLA__SetOf_1_flatnd_2
(assert
  (!
    (forall ((smt__a1 Idv) (smt__x Idv))
      (!
        (=>
          (smt__TLA____Mem smt__x (smt__TLA____SetOf__1__flatnd__2 smt__a1))
          (exists ((smt__y1 Idv))
            (and (smt__TLA____Mem smt__y1 smt__a1)
              (= smt__x
                (smt__TLA____Record__cite__obs__tier smt__CONSTANT__s__
                  smt__y1 smt__TLA____StrLit__correlation)))))
        :pattern ((smt__TLA____Mem smt__x
                    (smt__TLA____SetOf__1__flatnd__2 smt__a1)))))
    :named |SetOfElim 1 TLA__SetOf_1_flatnd_2|))

;; Axiom: AssertIsSetOf 1 TLA__SetOf_1_flatnd_2
(assert
  (!
    (forall ((smt__a Idv))
      (! (smt__TLA____IsSetOf (smt__TLA____SetOf__1__flatnd__2 smt__a))
        :pattern ((smt__TLA____SetOf__1__flatnd__2 smt__a))))
    :named |AssertIsSetOf 1 TLA__SetOf_1_flatnd_2|))

;; Goal
(assert
  (!
    (not
      (exists
        ((smt__CONSTANT__writespound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__forgotpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__namedpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__foundpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__markedpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__lostpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__roundpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__namedFpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__sendspound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__taintedpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__clearUpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__missespound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__effUpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__carriedFpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__deliveredpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__storeTaintpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__erasedpound__enabledpound__prime1__ Idv)
          (smt__CONSTANT__sharedFpound__enabledpound__prime1__ Idv))
        (and
          (and (smt__TLA____Mem smt__CONSTANT__s__ smt__VARIABLE__sends__)
            (not
              (smt__TLA____Mem smt__CONSTANT__s__
                (smt__TLA____FunApp smt__VARIABLE__marked__
                  smt__CONSTANT__c__))))
          (or
            (=
              (smt__TLA____FunApp smt__CONSTANT__s__ smt__TLA____StrLit__eff)
              smt__TLA____Tt__Idv)
            (= smt__CONSTANT__Mut__ smt__TLA____StrLit__M__BARE))
          (smt__TLA____TrigEq__Setdollarsign__Idvdollarsign__
            smt__CONSTANT__carriedFpound__enabledpound__prime1__
            (smt__TLA____Cup smt__VARIABLE__carriedF__
              (smt__TLA____SetEnum__1
                (smt__TLA____Record__by__cite__cond smt__CONSTANT__c__
                  smt__CONSTANT__s__
                  (smt__TLA____FunApp smt__CONSTANT__s__
                    smt__TLA____StrLit__eff)))))
          (= smt__CONSTANT__markedpound__enabledpound__prime1__
            (smt__TLA____FunExcept smt__VARIABLE__marked__ smt__CONSTANT__c__
              (smt__TLA____Cup
                (smt__TLA____FunApp smt__VARIABLE__marked__
                  smt__CONSTANT__c__)
                (smt__TLA____SetEnum__1 smt__CONSTANT__s__))))
          (= smt__CONSTANT__missespound__enabledpound__prime1__
            (ite (= smt__CONSTANT__Mut__ smt__TLA____StrLit__M__SELF)
              smt__VARIABLE__misses__
              (smt__TLA____Cup smt__VARIABLE__misses__
                (smt__TLA____SetOf__1__flatnd__2
                  (smt__TLA____SetSt__flatnd__1
                    (smt__TLA____SetMinus smt__CONSTANT__Corrs__
                      (smt__TLA____SetEnum__1 smt__CONSTANT__c__)))))))
          (and
            (= smt__CONSTANT__roundpound__enabledpound__prime1__
              smt__VARIABLE__round__)
            (= smt__CONSTANT__clearUpound__enabledpound__prime1__
              smt__VARIABLE__clearU__)
            (= smt__CONSTANT__effUpound__enabledpound__prime1__
              smt__VARIABLE__effU__)
            (= smt__CONSTANT__taintedpound__enabledpound__prime1__
              smt__VARIABLE__tainted__)
            (= smt__CONSTANT__lostpound__enabledpound__prime1__
              smt__VARIABLE__lost__)
            (= smt__CONSTANT__storeTaintpound__enabledpound__prime1__
              smt__VARIABLE__storeTaint__)
            (= smt__CONSTANT__forgotpound__enabledpound__prime1__
              smt__VARIABLE__forgot__)
            (= smt__CONSTANT__writespound__enabledpound__prime1__
              smt__VARIABLE__writes__)
            (= smt__CONSTANT__deliveredpound__enabledpound__prime1__
              smt__VARIABLE__delivered__)
            (= smt__CONSTANT__erasedpound__enabledpound__prime1__
              smt__VARIABLE__erased__)
            (= smt__CONSTANT__sendspound__enabledpound__prime1__
              smt__VARIABLE__sends__)
            (= smt__CONSTANT__foundpound__enabledpound__prime1__
              smt__VARIABLE__found__)
            (= smt__CONSTANT__sharedFpound__enabledpound__prime1__
              smt__VARIABLE__sharedF__)
            (= smt__CONSTANT__namedpound__enabledpound__prime1__
              smt__VARIABLE__named__)
            (= smt__CONSTANT__namedFpound__enabledpound__prime1__
              smt__VARIABLE__namedF__))))) :named |Goal|))

(check-sat)
(exit)
