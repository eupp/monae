(* monae: Monadic equational reasoning in Coq                                 *)
(* Copyright (C) 2020 monae authors, license: LGPL-2.1-or-later               *)
Require Import Reals.
From mathcomp Require Import all_ssreflect.
From mathcomp Require Import boolp classical_sets.
From mathcomp Require Import finmap.
From infotheo Require Import Reals_ext Rbigop ssrR fdist fsdist convex.
From infotheo Require Import necset.
Require category.
Require Import monae_lib hierarchy monad_lib proba_lib monad_model gcm_model.

(******************************************************************************)
(*                  Model of the monad type altProbMonad                      *)
(*                                                                            *)
(* gcmAP == model of a monad that combines non-deterministic choice and       *)
(*          probability, built on top of the geometrically convex monad       *)
(******************************************************************************)

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope proba_scope.
Local Open Scope category_scope.

Section P_delta_altProbMonad.
Local Open Scope R_scope.
Local Open Scope reals_ext_scope.
Local Open Scope classical_set_scope.
Local Open Scope convex_scope.
Local Open Scope latt_scope.
Local Open Scope monae_scope.

Definition alt A (x y : gcm A) : gcm A := x [+] y.
Definition choice p A (x y : gcm A) : gcm A := x <| p |> y.

Lemma altA A : associative (@alt A).
Proof. by move=> x y z; rewrite /alt lubA. Qed.

