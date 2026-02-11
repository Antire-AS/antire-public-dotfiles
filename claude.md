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
- **All configuration must use typed config objects** - never primitives in constructors
- Create frozen dataclasses for configuration (e.g., `GithubConfig`, `DatabaseConfig`)
- All environment variable logic and file reading happens in `main.py`, to be parsed into config structures,not in
  adapters or factories
- Config objects must have **explicit required values** - no `None` defaults for required config

### Container Setup Pattern

Follow this pattern for all DI setup:

```python
# 1. Create a ContainerFactory class as a context manager
class ContainerFactory:
    def __init__(self, config1: Config1, config2: Config2):
        self.config1 = config1
        self.config2 = config2
        self.container = punq.Container()
        self.session: Session | None = None  # Track resources needing cleanup

    def create_infrastructure_dependency(self) -> InfrastructureType:
        # Factory methods as proper class methods, not lambdas
        return InfrastructureType(self.config1.param)

    def build(self) -> punq.Container:
        # Register configs as instances
        self.container.register(Config1, instance=self.config1)
        self.container.register(Config2, instance=self.config2)

        # Register infrastructure with factory methods
        self.container.register(InfrastructureType, factory=self.create_infrastructure_dependency)

        # Register ports -> adapters (auto-wired)
        self.container.register(PortInterface, AdapterImplementation)

        # Register use cases (auto-wired)
        self.container.register(UseCase)

        return self.container

    def __enter__(self) -> punq.Container:
        return self.build()

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        # Clean up resources (e.g., close database sessions)
        if self.session:
            self.session.close()


# 2. In main.py, handle all environment variables and config creation
def get_required_env(env_var_name: str) -> str:
    """Get required environment variable or raise exception with clear message"""
    value = os.getenv(env_var_name)
    if value is None or value == "":
        raise Exception(f"{env_var_name} environment variable not set")
    return value

def get_optional_env(env_var_name: str, fallback: str) -> str:
    """Get optional environment variable with fallback for local dev"""
    return os.getenv(env_var_name, fallback)

def main():
    # Required config (API keys, secrets) - throws exception if missing
    api_key = get_required_env("API_KEY")

    # Optional config (has sane defaults) - uses fallback
    database_url = get_optional_env("DATABASE_URL", "postgresql://localhost/dev")

    config1 = Config1(api_key=api_key)
    config2 = Config2(database_url=database_url)

    with ContainerFactory(config1, config2) as container:
        app: AppType = container.resolve(AppType)  # type: ignore[assignment]
        app.run()
```

### Dependency Injection Rules

1. **Config objects are frozen dataclasses** - must be explicit, no hidden fallbacks
2. **Factory methods are class methods** - not lambdas or nested functions
3. **Use context manager for lifecycle** - automatic resource cleanup
4. **Type annotations on resolve** - use `# type: ignore[assignment]` for punq's dynamic resolution
5. **Register in order**: configs → infrastructure → ports/adapters → use cases → app
6. **Auto-wiring requirement**: Constructor parameters must be unambiguous types (no multiple `str` params)

### Environment Variable Handling

- **Required config (API keys, secrets)** - use `get_required_env()` which throws exception if missing
- **Optional config (has sane defaults)** - use `get_optional_env()` with fallback for local dev
- **Never put fallbacks on API keys or secrets** - must fail fast with clear error message
- All environment variable functions live in `main.py`, never in adapters or domain

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
