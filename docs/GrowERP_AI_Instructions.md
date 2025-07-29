# GrowERP AI Development Instructions

This file provides comprehensive instructions for AI coding assistants working on the GrowERP project.

## Project Overview

GrowERP is an open-source, multi-platform ERP system built with Flutter (frontend) and Moqui (backend). The architecture follows domain-driven design with clear separation between building blocks and applications.

## File Locations
- **Design Patterns**: `/docs/GrowERP_Design_Patterns.md`
- **Code Templates**: `/docs/GrowERP_Code_Templates.md`  
- **Extensibility Guide**: `/docs/GrowERP_Extensibility_Guide.md`
- **Frontend Packages**: `/flutter/packages/`
- **Backend Components**: `/moqui/runtime/component/`

## Core Principles

### 1. Architecture Patterns
- **BLoC State Management**: All business logic uses flutter_bloc
- **Layered Architecture**: Presentation → Business Logic → Data → Infrastructure
- **Domain Packages**: Each domain is a separate package (e.g., `growerp_catalog`, `growerp_user_company`)
- **Building Blocks**: Lower-level packages serve as dependencies for higher-level ones

### 2. Naming Conventions
- **Packages**: `growerp_[domain]` format
- **BLoCs**: `[Entity]Bloc`, `[Entity]Event`, `[Entity]State`
- **Views**: `[Entity]List`, `[Entity]Dialog`
- **Tests**: `[Entity]Test`
- **Keys**: Use descriptive keys for all interactive widgets

### 3. Code Quality Standards
- **Type Safety**: Use strong typing, generics, and null safety
- **Immutability**: Use Freezed for data models
- **Error Handling**: Consistent error handling across all layers
- **Testing**: Comprehensive integration tests for all features
- **Documentation**: Clear comments and documentation

## When Creating New Features

### 1. Before Starting
- Check existing patterns in `/docs/GrowERP_Design_Patterns.md`
- Review similar implementations in the codebase
- Use code templates from `/docs/GrowERP_Code_Templates.md`

### 2. Package Structure
Follow this exact structure for new domain packages:
```
growerp_[domain]/
├── lib/
│   ├── src/
│   │   └── [entity]/
│   │       ├── blocs/
│   │       ├── views/
│   │       ├── widgets/
│   │       └── integration_test/
│   └── growerp_[domain].dart
└── example/
    └── integration_test/
```

### 3. BLoC Implementation
- Always use the standard BLoC pattern with Events, States, and proper error handling
- Include these standard events: `Fetch`, `Update`, `Delete`
- Use proper status enums: `initial`, `loading`, `success`, `failure`
- Implement pagination for list views

### 4. UI Components
- Use `FormBuilder` for all forms with proper validation
- Follow the list + dialog pattern for CRUD operations
- Implement proper loading states and error handling
- Use consistent styling and responsive design

### 5. Testing Requirements
- Create integration tests for all new features
- Follow the `[Entity]Test` pattern with `add`, `update`, `delete`, and `check` methods
- Use `CommonTest` utilities for common operations
- Ensure tests are isolated and repeatable

## Specific Guidelines

### Forms and Validation
```dart
// Always use FormBuilder with validation
FormBuilderTextField(
  name: 'fieldName',
  key: const Key('fieldName'),
  initialValue: widget.entity.fieldValue ?? '',
  decoration: const InputDecoration(labelText: 'Field Label'),
  validator: FormBuilderValidators.compose([
    FormBuilderValidators.required(),
  ]),
),
```

### BLoC Integration
```dart
// Standard BLoC consumer pattern
BlocConsumer<EntityBloc, EntityState>(
  listener: (context, state) {
    if (state.status == EntityStatus.failure) {
      HelperFunctions.showMessage(context, '${state.message}', Colors.red);
    }
  },
  builder: (context, state) {
    switch (state.status) {
      case EntityStatus.success:
        return _buildSuccessView(state);
      case EntityStatus.loading:
        return const LoadingIndicator();
      default:
        return _buildErrorView(state);
    }
  },
)
```

