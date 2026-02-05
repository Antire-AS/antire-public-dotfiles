# Code Style and Architecture Guidelines

## Type Checking and Linting

- **Always** run `pyright` for type checking
- **Always** run `ruff` for linting
- Code must pass both before completion

## Architecture

- Use **hexagonal architecture** (ports and adapters pattern)
- **No global state** - all state must be explicitly passed or injected
- Separate domain logic from infrastructure concerns

## Type Safety

- **Strictly typed** - all functions, parameters, and return values must have type hints
- **Avoid `dict`** - use dataclasses or typed classes instead
- **Avoid `None`** - use `Optional` only when absolutely necessary; prefer sentinel values or result types
- **Avoid `Union`** - suggest refactorings instead of loosing type clarity
- **No comments in code** - code should be self-documenting through clear naming and types

## Dataclasses

- Use `mashumaro` with dict mixins for all dataclasses
- **All dataclasses must be `frozen=True`**
- Non-primitive fields: use `field(default_factory=...)`
- Primitive fields: use reasonable default values
- Example:
  ```python
  from dataclasses import dataclass, field
  from mashumaro.mixins.dict import DataClassDictMixin

  @dataclass(frozen=True)
  class MyClass(DataClassDictMixin):
      name: str = ""
      count: int = 0
      items: list[str] = field(default_factory=list)
  ```
