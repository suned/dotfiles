# Hypothesis PBT — Reference

## The 7 Property Patterns in Depth

### 1. Inverse ("There and Back Again")
Applying an operation then its inverse returns the original value.

**When to use:** serialization, encoding, compression, encryption, parsing.

```python
@given(st.text())
def test_serialize_roundtrip(s):
    assert deserialize(serialize(s)) == s

@given(st.lists(st.integers()))
def test_encode_decode(xs):
    assert decode(encode(xs)) == xs
```

**Variants:**
- One-sided inverse: `parse(format(x)) == x` (format may not be unique)
- Partial inverse: only valid for a subset — constrain the strategy


### 2. Invariant ("Some Things Never Change")
A structural fact that holds before and after any transformation.

**When to use:** sorting, filtering, mapping, any transformation that preserves structure.

```python
@given(st.lists(st.integers()))
def test_sort_preserves_length(xs):
    assert len(sorted(xs)) == len(xs)

@given(st.lists(st.integers()))
def test_sort_preserves_elements(xs):
    assert sorted(xs) == sorted(sorted(xs))  # same content, sorted
    assert set(sorted(xs)) == set(xs)

@given(st.lists(st.integers(), min_size=1))
def test_max_is_in_list(xs):
    assert max(xs) in xs
```

**Checklist for finding invariants:**
- Size / length preserved?
- Set of elements preserved (just reordered)?
- Sum / total preserved?
- Ordering relationships preserved?
- Type constraints preserved (all positive, all unique)?


### 3. Idempotence ("The More Things Change, The More They Stay the Same")
Applying an operation twice yields the same result as once.

**When to use:** normalization, deduplication, sorting, clamping, formatting.

```python
@given(st.lists(st.integers()))
def test_sort_idempotent(xs):
    assert sorted(sorted(xs)) == sorted(xs)

@given(st.text())
def test_strip_idempotent(s):
    assert s.strip().strip() == s.strip()

@given(st.lists(st.integers()))
def test_deduplicate_idempotent(xs):
    assert deduplicate(deduplicate(xs)) == deduplicate(xs)
```


### 4. Commutative Diagram ("Different Paths, Same Destination")
Two sequences of operations that should produce the same result.

**When to use:** operations that should compose in any order, map/filter independence, batching vs. per-item.

```python
# map and sort commute when f is order-preserving
@given(st.lists(st.integers()))
def test_map_sort_commute(xs):
    f = lambda x: x * 2           # monotone — preserves sort order
    assert list(map(f, sorted(xs))) == sorted(map(f, xs))

# batch operation equals applying one at a time
@given(st.lists(st.integers(), min_size=1))
def test_batch_equals_sequential(xs):
    assert process_batch(xs) == [process_one(x) for x in xs]
```

**Diagram template:**
```
input ──f──► intermediate
  │                │
  g                g
  │                │
  ▼                ▼
intermediate ──f──► output   (both paths reach same output)
```


### 5. Structural Induction ("Solve a Smaller Problem First")
If a property holds for smaller parts, it holds for the whole.

**When to use:** recursive data structures, lists, trees, divide-and-conquer algorithms.

```python
@given(st.lists(st.integers(), min_size=1))
def test_sorted_tail_is_sorted(xs):
    result = sorted(xs)
    assert result[1:] == sorted(result[1:])  # tail is also sorted

@given(st.lists(st.integers()), st.lists(st.integers()))
def test_sort_concat(xs, ys):
    # merge of two sorted lists contains all elements
    merged = merge_sorted(sorted(xs), sorted(ys))
    assert sorted(xs + ys) == sorted(merged)
```


### 6. Easy to Verify ("Hard to Prove, Easy to Check")
Finding the answer is hard, but checking it is trivial.

**When to use:** search, optimization, parsing, factorization, pathfinding, constraint solving.

```python
@given(st.integers(min_value=2, max_value=10_000))
def test_factorization(n):
    factors = factorize(n)
    product = 1
    for f in factors:
        product *= f
    assert product == n                        # check: product equals input
    assert all(is_prime(f) for f in factors)  # check: all factors are prime

@given(st.text())
def test_tokenizer(s):
    tokens = tokenize(s)
    assert "".join(tokens) == s               # reconstruction property
```


