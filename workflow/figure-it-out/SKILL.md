---
name: figure-it-out
description: Design and execute an auditable playbook for a large migration, cross-cutting change, or open-ended task when no narrower workflow fits.
---

# Figure it out

Create the workflow before starting a long run. Scale rigor to the cost of a
wrong result, not to the amount of ceremony available.

## Frame the outcome

State a falsifiable definition of done. Quantify the scope, identify authority
boundaries, and name the highest-risk unknown. Separate reversible work from
actions that need approval. Reversible repository work proceeds unless the
user set a checkpoint.

Use an architecture sketch before a one-way-door design. Skip that step for a
mechanical change whose shape is already owned by the repository.

## Build the playbook

Split the task into independently verifiable units. Put the riskiest unknown
first. Build or identify the verification method before the feature so each
unit has a real before-and-after comparison.

Parallelize only independent units, and only when delegation is authorized.
Give each writer a separate branch or worktree and a disjoint file boundary.
Sequential work is valid when shared state or user policy rules out delegation.

Record the phase list in the active plan. For each unit, keep a compact decision
trail with:

- the hypothesis;
- the artifact changed;
- the observation method;
- the result: verified, not verified, or inconclusive;
- the next decision.

Use repository-native planning or task files when they exist. Do not add a log
only to prove that a process happened.

## Run the loop

Make the smallest change that tests the current hypothesis. Inspect the real
artifact. Keep the change only when the observation advances the definition of
done. An inconclusive result is not a pass.

Verify each unit before starting its dependent unit. When a check passes too
easily, test the observation method. When the same correction recurs, encode it
in a type, boundary, generator, lint rule, or deterministic check.

## Finish

Exercise the complete user or operator path against the real system. Report the
playbook, what is proven, what remains open, the authority boundary for each
blocker, and the first unfinished unit. Do not substitute a build, self-report,
or planning artifact for product proof.
