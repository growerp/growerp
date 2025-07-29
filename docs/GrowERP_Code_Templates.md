# GrowERP Code Generation Templates

This file contains ready-to-use templates for generating new components in GrowERP following the established design patterns.

## Quick Generation Commands

Use these templates by replacing `[Entity]` with your actual entity name (e.g., Product, User, Order).

### 1. Generate New Domain Package Structure

```bash
mkdir -p flutter/packages/growerp_[domain]/lib/src/[entity]/{blocs,views,widgets,integration_test}
mkdir -p flutter/packages/growerp_[domain]/example/integration_test
```

### 2. BLoC Files Generation

#### [entity]_bloc.dart
```dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

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
      final result = await restClient.get[Entity]s(
        searchString: event.searchString,
        limit: event.limit,
      );
      emit(state.copyWith(
        status: [Entity]Status.success,
        [entity]s: event.refresh ? result.[entity]s : state.[entity]s + result.[entity]s,
        hasReachedMax: result.[entity]s.length < event.limit,
      ));
    } catch (error) {
      emit(state.copyWith(
        status: [Entity]Status.failure,
        message: error.toString(),
      ));
    }
  }

  Future<void> _on[Entity]Update([Entity]Update event, Emitter<[Entity]State> emit) async {
    emit(state.copyWith(status: [Entity]Status.loading));
    try {
      final [entity] = event.[entity].id.isEmpty
          ? await restClient.create[Entity]([entity]: event.[entity])
          : await restClient.update[Entity]([entity]: event.[entity]);
      
      final updated[Entity]s = List<[Entity]>.from(state.[entity]s);
      final index = updated[Entity]s.indexWhere((p) => p.id == [entity].id);
      
      if (index >= 0) {
        updated[Entity]s[index] = [entity];
      } else {
        updated[Entity]s.insert(0, [entity]);
      }

      emit(state.copyWith(
        status: [Entity]Status.success,
        [entity]s: updated[Entity]s,
        message: '[Entity] ${event.[entity].id.isEmpty ? 'created' : 'updated'} successfully',
      ));
    } catch (error) {
      emit(state.copyWith(
        status: [Entity]Status.failure,
        message: error.toString(),
      ));
    }
  }

  Future<void> _on[Entity]Delete([Entity]Delete event, Emitter<[Entity]State> emit) async {
    emit(state.copyWith(status: [Entity]Status.loading));
    try {
      await restClient.delete[Entity]([entity]: event.[entity]);
      final updated[Entity]s = state.[entity]s.where((p) => p.id != event.[entity].id).toList();
      emit(state.copyWith(
        status: [Entity]Status.success,
        [entity]s: updated[Entity]s,
        message: '[Entity] deleted successfully',
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

#### [entity]_event.dart
```dart
part of '[entity]_bloc.dart';

abstract class [Entity]Event extends Equatable {
  const [Entity]Event();
  @override
  List<Object> get props => [];
}

