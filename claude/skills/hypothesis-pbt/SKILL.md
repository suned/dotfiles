---
name: hypothesis-pbt
description: Write property-based tests using Python's Hypothesis library. Use when writing Python tests, doing TDD driven by properties, modeling input spaces, or when asked to find edge cases with Hypothesis.
---

# Hypothesis Property-Based Testing

The goal with property based testing is not to construct a single test, but rather a _set_ of properties
that together strongly imply that the system under test is correct.

## TDD Workflow

1. **Understand the contract** — what must always be true regardless of input?
2. **Pick properties** — use the 7 patterns to find meaningful assertions
3. **Build strategies** — model the valid input space with `st.*`
4. **Write the test** — `@given(strategy)` → assert property
5. **Run and shrink** — Hypothesis finds and minimizes the counterexample
6. **Fix or refine** — update implementation or tighten the strategy

## The 7 Property Patterns

This is NOT an exhaustive list, but meant for inspiration.

| Pattern | Trigger question | Hypothesis hint |
|---------|-----------------|-----------------|
| **Inverse** | Is there an undo operation? | `f_inv(f(x)) == x` |
| **Invariant** | What must never change? | Assert structural fact after transformation |
| **Idempotence** | Is it safe to repeat? | `f(f(x)) == f(x)` |
| **Commutative diagram** | Two paths, same result? | `f(g(x)) == g(f(x))` |
| **Structural induction** | Holds for parts → holds for whole? | Split input, verify property on each part |
| **Easy to verify** | Hard to compute, trivial to check? | Verify the answer satisfies constraints |
| **Oracle** | Can a simpler version cross-check? | `optimized(x) == brute_force(x)` |

See [REFERENCE.md](REFERENCE.md) for deep dives on each pattern and strategy recipes.
See [EXAMPLES.md](EXAMPLES.md) for worked end-to-end examples.

## Strategy Quick Reference

```python
from hypothesis import given, settings, assume, note, example, target
from hypothesis import strategies as st

# Primitives
st.integers(min_value=0, max_value=100)
st.floats(allow_nan=False, allow_infinity=False)
st.text(min_size=1)
st.booleans()

# Collections
st.lists(st.integers(), min_size=1, max_size=50)
st.dictionaries(st.text(), st.integers())
st.tuples(st.integers(), st.text())

# Custom types
st.builds(MyClass, field=st.integers())       # construct from args
st.from_type(MyType)                          # infer from type hints

# Combinators
st.one_of(st.integers(), st.none())           # union / Optional
st.lists(st.integers()).flatmap(              # dependent strategies
    lambda xs: st.tuples(st.just(xs), st.sampled_from(xs))
)

# Composite (full control)
@st.composite
def my_strategy(draw):
    n = draw(st.integers(min_value=1, max_value=10))
    xs = draw(st.lists(st.integers(), min_size=n, max_size=n))
    return xs
```

## Debugging

```python
@settings(max_examples=500)          # more thorough search
@example(x=0)                        # always run this case
def test_foo(x):
    assume(x != 0)                   # filter (prefer strategy constraints)
    note(f"intermediate={x * 2}")    # shown on failure
    target(len(result))              # guide search toward larger values
```
