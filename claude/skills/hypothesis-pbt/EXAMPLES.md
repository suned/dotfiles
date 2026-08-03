# Hypothesis PBT — Worked Examples

## Example 1: Shopping Cart

A cart that holds items with quantities and prices.

```python
from dataclasses import dataclass, field
from decimal import Decimal
from hypothesis import given, assume
from hypothesis import strategies as st

@dataclass
class Item:
    name: str
    price: Decimal
    quantity: int

@dataclass
class Cart:
    items: list[Item] = field(default_factory=list)

    def total(self) -> Decimal:
        return sum(i.price * i.quantity for i in self.items)

    def add(self, item: Item) -> "Cart":
        return Cart(items=self.items + [item])

    def merge(self, other: "Cart") -> "Cart":
        return Cart(items=self.items + other.items)


# Strategies
item_strategy = st.builds(
    Item,
    name=st.text(min_size=1, max_size=20),
    price=st.decimals(min_value="0.01", max_value="999.99", places=2),
    quantity=st.integers(min_value=1, max_value=100),
)

cart_strategy = st.builds(Cart, items=st.lists(item_strategy, max_size=10))


# Invariant: total is always non-negative
@given(cart_strategy)
def test_cart_total_non_negative(cart):
    assert cart.total() >= 0


# Commutative diagram: merge is commutative for totals
@given(cart_strategy, cart_strategy)
def test_merge_total_commutative(cart_a, cart_b):
    assert cart_a.merge(cart_b).total() == cart_b.merge(cart_a).total()


# Structural induction: total of merged carts equals sum of individual totals
@given(cart_strategy, cart_strategy)
def test_merge_total_additive(cart_a, cart_b):
    assert cart_a.merge(cart_b).total() == cart_a.total() + cart_b.total()


# Invariant: adding an item increases total by exactly item.price * item.quantity
@given(cart_strategy, item_strategy)
def test_add_item_increases_total(cart, item):
    new_cart = cart.add(item)
    assert new_cart.total() == cart.total() + item.price * item.quantity
```


## Example 2: Text Processor (Parser/Formatter)

Demonstrates inverse and easy-to-verify patterns.

```python
from hypothesis import given
from hypothesis import strategies as st


def tokenize(text: str) -> list[str]:
    """Split text into words, preserving whitespace as tokens."""
    ...

def join(tokens: list[str]) -> str:
    return "".join(tokens)

def normalize(text: str) -> str:
    """Lowercase, strip extra whitespace."""
    ...


printable = st.text(alphabet=st.characters(whitelist_categories=("Lu", "Ll", "Nd", "Zs")))


# Inverse: tokenize then join reconstructs the original
@given(printable)
def test_tokenize_join_roundtrip(text):
    assert join(tokenize(text)) == text


# Easy to verify: every token in result is a substring of input
@given(printable)
def test_tokens_are_substrings(text):
    for token in tokenize(text):
        assert token in text


# Idempotence: normalizing twice equals normalizing once
@given(printable)
def test_normalize_idempotent(text):
    assert normalize(normalize(text)) == normalize(text)


# Invariant: normalization preserves non-whitespace content
@given(printable)
def test_normalize_preserves_words(text):
    original_words = set(text.lower().split())
    normalized_words = set(normalize(text).split())
    assert original_words == normalized_words
```


## Example 3: Sorted Collection (Oracle + Induction)

```python
from hypothesis import given
from hypothesis import strategies as st


def my_sort(xs: list[int]) -> list[int]:
    """Custom sort implementation to verify."""
    ...


# Oracle: matches Python's built-in sort
@given(st.lists(st.integers()))
def test_sort_matches_builtin(xs):
    assert my_sort(xs) == sorted(xs)


# Invariant: result is actually sorted
@given(st.lists(st.integers()))
def test_result_is_ordered(xs):
    result = my_sort(xs)
    assert all(result[i] <= result[i + 1] for i in range(len(result) - 1))


# Invariant: preserves multiset of elements
@given(st.lists(st.integers()))
def test_sort_preserves_elements(xs):
    from collections import Counter
    assert Counter(my_sort(xs)) == Counter(xs)


# Structural induction: tail of sorted list is sorted
@given(st.lists(st.integers(), min_size=2))
def test_tail_is_sorted(xs):
    result = my_sort(xs)
    assert result[1:] == my_sort(result[1:])


# Idempotence
@given(st.lists(st.integers()))
def test_sort_idempotent(xs):
    assert my_sort(my_sort(xs)) == my_sort(xs)
```


## Example 4: API / Domain Service (Multiple Patterns)

A user account service — common in TDD workflows.

```python
from dataclasses import dataclass
from hypothesis import given
from hypothesis import strategies as st

@dataclass
class User:
    id: str
    email: str
    active: bool = True

class UserRepository:
    def __init__(self): self._store = {}
    def save(self, user): self._store[user.id] = user
    def get(self, id): return self._store.get(id)
    def delete(self, id): self._store.pop(id, None)
    def list_active(self): return [u for u in self._store.values() if u.active]


user_ids = st.text(min_size=1, max_size=36, alphabet="abcdef0123456789-")
emails = st.emails()
user_strategy = st.builds(User, id=user_ids, email=emails, active=st.booleans())


# Inverse: save then get returns the same user
@given(user_strategy)
def test_save_get_roundtrip(user):
    repo = UserRepository()
    repo.save(user)
    assert repo.get(user.id) == user


# Invariant: delete makes user unretrievable
@given(user_strategy)
def test_delete_removes_user(user):
    repo = UserRepository()
    repo.save(user)
    repo.delete(user.id)
    assert repo.get(user.id) is None


# Invariant: list_active never includes inactive users
@given(st.lists(user_strategy, max_size=20))
def test_list_active_only_active(users):
    repo = UserRepository()
    for u in users:
        repo.save(u)
    assert all(u.active for u in repo.list_active())


# Idempotence: saving same user twice is same as once
@given(user_strategy)
def test_save_idempotent(user):
    repo = UserRepository()
    repo.save(user)
    repo.save(user)
    assert repo.get(user.id) == user
```
