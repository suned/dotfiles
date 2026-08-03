---
name: review-type-design
description: Review Python type designs for domain modeling quality. Applies "Designing with Types" principles (make illegal states unrepresentable, NewType wrappers, explicit state machines, constrained constructors). Use when reviewing dataclasses, Pydantic models, type aliases, or domain model code. Also use when user asks to "review types", "check my models", or "improve type safety".
---

# Review Type Design

Evaluate Python type designs against domain modeling principles translated from Scott Wlaschin's "Designing with Types" series.

## Workflow

1. Read the file(s) containing the types under review
2. Run through the [CHECKLIST.md](CHECKLIST.md) systematically
3. For each violation found, report:
   - Which principle is violated
   - The specific code location
   - A concrete fix using Python idioms (see [EXAMPLES.md](EXAMPLES.md))
4. Summarize: list what's good, what to fix, and any domain concepts that may be hiding

## Key Principles (quick reference)

| # | Principle | Python Smell |
|---|-----------|-------------|
| 1 | Wrap primitives in NewTypes | Bare `str`, `int`, `float` for domain concepts |
| 2 | Make illegal states unrepresentable | Multiple `Optional` fields that are mutually dependent |
| 3 | Group atomic data | Related fields scattered across classes |
| 4 | Discover domain concepts | Long union types or repeated field groups |
| 5 | Make state explicit | Boolean flags like `is_verified`, `is_active` |
| 6 | Constrain at construction | Validation in business logic instead of `__post_init__`/validators |
| 7 | Use semantic non-string types | Bare `int` for IDs, bare `datetime` without timezone clarity |

## Output Format

```
## Type Design Review: <file>

### Findings

1. **[Principle Name]** — `ClassName.field_name` (line X)
   Problem: ...
   Fix: ...

### Summary
- Strengths: ...
- Issues: N findings across M principles
- Hidden concepts: ... (domain ideas surfaced by the review)
```
