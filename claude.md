# Code Style and Architecture Guidelines

## Type Checking and Linting

- **Always** run type checking and linting with: `uv run pyright; uv run ruff check; uv run ruff format`
- Use semicolons to run all three commands regardless of individual failures
- **Never** run type checking or linting on non-Python files (markdown, JSON, etc.)
- Code must pass all three before completion

## Package Management

- **Always** use `uv add <package>` to add dependencies
- **Never** use `pip install` or `uv pip install`

## Architecture

- Use **hexagonal architecture** (ports and adapters pattern)
- **All adapters must have corresponding ports** - adapters implement port interfaces
- **Try to reuse existing ports** if they naturally match new adapter needs, but keep it SOLID:
    - **Liskov Substitution Principle** - adapters must be substitutable for their ports
    - **Interface Segregation Principle** - don't force adapters to depend on methods they don't use
    - **Dependency Inversion Principle** - depend on port abstractions, not concrete adapters
- **Adapters are regular classes with `__init__`** - not dataclasses
- **No global state** - all state must be explicitly passed or injected
- Separate domain logic from infrastructure concerns

## Dependency Injection

- Use **punq** for dependency injection with auto-wiring
- **Never use manual dependency injection** - always use the container

### Dependency Injection Rules

1. **Config objects are frozen dataclasses** - must be explicit, no hidden fallbacks, never primitives in constructors
2. **Factory methods are class methods** - not lambdas or nested functions
3. **Use context manager for lifecycle** - automatic resource cleanup
4. **Type annotations on resolve** - use `# type: ignore[assignment]` for punq's dynamic resolution
5. **Register in order**: configs → infrastructure → ports/adapters → use cases → app
6. **Auto-wiring requirement**: Constructor parameters must be unambiguous types (no multiple `str` params)

### ContainerFactory Pattern

Create a ContainerFactory class as a context manager:

```python
class ContainerFactory:
    def __init__(self, config1: Config1, config2: Config2):
        self.config1 = config1
        self.config2 = config2
        self.container = punq.Container()
        self.session: Session | None = None

    def create_infrastructure_dependency(self) -> InfrastructureType:
        return InfrastructureType(self.config1.param)

    def build(self) -> punq.Container:
        self.container.register(Config1, instance=self.config1)
        self.container.register(Config2, instance=self.config2)
        self.container.register(InfrastructureType, factory=self.create_infrastructure_dependency)
        self.container.register(PortABC, AdapterImplementation)
        self.container.register(UseCase)
        return self.container

    def __enter__(self) -> punq.Container:
        return self.build()

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        if self.session:
            self.session.close()
```

### Environment Variable Handling in main.py

All environment variable logic and file reading happens in `main.py`, never in adapters or factories.

```python
def get_required_env(env_var_name: str) -> str:
    value = os.getenv(env_var_name)
    if value is None or value == "":
        raise Exception(f"{env_var_name} environment variable not set")
    return value

def get_optional_env(env_var_name: str, fallback: str) -> str:
    return os.getenv(env_var_name, fallback)
```

Rules:
- **Required config (API keys, secrets)** - use `get_required_env()`, throws exception if missing
- **Optional config (has sane defaults)** - use `get_optional_env()` with fallback for local dev
- **Never put fallbacks on API keys or secrets** - must fail fast with clear error message

### Main Entry Point Pattern

```python
def main():
    api_key = get_required_env("API_KEY")
    database_url = get_optional_env("DATABASE_URL", "postgresql://localhost/dev")

    config1 = Config1(api_key=api_key)
    config2 = Config2(database_url=database_url)

    with ContainerFactory(config1, config2) as container:
        app: AppType = container.resolve(AppType)  # type: ignore[assignment]
        app.run()
```

## Type Safety

- **Strictly typed** - all functions, parameters, and return values must have type hints
- **Avoid `dict`** - use dataclasses or typed classes instead
- **Avoid `None`** - use `Optional` only when absolutely necessary; prefer sentinel values or result types
- **Avoid `Union`** - prefer refactoring to polymorphic types or separate functions instead of losing type clarity
- **No comments in code** - code should be self-documenting through clear naming and types

## Dataclasses

- **Use dataclasses only for entities that hold typed data** (DTOs, domain entities, value objects)
- **Do not use dataclasses for adapters, use cases, or other behavioral classes**
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
