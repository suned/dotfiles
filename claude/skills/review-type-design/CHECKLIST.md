# Type Design Review Checklist

Work through each section. For every violation, note the class, field, and line number.

## 1. Primitive Obsession

- [ ] Are domain concepts (email, phone, money, IDs) represented as bare `str`, `int`, or `float`?
- [ ] Could two fields with the same Python type be accidentally swapped at a call site?
- [ ] Are there `str` parameters that only accept a specific format (e.g. email, URL, ISO date)?

**Fix:** Use `NewType`, a wrapper class, or `Annotated[str, ...]` with Pydantic constraints.

```python
# Before
email: str

# After — pick the style that fits your stack
EmailAddress = NewType("EmailAddress", str)

# Or with validation (Pydantic)
class EmailAddress(BaseModel):
    value: str
    @field_validator("value")
    @classmethod
    def validate(cls, v: str) -> str:
        if "@" not in v:
            raise ValueError("invalid email")
        return v.strip().lower()
```

## 2. Illegal States

- [ ] Are there multiple `Optional` fields where at least one must be set?
- [ ] Are there field combinations that are invalid together but the type allows them?
- [ ] Can the class be instantiated in a state that violates business rules?

**Fix:** Use `Union` of specific dataclasses, each representing a valid state.

```python
# Before — allows neither or both
@dataclass
class Contact:
    email: str | None = None
    phone: str | None = None  # "must have at least one"

# After
@dataclass
class EmailOnly:
    email: EmailAddress

@dataclass
class PhoneOnly:
    phone: PhoneNumber

@dataclass
class EmailAndPhone:
    email: EmailAddress
    phone: PhoneNumber

ContactInfo = EmailOnly | PhoneOnly | EmailAndPhone
```

## 3. Atomic Grouping

- [ ] Are related fields (that must stay consistent) spread across different classes?
- [ ] Are unrelated fields bundled together in the same class?
- [ ] Does a boolean "flag" field only make sense alongside specific other fields?

**Fix:** Extract coherent groups into their own dataclass/model.

```python
# Before
@dataclass
class Contact:
    email: str
    is_email_verified: bool  # only meaningful with email
    street: str
    city: str
    zip_code: str

# After
@dataclass
class EmailContactInfo:
    email: EmailAddress
    is_verified: bool

@dataclass
class PostalAddress:
    street: str
    city: str
    zip_code: ZipCode
```

## 4. Hidden Domain Concepts

- [ ] Are there repeated groups of fields that could be a named concept?
- [ ] Is a `Union` growing beyond 3-4 variants? Could a higher abstraction unify them?
- [ ] Are there parallel lists/dicts that should be a single list of a richer type?

**Fix:** Introduce a new domain type that names the hidden concept.

```python
# Before — parallel structures
@dataclass
class Contact:
    emails: list[str]
    phones: list[str]
    addresses: list[Address]

# After — unified concept
@dataclass
class ContactMethod:
    kind: Literal["email", "phone", "postal"]
    value: EmailAddress | PhoneNumber | PostalAddress

@dataclass
class Contact:
    primary: ContactMethod
    secondary: list[ContactMethod]  # enforces "at least one"
```

## 5. Implicit State (Boolean/Enum Flags)

- [ ] Are boolean fields used to track lifecycle state (`is_active`, `is_verified`, `is_paid`)?
- [ ] Is there a `status: str` or `status: SomeEnum` with fields that are only valid in certain statuses?
- [ ] Are there `Optional` fields that are only `None` in certain states?

**Fix:** Model as a union of state-specific types (a simple state machine).

```python
# Before
@dataclass
class Order:
    status: str  # "pending" | "shipped" | "delivered"
    shipped_at: datetime | None = None  # only set when shipped
    tracking: str | None = None         # only set when shipped
    delivered_at: datetime | None = None # only set when delivered

# After
@dataclass
class PendingOrder:
    items: list[OrderItem]

@dataclass
class ShippedOrder:
    items: list[OrderItem]
    shipped_at: datetime
    tracking: str

@dataclass
class DeliveredOrder:
    items: list[OrderItem]
    shipped_at: datetime
    tracking: str
    delivered_at: datetime

Order = PendingOrder | ShippedOrder | DeliveredOrder
```

## 6. Construction-Time Constraints

- [ ] Are constraints (length limits, value ranges, format rules) validated somewhere other than construction?
- [ ] Can invalid instances be created and passed around before validation happens?
- [ ] Are there comments or docstrings describing constraints that aren't enforced by code?

**Fix:** Validate in `__post_init__`, Pydantic validators, or a factory classmethod that returns `T | None`.

```python
# Factory pattern (stdlib dataclasses)
@dataclass(frozen=True)
class ZipCode:
    value: str

    def __post_init__(self) -> None:
        if not re.fullmatch(r"\d{5}", self.value):
            raise ValueError(f"Invalid zip: {self.value}")

# Factory returning Optional (for "parse, don't validate")
class ZipCode:
    def __init__(self, value: str) -> None:
        self._value = value

    @classmethod
    def parse(cls, raw: str) -> "ZipCode | None":
        return cls(raw.strip()) if re.fullmatch(r"\d{5}", raw.strip()) else None

    @property
    def value(self) -> str:
        return self._value
```

## 7. Semantic Non-String Types

- [ ] Are integer IDs used without distinguishing what they identify (`user_id: int` vs `order_id: int`)?
- [ ] Are `datetime` values used without clarity on timezone (naive vs aware, local vs UTC)?
- [ ] Are numeric quantities missing their unit (kg, cents, meters)?

**Fix:** Use `NewType` or wrapper classes for IDs; use `Annotated` or wrapper for units.

```python
UserId = NewType("UserId", int)
OrderId = NewType("OrderId", int)

# Units
@dataclass(frozen=True)
class Money:
    amount_cents: int
    currency: str

# Timezone clarity
UtcDatetime = NewType("UtcDatetime", datetime)  # document: always UTC-aware
```

## Final Check

- [ ] Could a new developer read just the types and understand the business rules?
- [ ] If a new state/variant is added, will the type checker force updates to all handlers?
- [ ] Are there any remaining `# type: ignore` or `cast()` calls that smell of a design issue?
