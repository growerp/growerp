# GrowERP Design Patterns Guide

This document defines the standard design patterns used in GrowERP for consistent development and AI-assisted code generation.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Package Structure Patterns](#package-structure-patterns)
3. [BLoC State Management Patterns](#bloc-state-management-patterns)
4. [UI Component Patterns](#ui-component-patterns)
5. [Testing Patterns](#testing-patterns)
6. [Data Model Patterns](#data-model-patterns)
7. [API Integration Patterns](#api-integration-patterns)
8. [Form Handling Patterns](#form-handling-patterns)

## Architecture Overview

GrowERP follows a multi-layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────┐
│           Presentation Layer        │
│  (Views, Dialogs, Forms, Lists)     │
├─────────────────────────────────────┤
│           Business Logic Layer      │
│        (BLoC, Events, States)       │
├─────────────────────────────────────┤
│            Data Layer              │
│      (Models, Repositories)        │
├─────────────────────────────────────┤
│          Infrastructure Layer       │
│    (REST Client, API Services)     │
└─────────────────────────────────────┘
```

## Package Structure Patterns

### 1. Domain Package Structure
```
growerp_[domain]/
├── lib/
│   ├── src/
│   │   └── [entity]/
│   │       ├── blocs/
│   │       │   ├── [entity]_bloc.dart
│   │       │   ├── [entity]_event.dart
│   │       │   └── [entity]_state.dart
│   │       ├── views/
│   │       │   ├── [entity]_list.dart
│   │       │   └── [entity]_dialog.dart
│   │       ├── widgets/
│   │       │   └── [entity]_list_table_def.dart
│   │       └── integration_test/
│   │           └── [entity]_test.dart
│   └── growerp_[domain].dart
└── example/
    └── integration_test/
        └── [entity]_test.dart
```

### 2. Naming Conventions
- **Packages**: `growerp_[domain]` (e.g., `growerp_catalog`, `growerp_user_company`)
- **BLoCs**: `[Entity]Bloc`, `[Entity]Event`, `[Entity]State`
- **Views**: `[Entity]List`, `[Entity]Dialog`
- **Models**: `[Entity]` (e.g., `Product`, `User`, `Company`)
- **Tests**: `[Entity]Test`

## BLoC State Management Patterns

### 1. BLoC Structure Template
```dart
// [entity]_bloc.dart
part of '[entity]_bloc.dart';
part '[entity]_event.dart';
part '[entity]_state.dart';

class [Entity]Bloc extends Bloc<[Entity]Event, [Entity]State> {
  [Entity]Bloc({required this.restClient}) : super(const [Entity]State()) {
    on<[Entity]Fetch>(_on[Entity]Fetch);
    on<[Entity]Update>(_on[Entity]Update);
    on<[Entity]Delete>(_on[Entity]Delete);
  }
  
  final RestClient restClient;
  
  Future<void> _on[Entity]Fetch([Entity]Fetch event, Emitter<[Entity]State> emit) async {
    emit(state.copyWith(status: [Entity]Status.loading));
    try {
      final result = await restClient.get[Entity]s(/* parameters */);
      emit(state.copyWith(
        status: [Entity]Status.success,
        [entity]s: result.[entity]s,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: [Entity]Status.failure,
        message: error.toString(),
      ));
    }
  }
}
```

### 2. Event Patterns
```dart
// [entity]_event.dart
abstract class [Entity]Event extends Equatable {
  const [Entity]Event();
  @override
  List<Object> get props => [];
}

class [Entity]Fetch extends [Entity]Event {
  const [Entity]Fetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20
  });
  final String searchString;
  final bool refresh;
  final int limit;
}

class [Entity]Update extends [Entity]Event {
  const [Entity]Update(this.[entity]);
  final [Entity] [entity];
}

class [Entity]Delete extends [Entity]Event {
  const [Entity]Delete(this.[entity]);
  final [Entity] [entity];
}
```

### 3. State Patterns
```dart
// [entity]_state.dart
enum [Entity]Status { initial, loading, success, failure }

class [Entity]State extends Equatable {
  const [Entity]State({
    this.status = [Entity]Status.initial,
    this.[entity]s = const <[Entity]>[],
    this.message,
    this.hasReachedMax = false,
  });

  final [Entity]Status status;
  final List<[Entity]> [entity]s;
  final String? message;
  final bool hasReachedMax;

  [Entity]State copyWith({
    [Entity]Status? status,
    List<[Entity]>? [entity]s,
    String? message,
    bool? hasReachedMax,
  }) {
    return [Entity]State(
      status: status ?? this.status,
      [entity]s: [entity]s ?? this.[entity]s,
      message: message ?? this.message,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [status, [entity]s, message, hasReachedMax];
}
```

## UI Component Patterns

### 1. List View Pattern
```dart
class [Entity]List extends StatefulWidget {
  const [Entity]List({super.key});
  @override
  [Entity]ListState createState() => [Entity]ListState();
}

class [Entity]ListState extends State<[Entity]List> {
  late [Entity]Bloc _[entity]Bloc;
  late String classificationId;

  @override
  void initState() {
    super.initState();
    _[entity]Bloc = context.read<[Entity]Bloc>();
    classificationId = context.read<String>();
    _[entity]Bloc.add(const [Entity]Fetch());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<[Entity]Bloc, [Entity]State>(
      listener: (context, state) {
        if (state.status == [Entity]Status.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case [Entity]Status.failure:
            return Center(child: Text('Failed to fetch [entity]s: ${state.message}'));
          case [Entity]Status.success:
            return RefreshIndicator(
              onRefresh: () async => _[entity]Bloc.add(const [Entity]Fetch(refresh: true)),
              child: ListView.builder(
                itemCount: state.[entity]s.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(state.[entity]s[index].name ?? ''),
                    onTap: () => showDialog(
                      context: context,
                      builder: (context) => BlocProvider.value(
                        value: _[entity]Bloc,
                        child: [Entity]Dialog(state.[entity]s[index]),
                      ),
                    ),
                  );
                },
              ),
            );
          default:
            return const LoadingIndicator();
        }
      },
    );
  }
}
```

### 2. Dialog Pattern with FormBuilder
```dart
class [Entity]Dialog extends StatefulWidget {
  final [Entity] [entity];
  const [Entity]Dialog(this.[entity], {super.key});
  @override
  [Entity]DialogState createState() => [Entity]DialogState();
}

class [Entity]DialogState extends State<[Entity]Dialog> {
  late final GlobalKey<FormBuilderState> _formKey;
  late [Entity]Bloc _[entity]Bloc;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormBuilderState>();
    _[entity]Bloc = context.read<[Entity]Bloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<[Entity]Bloc, [Entity]State>(
      listener: (context, state) {
        switch (state.status) {
          case [Entity]Status.success:
            Navigator.of(context).pop();
          case [Entity]Status.failure:
            HelperFunctions.showMessage(context, '${state.message}', Colors.red);
          default:
        }
      },
      builder: (context, state) {
        if (state.status == [Entity]Status.loading) {
          return const LoadingIndicator();
        }
        
        return Dialog(
          child: FormBuilder(
            key: _formKey,
            child: Column(
              children: [
                FormBuilderTextField(
                  name: 'name',
                  initialValue: widget.[entity].name ?? '',
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                ),
                // Add more fields...
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.saveAndValidate()) {
                      final formData = _formKey.currentState!.value;
                      _[entity]Bloc.add([Entity]Update(
                        widget.[entity].copyWith(
                          name: formData['name'],
                          // Map other fields...
                        ),
                      ));
                    }
                  },
                  child: Text(widget.[entity].id.isEmpty ? 'Create' : 'Update'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

## Testing Patterns

### 1. Integration Test Pattern
```dart
class [Entity]Test {
  static Future<void> select[Entity]s(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'db[Entity]', '[Entity]List', '1');
  }

  static Future<void> add[Entity]s(WidgetTester tester, List<[Entity]> [entity]s) async {
    List<[Entity]> new[Entity]s = await enter[Entity]Data(tester, [entity]s);
    await check[Entity](tester, new[Entity]s);
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith([entity]s: new[Entity]s));
  }

  static Future<List<[Entity]>> enter[Entity]Data(
      WidgetTester tester, List<[Entity]> [entity]s) async {
    List<[Entity]> new[Entity]s = [];
    for ([Entity] [entity] in [entity]s) {
      if ([entity].id.isEmpty) {
        await CommonTest.tapByKey(tester, 'addNew');
      } else {
        await CommonTest.doNewSearch(tester, searchString: [entity].name!);
      }
      
      await CommonTest.enterText(tester, 'name', [entity].name!);
      // Enter other form fields...
      
      await CommonTest.tapByKey(tester, 'update');
      await CommonTest.waitForSnackbarToGo(tester);
      
      if ([entity].id.isEmpty) {
        new[Entity]s.add([entity].copyWith(id: CommonTest.getTextField('id0')));
      } else {
        new[Entity]s.add([entity]);
      }
    }
    return new[Entity]s;
  }

  static Future<List<[Entity]>> check[Entity](
      WidgetTester tester, List<[Entity]> [entity]s) async {
    List<[Entity]> new[Entity]s = [];
    for ([Entity] [entity] in [entity]s) {
      await CommonTest.doNewSearch(tester, searchString: [entity].name!);
      expect(find.byKey(const Key('[Entity]Dialog')), findsOneWidget);
      expect(CommonTest.getFormBuilderTextFieldByName(tester, 'name'), [entity].name);
      // Check other fields...
      new[Entity]s.add([entity]);
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return new[Entity]s;
  }
}
```

## Data Model Patterns

### 1. Freezed Model Pattern
```dart
@freezed
class [Entity] extends Equatable with _$[Entity] {
  const [Entity]._();
  const factory [Entity]({
    @Default("") String id,
    @Default("") String name,
    String? description,
    // Add other fields...
  }) = _[Entity];

  factory [Entity].fromJson(Map<String, dynamic> json) =>
      _$[Entity]FromJson(json['[entity]'] ?? json);

  @override
  List<Object?> get props => [id];

  @override
  String toString() => '$name[$id]';
}
```

### 2. CSV Import/Export Pattern
```dart
String [entity]CsvFormat = 'id, name, description\r\n';
List<String> [entity]CsvTitles = [entity]CsvFormat.split(',');
int [entity]CsvLength = [entity]CsvTitles.length;

List<[Entity]> csvTo[Entity]s(String csvFile) {
  List<[Entity]> [entity]s = [];
  final result = fast_csv.parse(csvFile);
  for (final row in result) {
    if (row == result.first) continue;
    [entity]s.add([Entity](
      id: row[0],
      name: row[1],
      description: row[2],
    ));
  }
  return [entity]s;
}

String csvFrom[Entity]s(List<[Entity]> [entity]s) {
  var csv = [[entity]CsvFormat];
  for ([Entity] [entity] in [entity]s) {
    csv.add(createCsvRow([
      [entity].id,
      [entity].name,
      [entity].description ?? '',
    ], [entity]CsvLength));
  }
  return csv.join();
}
```

## API Integration Patterns

### 1. REST Client Method Pattern
```dart
@GET("rest/s1/growerp/100/[Entity]s")
Future<[Entity]s> get[Entity]s({
  @Query('start') int? start,
  @Query('limit') int? limit,
  @Query('search') String? searchString,
});

@POST("rest/s1/growerp/100/[Entity]")
Future<[Entity]> create[Entity]({@Field() required [Entity] [entity]});

@PATCH("rest/s1/growerp/100/[Entity]")
Future<[Entity]> update[Entity]({@Field() required [Entity] [entity]});

@DELETE("rest/s1/growerp/100/[Entity]")
Future<[Entity]> delete[Entity]({@Field() required [Entity] [entity]});
```

## Form Handling Patterns

### 1. FormBuilder Field Patterns
```dart
// Text Field
FormBuilderTextField(
  name: 'fieldName',
  key: const Key('fieldName'),
  initialValue: widget.entity.fieldValue ?? '',
  decoration: const InputDecoration(labelText: 'Field Label'),
  validator: FormBuilderValidators.compose([
    FormBuilderValidators.required(),
  ]),
),

// Dropdown Field
FormBuilderDropdown<String>(
  name: 'fieldName',
  key: const Key('fieldName'),
  initialValue: widget.entity.fieldValue,
  decoration: const InputDecoration(labelText: 'Field Label'),
  validator: FormBuilderValidators.compose([
    FormBuilderValidators.required(),
  ]),
  items: options.map((item) {
    return DropdownMenuItem<String>(
      value: item,
      child: Text(item),
    );
  }).toList(),
  onChanged: (String? newValue) {
    setState(() {
      selectedValue = newValue!;
    });
  },
),
```

## Key Principles

1. **Consistency**: All similar components follow the same pattern
2. **Separation of Concerns**: Clear boundaries between layers
3. **Reusability**: Components can be easily reused across domains
4. **Testability**: All components have corresponding test patterns
5. **Type Safety**: Use strongly typed models and generics
6. **Error Handling**: Consistent error handling across all components
7. **State Management**: BLoC for all business logic
8. **Form Validation**: FormBuilder with validators for all forms

## Usage Guidelines

When creating new features:
1. Follow the package structure pattern
2. Use the appropriate BLoC pattern for state management
3. Implement both list and dialog views following the UI patterns
4. Create corresponding test classes following the testing patterns
5. Use Freezed for data models
6. Implement CSV import/export if applicable
7. Follow the API integration patterns for backend communication

This ensures consistency across the entire GrowERP ecosystem and enables AI tools to generate code that follows established patterns.