class [Entity]Fetch extends [Entity]Event {
  const [Entity]Fetch({
    this.searchString = '',
    this.refresh = false,
    this.limit = 20,
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

#### [entity]_state.dart
```dart
part of '[entity]_bloc.dart';

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

### 3. UI Component Templates

#### [entity]_list.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../[entity].dart';

class [Entity]List extends StatefulWidget {
  const [Entity]List({super.key});
  @override
  [Entity]ListState createState() => [Entity]ListState();
}

class [Entity]ListState extends State<[Entity]List> {
  late [Entity]Bloc _[entity]Bloc;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _[entity]Bloc = context.read<[Entity]Bloc>();
    _scrollController = ScrollController()..addListener(_onScroll);
    _[entity]Bloc.add(const [Entity]Fetch());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _[entity]Bloc.add(const [Entity]Fetch());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<[Entity]Bloc, [Entity]State>(
      listener: (context, state) {
        if (state.status == [Entity]Status.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == [Entity]Status.success && state.message != null) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.green);
        }
      },
      builder: (context, state) {
        switch (state.status) {
          case [Entity]Status.failure:
            return Center(
              child: Text('Failed to fetch [entity]s: ${state.message}'),
            );
          case [Entity]Status.success:
            return Scaffold(
              appBar: AppBar(
                title: const Text('[Entity]s'),
                actions: [
                  IconButton(
                    key: const Key('search'),
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      // Implement search functionality
                    },
                  ),
                ],
              ),
              body: RefreshIndicator(
                onRefresh: () async => _[entity]Bloc.add(const [Entity]Fetch(refresh: true)),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: state.hasReachedMax
                      ? state.[entity]s.length
                      : state.[entity]s.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= state.[entity]s.length) {
                      return const BottomLoader();
                    }
                    final [entity] = state.[entity]s[index];
                    return Card(
                      key: Key('[entity]Item$index'),
                      child: ListTile(
                        title: Text([entity].name ?? ''),
                        subtitle: Text([entity].description ?? ''),
                        trailing: IconButton(
                          key: Key('delete$index'),
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _[entity]Bloc.add([Entity]Delete([entity]));
                          },
                        ),
                        onTap: () => showDialog(
                          context: context,
                          builder: (context) => BlocProvider.value(
                            value: _[entity]Bloc,
                            child: [Entity]Dialog([entity]),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              floatingActionButton: FloatingActionButton(
                key: const Key('addNew'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => BlocProvider.value(
                    value: _[entity]Bloc,
                    child: const [Entity]Dialog([Entity]()),
                  ),
                ),
                child: const Icon(Icons.add),
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

#### [entity]_dialog.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

import '../[entity].dart';

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
          key: const Key('[Entity]Dialog'),
          insetPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: popUp(
            context: context,
            title: '[Entity] #${widget.[entity].id.isEmpty ? 'New' : widget.[entity].id}',
            height: 400,
            width: 600,
            child: _buildForm(),
          ),
        );
      },
    );
  }

  Widget _buildForm() {
    return FormBuilder(
      key: _formKey,
      child: Column(
        children: [
          FormBuilderTextField(
            name: 'name',
            key: const Key('name'),
            initialValue: widget.[entity].name ?? '',
            decoration: const InputDecoration(labelText: 'Name'),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'description',
            key: const Key('description'),
            initialValue: widget.[entity].description ?? '',
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  key: const Key('update'),
                  onPressed: () {
                    if (_formKey.currentState!.saveAndValidate()) {
                      final formData = _formKey.currentState!.value;
                      _[entity]Bloc.add([Entity]Update(
                        widget.[entity].copyWith(
                          name: formData['name'],
                          description: formData['description'],
                        ),
                      ));
                    }
                  },
                  child: Text(widget.[entity].id.isEmpty ? 'Create' : 'Update'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 4. Test Template

#### [entity]_test.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class [Entity]Test {
  static Future<void> select[Entity]s(WidgetTester tester) async {
    await CommonTest.selectOption(tester, 'db[Entity]', '[Entity]List', '1');
  }

  static Future<void> add[Entity]s(WidgetTester tester, List<[Entity]> [entity]s,
      {bool check = true}) async {
    List<[Entity]> new[Entity]s = await enter[Entity]Data(tester, [entity]s);
    if (check) await check[Entity](tester, new[Entity]s);
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
        expect(CommonTest.getTextField('topHeader').split('#')[1], [entity].id);
      }

      await CommonTest.enterText(tester, 'name', [entity].name!);
      if ([entity].description != null) {
        await CommonTest.enterText(tester, 'description', [entity].description!);
      }

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
      var id = CommonTest.getTextField('topHeader').split('#')[1];
      expect(find.byKey(const Key('[Entity]Dialog')), findsOneWidget);
      expect(CommonTest.getFormBuilderTextFieldByName(tester, 'name'), [entity].name);
      if ([entity].description != null) {
        expect(CommonTest.getFormBuilderTextFieldByName(tester, 'description'), [entity].description);
      }
      new[Entity]s.add([entity].copyWith(id: id));
      await CommonTest.tapByKey(tester, 'cancel');
    }
    await CommonTest.closeSearch(tester);
    return new[Entity]s;
  }

  static Future<void> updateProducts(WidgetTester tester, List<[Entity]> [entity]s,
      {bool check = true}) async {
    List<[Entity]> mod[Entity]s = await enter[Entity]Data(tester, [entity]s);
    if (check) await check[Entity](tester, mod[Entity]s);
    SaveTest test = await PersistFunctions.getTest();
    await PersistFunctions.persistTest(test.copyWith([entity]s: mod[Entity]s));
  }

  static Future<void> deleteLast[Entity](WidgetTester tester) async {
    SaveTest test = await PersistFunctions.getTest();
    int count = test.[entity]s.length;
    await CommonTest.gotoMainMenu(tester);
    await [Entity]Test.select[Entity]s(tester);
    expect(find.byKey(const Key('[entity]Item')), findsNWidgets(count));
    await CommonTest.tapByKey(tester, 'delete${count - 2}');
    await CommonTest.gotoMainMenu(tester);
    await [Entity]Test.select[Entity]s(tester);
    expect(find.byKey(const Key('[entity]Item')), findsNWidgets(count - 1));
    await PersistFunctions.persistTest(test.copyWith(
        [entity]s: test.[entity]s.sublist(0, test.[entity]s.length - 1)));
  }
}
```

### 5. Model Template (Freezed)

#### [entity]_model.dart
```dart
import 'package:equatable/equatable.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fast_csv/fast_csv.dart' as fast_csv;

part '[entity]_model.freezed.dart';
part '[entity]_model.g.dart';

@freezed
class [Entity] extends Equatable with _$[Entity] {
  const [Entity]._();
  const factory [Entity]({
    @Default("") String id,
    @Default("") String name,
    String? description,
    // Add other fields as needed
  }) = _[Entity];

  factory [Entity].fromJson(Map<String, dynamic> json) =>
      _$[Entity]FromJson(json['[entity]'] ?? json);

  @override
  List<Object?> get props => [id];

  @override
  String toString() => '$name[$id]';
}

// CSV Import/Export
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
      [entity].name ?? '',
      [entity].description ?? '',
    ], [entity]CsvLength));
  }
  return csv.join();
}
```

### 6. REST Client Integration

Add to rest_client.dart:
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

## Usage Instructions

1. **Replace Placeholders**: Replace all instances of `[Entity]` and `[entity]` with your actual entity names
2. **Update Dependencies**: Add necessary imports and dependencies
3. **Customize Fields**: Add specific fields and business logic for your entity
4. **Generate Code**: Run code generation for Freezed models: `flutter packages pub run build_runner build`
5. **Test**: Create integration tests following the test patterns

This template system ensures consistency across all GrowERP components and makes it easy for AI tools to generate new features following established patterns.
