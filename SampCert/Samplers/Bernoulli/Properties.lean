/-
Copyright (c) 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jean-Baptiste Tristan
-/
import SampCert.Foundations.Basic
import SampCert.Samplers.Uniform.Basic
import Mathlib.Probability.Distributions.Uniform
import SampCert.Samplers.Bernoulli.Code

/-!
# Bernoulli Sampler Properties

This file describes properties about the ``SLang`` Bernoulli sampler.

MARKUSDE: which ones?
-/

noncomputable section

open PMF Finset BigOperators Nat

namespace SLang

-- MARKUSDE: unused?
-- theorem ite_total_same (a b : ℕ) (x : ENNReal) :
--   (if a ≤ b then x else 0) + (if b < a then x else 0) = x := by
--   split
--   . rename_i h
--     have A : ¬ (b < a) := by exact Nat.not_lt.mpr h
--     simp [A]
--   . rename_i h
--     have A : ¬ (a ≤ b) := by exact h
--     simp [A]

/--
Total mass of the Bernoulli sampler is 1
-/
@[simp]
theorem BernoulliSample_normalizes (num : Nat) (den : PNat) (wf : num ≤ den) :
  ∑' b : Bool, BernoulliSample num den wf b = 1 := by
  simp [BernoulliSample]
  rw [ENNReal.tsum_comm]
  rw [← @sum_add_tsum_nat_add' _ _ _ _ _ _ den]
  simp [tsum_bool]
  simp [UniformSample_support_Sum']
  exact ENNReal.summable

-- MARKUSDE: What is the difference between ∑ and ∑'? Interrogating types is getting me nowhere.
/--
Total mass of the Bernoulli sampler is 1
-/
theorem BernoulliSample_normalizes' (num : Nat) (den : PNat) (wf : num ≤ den) :
  ∑ b : Bool, BernoulliSample num den wf b = 1 := by
  rw [← @tsum_fintype]
  apply BernoulliSample_normalizes num den wf

/--
Bernoulli sampler evaluates to ``true`` with probability ``num/den``
-/
@[simp]
theorem BernoulliSample_apply_true (num : Nat) (den : PNat) (wf : num ≤ den) :
  BernoulliSample num den wf true = num / den := by
  unfold BernoulliSample
  simp
  conv =>
    left
    right
    intro a
    rw [UniformSample_apply_ite _ _ _ wf]
  simp
  rw [ENNReal.div_eq_inv_mul]

/--
Bernoulli sampler evaluates to ``false`` with probability ``num/den``
-/
@[simp]
theorem BernoulliSample_apply_false (num : Nat) (den : PNat) (wf : num ≤ den) :
  BernoulliSample num den wf false = 1 - (num / den) := by
  have A := BernoulliSample_normalizes num den wf
  rw [tsum_bool, BernoulliSample_apply_true] at A
  apply ENNReal.eq_sub_of_add_eq
  . have B : ↑num / ↑↑den < (⊤ : ENNReal) := by
      apply ENNReal.div_lt_top
      . simp
      . simp
    exact lt_top_iff_ne_top.mp B
  . trivial

/--
Closed form for evaulation of Bernoulli distribution in terms of its paramater ``num/den``
-/
@[simp]
theorem BernoulliSample_apply (num : Nat) (den : PNat) (wf : num ≤ den) (b : Bool) :
  BernoulliSample num den wf b = if b then ((num : ENNReal) / (den : ENNReal)) else ((1 : ENNReal) - ((num : ENNReal) / (den : ENNReal))) := by
  cases b
  . simp
  . simp

/--
``SLang`` Bernoulli program is a proper distribution.
-/
def BernoulliSamplePMF (num : Nat) (den : PNat) (wf : num ≤ den) : PMF Bool := PMF.ofFintype (BernoulliSample num den wf) (BernoulliSample_normalizes' num den wf)

namespace SLang
