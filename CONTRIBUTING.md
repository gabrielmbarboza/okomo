# Contribution Guide

Thank you for your interest in contributing to Okomo! This guide provides instructions on how to set up the environment, run tests, and submit contributions.

## Contribution Process Overview

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/feature-name`)
3. Make your changes following the project conventions
4. Run tests and ensure they all pass
5. Commit your changes following Conventional Commits
6. Push to your branch (`git push origin feature/feature-name`)
7. Open a Pull Request describing your changes

## Environment Setup with Docker

Okomo uses Docker and Docker Compose to facilitate development environment setup.

### Prerequisites

- Docker
- Docker Compose

### Setup Steps

```bash
# 1. Clone the repository
git clone <repo-url> && cd okomo

# 2. Copy environment variables
cp .env.example .env

# 3. Build and start all services
docker-compose up --build

# 4. In another terminal, create and migrate the database
docker-compose exec app bundle exec rails db:create db:migrate

# 5. Run tests
docker-compose exec app bundle exec rspec
```

### Useful Commands

```bash
# Rails console
docker-compose exec app bundle exec rails console

# Run migrations
docker-compose exec app bundle exec rails db:migrate

# Run tests
docker-compose exec app bundle exec rspec

# Run specific tests
docker-compose exec app bundle exec rspec spec/path/to/spec.rb

# Run RuboCop
docker-compose exec app bundle exec rubocop

# Stop all services
docker-compose down

# Stop and remove volumes (reset data)
docker-compose down -v
```

## Custom Generators

Okomo includes custom generators to automate the creation of bounded contexts and domain artifacts, following the project's DDD conventions.

### Create a Bounded Context

```bash
bin/rails generate domain Identity
```

Creates the complete directory structure for the bounded context.

### Create Domain Artifacts

```bash
# Create an entity
bin/rails generate domain_entity Identity User

# Create a service
bin/rails generate domain_service Identity RegisterUser

# Create a value object
bin/rails generate domain_value_object Orders Money

# Create a repository
bin/rails generate domain_repository Orders OrderRepository

# Create a domain event
bin/rails generate domain_event Orders OrderCreated
```

For more details about the generators, see the [README](README.md#custom-generators) and [ADR-015](docs/adr/ADR-015-custom-rails-generators-for-domain-scaffolding.md).

## Test Execution

Okomo uses RSpec as the testing framework. Run the complete test suite before submitting any contribution:

```bash
docker-compose exec app bundle exec rspec
```

### Test Coverage

Maintain test coverage above 90% for domain logic. Use SimpleCov to check coverage:

```bash
docker-compose exec app bundle exec rspec
```

The coverage report will be generated at `coverage/index.html`.

## Commit Convention

This project follows the [Conventional Commits](https://www.conventionalcommits.org/) specification. The basic structure is:

```
<type>(<scope>): <description>
```

### Common Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `test`: Test additions or changes
- `refactor`: Code refactoring
- `chore`: Maintenance or configuration tasks

### Examples

```
feat(identity): implement user registration
fix(inventory): prevent overselling with pessimistic locking
docs(adr): add ADR-014 for authentication
test(orders): add CreateOrder service specs
refactor(payments): extract gateway interface
chore(ci): configure GitHub Actions
```

## Pull Request Rules

When opening a Pull Request:

1. **Describe the purpose clearly**: Explain what your PR does and why it's necessary.
2. **Reference related issues**: If your PR resolves an issue, include `Fixes #123` in the description.
3. **Keep focus**: Each PR should address a single concern or feature.
4. **Complete tests**: Include tests for new features and update existing tests if necessary.
5. **Updated documentation**: Update relevant documentation (README, docs/, etc.) if your change affects the public interface or system behavior.
6. **CI/CD passing**: Ensure all CI/CD checks pass before requesting review.

### Review Process

- Maintainers will review your PR and provide feedback
- Respond to comments and make requested changes
- After approval, your PR will be merged into the main branch

## Code of Conduct

By participating in this project, you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md). All participants are expected to act with respect, empathy, and professionalism.

## Questions?

If you have questions about the contribution process or the project in general, feel free to open an issue or contact the maintainers.

---

Thank you for contributing to Okomo! 🚀
