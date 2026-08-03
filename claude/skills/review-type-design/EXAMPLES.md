# Examples: Before/After Type Design Reviews

## Example 1: E-commerce Order (comprehensive rewrite)

### Before

```python
@dataclass
class Order:
    id: int
    customer_id: int
    customer_email: str
    items: list[dict]
    total: float
    currency: str
    status: str  # "draft", "placed", "paid", "shipped", "delivered", "cancelled"
    paid_at: datetime | None = None
    payment_ref: str | None = None
    shipped_at: datetime | None = None
    tracking_number: str | None = None
    delivered_at: datetime | None = None
    cancelled_at: datetime | None = None
    cancel_reason: str | None = None
```

### Review Findings

1. **Primitive Obsession** — `id`, `customer_id` both `int`; swappable at call sites.
2. **Primitive Obsession** — `customer_email: str`, `currency: str` carry implicit format rules.
3. **Illegal States** — `status="draft"` with `paid_at` set; `status="cancelled"` with `delivered_at` set.
4. **Implicit State** — 5 `Optional` fields are proxies for the order lifecycle.
5. **Atomic Grouping** — `total` + `currency` are inseparable but not grouped.
6. **Semantic Types** — `total: float` loses precision for money; `items: list[dict]` is untyped.

### After

```python
from __future__ import annotations
from dataclasses import dataclass
from datetime import datetime
from typing import NewType

OrderId = NewType("OrderId", int)
CustomerId = NewType("CustomerId", int)

@dataclass(frozen=True)
class Money:
    amount_cents: int
    currency: str  # could be further constrained to an enum

@dataclass(frozen=True)
class OrderItem:
    product_id: str
    quantity: int
    unit_price: Money

# -- State machine for order lifecycle --

@dataclass(frozen=True)
class DraftOrder:
    id: OrderId
    customer_id: CustomerId
    items: list[OrderItem]
    total: Money

@dataclass(frozen=True)
class PlacedOrder:
    id: OrderId
    customer_id: CustomerId
    items: list[OrderItem]
    total: Money

@dataclass(frozen=True)
class PaidOrder:
    id: OrderId
    customer_id: CustomerId
    items: list[OrderItem]
    total: Money
    paid_at: datetime
    payment_ref: str

@dataclass(frozen=True)
class ShippedOrder:
    id: OrderId
    customer_id: CustomerId
    items: list[OrderItem]
    total: Money
    paid_at: datetime
    payment_ref: str
    shipped_at: datetime
    tracking_number: str

@dataclass(frozen=True)
class DeliveredOrder:
    id: OrderId
    customer_id: CustomerId
    items: list[OrderItem]
    total: Money
    paid_at: datetime
    payment_ref: str
    shipped_at: datetime
    tracking_number: str
    delivered_at: datetime

@dataclass(frozen=True)
class CancelledOrder:
    id: OrderId
    customer_id: CustomerId
    items: list[OrderItem]
    total: Money
    cancelled_at: datetime
    reason: str

Order = DraftOrder | PlacedOrder | PaidOrder | ShippedOrder | DeliveredOrder | CancelledOrder
```

---

## Example 2: User Profile (targeted fixes)

### Before

```python
@dataclass
class UserProfile:
    user_id: int
    name: str
    email: str
    email_verified: bool
    phone: str | None
    phone_verified: bool
    avatar_url: str | None
    bio: str | None
    created_at: datetime
    last_login: datetime | None
    is_active: bool
    is_admin: bool
```

### Review Findings

1. **Primitive Obsession** — `user_id: int`, `email: str`
2. **Atomic Grouping** — `email` + `email_verified` are a unit; `phone` + `phone_verified` are a unit
3. **Implicit State** — `email_verified` and `phone_verified` are state flags
4. **Construction Constraints** — no length limit on `bio`, no format check on `email`

### After

```python
UserId = NewType("UserId", int)

@dataclass(frozen=True)
class UnverifiedEmail:
    address: str  # validated at construction

@dataclass(frozen=True)
class VerifiedEmail:
    address: str
    verified_at: datetime

Email = UnverifiedEmail | VerifiedEmail

@dataclass(frozen=True)
class UnverifiedPhone:
    number: str

@dataclass(frozen=True)
class VerifiedPhone:
    number: str
    verified_at: datetime

Phone = UnverifiedPhone | VerifiedPhone

@dataclass(frozen=True)
class UserProfile:
    user_id: UserId
    name: str
    email: Email
    phone: Phone | None
    avatar_url: str | None
    bio: str | None  # consider constraining length
    created_at: datetime
    last_login: datetime | None
```

---

## Example 3: Minimal — just NewType wrapping

Not every review needs a full rewrite. Sometimes the fix is surgical.

### Before

```python
def send_invoice(customer_id: int, order_id: int, amount: float) -> None: ...
```

### Finding

`customer_id` and `order_id` are trivially swappable. `amount` has no currency.

### After

```python
CustomerId = NewType("CustomerId", int)
OrderId = NewType("OrderId", int)

def send_invoice(customer_id: CustomerId, order_id: OrderId, amount: Money) -> None: ...
```

---

## Python Idiom Reference

| F# Concept | Python Equivalent |
|---|---|
| Single-case DU | `NewType("X", str)` or `@dataclass(frozen=True) class X` |
| Discriminated Union | `X = A \| B \| C` (Python 3.10+ `Union` with `match`) |
| Option type | `X \| None` (or `Optional[X]`) |
| Module with opaque type | Class with `@classmethod` factory + private `__init__` |
| Record type | `@dataclass(frozen=True)` or Pydantic `BaseModel(frozen=True)` |
| Pattern matching | `match obj: case A(): ... case B(): ...` (Python 3.10+) |
| Constrained constructor | `__post_init__`, Pydantic `@field_validator`, or factory returning `T \| None` |
