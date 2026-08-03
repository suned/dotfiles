---
name: design-an-interface
description: Generate multiple radically different interface designs for a module using parallel sub-agents. Use when user wants to design an API, explore interface options, compare module shapes, or mentions "design it twice".
---

# Design an Interface

Based on "Design It Twice" from "A Philosophy of Software Design": your first idea is unlikely to be the best. Generate multiple radically different designs, then compare.

## Workflow

### 1. Gather Requirements

Before designing, understand:

- [ ] What problem does this module solve?
- [ ] Who are the callers? (other modules, external users, tests)
- [ ] What are the key operations?
- [ ] Any constraints? (performance, compatibility, existing patterns)
- [ ] What should be hidden inside vs exposed?

Ask: "What does this module need to do? Who will use it?"

### 2. Generate Designs (Parallel Sub-Agents)

Spawn 3+ sub-agents simultaneously using Task tool. Each must produce a **radically different** approach.

```
Prompt template for each sub-agent:

Design an interface for: [module description]

Requirements: [gathered requirements]

Constraints for this design: [assign a different constraint to each agent]
- Agent 1: "Minimize method count - aim for 1-3 methods max"
- Agent 2: "Maximize flexibility - support many use cases"
- Agent 3: "Optimize for the most common case"
- Agent 4: "Take inspiration from [specific paradigm/library]"

Output format:
1. Interface signature (types/methods)
2. Usage example (how caller uses it)
3. What this design hides internally
4. Trade-offs of this approach
```

### 3. Present Designs

Show each design with:

1. **Interface signature** - types, methods, params
2. **Usage examples** - how callers actually use it in practice
3. **What it hides** - complexity kept internal

Present designs sequentially so user can absorb each approach before comparison.

### 4. Compare Designs

After showing all designs, compare them on:

- **Interface simplicity**: fewer methods, simpler params
- **General-purpose vs specialized**: flexibility vs focus
- **Implementation efficiency**: does shape allow efficient internals?
- **Depth**: small interface hiding significant complexity (good) vs large interface with thin implementation (bad)
- **Ease of correct use** vs **ease of misuse**

Discuss trade-offs in prose, not tables. Highlight where designs diverge most.

### 5. Synthesize

Often the best design combines insights from multiple options. Ask:

- "Which design best fits your primary use case?"
- "Any elements from other designs worth incorporating?"

## Evaluation Criteria

From "A Philosophy of Software Design":

**Interface simplicity**: Fewer methods, simpler params = easier to learn and use correctly.

**General-purpose**: Can handle future use cases without changes. But beware over-generalization.

**Implementation efficiency**: Does interface shape allow efficient implementation? Or force awkward internals?

**Depth**: Small interface hiding significant complexity = deep module (good). Large interface with thin implementation = shallow module (avoid).

**Illegal states**: To what extent does the proposed interface and its types make illegal states unrepresentable?

### Making Illegal States Unrepresentable

A good interface uses the type system to make invalid usage impossible to express, not just documented or runtime-checked. Evaluate each design on this axis.

**Core patterns:**

- **Discriminated unions over stringly-typed state** — instead of a `Contact` with both `email` and `phone` fields where one might be null, use a union: `EmailContact of string | PhoneContact of string | BothContact of string * string`. The type itself encodes which combinations are valid.

- **Single-case wrapper types** — wrap primitives to prevent mixups. `CustomerId` and `OrderId` are both ints, but a type system that distinguishes them prevents passing one where the other is expected. Raw `string` for an email address allows any string; a `EmailAddress` type (only constructable via validation) does not.

- **State machines via types** — if an entity transitions through states, model each state as its own type carrying only the fields relevant to that state. An `UnverifiedContact` and `VerifiedContact` are different types; you can't call `sendEmail` on an unverified one because it doesn't have an email field yet.

- **Non-empty collections** — if a function requires at least one element, `NonEmptyList` is better than `List` + a runtime check.

- **Replace booleans with unions** — `type ContactMethod = Email | Phone` is clearer and more extensible than a boolean `preferEmail: bool`.

**Questions to ask when evaluating a design:**

- Can a caller construct an invalid object without going out of their way?
- Are there combinations of fields that are mutually exclusive but both present in the type?
- Does the type distinguish between "not yet set" and "intentionally absent"?
- Can you pass the wrong kind of ID, string, or number without a compile error?
- Does state-dependent behavior live on a single God type, or on separate types per state?

## Anti-Patterns

- Don't let sub-agents produce similar designs - enforce radical difference
- Don't skip comparison - the value is in contrast
- Don't implement - this is purely about interface shape
- Don't evaluate based on implementation effort
