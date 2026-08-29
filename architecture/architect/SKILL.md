---
name: architect
description: Sketch caller usage, domain types, interfaces, and module ownership before implementing a non-trivial design or changing an established system boundary.
---

# Architect

Design the public shape before filling in implementation details. Use the
smallest sketch that can disprove a bad boundary early.

## Ground the design

Trace the current path from caller to side effect. Read the repository's
documents of record, types, configuration, tests, and history. Write down:

- the user or caller outcome;
- the existing owner of each capability;
- the invariants and failure modes;
- the data that crosses a system boundary;
- the parts the change makes obsolete.

Do not treat a filename or a diagram as a traced model. Follow real calls and
state transitions.

## Sketch alternatives

Write caller usage first. Derive the types, function signatures, and module map
from that usage. Leave implementation bodies empty or as short pseudocode.

Compare at least two structurally different designs for a one-way-door or
high-blast-radius choice. You may produce both yourself. Use independent
reviewers only when delegation is available and authorized. Compare the whole
shape, not small variations of one design.

Reject a candidate when it:

- leaks storage, transport, or framework details into domain callers;
- splits one policy across shallow pass-through modules;
- models a process timeline instead of stable domain ownership;
- requires callers to know hidden ordering or lifecycle rules;
- adds a second owner for a capability the platform or repository already has.

Choose the design that makes caller code direct, gives every invariant one
owner, keeps boundary parsing at the edge, and removes more concepts than it
adds. Record why the rejected design lost.

## Implement against the sketch

Implement the chosen shape in verifiable units. A new parameter, optional field,
cast, sentinel, lock, or repeated special case is evidence that the sketch may
be wrong. Do not absorb repeated friction with workarounds.

If two independent implementation points need the same escape hatch, stop.
Re-ground the new constraint and redesign as if it had been known on day one.

## Output

Leave a reviewable artifact with caller usage, types and signatures, the module
map, capability ownership, rejected alternative, and verification boundary.
For a small change, one source file can be that artifact. For a larger change,
keep the rationale beside the repository's other architecture records.
