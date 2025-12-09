# Contributing to GrowERP

Thank you for your interest in contributing to GrowERP! We welcome contributions from developers of all skill levels and backgrounds. This guide will help you get started with contributing to our open-source ERP platform.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Ways to Contribute](#ways-to-contribute)
3. [Development Setup](#development-setup)
4. [Contribution Workflow](#contribution-workflow)
5. [Coding Standards](#coding-standards)
6. [Testing Guidelines](#testing-guidelines)
7. [Documentation](#documentation)
8. [Community Guidelines](#community-guidelines)

## Getting Started

### Prerequisites

Before contributing, please:

1. **Read our [Code of Conduct](CODE_OF_CONDUCT.md)** - We're committed to providing a welcoming and inclusive environment
2. **Review the [Extensibility Documentation](docs/README.md)** - Understand GrowERP's modular architecture
3. **Explore the codebase** - Familiarize yourself with the project structure
4. **Check existing issues** - See if your idea or bug report already exists

### Understanding GrowERP's Architecture

GrowERP uses a modular architecture with two main layers:

- **Frontend**: Flutter-based building blocks (growerp_* packages)
- **Backend**: Moqui framework components

For detailed information, see our [Extensibility Documentation](docs/README.md).

## Ways to Contribute

### 🐛 Bug Reports and Fixes
- Report bugs using GitHub Issues
- Include detailed reproduction steps
- Fix bugs and submit pull requests

### ✨ New Features
- **Building Blocks**: Create new growerp_* packages for specific domains
- **Backend Components**: Develop Moqui components for new functionality
- **Applications**: Build complete applications using existing building blocks
- **Integrations**: Connect with third-party services

### 📚 Documentation
- Improve existing documentation
- Add code examples and tutorials
- Translate documentation to other languages
- Create video tutorials or blog posts

### 🧪 Testing
- Write unit tests for new features
- Add integration tests for workflows
- Improve test coverage
- Test on different platforms and devices

### 🎨 UI/UX Improvements
- Enhance user interface designs
- Improve accessibility
- Create new themes and templates
- Optimize for mobile and desktop

## Development Setup

### Frontend Development

1. **Install Flutter** (stable channel)
2. **Clone the repository**:
   ```bash
   git clone https://github.com/growerp/growerp.git
   cd growerp
   ```
3. initialize the system as is described in the [README](README.md)

For detailed frontend development, see the [Building Blocks Development Guide](docs/Building_Blocks_Development_Guide.md).

For detailed backend development, see the [Backend Components Development Guide](docs/Backend_Components_Development_Guide.md).

## Contribution Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/growerp.git
cd growerp
```

### 2. Create a Feature Branch

```bash
# Create a new branch from the development branch
git checkout development
git checkout -b my-new-feature
```

### 3. Make Your Changes

- Follow our [coding standards](#coding-standards)
- Write tests for new functionality
- Update documentation as needed
- Test your changes thoroughly

### 4. Commit Your Changes

Use conventional commit messages:

```bash
git commit -am 'feat: add new inventory tracking feature'
```

#### Commit Message Prefixes

- `feat:` - A new feature
- `fix:` - A bug fix
- `docs:` - Documentation changes
- `test:` - Adding or updating tests
- `refactor:` - Code refactoring without functional changes
- `perf:` - Performance improvements
- `chore:` - Other changes (build, dependencies, etc.)
- `revert:` - Reverting previous changes
- `build:` - Build system or docker image changes
- `upgrade:` - Upgrading third-party packages

### 5. Push and Create Pull Request

```bash
git push --set-upstream origin my-new-feature
```

Then create a pull request on GitHub with:
- Clear description of changes
- Reference to related issues
- Screenshots for UI changes
- Test results

## Coding Standards

### Flutter/Dart Standards

- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check for issues
- Format code with `dart format`
- Use meaningful variable and function names
- Add documentation comments for public APIs

### Backend Standards

- Follow Moqui framework conventions
- Use clear XML formatting and indentation
- Document all services and entities
- Include proper error handling
- Follow RESTful API conventions

### General Standards

- Write self-documenting code
- Use consistent naming conventions
- Keep functions and classes focused and small
- Include appropriate comments for complex logic
- Follow the existing code style in each area

## Testing Guidelines

### Frontend Testing

```bash
# Run all tests
cd flutter
melos test

## Documentation

### Types of Documentation

1. **Code Documentation**: Inline comments and API documentation
2. **User Guides**: How to use features from a user perspective
3. **Developer Guides**: Technical implementation details
4. **Architecture Documentation**: System design and patterns

### Documentation Standards

- Write clear, concise explanations
- Include code examples where helpful
- Use proper markdown formatting
- Keep documentation up-to-date with code changes
- Reference the [Extensibility Documentation](docs/README.md) for architectural guidance

### Creating New Building Blocks

When creating new growerp_* packages, follow the [Building Blocks Development Guide](docs/Building_Blocks_Development_Guide.md):

1. Use the standard package structure
2. Implement proper state management with BLoC
3. Include comprehensive tests
4. Document the public API
5. Add examples and usage instructions

### Creating Backend Components

When developing Moqui components, follow the [Backend Components Development Guide](docs/Backend_Components_Development_Guide.md):

1. Define entities with proper relationships
2. Implement services with validation and error handling
3. Create REST APIs with authentication
4. Include seed and demo data
5. Document all services and entities

## Community Guidelines

### Getting Help

- **GitHub Discussions**: For questions and ideas
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: Check the [docs](docs/) directory first
- **Code Review**: Participate in reviewing others' contributions

### Communication

- Be respectful and constructive in all interactions
- Ask questions if you're unsure about anything
- Share knowledge and help newcomers
- Follow our [Code of Conduct](CODE_OF_CONDUCT.md)

### Recognition

We recognize contributors through:
- Acknowledgment in release notes
- Contributor highlights in documentation
- Mentorship opportunities for significant contributors
- Community showcase of innovative extensions

## Specific Contribution Areas

### High-Priority Areas

1. **Industry-Specific Building Blocks**
   - Healthcare management
   - Education systems
   - Manufacturing workflows
   - Professional services

2. **Integration Modules**
   - Payment processors
   - Shipping providers
   - Analytics platforms
   - Communication tools

3. **Localization**
   - Multi-language support
   - Regional business rules
   - Currency and tax handling
   - Cultural adaptations

4. **Performance and Scalability**
   - Database optimization
   - Caching improvements
   - Mobile performance
   - Large dataset handling

### Getting Started Suggestions

#### For New Contributors
- Start with documentation improvements
- Fix small bugs or typos
- Add tests to existing code
- Improve error messages

#### For Experienced Developers
- Create new building blocks for your industry
- Develop integration modules
- Optimize performance bottlenecks
- Mentor new contributors

#### For Domain Experts
- Contribute business logic for your field
- Review and improve workflows
- Provide feedback on user experience
- Create industry-specific applications

## Release Process

### Versioning

We follow [Semantic Versioning](https://semver.org/):
- **Major** (1.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.1.1): Bug fixes, backward compatible

### Release Cycle

- Regular releases every 2-4 months
- Security patches as needed
- Major releases with significant new features
- Beta releases for testing new functionality

## Resources

### Documentation
- [Extensibility Overview](docs/README.md)
- [Building Blocks Guide](docs/Building_Blocks_Development_Guide.md)
- [Backend Components Guide](docs/Backend_Components_Development_Guide.md)
- [Management Summary](docs/Management_Summary_Open_Source_Extensibility.md)

### External Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Moqui Framework](https://www.moqui.org/docs)
- [GitHub Flow Guide](https://github.blog/developer-skills/github/beginners-guide-to-github-creating-a-pull-request/)

### Community
- [GitHub Repository](https://github.com/growerp/growerp)
- [GitHub Discussions](https://github.com/growerp/growerp/discussions)
- [Issues and Bug Reports](https://github.com/growerp/growerp/issues)

## Questions?

If you have questions about contributing:

1. Check the [documentation](docs/README.md)
2. Search existing [GitHub Issues](https://github.com/growerp/growerp/issues)
3. Start a [GitHub Discussion](https://github.com/growerp/growerp/discussions)
4. Contact the maintainers (see README.md for contact information)

---

**Thank you for contributing to GrowERP!** Your contributions help make enterprise software more accessible, flexible, and powerful for businesses worldwide.

*Last updated: December 2025*
