/-
Copyright (c) 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jean-Baptiste Tristan
-/

variable {T : Type}

inductive Neighbour (l₁ l₂ : List T) : Prop where
  | Addition : l₁ = a ++ b → l₂ = a ++ [n] ++ b → Neighbour l₁ l₂
  | Deletion : l₁ = a ++ [n] ++ b → l₂ = a ++ b → Neighbour l₁ l₂
  | Update : l₁ = a ++ [n] ++ b → l₂ = a ++ [m] ++ b -> Neighbour l₁ l₂
