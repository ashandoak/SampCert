/-
Copyright (c) 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jean-Baptiste Tristan
-/

import Mathlib.Topology.Algebra.InfiniteSum.Basic
import Mathlib.Topology.Algebra.InfiniteSum.Ring
import Mathlib.Algebra.Group.Basic
import SampCert.DiffPrivacy.ConcentratedBound
import SampCert.SLang
import SampCert.Samplers.GaussianGen.Basic
import SampCert.DiffPrivacy.Neighbours
import SampCert.DiffPrivacy.Sensitivity
import Mathlib.MeasureTheory.MeasurableSpace.Basic
import Mathlib.MeasureTheory.Measure.Count
import Mathlib.Probability.ProbabilityMassFunction.Integrals
import Mathlib.Analysis.Convex.SpecificFunctions.Basic
import Mathlib.Analysis.Convex.Integral

noncomputable section

open Classical Nat Int Real ENNReal MeasureTheory Measure

def DP (q : List T → SLang U) (ε : ℝ) : Prop :=
  ∀ α : ℝ, 1 < α → ∀ l₁ l₂ : List T, Neighbour l₁ l₂ →
  RenyiDivergence (q l₁) (q l₂) α ≤ (1/2) * ε ^ 2 * α

def NonZeroNQ (nq : List T → SLang U) :=
  ∀ l : List T, ∀ n : U, nq l n ≠ 0

def NonTopSum (nq : List T → SLang U) :=
  ∀ l : List T, ∑' n : U, nq l n ≠ ⊤

def NonTopNQ (nq : List T → SLang U) :=
  ∀ l : List T, ∀ n : U, nq l n ≠ ⊤

def NonTopRDNQ (nq : List T → SLang U) : Prop :=
  ∀ α : ℝ, 1 < α → ∀ l₁ l₂ : List T, Neighbour l₁ l₂ →
  ∑' (x : U), nq l₁ x ^ α * nq l₂ x ^ (1 - α) ≠ ⊤

namespace SLang

def NoisedQuery (query : List T → ℤ) (Δ : ℕ+) (ε₁ ε₂ : ℕ+) (l : List T) : SLang ℤ := do
  DiscreteGaussianGenSample (Δ * ε₂) ε₁ (query l)