### Data Models
```dart
// Use Freezed for all data models
@freezed
class Entity extends Equatable with _$Entity {
  const Entity._();
  const factory Entity({
    @Default("") String id,
    @Default("") String name,
    // Other fields...
  }) = _Entity;

  factory Entity.fromJson(Map<String, dynamic> json) =>
      _$EntityFromJson(json['entity'] ?? json);

  @override
  List<Object?> get props => [id];
}
```

### Testing Patterns
```dart
// Standard test class structure
class EntityTest {
  static Future<void> selectEntities(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'dbEntity', 'EntityList', '1');
  }

  static Future<void> addEntities(WidgetTester tester, List<Entity> entities) async {
    // Implementation following the pattern...
  }
}
```

## Common Patterns to Follow

### 1. List Views
- Implement infinite scrolling with pagination
- Add search functionality
- Include refresh-to-reload
- Show proper loading states

### 2. Dialog Forms
- Use responsive design (different layouts for mobile/desktop)
- Implement proper form validation
- Handle success/error states appropriately
- Include cancel and submit actions

### 3. State Management
- Always emit loading state before async operations
- Handle errors gracefully with user-friendly messages
- Update state immutably using copyWith
- Implement proper success messages

### 4. Navigation
- Use named routes consistently
- Pass data through route arguments
- Handle deep linking appropriately

## Error Handling Patterns

### Frontend Errors
```dart
try {
  final result = await operation();
  emit(state.copyWith(status: Status.success, data: result));
} catch (error) {
  emit(state.copyWith(
    status: Status.failure,
    message: error.toString(),
  ));
}
```

### User Feedback
```dart
// Success messages
HelperFunctions.showMessage(context, 'Operation successful', Colors.green);

// Error messages  
HelperFunctions.showMessage(context, 'Error: ${error}', Colors.red);
```

## Integration with Backend

### REST API Patterns
- Follow RESTful conventions
- Use proper HTTP methods (GET, POST, PATCH, DELETE)
- Include proper error handling for network issues
- Implement retry logic where appropriate

### Data Flow
1. UI triggers BLoC event
2. BLoC calls REST client
3. REST client communicates with Moqui backend
4. Response flows back through the layers
5. UI updates based on new state

## Key Files to Reference

When working on specific domains, always check these existing implementations:
- **Products**: `/flutter/packages/growerp_catalog/lib/src/product/`
- **Users**: `/flutter/packages/growerp_user_company/lib/src/user/`
- **Orders**: `/flutter/packages/growerp_order_accounting/lib/src/findoc/`

## Quality Checklist

Before considering any feature complete:
- [ ] Follows established naming conventions
- [ ] Uses proper BLoC pattern with Events/States
- [ ] Implements FormBuilder for forms with validation
- [ ] Includes comprehensive error handling
- [ ] Has integration tests covering all functionality
- [ ] Uses consistent UI patterns and styling
- [ ] Implements proper loading states
- [ ] Handles responsive design appropriately
- [ ] Includes proper documentation
- [ ] Follows the package structure pattern

## Anti-Patterns to Avoid

1. **Direct State Mutation**: Always use copyWith() for state updates
2. **UI Business Logic**: Keep business logic in BLoCs, not in UI components
3. **Hardcoded Strings**: Use proper localization and constants
4. **Inconsistent Patterns**: Don't deviate from established patterns without good reason
5. **Missing Error Handling**: Always handle potential errors gracefully
6. **Poor Test Coverage**: Every feature needs comprehensive integration tests

## Getting Help

When unsure about implementation details:
1. Check existing similar implementations in the codebase
2. Refer to the design patterns documentation
3. Look at the extensibility guide for architectural guidance
4. Review existing tests for testing patterns

Remember: Consistency is key. When in doubt, follow the patterns established by existing code in the same domain.