### 7. Oracle ("Two Heads Are Better Than One")
Cross-check an optimized or complex implementation against a simple reference.

**When to use:** optimized algorithms, parallel vs. sequential, refactoring, porting.

```python
@given(st.lists(st.integers()))
def test_optimized_sort_matches_builtin(xs):
    assert my_optimized_sort(xs) == sorted(xs)

@given(st.text(), st.text())
def test_parallel_search_matches_linear(haystack, needle):
    assert parallel_search(haystack, needle) == haystack.find(needle)
```

**Note:** The oracle doesn't need to be fast — it just needs to be obviously correct.


---

## Building Strategies for Custom Types

### Pattern: `st.builds` for simple dataclasses

```python
from dataclasses import dataclass
from hypothesis import given
from hypothesis import strategies as st

@dataclass
class Order:
    quantity: int
    price: float

order_strategy = st.builds(
    Order,
    quantity=st.integers(min_value=1, max_value=1000),
    price=st.floats(min_value=0.01, max_value=99_999.99, allow_nan=False),
)

@given(order_strategy)
def test_order_total_positive(order):
    assert order.quantity * order.price > 0
```

### Pattern: `@st.composite` for dependent fields

Use when fields have relationships or must be constructed procedurally.

```python
@st.composite
def valid_date_range(draw):
    start = draw(st.dates())
    end = draw(st.dates(min_value=start))  # end >= start
    return start, end

@given(valid_date_range())
def test_range_duration_non_negative(date_range):
    start, end = date_range
    assert (end - start).days >= 0
```

### Pattern: `st.from_type` with type hints

If your class has full type annotations, Hypothesis can infer strategies automatically.

```python
from hypothesis.strategies import from_type

@given(from_type(MyAnnotatedClass))
def test_something(obj):
    ...
```

Register custom strategies for types used across tests:

```python
from hypothesis import strategies as st
st.register_type_strategy(Money, st.builds(Money, amount=st.decimals(min_value=0)))
```

### Pattern: Recursive / nested structures

```python
json_strategy = st.recursive(
    base=st.one_of(st.none(), st.booleans(), st.integers(), st.text()),
    extend=lambda children: st.one_of(
        st.lists(children),
        st.dictionaries(st.text(), children),
    ),
    max_leaves=20,
)
```

### Pattern: Filtering with `assume` vs. constrained strategies

Prefer constrained strategies over `assume` — filtering wastes examples.

```python
# Bad: wastes examples when n happens to be even
@given(st.integers())
def test_odd(n):
    assume(n % 2 == 1)
    ...

# Good: generate only odd numbers
@given(st.integers().filter(lambda n: n % 2 == 1))
def test_odd(n):
    ...

# Best for numeric ranges:
@given(st.integers(min_value=1))
def test_positive(n):
    ...
```

---

## Settings and Profiles

```python
from hypothesis import settings, HealthCheck, Phase

# Per-test settings
@settings(max_examples=1000, deadline=None)
@given(...)
def test_thorough(x): ...

# Suppress slow-test warning
@settings(suppress_health_check=[HealthCheck.too_slow])

# CI vs. local profiles
settings.register_profile("ci", max_examples=1000)
settings.register_profile("dev", max_examples=50)
settings.load_profile("ci" if os.getenv("CI") else "dev")
```

---

## Property Discovery Checklist

When given a function `f` to test, ask:

- [ ] Does `f` have an inverse? → **Inverse**
- [ ] What structural facts survive `f`? → **Invariant**
- [ ] Is `f(f(x)) == f(x)` meaningful? → **Idempotence**
- [ ] Does `f` compose with related ops in any order? → **Commutative diagram**
- [ ] Does `f` operate on recursive/nested data? → **Structural induction**
- [ ] Is the output easy to validate independently? → **Easy to verify**
- [ ] Is there a simpler correct version to compare? → **Oracle**