theorem NoisedQueryDP (query : List T → ℤ) (Δ ε₁ ε₂ : ℕ+) (bounded_sensitivity : sensitivity query Δ) :
  DP (NoisedQuery query Δ ε₁ ε₂) ((ε₁ : ℝ) / ε₂) := by
  simp [DP, NoisedQuery]
  intros α h1 l₁ l₂ h2
  have A := @DiscreteGaussianGenSampleZeroConcentrated α h1 (Δ * ε₂) ε₁ (query l₁) (query l₂)
  apply le_trans A
  clear A
  replace bounded_sensitivity := bounded_sensitivity l₁ l₂ h2
  ring_nf
  simp
  conv =>
    left
    left
    right
    rw [mul_pow]
  conv =>
    left
    rw [mul_assoc]
    right
    rw [mul_comm]
    rw [← mul_assoc]
  conv =>
    left
    rw [mul_assoc]
    right
    rw [← mul_assoc]
    left
    rw [mul_comm]
  rw [← mul_assoc]
  rw [← mul_assoc]
  rw [← mul_assoc]
  simp only [inv_pow]
  rw [mul_inv_le_iff']
  . have A : (α * ↑↑ε₁ ^ 2 * (↑↑ε₂ ^ 2)⁻¹) ≤ (α * ↑↑ε₁ ^ 2 * (↑↑ε₂ ^ 2)⁻¹) := le_refl (α * ↑↑ε₁ ^ 2 * (↑↑ε₂ ^ 2)⁻¹)
    have B : 0 ≤ (α * ↑↑ε₁ ^ 2 * (↑↑ε₂ ^ 2)⁻¹) := by
      simp
      apply @le_trans ℝ _ 0 1 α (instStrictOrderedCommRingReal.proof_3) (le_of_lt h1)
    apply mul_le_mul A _ _ B
    . apply sq_le_sq.mpr
      simp only [abs_cast]
      rw [← Int.cast_sub]
      rw [← Int.cast_abs]
      apply Int.cast_le.mpr
      rw [← Int.natCast_natAbs]
      apply Int.ofNat_le.mpr
      trivial
    . apply sq_nonneg
  . rw [pow_two]
    rw [_root_.mul_pos_iff]
    left
    simp

theorem NoisedQuery_NonZeroNQ (query : List T → ℤ) (Δ ε₁ ε₂ : ℕ+) :
  NonZeroNQ (NoisedQuery query Δ ε₁ ε₂) := by
  simp [NonZeroNQ, NoisedQuery, DiscreteGaussianGenSample]
  intros l n
  exists (n - query l)
  simp
  have A : ((Δ : ℝ) * ε₂ / ε₁) ≠ 0 := by
    simp
  have X := @discrete_gaussian_pos (↑↑Δ * ↑↑ε₂ / ↑↑ε₁) A 0 (n - query l)
  simp at X
  trivial

theorem NoisedQuery_NonTopNQ (query : List T → ℤ) (Δ ε₁ ε₂ : ℕ+) :
  NonTopNQ (NoisedQuery query Δ ε₁ ε₂) := by
  simp [NonTopNQ, NoisedQuery, DiscreteGaussianGenSample]
  intro l n
  rw [ENNReal.tsum_eq_add_tsum_ite (n - query l)]
  simp
  have X : ∀ x : ℤ, (@ite ℝ≥0∞ (x = n - query l) (propDecidable (x = n - query l)) 0
    (@ite ℝ≥0∞ (n = x + query l) (instDecidableEqInt n (x + query l))
  (ENNReal.ofReal (discrete_gaussian (↑↑Δ * ↑↑ε₂ / ↑↑ε₁) 0 ↑x)) 0)) = 0 := by
    intro x
    split
    . simp
    . split
      . rename_i h1 h2
        subst h2
        simp at h1
      . simp
  conv =>
    right
    left
    right
    intro x
    rw [X]
  simp

theorem discrete_gaussian_shift {σ : ℝ} (h : σ ≠ 0) (μ : ℝ) (τ x : ℤ) :
  discrete_gaussian σ μ (x - τ) = discrete_gaussian σ (μ + τ) (x) := by
  simp [discrete_gaussian]
  congr 1
  . simp [gauss_term_ℝ]
    congr 3
    ring_nf
  . rw [SG_periodic h]

theorem NoisedQuery_NonTopSum (query : List T → ℤ) (Δ ε₁ ε₂ : ℕ+) :
  NonTopSum (NoisedQuery query Δ ε₁ ε₂) := by
  simp [NonTopSum, NoisedQuery, DiscreteGaussianGenSample]
  intro l
  have X : ∀ n: ℤ, ∀ x : ℤ, (@ite ℝ≥0∞ (x = n - query l) (propDecidable (x = n - query l)) 0
    (@ite ℝ≥0∞ (n = x + query l) (instDecidableEqInt n (x + query l))
    (ENNReal.ofReal (discrete_gaussian (↑↑Δ * ↑↑ε₂ / ↑↑ε₁) 0 ↑x)) 0)) = 0 := by
    intro n x
    split
    . simp
    . split
      . rename_i h1 h2
        subst h2
        simp at h1
      . simp
  conv =>
    right
    left
    right
    intro n
    rw [ENNReal.tsum_eq_add_tsum_ite (n - query l)]
    simp
    right
    right
    intro x
    rw [X]
  simp
  have A : (Δ : ℝ) * ε₂ / ε₁ ≠ 0 := by
    simp
  conv =>
    right
    left
    right
    intro n
    rw [discrete_gaussian_shift A]
  simp
  rw [← ENNReal.ofReal_tsum_of_nonneg]
  . rw [discrete_gaussian_normalizes A]
    simp
  . apply discrete_gaussian_nonneg A
  . apply discrete_gaussian_summable' A (query l)

theorem NoisedQuery_NonTopRDNQ (query : List T → ℤ) (Δ ε₁ ε₂ : ℕ+) :
  NonTopRDNQ (NoisedQuery query Δ ε₁ ε₂) := by
  simp [NonTopRDNQ, NoisedQuery, DiscreteGaussianGenSample]
  intro α _ l₁ l₂ _
  have A : ∀ x_1 x : ℤ, (@ite ℝ≥0∞ (x_1 = x - query l₁) (propDecidable (x_1 = x - query l₁)) 0
  (@ite ℝ≥0∞ (x = x_1 + query l₁) (instDecidableEqInt x (x_1 + query l₁))
  (ENNReal.ofReal (discrete_gaussian (↑↑Δ * ↑↑ε₂ / ↑↑ε₁) 0 ↑x_1)) 0 )) = 0 := by
    intro x y
    split
    . simp
    . split
      . rename_i h1 h2
        subst h2
        simp at h1
      . simp
  have B : ∀ x_1 x : ℤ, (@ite ℝ≥0∞ (x_1 = x - query l₂) (propDecidable (x_1 = x - query l₂)) 0
    (@ite ℝ≥0∞ (x = x_1 + query l₂) (instDecidableEqInt x (x_1 + query l₂))
  (ENNReal.ofReal (discrete_gaussian (↑↑Δ * ↑↑ε₂ / ↑↑ε₁) 0 ↑x_1)) 0)) = 0 := by
    intro x y
    split
    . simp
    . split
      . rename_i h1 h2
        subst h2
        simp at h1
      . simp
  conv =>
    right
    left
    right
    intro x
    left
    rw [ENNReal.tsum_eq_add_tsum_ite (x - query l₁)]
    simp
    left
    right
    right
    intro y
    rw [A]
  simp
  conv =>
    right
    left
    right
    intro x
    right
    rw [ENNReal.tsum_eq_add_tsum_ite (x - query l₂)]
    simp
    left
    right
    right
    intro y
    rw [B]
  simp
  clear A B
  have P : (Δ : ℝ) * ε₂ / ε₁ ≠ 0 := by
    simp
  have A : ∀ x : ℤ, ∀ l : List T, 0 < discrete_gaussian (↑↑Δ * ↑↑ε₂ / ↑↑ε₁) 0 (↑x - ↑(query l)) := by
    intro x l
    have A' := @discrete_gaussian_pos _ P 0 (x - query l)
    simp at A'
    trivial
  have B : ∀ x : ℤ, 0 ≤ discrete_gaussian (↑↑Δ * ↑↑ε₂ / ↑↑ε₁) 0 (↑x - ↑(query l₁)) ^ α := by
    intro x
    have A' := @discrete_gaussian_nonneg _ P 0 (x - query l₁)
    simp at A'
    apply rpow_nonneg A'
  conv =>
    right
    left
    right
    intro x
    rw [ENNReal.ofReal_rpow_of_pos (A x l₁)]
    rw [ENNReal.ofReal_rpow_of_pos (A x l₂)]
    rw [← ENNReal.ofReal_mul (B x)]
  rw [← ENNReal.ofReal_tsum_of_nonneg]
  . simp
  . intro n
    have X := @RenyiSumSG_nonneg _ α P (query l₁) (query l₂) n
    rw [discrete_gaussian_shift P]
    rw [discrete_gaussian_shift P]
    simp [X]
  . have X := @SummableRenyiGauss _ P (query l₁) (query l₂)
    conv =>
      right
      intro x
      rw [discrete_gaussian_shift P]
      rw [discrete_gaussian_shift P]
    simp [X]

def Compose (nq1 nq2 : List T → SLang ℤ) (l : List T) : SLang (ℤ × ℤ) := do
  let A ← nq1 l
  let B ← nq2 l
  return (A,B)

theorem ENNReal_toTeal_NZ (x : ENNReal) (h1 : x ≠ 0) (h2 : x ≠ ⊤) :
  x.toReal ≠ 0 := by
  unfold ENNReal.toReal
  unfold ENNReal.toNNReal
  simp
  intro H
  cases H
  . contradiction
  . contradiction

theorem simp_α_1 {α : ℝ} (h : 1 < α) : 0 < α := by
  apply @lt_trans _ _ _ 1 _ _ h
  simp only [zero_lt_one]

theorem RenyiNoisedQueryNonZero {nq : List T → SLang ℤ} {α ε : ℝ} (h1 : 1 < α) {l₁ l₂ : List T} (h2 : Neighbour l₁ l₂) (h3 : DP nq ε) (h4 : NonZeroNQ nq) (h5 : NonTopRDNQ nq) (nts : NonTopNQ nq) :
  (∑' (i : ℤ), nq l₁ i ^ α * nq l₂ i ^ (1 - α)).toReal ≠ 0 := by
  simp [DP] at h3
  replace h3 := h3 α h1 l₁ l₂ h2
  simp [RenyiDivergence] at h3
  simp [NonZeroNQ] at h4
  simp [NonTopRDNQ] at h5
  replace h5 := h5 α h1 l₁ l₂ h2
  have h6 := h4 l₁
  have h7 := h4 l₂
  apply ENNReal_toTeal_NZ
  . by_contra CONTRA
    rw [ENNReal.tsum_eq_zero] at CONTRA
    replace CONTRA := CONTRA 42
    replace h6 := h6 42
    replace h7 := h7 42
    rw [_root_.mul_eq_zero] at CONTRA
    cases CONTRA
    . rename_i h8
      rw [rpow_eq_zero_iff_of_pos] at h8
      contradiction
      apply simp_α_1 h1
    . rename_i h8
      rw [ENNReal.rpow_eq_zero_iff] at h8
      cases h8
      . rename_i h8
        cases h8
        contradiction
      . rename_i h8
        cases h8
        rename_i h8 h9
        replace nts := nts l₂ 42
        contradiction
  . exact h5

theorem compose_sum_rw (nq1 nq2 : List T → SLang ℤ) (b c : ℤ) (l : List T) :
  (∑' (a : ℤ), nq1 l a * ∑' (a_1 : ℤ), if b = a ∧ c = a_1 then nq2 l a_1 else 0) = nq1 l b * nq2 l c := by
  have A : ∀ a b : ℤ, (∑' (a_1 : ℤ), if b = a ∧ c = a_1 then nq2 l a_1 else 0) = if b = a then (∑' (a_1 : ℤ), if c = a_1 then nq2 l a_1 else 0) else 0 := by
    intro x  y
    split
    . rename_i h
      subst h
      simp
    . rename_i h
      simp
      intro h
      contradiction
  conv =>
    left
    right
    intro a
    right
    rw [A]
  rw [ENNReal.tsum_eq_add_tsum_ite b]
  simp
  have B : ∀ x : ℤ, (@ite ℝ≥0∞ (x = b) (instDecidableEqInt x b) 0
    (@ite ℝ≥0∞ (b = x) (instDecidableEqInt b x) (nq1 l x * ∑' (a_1 : ℤ), @ite ℝ≥0∞ (c = a_1) (instDecidableEqInt c a_1) (nq2 l a_1) 0) 0)) = 0 := by
    intro x
    split
    . simp
    . split
      . rename_i h1 h2
        subst h2
        contradiction
      . simp
  conv =>
    left
    right
    right
    intro x
    rw [B]
  simp
  congr 1
  rw [ENNReal.tsum_eq_add_tsum_ite c]
  simp
  have C :∀ x : ℤ,  (@ite ℝ≥0∞ (x = c) (propDecidable (x = c)) 0 (@ite ℝ≥0∞ (c = x) (instDecidableEqInt c x) (nq2 l x) 0)) = 0 := by
    intro x
    split
    . simp
    . split
      . rename_i h1 h2
        subst h2
        contradiction
      . simp
  conv =>
    left
    right
    right
    intro X
    rw [C]
  simp

theorem DPCompose {nq1 nq2 : List T → SLang ℤ} {ε₁ ε₂ ε₃ ε₄ : ℕ+} (h1 : DP nq1 ((ε₁ : ℝ) / ε₂))  (h2 : DP nq2 ((ε₃ : ℝ) / ε₄)) (nn1 : NonZeroNQ nq1) (nn2 : NonZeroNQ nq2) (nt1 : NonTopRDNQ nq1) (nt2 : NonTopRDNQ nq2) (nts1 : NonTopNQ nq1) (nts2 : NonTopNQ nq2) :
  DP (Compose nq1 nq2) (((ε₁ : ℝ) / ε₂) + ((ε₃ : ℝ) / ε₄)) := by
  simp [Compose, RenyiDivergence, DP]
  intro α h3 l₁ l₂ h4
  have X := h1
  have Y := h2
  simp [DP] at h1 h2
  replace h1 := h1 α h3 l₁ l₂ h4
  replace h2 := h2 α h3 l₁ l₂ h4
  simp [RenyiDivergence] at h1 h2
  rw [tsum_prod' ENNReal.summable (fun b : ℤ => ENNReal.summable)]
  . simp
    conv =>
      left
      right
      right
      right
      right
      intro b
      right
      intro c
      rw [compose_sum_rw]
      rw [compose_sum_rw]
      rw [ENNReal.mul_rpow_of_ne_zero (nn1 l₁ b) (nn2 l₁ c)]
      rw [ENNReal.mul_rpow_of_ne_zero (nn1 l₂ b) (nn2 l₂ c)]
      rw [mul_assoc]
      right
      rw [mul_comm]
      rw [mul_assoc]
      right
      rw [mul_comm]
    conv =>
      left
      right
      right
      right
      right
      intro b
      right
      intro c
      rw [← mul_assoc]
    conv =>
      left
      right
      right
      right
      right
      intro b
      rw [ENNReal.tsum_mul_left]
    rw [ENNReal.tsum_mul_right]
    rw [ENNReal.toReal_mul]
    rw [Real.log_mul]
    . rw [mul_add]
      have D := _root_.add_le_add h1 h2
      apply le_trans D
      rw [← add_mul]
      rw [mul_le_mul_iff_of_pos_right]
      . rw [← mul_add]
        rw [mul_le_mul_iff_of_pos_left]
        . ring_nf
          simp
        . simp
      . apply lt_trans zero_lt_one h3
    . apply RenyiNoisedQueryNonZero h3 h4 X nn1 nt1 nts1
    . apply RenyiNoisedQueryNonZero h3 h4 Y nn2 nt2 nts2

theorem DPCompose_NonZeroNQ {nq1 nq2 : List T → SLang ℤ} (nn1 : NonZeroNQ nq1) (nn2 : NonZeroNQ nq2) :
  NonZeroNQ (Compose nq1 nq2) := by
  simp [NonZeroNQ] at *
  intro l a b
  replace nn1 := nn1 l a
  replace nn2 := nn2 l b
  simp [Compose]
  exists a
  simp
  intro H
  cases H
  . rename_i H
    contradiction
  . rename_i H
    contradiction

theorem DPCompose_NonTopNQ {nq1 nq2 : List T → SLang ℤ} (nt1 : NonTopNQ nq1) (nt2 : NonTopNQ nq2) :
  NonTopNQ (Compose nq1 nq2) := by
  simp [NonTopNQ] at *
  intro l a b
  replace nt1 := nt1 l a
  replace nt2 := nt2 l b
  simp [Compose]
  rw [compose_sum_rw]
  rw [mul_eq_top]
  intro H
  cases H
  . rename_i H
    cases H
    contradiction
  . rename_i H
    cases H
    contradiction

theorem DPCompose_NonTopSum {nq1 nq2 : List T → SLang ℤ} (nt1 : NonTopSum nq1) (nt2 : NonTopSum nq2) :
  NonTopSum (Compose nq1 nq2) := by
  simp [NonTopSum] at *
  intro l
  replace nt1 := nt1 l
  replace nt2 := nt2 l
  simp [Compose]
  rw [ENNReal.tsum_prod']
  conv =>
    right
    left
    right
    intro a
    right
    intro b
    simp
    rw [compose_sum_rw]
  conv =>
    right
    left
    right
    intro a
    rw [ENNReal.tsum_mul_left]
  rw [ENNReal.tsum_mul_right]
  rw [mul_eq_top]
  intro H
  cases H
  . rename_i H
    cases H
    contradiction
  . rename_i H
    cases H
    contradiction

theorem DPCompose_NonTopRDNQ {nq1 nq2 : List T → SLang ℤ} (nt1 : NonTopRDNQ nq1) (nt2 : NonTopRDNQ nq2) (nn1 : NonZeroNQ nq1) (nn2 : NonZeroNQ nq2) :
  NonTopRDNQ (Compose nq1 nq2) := by
  simp [NonTopRDNQ] at *
  intro α h1 l₁ l₂ h2
  replace nt1 := nt1 α h1 l₁ l₂ h2
  replace nt2 := nt2 α h1 l₁ l₂ h2
  simp [Compose]
  rw [ENNReal.tsum_prod']
  simp
  conv =>
    right
    left
    right
    intro x
    right
    intro y
    congr
    . left
      rw [compose_sum_rw]
    . left
      rw [compose_sum_rw]
  conv =>
    right
    left
    right
    intro x
    right
    intro y
    rw [ENNReal.mul_rpow_of_ne_zero (nn1 l₁ x) (nn2 l₁ y)]
    rw [ENNReal.mul_rpow_of_ne_zero (nn1 l₂ x) (nn2 l₂ y)]
    rw [mul_assoc]
    right
    rw [mul_comm]
    rw [mul_assoc]
    right
    rw [mul_comm]
  conv =>
    right
    left
    right
    intro x
    right
    intro y
    rw [← mul_assoc]
  conv =>
    right
    left
    right
    intro x
    rw [ENNReal.tsum_mul_left]
  rw [ENNReal.tsum_mul_right]
  intro H
  rw [mul_eq_top] at H
  cases H
  . rename_i h3
    cases h3
    rename_i h4 h5
    contradiction
  . rename_i h3
    cases h3
    rename_i h4 h5
    contradiction

def PostProcess (nq : List T → SLang U) (pp : U → ℤ) (l : List T) : SLang ℤ := do
  let A ← nq l
  return pp A

theorem foo (f : U → ℤ) (g : U → ENNReal) (x : ℤ) :
  (∑' a : U, if x = f a then g a else 0) = ∑' a : { a | x = f a }, g a := by
  have A := @tsum_split_ite U (fun a : U => x = f a) g (fun _ => 0)
  simp only [decide_eq_true_eq, tsum_zero, add_zero] at A
  rw [A]
  have B : ↑{i | decide (x = f i) = true} = ↑{a | x = f a} := by
    simp
  rw [B]

variable {T : Type}
variable [m1 : MeasurableSpace T]
variable [m2 : MeasurableSingletonClass T]
variable [m3: MeasureSpace T]

theorem Integrable_rpow (f : T → ℝ) (nn : ∀ x : T, 0 ≤ f x) (μ : Measure T) (α : ENNReal) (mem : Memℒp f α μ) (h1 : α ≠ 0) (h2 : α ≠ ⊤)  :
  MeasureTheory.Integrable (fun x : T => (f x) ^ α.toReal) μ := by
  have X := @MeasureTheory.Memℒp.integrable_norm_rpow T ℝ m1 μ _ f α mem h1 h2
  revert X
  conv =>
    left
    left
    intro x
    rw [← norm_rpow_of_nonneg (nn x)]
  intro X
  simp [Integrable] at *
  constructor
  . cases X
    rename_i left right
    rw [@aestronglyMeasurable_iff_aemeasurable]
    apply AEMeasurable.pow_const
    simp [Memℒp] at mem
    cases mem
    rename_i left' right'
    rw [aestronglyMeasurable_iff_aemeasurable] at left'
    simp [left']
  . rw [← hasFiniteIntegral_norm_iff]
    simp [X]

theorem bar (f : T → ℝ) (q : PMF T) (α : ℝ) (h : 1 < α) (h2 : ∀ x : T, 0 ≤ f x) (mem : Memℒp f (ENNReal.ofReal α) (PMF.toMeasure q)) :
  ((∑' x : T, (f x) * (q x).toReal)) ^ α ≤ (∑' x : T, (f x) ^ α * (q x).toReal) := by

  conv =>
    left
    left
    right
    intro x
    rw [mul_comm]
    rw [← smul_eq_mul]
  conv =>
    right
    right
    intro x
    rw [mul_comm]
    rw [← smul_eq_mul]
  rw [← PMF.integral_eq_tsum]
  rw [← PMF.integral_eq_tsum]

  have A := @convexOn_rpow α (le_of_lt h)
  have B : ContinuousOn (fun (x : ℝ) => x ^ α) (Set.Ici 0) := by
    apply ContinuousOn.rpow
    . exact continuousOn_id' (Set.Ici 0)
    . exact continuousOn_const
    . intro x h'
      simp at h'
      have OR : x = 0 ∨ 0 < x := by exact LE.le.eq_or_gt h'
      cases OR
      . rename_i h''
        subst h''
        right
        apply lt_trans zero_lt_one h
      . rename_i h''
        left
        by_contra
        rename_i h3
        subst h3
        simp at h''
  have C : @IsClosed ℝ UniformSpace.toTopologicalSpace (Set.Ici 0) := by
    exact isClosed_Ici
  have D := @ConvexOn.map_integral_le T ℝ m1 _ _ _ (PMF.toMeasure q) (Set.Ici 0) f (fun (x : ℝ) => x ^ α) (PMF.toMeasure.isProbabilityMeasure q) A B C
  simp at D
  apply D
  . exact MeasureTheory.ae_of_all (PMF.toMeasure q) h2
  . apply MeasureTheory.Memℒp.integrable _ mem
    rw [one_le_ofReal]
    apply le_of_lt h
  . rw [Function.comp_def]
    have X : ENNReal.ofReal α ≠ 0 := by
      simp
      apply lt_trans zero_lt_one h
    have Y : ENNReal.ofReal α ≠ ⊤ := by
      simp
    have Z := @Integrable_rpow T m1 f h2 (PMF.toMeasure q) (ENNReal.ofReal α) mem X Y
    rw [toReal_ofReal] at Z
    . exact Z
    . apply le_of_lt
      apply lt_trans zero_lt_one h
  . have X : ENNReal.ofReal α ≠ 0 := by
      simp
      apply lt_trans zero_lt_one h
    have Y : ENNReal.ofReal α ≠ ⊤ := by
      simp
    have Z := @Integrable_rpow T m1 f h2 (PMF.toMeasure q) (ENNReal.ofReal α) mem X Y
    rw [toReal_ofReal] at Z
    . exact Z
    . apply le_of_lt
      apply lt_trans zero_lt_one h
  . apply MeasureTheory.Memℒp.integrable _ mem
    rw [one_le_ofReal]
    apply le_of_lt h

variable {U : Type}
variable [m2 : MeasurableSpace U] -- [m2' : MeasurableSingletonClass U]
variable [count : Countable U]
variable [disc : DiscreteMeasurableSpace U]

def δ (nq : SLang U) (f : U → ℤ) (a : ℤ)  : {n : U | a = f n} → ENNReal := fun x : {n : U | a = f n} => nq x * (∑' (x : {n | a = f n}), nq x)⁻¹

theorem δ_normalizes (nq : SLang U) (f : U → ℤ) (a : ℤ) (h1 : ∑' (i : ↑{n | a = f n}), nq ↑i ≠ 0) (h2 : ∑' (i : ↑{n | a = f n}), nq ↑i ≠ ⊤) :
  HasSum (δ nq f a) 1 := by
  rw [Summable.hasSum_iff ENNReal.summable]
  unfold δ
  rw [ENNReal.tsum_mul_right]
  rw [ENNReal.mul_inv_cancel h1 h2]

def δpmf (nq : SLang U) (f : U → ℤ) (a : ℤ) (h1 : ∑' (i : ↑{n | a = f n}), nq ↑i ≠ 0) (h2 : ∑' (i : ↑{n | a = f n}), nq ↑i ≠ ⊤) : PMF {n : U | a = f n} :=
  ⟨ δ nq f a , δ_normalizes nq f a h1 h2 ⟩

theorem δpmf_conv (nq : SLang U) (a : ℤ) (x : {n | a = f n}) (h1 : ∑' (i : ↑{n | a = f n}), nq ↑i ≠ 0) (h2 : ∑' (i : ↑{n | a = f n}), nq ↑i ≠ ⊤) :
  nq x * (∑' (x : {n | a = f n}), nq x)⁻¹ = (δpmf nq f a h1 h2) x := by
  simp [δpmf]
  conv =>
    right
    left
    left

theorem δpmf_conv' (nq : SLang U) (f : U → ℤ) (a : ℤ) (h1 : ∑' (i : ↑{n | a = f n}), nq ↑i ≠ 0) (h2 : ∑' (i : ↑{n | a = f n}), nq ↑i ≠ ⊤) :
  (fun x : {n | a = f n} => nq x * (∑' (x : {n | a = f n}), nq x)⁻¹) = (δpmf nq f a h1 h2) := by
  ext x
  rw [δpmf_conv]

theorem witness {f : U → ℤ} {i : ℤ} (h : ¬{b | i = f b} = ∅) :
  ∃ x : U, i = f x := by
  rw [← nonempty_subtype]
  exact Set.nonempty_iff_ne_empty'.mpr h

theorem norm_simplify (x : ENNReal) (h : x ≠ ⊤) :
  @nnnorm ℝ SeminormedAddGroup.toNNNorm x.toReal = x := by
  simp [nnnorm]
  cases x
  . contradiction
  . rename_i v
    simp
    rfl

theorem RD1 (p q : T → ENNReal) (α : ℝ) (h : 1 < α) (RD : ∑' (x : T), p x ^ α * q x ^ (1 - α) ≠ ⊤) (nz : ∀ x : T, q x ≠ 0) (nt : ∀ x : T, q x ≠ ⊤) :
  ∑' (x : T), (p x / q x) ^ α * q x ≠ ⊤ := by
  rw [← RenyiDivergenceExpectation p q h nz nt]
  trivial

theorem ENNReal.HasSum_fiberwise {f : T → ENNReal} {a : ENNReal} (hf : HasSum f a) (g : T → ℤ) :
    HasSum (fun c : ℤ ↦ ∑' b : g ⁻¹' {c}, f b) a := by
  let A := (Equiv.sigmaFiberEquiv g)
  have B := @Equiv.hasSum_iff ENNReal T ((y : ℤ) × { x // g x = y }) _ _ f a A
  replace B := B.2 hf
  have C := @HasSum.sigma ENNReal ℤ _ _ _ _ (fun y : ℤ => { x // g x = y }) (f ∘ ⇑(Equiv.sigmaFiberEquiv g)) (fun c => ∑' (b : ↑(g ⁻¹' {c})), f ↑b) a B
  apply C
  intro b
  have F := @Summable.hasSum_iff ENNReal _ _ _ (fun c => (f ∘ ⇑(Equiv.sigmaFiberEquiv g)) { fst := b, snd := c }) ((fun c => ∑' (b : ↑(g ⁻¹' {c})), f ↑b) b) _
  apply (F _).2
  . rfl
  . apply ENNReal.summable

theorem ENNReal.tsum_fiberwise (p : T → ENNReal) (f : T → ℤ) :
  ∑' (x : ℤ), ∑' (b : (f ⁻¹' {x})), p b
    = ∑' i : T, p i := by
  apply HasSum.tsum_eq
  apply ENNReal.HasSum_fiberwise
  apply Summable.hasSum
  exact ENNReal.summable

theorem quux (p : T → ENNReal) (f : T → ℤ) :
 (∑' i : T, p i)
    = ∑' (x : ℤ), if {a : T | x = f a} = {} then 0 else ∑'(i : {a : T | x = f a}), p i := by
  rw [← ENNReal.tsum_fiberwise p f]
  have A : ∀ x, f ⁻¹' {x} = { a | x = f a } := by
    intro x
    simp [Set.preimage]
    rw [Set.ext_iff]
    simp
    intro y
    exact eq_comm
  conv =>
    left
    right
    intro x
    rw [A]
  clear A
  apply tsum_congr
  intro b
  split
  . rename_i h'
    rw [h']
    simp only [tsum_empty]
  . simp

theorem convergent_subset {p : T → ENNReal} (f : T → ℤ) (conv : ∑' (x : T), p x ≠ ⊤) :
  ∑' (x : { y : T| x = f y }), p x ≠ ⊤ := by
  rw [← foo]
  have A : (∑' (y : T), if x = f y  then p y else 0) ≤ ∑' (x : T), p x := by
    apply tsum_le_tsum
    . intro i
      split
      . trivial
      . simp only [_root_.zero_le]
    . exact ENNReal.summable
    . exact ENNReal.summable
  rw [← lt_top_iff_ne_top]
  apply lt_of_le_of_lt A
  rw [lt_top_iff_ne_top]
  trivial

theorem ENNReal.tsum_pos {f : T → ENNReal} (h1 : ∑' x : T, f x ≠ ⊤) (h2 : ∀ x : T, f x ≠ 0) (i : T) :
  0 < ∑' x : T, f x := by
  apply (toNNReal_lt_toNNReal ENNReal.zero_ne_top h1).mp
  simp only [zero_toNNReal]
  rw [ENNReal.tsum_toNNReal_eq (ENNReal.ne_top_of_tsum_ne_top h1)]
  have S : Summable fun a => (f a).toNNReal := by
    rw [← tsum_coe_ne_top_iff_summable]
    conv =>
      left
      right
      intro b
      rw [ENNReal.coe_toNNReal (ENNReal.ne_top_of_tsum_ne_top h1 b)]
    trivial
  have B:= @NNReal.tsum_pos T (fun (a : T) => (f a).toNNReal) S i
  apply B
  apply ENNReal.toNNReal_pos (h2 i) (ENNReal.ne_top_of_tsum_ne_top h1 i)

theorem ENNReal.tsum_pos_int {f : ℤ → ENNReal} (h1 : ∑' x : ℤ, f x ≠ ⊤) (h2 : ∀ x : ℤ, f x ≠ 0) :
  0 < ∑' x : ℤ, f x := by
  apply ENNReal.tsum_pos h1 h2 42

theorem tsum_pos_int {f : ℤ → ENNReal} (h1 : ∑' x : ℤ, f x ≠ ⊤) (h2 : ∀ x : ℤ, f x ≠ 0) :
  0 < (∑' x : ℤ, f x).toReal := by
  have X : 0 = (0 : ENNReal).toReal := rfl
  rw [X]
  clear X
  apply toReal_strict_mono h1
  apply ENNReal.tsum_pos_int h1 h2

theorem DPostPocess_pre {nq : List T → SLang U} {ε₁ ε₂ : ℕ+} (h : DP nq ((ε₁ : ℝ) / ε₂)) (nn : NonZeroNQ nq) (nt : NonTopRDNQ nq) (nts : NonTopNQ nq) (conv : NonTopSum nq) (f : U → ℤ) {α : ℝ} (h1 : 1 < α) {l₁ l₂ : List T} (h2 : Neighbour l₁ l₂) :
  (∑' (x : ℤ),
      (∑' (a : U), if x = f a then nq l₁ a else 0) ^ α *
        (∑' (a : U), if x = f a then nq l₂ a else 0) ^ (1 - α)) ≤
  (∑' (x : U), nq l₁ x ^ α * nq l₂ x ^ (1 - α)) := by

  simp [DP, RenyiDivergence] at h

  -- Rewrite as cascading expectations
  rw [@RenyiDivergenceExpectation _ (nq l₁) (nq l₂) _ h1 (nn l₂) (nts l₂)]

  -- Shuffle the sum
  rw [quux (fun x => (nq l₁ x / nq l₂ x) ^ α * nq l₂ x) f]

  apply ENNReal.tsum_le_tsum

  intro i

  -- Get rid of elements with probability 0 in the pushforward
  split
  . rename_i empty
    rw [foo]
    have ZE : (∑' (x_1 : ↑{n | i = f n}), nq l₁ ↑x_1) = 0 := by
      simp
      intro a H
      have I₁ : a ∈ {b | i = f b} := by
        simp [H]
      have I2 : {b | i = f b} ≠ ∅ := by
        apply ne_of_mem_of_not_mem' I₁
        simp
      contradiction
    rw [ZE]
    simp only [toReal_mul, zero_toReal, ge_iff_le]

    rw [ENNReal.zero_rpow_of_pos]
    . simp
    . apply lt_trans zero_lt_one h1

  -- Part 2: apply Jensen's inequality
  . rename_i NotEmpty

    have MasterRW : ∀ l : List T, ∑' (a : ↑{a | i = f a}), nq l ↑a ≠ ⊤ := by
      intro l
      apply convergent_subset
      simp [NonTopSum] at conv
      have conv := conv l
      apply conv

    have MasterZero : ∀ l : List T, ∑' (a : ↑{a | i = f a}), nq l ↑a ≠ 0 := by
      intro l
      simp
      have T := witness NotEmpty
      cases T
      rename_i z w
      exists z
      constructor
      . trivial
      . apply nn l

    have S2 : (∑' (a : ↑{n | i = f n}), nq l₁ ↑a / nq l₂ ↑a * (δpmf (nq l₂) f i (MasterZero l₂) (MasterRW l₂)) a) ^ α ≠ ⊤ := by
      conv =>
        left
        left
        right
        intro a
        rw [← δpmf_conv]
        rw [division_def]
        rw [mul_assoc]
        right
        rw [← mul_assoc]
        rw [ENNReal.inv_mul_cancel (nn l₂ a) (nts l₂ a)]
      rw [one_mul]
      rw [ENNReal.tsum_mul_right]
      apply ENNReal.rpow_ne_top_of_nonneg (le_of_lt (lt_trans zero_lt_one h1 ))
      apply mul_ne_top
      . apply convergent_subset _ (conv l₁)
      . apply inv_ne_top.mpr (MasterZero l₂)

    have S1 : ∀ (a : ↑{n | i = f n}), nq l₁ ↑a / nq l₂ ↑a * (δpmf (nq l₂) f i (MasterZero l₂) (MasterRW l₂)) a ≠ ⊤ := by
      intro a
      apply mul_ne_top
      . rw [division_def]
        apply mul_ne_top (nts l₁ a)
        apply inv_ne_top.mpr (nn l₂ a)
      . rw [← δpmf_conv]
        apply mul_ne_top (nts l₂ a)
        apply inv_ne_top.mpr (MasterZero l₂)

    have S3 : ∑' (a : ↑{n | i = f n}), (nq l₁ ↑a / nq l₂ ↑a) ^ α * (δpmf (nq l₂) f i (MasterZero l₂) (MasterRW l₂)) a ≠ ⊤ := by
      conv =>
        left
        right
        intro a
        rw [← δpmf_conv]
        rw [← mul_assoc]
      rw [ENNReal.tsum_mul_right]
      apply mul_ne_top
      . rw [← RenyiDivergenceExpectation _ _ h1]
        . replace nt := nt α h1 l₁ l₂ h2
          apply convergent_subset _ nt
        . intro x
          apply nn
        . intro x
          apply nts
      . apply inv_ne_top.mpr (MasterZero l₂)

    have S4 : ∀ (a : ↑{n | i = f n}), (nq l₁ ↑a / nq l₂ ↑a) ^ α * (δpmf (nq l₂) f i (MasterZero l₂) (MasterRW l₂)) a ≠ ⊤ := by
      intro a
      apply ENNReal.ne_top_of_tsum_ne_top S3

    rw [foo]
    rw [foo]

    -- Introduce Q(f⁻¹ i)
    let κ := ∑' x : {n : U | i = f n}, nq l₂ x
    have P4 : κ / κ = 1 := by
      rw [division_def]
      rw [ENNReal.mul_inv_cancel]
      . simp [κ]  -- Use here for δ normalization
        have T := witness NotEmpty
        cases T
        rename_i z w
        exists z
        constructor
        . trivial
        . apply nn l₂
      . simp only [κ]
        apply MasterRW l₂

    conv =>
      right
      right
      intro a
      rw [← mul_one ((nq l₁ ↑a / nq l₂ ↑a) ^ α * nq l₂ ↑a)]
      right
      rw [← P4]
    clear P4
    simp only [κ]

    conv =>
      right
      right
      intro a
      right
      rw [division_def]
      rw [mul_comm]

    conv =>
      right
      right
      intro a
      rw [← mul_assoc]

    rw [ENNReal.tsum_mul_right]

    -- Jensen's inequality

    have P5 : ∀ (x : ↑{n | i = f n}), 0 ≤ (fun a => (nq l₁ ↑a / nq l₂ ↑a).toReal) x := by
      intro x
      simp only [toReal_nonneg]

    have XXX : @Memℒp ℝ Real.normedAddCommGroup (↑{n | i = f n}) Subtype.instMeasurableSpace (fun a => (nq l₁ ↑a / nq l₂ ↑a).toReal)
      (ENNReal.ofReal α) (PMF.toMeasure (δpmf (nq l₂) f i (MasterZero l₂) (MasterRW l₂))) := by
      simp [Memℒp]
      constructor
      . apply MeasureTheory.StronglyMeasurable.aestronglyMeasurable
        apply Measurable.stronglyMeasurable
        apply Measurable.ennreal_toReal
        conv =>
          right
          intro x
          rw [division_def]
        apply Measurable.mul
        . -- MeasurableSingletonClass.toDiscreteMeasurableSpace
          apply measurable_discrete
        . apply Measurable.inv
          apply measurable_discrete
      . simp [snorm]
        split
        . simp
        . simp [snorm']
          rw [MeasureTheory.lintegral_countable'] -- Uses countable
          rw [toReal_ofReal (le_of_lt (lt_trans zero_lt_one h1))]
          have OTHER : ∀ a, nq l₁ a / nq l₂ a ≠ ⊤ := by
            intro a
            rw [division_def]
            rw [ne_iff_lt_or_gt]
            left
            rw [mul_lt_top_iff]
            left
            constructor
            . exact Ne.lt_top' (id (Ne.symm (nts l₁ a)))
            . simp
              exact pos_iff_ne_zero.mpr (nn l₂ a)

          conv =>
            left
            left
            right
            intro a
            rw [norm_simplify _ (OTHER a)]
          have Z : 0 < α⁻¹ := by
            simp
            apply lt_trans zero_lt_one h1
          rw [rpow_lt_top_iff_of_pos Z]
          conv =>
            left
            right
            intro a
            rw [PMF.toMeasure_apply_singleton _ _ (measurableSet_singleton a)]

          apply Ne.lt_top' (id (Ne.symm _))
          apply S3


    have Jensen's := @bar {n : U | i = f n} Subtype.instMeasurableSpace Subtype.instMeasurableSingletonClass (fun a => (nq l₁ a / nq l₂ a).toReal) (δpmf (nq l₂) f i (MasterZero l₂) (MasterRW l₂)) α h1 P5 XXX
    clear P5

    have P6 : 0 ≤ (∑' (x : ↑{n | i = f n}), nq l₂ ↑x).toReal := by
      simp only [toReal_nonneg]
    have A' := mul_le_mul_of_nonneg_left Jensen's P6
    clear Jensen's P6

    conv =>
      right
      rw [mul_comm]
      right
      right
      intro a
      rw [mul_assoc]
      rw [δpmf_conv]

    -- Here

    replace A' := ofReal_le_ofReal A'
    rw [ofReal_mul toReal_nonneg] at A'
    rw [ofReal_mul toReal_nonneg] at A'
    rw [ofReal_toReal_eq_iff.2 (MasterRW l₂)] at A'
    simp only at A'

    revert A'
    conv =>
      left
      right
      right
      right
      right
      intro x
      rw [toReal_rpow]
      rw [← toReal_mul]
    conv =>
      left
      right
      right
      right
      rw [← ENNReal.tsum_toReal_eq S4]
    intro A'
    rw [ofReal_toReal_eq_iff.2 S3] at A'

    apply le_trans _ A'
    clear A'
    apply le_of_eq

    -- Part 3:

    conv =>
      right
      right
      right
      left
      right
      intro x
      rw [← toReal_mul]
    rw [← ENNReal.tsum_toReal_eq S1]
    rw [toReal_rpow]
    rw [ofReal_toReal_eq_iff.2 S2]

    conv =>
      right
      right
      left
      right
      intro x
      rw [division_def]
      rw [← δpmf_conv]
      rw [mul_assoc]
      right
      rw [← mul_assoc]
      left
      rw [ENNReal.inv_mul_cancel (nn l₂ x) (nts l₂ x)]
    simp only [one_mul]

    rw [ENNReal.tsum_mul_right]
    have H1 : 0 ≤ ∑' (x : ↑{n | i = f n}), (nq l₁ ↑x).toReal := by
      apply tsum_nonneg
      simp
    have H2 : 0 ≤ (∑' (a : ↑{a | i = f a}), nq l₂ ↑a)⁻¹.toReal := by
       apply toReal_nonneg
    have H4 : (∑' (a : ↑{a | i = f a}), nq l₂ ↑a)⁻¹ ≠ ⊤ := by
      apply inv_ne_top.mpr
      simp
      have T := witness NotEmpty
      cases T
      rename_i z w
      exists z
      constructor
      . trivial
      . apply nn l₂
    rw [ENNReal.mul_rpow_of_ne_top (MasterRW l₁) H4]

    have H3 : ∑' (a : ↑{a | i = f a}), nq l₂ ↑a ≠ 0 := by
      simp
      have T := witness NotEmpty
      cases T
      rename_i z w
      exists z
      constructor
      . trivial
      . apply nn l₂
    rw [ENNReal.rpow_sub _ _ H3 (MasterRW l₂)]
    rw [ENNReal.rpow_one]
    rw [division_def]
    rw [← mul_assoc]
    rw [← mul_assoc]
    congr 1
    . rw [mul_comm]
    . congr 1
      rw [ENNReal.inv_rpow]

theorem tsum_ne_zero_of_ne_zero {T : Type} [Inhabited T] (f : T → ENNReal) (h : ∀ x : T, f x ≠ 0) :
  ∑' x : T, f x ≠ 0 := by
  by_contra CONTRA
  rw [ENNReal.tsum_eq_zero] at CONTRA
  have A := h default
  have B := CONTRA default
  contradiction

variable [Inhabited U]

theorem DPPostProcess_alt1 {nq : List T → SLang U} {ε₁ ε₂ : ℕ+} (h : DP nq ((ε₁ : ℝ) / ε₂)) (nn : NonZeroNQ nq) (nt : NonTopRDNQ nq) (nts : NonTopNQ nq) (conv : NonTopSum nq) (f : U → ℤ) :
  DP (PostProcess nq f) ((ε₁ : ℝ) / ε₂) := by
  simp [PostProcess, DP, RenyiDivergence]
  intro α h1 l₁ l₂ h2
  have h' := h
  simp [DP, RenyiDivergence] at h'
  replace h' := h' α h1 l₁ l₂ h2

  -- Part 1, removing fluff

  apply le_trans _ h'
  clear h'

  -- remove the α scaling
  have A : 0 ≤ (α - 1)⁻¹ := by
    simp
    apply le_of_lt h1
  apply mul_le_mul_of_nonneg_left _ A
  clear A

  have RDConvegence : ∑' (x : U), nq l₁ x ^ α * nq l₂ x ^ (1 - α) ≠ ⊤ := by
    simp [NonTopRDNQ] at nt
    have nt := nt α h1 l₁ l₂ h2
    trivial

  have B := DPostPocess_pre h nn nt nts conv f h1 h2
  have B' : ∑' (x : ℤ), (∑' (a : U), if x = f a then nq l₁ a else 0) ^ α * (∑' (a : U), if x = f a then nq l₂ a else 0) ^ (1 - α) ≠ ⊤ := by
    by_contra CONTRA
    rw [CONTRA] at B
    simp at B
    contradiction

  -- remove the log
  apply log_le_log _ (toReal_mono RDConvegence B)
  apply toReal_pos _ B'
  apply (tsum_ne_zero_iff ENNReal.summable).mpr
  exists (f default)

  rw [ENNReal.tsum_eq_add_tsum_ite default]
  conv =>
    left
    right
    rw [ENNReal.tsum_eq_add_tsum_ite default]
  simp only [reduceIte]
  apply mul_ne_zero
  . by_contra CONTRA
    rw [ENNReal.rpow_eq_zero_iff_of_pos (lt_trans zero_lt_one h1)] at CONTRA
    simp at CONTRA
    cases CONTRA
    rename_i left right
    have Y := nn l₁ default
    contradiction
  . by_contra CONTRA
    rw [ENNReal.rpow_eq_zero_iff] at CONTRA
    cases CONTRA
    . rename_i CONTRA
      cases CONTRA
      rename_i left right
      simp at left
      cases left
      rename_i le1 le2
      have Y := nn l₂ default
      contradiction
    . rename_i CONTRA
      cases CONTRA
      rename_i left right
      simp at left
      cases left
      . rename_i left
        have Y := nts l₂ default
        contradiction
      . rename_i left
        have Rem := conv l₂
        have X : (∑' (x : U), if x = default then 0 else if f default = f x then nq l₂ x else 0) ≤ ∑' (n : U), nq l₂ n := by
          apply ENNReal.tsum_le_tsum
          intro a
          split
          . simp
          . split
            . simp
            . simp
        replace Rem := Ne.symm Rem
        have Y := Ne.lt_top' Rem
        have Z : (∑' (x : U), if x = default then 0 else if f default = f x then nq l₂ x else 0) < ⊤ := by
          apply lt_of_le_of_lt X Y
        rw [lt_top_iff_ne_top] at Z
        contradiction


end SLang