Lemma image_FSDistfmap A B (x : gcm A) (k : choice_of_Type A -> gcm B) :
  FSDistfmap k @` x = (gcm # k) x.
Proof.
rewrite /Actm /= /category.Monad_of_category_monad.f /= /category.id_f /=.
by rewrite/free_semiCompSemiLattConvType_mor /=; unlock.
Qed.

Section funalt_funchoice.
Import category.
Import comps_notation.
Local Notation F1 := free_semiCompSemiLattConvType.
Local Notation F0 := free_convType.
Local Notation FC := free_choiceType.
Local Notation UC := forget_choiceType.
Local Notation U0 := forget_convType.
Local Notation U1 := forget_semiCompSemiLattConvType.
Lemma FunaltDr (A B : Type) (x y : gcm A) (k : A -> gcm B) :
  (gcm # k) (x [+] y) = (gcm # k) x [+] (gcm # k) y.
Proof.
rewrite /hierarchy.Functor.Exports.Actm /=.
rewrite /Monad_of_category_monad.f /=.
case: (free_semiCompSemiLattConvType_mor
        (free_convType_mor (free_choiceType_mor (hom_Type k))))=> f /= [] Haf Hbf.
rewrite Hbf lubE.
congr biglub.
apply neset_ext=> /=.
by rewrite image_setU !image_set1.
Qed.

Lemma FunpchoiceDr (A B : Type) (x y : gcm A) (k : A -> gcm B) p :
  (gcm # k) (x <|p|> y) = (gcm # k) x <|p|> (gcm # k) y.
Proof.
rewrite /hierarchy.Functor.Exports.Actm /=.
rewrite /Monad_of_category_monad.f /=.
case: (free_semiCompSemiLattConvType_mor
        (free_convType_mor (free_choiceType_mor (hom_Type k))))=> f /= [] Haf Hbf.
by apply Haf.
Qed.
End funalt_funchoice.

Section bindaltDl.
Import category.
Import comps_notation.
Local Notation F1 := free_semiCompSemiLattConvType.
Local Notation F0 := free_convType.
Local Notation FC := free_choiceType.
Local Notation UC := forget_choiceType.
Local Notation U0 := forget_convType.
Local Notation U1 := forget_semiCompSemiLattConvType.

Lemma affine_F1e0U1PD_alt T (u v : gcm (gcm T)) :
  (F1 # eps0 (U1 (P_delta_left T)))%category (u [+] v) =
  (F1 # eps0 (U1 (P_delta_left T)))%category u [+] (F1 # eps0 (U1 (P_delta_left T)))%category v.
Proof.
case: ((F1 # eps0 (U1 (P_delta_left T)))%category)=> f /= [] Haf Hbf.
rewrite !lubE Hbf.
congr biglub.
apply neset_ext=> /=.
by rewrite image_setU !image_set1.
Qed.

Lemma affine_e1PD_alt T (x y : el (F1 (FId (U1 (P_delta_left T))))) :
  (eps1 (P_delta_left T)) (x [+] y) =
  (eps1 (P_delta_left T)) x [+] (eps1 (P_delta_left T)) y.
Proof.
case: (eps1 (P_delta_left T))=> f /= [] Haf Hbf.
rewrite !lubE Hbf.
congr biglub.
apply neset_ext=> /=.
by rewrite image_setU !image_set1.
Qed.

Lemma bindaltDl : BindLaws.left_distributive (@hierarchy.Bind gcm) alt.
Proof.
move=> A B x y k.
rewrite !hierarchy.bindE /alt FunaltDr.
suff -> : forall T (u v : gcm (gcm T)),
  hierarchy.Join (u [+] v : gcm (gcm T)) = hierarchy.Join u [+] hierarchy.Join v by [].
move=> T u v.
rewrite /= /Monad_of_category_monad.join /=.
rewrite HCompId HIdComp !HCompId !HIdComp.
have-> : ((F1 \O F0) # epsC (U0 (U1 (P_delta_left T))))%category = idfun :> (_ -> _).
  have -> : epsC (U0 (U1 (P_delta_left T))) =
            [NEq _, _] _ by rewrite hom_ext /= epsCE.
  by rewrite functor_id.
by rewrite affine_F1e0U1PD_alt affine_e1PD_alt.
Qed.
End bindaltDl.

Definition P_delta_monadAltMixin : MonadAlt.mixin_of gcm :=
  MonadAlt.Mixin altA bindaltDl.
Definition gcmA : altMonad := MonadAlt.Pack (MonadAlt.Class P_delta_monadAltMixin).

Lemma altxx A : idempotent (@Alt gcmA A).
Proof. by move=> x; rewrite /Alt /= /alt lubxx. Qed.
Lemma altC A : commutative (@Alt gcmA A).
Proof. by move=> a b; rewrite /Alt /= /alt /= lubC. Qed.

Definition P_delta_monadAltCIMixin : MonadAltCI.class_of gcmA :=
  MonadAltCI.Class (MonadAltCI.Mixin altxx altC).
Definition gcmACI : altCIMonad := MonadAltCI.Pack P_delta_monadAltCIMixin.

Lemma choice0 A (x y : gcm A) : x <| 0%:pr |> y = y.
Proof. by rewrite /choice conv0. Qed.
Lemma choice1 A (x y : gcm A) : x <| 1%:pr |> y = x.
Proof. by rewrite /choice conv1. Qed.
Lemma choiceC A p (x y : gcm A) : x <|p|> y = y <|p.~%:pr|> x.
Proof. by rewrite /choice convC. Qed.
Lemma choicemm A p : idempotent (@choice p A).
Proof. by move=> m; rewrite /choice convmm. Qed.
Lemma choiceA A (p q r s : prob) (x y z : gcm A) :
  p = (r * s) :> R /\ s.~ = (p.~ * q.~)%R ->
  x <| p |> (y <| q |> z) = (x <| r |> y) <| s |> z.
Proof.
case=> H1 H2.
case/boolP : (r == 0%:pr) => r0.
  have p0 : p = 0%:pr by apply/prob_ext => /=; rewrite H1 (eqP r0) mul0R.
  rewrite p0 choice0 (eqP r0) choice0 (_ : q = s) //; apply/prob_ext => /=.
  by move: H2; rewrite p0 onem0 mul1R => /(congr1 onem); rewrite !onemK.
case/boolP : (s == 0%:pr) => s0.
  have p0 : p = 0%:pr by apply/prob_ext => /=; rewrite H1 (eqP s0) mulR0.
  rewrite p0 (eqP s0) 2!choice0 (_ : q = 0%:pr) ?choice0 //; apply/prob_ext.
  move: H2; rewrite p0 onem0 mul1R (eqP s0) onem0 => /(congr1 onem).
  by rewrite onemK onem1.
rewrite /choice convA (@r_of_pq_is_r _ _ r s) //; congr ((_ <| _ |> _) <| _ |> _).
by apply/prob_ext; rewrite s_of_pqE -H2 onemK.
Qed.

Section bindchoiceDl.
Import category.
Import comps_notation.
Local Notation F1 := free_semiCompSemiLattConvType.
Local Notation F0 := free_convType.
Local Notation FC := free_choiceType.
Local Notation UC := forget_choiceType.
Local Notation U0 := forget_convType.
Local Notation U1 := forget_semiCompSemiLattConvType.

Lemma affine_F1e0U1PD_conv T (u v : gcm (gcm T)) p :
  ((F1 # eps0 (U1 (P_delta_left T))) (u <|p|> v) =
   (F1 # eps0 (U1 (P_delta_left T))) u <|p|> (F1 # eps0 (U1 (P_delta_left T))) v)%category.
Proof.
case: ((F1 # eps0 (U1 (P_delta_left T)))%category)=> f /= [] Haf Hbf.
by apply: Haf.
Qed.

Lemma affine_e1PD_conv T (x y : el (F1 (FId (U1 (P_delta_left T))))) p :
  (eps1 (P_delta_left T)) (x <|p|> y) =
  (eps1 (P_delta_left T)) x <|p|> (eps1 (P_delta_left T)) y.
Proof.
rewrite eps1E -biglub_conv_setD; congr (|_| _); apply/neset_ext => /=.
by rewrite -necset_convType.conv_conv_set.
Qed.

Lemma bindchoiceDl p : BindLaws.left_distributive (@hierarchy.Bind gcm) (@choice p).
Proof.
move=> A B x y k.
rewrite !hierarchy.bindE /choice FunpchoiceDr.
suff -> : forall T (u v : gcm (gcm T)), hierarchy.Join (u <|p|> v : gcm (gcm T)) = hierarchy.Join u <|p|> hierarchy.Join v by [].
move=> T u v.
rewrite /= /Monad_of_category_monad.join /=.
rewrite HCompId HIdComp !HCompId !HIdComp.
have-> : ((F1 \O F0) # epsC (U0 (U1 (P_delta_left T))))%category = idfun :> (_ -> _).
  have -> : epsC (U0 (U1 (P_delta_left T))) =
            [NEq _, _] _ by rewrite hom_ext /= epsCE.
  by rewrite functor_id.
by rewrite affine_F1e0U1PD_conv affine_e1PD_conv.
Qed.
End bindchoiceDl.

Definition P_delta_monadProbMixin : MonadProb.mixin_of gcm :=
  MonadProb.Mixin choice0 choice1 choiceC choicemm choiceA bindchoiceDl.
Definition P_delta_monadProbMixin' :
  MonadProb.mixin_of (Monad.Pack (MonadAlt.base (MonadAltCI.base (MonadAltCI.class gcmACI)))) :=
  P_delta_monadProbMixin.
Definition gcmp : probMonad :=
  MonadProb.Pack (MonadProb.Class P_delta_monadProbMixin).

Lemma choicealtDr A (p : prob) :
  right_distributive (fun x y : gcmACI A => x <| p |> y) Alt.
Proof. by move=> x y z; rewrite /choice lubDr. Qed.

Definition P_delta_monadAltProbMixin : @MonadAltProb.mixin_of gcmACI choice :=
  MonadAltProb.Mixin choicealtDr.
Definition P_delta_monadAltProbMixin' :
  @MonadAltProb.mixin_of gcmACI (MonadProb.choice P_delta_monadProbMixin) :=
  P_delta_monadAltProbMixin.
Definition gcmAP : altProbMonad :=
  MonadAltProb.Pack (MonadAltProb.Class P_delta_monadAltProbMixin').
End P_delta_altProbMonad.

Section examples.
Local Open Scope proba_monad_scope.

(* An example that probabilistic choice in this model is not trivial:
   we can distinguish different probabilities. *)
Example gcmAP_choice_nontrivial (p q : prob) :
  p <> q ->
  Ret true <|p|> Ret false <> Ret true <|q|> Ret false :> gcmAP bool.
Proof.
move/eqP => pq.
apply/eqP.
apply: contra pq => /eqP Heq.
apply/eqP.
move: Heq.
rewrite !gcm_retE.
rewrite /Choice /= /Conv /= /necset_convType.conv /=.
unlock.
move/(congr1 (@NECSet.car _)) => /=.
rewrite /necset_convType.pre_pre_conv /=.
Local Open Scope convex_scope.
set mk1d := fun b : choice_of_Type bool => FSDist1.d b.
move/(congr1 (fun x : FSDist.t _ -> _ => x (mk1d true <|p|> mk1d false))).
rewrite /mkset; set tmp := ex _.
move=> Heq.
have: tmp -> tmp by [].
rewrite {2}Heq /tmp {Heq tmp}.
case.
  exists (mk1d true).
  exists (mk1d false).
  split; first by apply/asboolP.
  split; by [|apply/asboolP].
move=> x [] y.
rewrite 2!in_setE 2!necset1E => -[] -> [] ->.
move/(congr1 (fun x : {dist (choice_of_Type bool)} => x true)) => /=.
rewrite /Conv /= !ConvFSDist.dE !FSDist1.dE !inE !eqxx.
case/boolP: ((true : choice_of_Type bool) == false) => [/eqP//|].
by rewrite !mulR1 !mulR0 !addR0 => _ ?; apply prob_ext.
Qed.
End examples.
