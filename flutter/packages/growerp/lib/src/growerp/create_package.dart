/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

import 'dart:async';
import 'dart:io';
import 'package:dcli/dcli.dart';
import 'package:logger/logger.dart';

final _logger = Logger(filter: ProductionFilter());

/// Creates a new GrowERP package with both Flutter frontend and Moqui backend component.
///
/// The [packageName] should be lowercase without the 'growerp_' prefix.
/// The [growerpPath] is the root path of the GrowERP installation.
void createPackage(String packageName, String growerpPath) {
  // Validate package name
  final validNameRegex = RegExp(r'^[a-z][a-z0-9_]*$');
  if (!validNameRegex.hasMatch(packageName)) {
    _logger.e(
      'Invalid package name: $packageName\n'
      'Package name must be lowercase, start with a letter, '
      'and contain only letters, numbers, and underscores.',
    );
    exit(1);
  }

  final flutterPackageName = 'growerp_$packageName';
  final moquiComponentName = 'growerp-$packageName';
  final pascalCaseName = _toPascalCase(packageName);
  final upperCaseName = packageName.toUpperCase();

  final flutterPath = '$growerpPath/flutter/packages/$flutterPackageName';
  final moquiPath = '$growerpPath/moqui/runtime/component/$moquiComponentName';

  // Check if paths already exist
  if (exists(flutterPath)) {
    _logger.e('Flutter package already exists: $flutterPath');
    exit(1);
  }
  if (exists(moquiPath)) {
    _logger.e('Moqui component already exists: $moquiPath');
    exit(1);
  }

  _logger.i('Creating GrowERP package: $packageName');
  _logger.i('  Flutter package: $flutterPackageName');
  _logger.i('  Moqui component: $moquiComponentName');

  // Create Flutter package
  _createFlutterPackage(
    flutterPath,
    flutterPackageName,
    packageName,
    pascalCaseName,
  );

  // Create Moqui component
  _createMoquiComponent(
    moquiPath,
    moquiComponentName,
    packageName,
    pascalCaseName,
    upperCaseName,
  );

  // Add package to melos.yaml
  _addToMelosYaml(growerpPath, flutterPackageName);

  _logger.i('\n✅ Package created successfully!');
  Zone.root.run(() {
    // ignore: avoid_print
    print('\nNext steps:');
    // ignore: avoid_print
    print('  1. Run: cd $growerpPath/flutter && melos bootstrap');
    // ignore: avoid_print
    print('  2. Run: cd $growerpPath/flutter && melos build');
    // ignore: avoid_print
    print(
      '  3. Load seed data: cd $growerpPath/moqui && java -jar moqui.war load types=seed,seed-initial',
    );
    // ignore: avoid_print
    print('  4. Restart backend: cd $growerpPath/moqui && java -jar moqui.war');
    // ignore: avoid_print
    print('  5. Run example app: cd $flutterPath/example && flutter run');
  });
}

String _toPascalCase(String input) {
  return input.split('_').map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1);
  }).join();
}

/// Adds the new package to flutter/melos.yaml
void _addToMelosYaml(String growerpPath, String flutterPackageName) {
  final melosPath = '$growerpPath/flutter/melos.yaml';

  if (!exists(melosPath)) {
    _logger.w('Warning: melos.yaml not found at $melosPath');
    return;
  }

  final content = read(melosPath).toList().join('\n');
  final lines = content.split('\n');

  // Find the packages section
  int packagesStartIndex = -1;
  int packagesEndIndex = -1;

  for (int i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trim();
    if (trimmed == 'packages:') {
      packagesStartIndex = i;
    } else if (packagesStartIndex != -1 && packagesEndIndex == -1) {
      // Check if this line is still part of packages section (starts with - and indentation)
      if (trimmed.startsWith('-') && lines[i].startsWith('  ')) {
        continue;
      } else if (trimmed.isEmpty) {
        // Empty line might be within or after the section
        continue;
      } else if (!lines[i].startsWith('  ')) {
        // New section starts - packages section ended at previous line
        packagesEndIndex = i;
        break;
      }
    }
  }

  if (packagesStartIndex == -1) {
    _logger.w('Warning: packages section not found in melos.yaml');
    return;
  }

  // If we didn't find an end, it means packages go to end of file
  if (packagesEndIndex == -1) {
    packagesEndIndex = lines.length;
  }

  // Find where to insert the new package entries
  // growerp_* packages should be grouped together followed by example apps
  // Non-growerp packages come after

  final packageEntry = '  - packages/$flutterPackageName';
  final exampleEntry = '  - packages/$flutterPackageName/example';

  // Check if already exists
  if (content.contains(packageEntry)) {
    _logger.i('  ✓ Package already in melos.yaml');
    return;
  }

  // Find the insertion point - after the last growerp_* package/example, before non-growerp packages
  int insertIndex = packagesEndIndex;

  for (int i = packagesStartIndex + 1; i < packagesEndIndex; i++) {
    final trimmed = lines[i].trim();
    if (trimmed.isEmpty) continue;

    // Extract package name from line like "  - packages/packagename"
    if (trimmed.startsWith('- packages/')) {
      final pkgName = trimmed.substring('- packages/'.length);
      // If this is NOT a growerp_ package and NOT an example, we should insert before it
      if (!pkgName.startsWith('growerp_') && !pkgName.contains('/example')) {
        insertIndex = i;
        break;
      }
    }
  }

  // Insert the new entries
  lines.insert(insertIndex, exampleEntry);
  lines.insert(insertIndex, packageEntry);

  // Write back to file
  melosPath.write(lines.join('\n'));

  _logger.i('  ✓ Added to melos.yaml: $flutterPackageName');
}

void _createFlutterPackage(
  String path,
  String packageName,
  String baseName,
  String pascalCaseName,
) {
  // Create directory structure
  createDir('$path/lib/src/models', recursive: true);
  createDir('$path/lib/src/bloc', recursive: true);
  createDir('$path/lib/src/repository', recursive: true);
  createDir('$path/lib/src/views', recursive: true);
  createDir('$path/lib/l10n', recursive: true);
  createDir('$path/example/lib', recursive: true);
  createDir('$path/example/integration_test', recursive: true);
  createDir('$path/example/assets/cfg', recursive: true);

  // pubspec.yaml
  '$path/pubspec.yaml'.write(_flutterPubspec(packageName, baseName));

  // build.yaml for build_runner configuration
  '$path/build.yaml'.write(_flutterBuildYaml());

  // Main library export
  '$path/lib/$packageName.dart'.write(
    _flutterMainExport(baseName, pascalCaseName),
  );

  // Demo model
  '$path/lib/src/models/demo_model.dart'.write(
    _flutterDemoModel(pascalCaseName),
  );
  '$path/lib/src/models/models.dart'.write("export 'demo_model.dart';\n");

  // Demo repository
  '$path/lib/src/repository/demo_repository.dart'.write(
    _flutterDemoRepository(baseName, pascalCaseName),
  );
  '$path/lib/src/repository/repository.dart'.write(
    "export 'demo_repository.dart';\n",
  );

  // Demo BLoC
  '$path/lib/src/bloc/demo_bloc.dart'.write(_flutterDemoBloc(pascalCaseName));
  '$path/lib/src/bloc/bloc.dart'.write("export 'demo_bloc.dart';\n");

  // Demo view
  '$path/lib/src/views/demo_list_screen.dart'.write(
    _flutterDemoListScreen(pascalCaseName),
  );
  '$path/lib/src/views/views.dart'.write("export 'demo_list_screen.dart';\n");

  // Integration test class
  createDir('$path/lib/src/integration_test', recursive: true);
  '$path/lib/src/integration_test/demo_test.dart'.write(
    _flutterDemoTestClass(pascalCaseName),
  );

  // Example app
  '$path/example/pubspec.yaml'.write(
    _flutterExamplePubspec(packageName, baseName),
  );
  '$path/example/lib/main.dart'.write(
    _flutterExampleMain(packageName, pascalCaseName),
  );

  // Integration test
  '$path/example/integration_test/demo_test.dart'.write(
    _flutterIntegrationTest(packageName, pascalCaseName),
  );

  // Example assets configuration
  '$path/example/assets/cfg/app_settings.json'.write(
    _flutterExampleAppSettings(),
  );

  // README
  '$path/README.md'.write(
    '# $packageName\n\nA GrowERP package for $baseName functionality.\n',
  );

  // l10n.yaml
  '$path/l10n.yaml'.write(_flutterL10nYaml(baseName));

  // ARB file
  '$path/lib/l10n/intl_en.arb'.write(_flutterArbFile(baseName, pascalCaseName));

  _logger.i('  ✓ Created Flutter package: $path');
}

void _createMoquiComponent(
  String path,
  String componentName,
  String baseName,
  String pascalCaseName,
  String upperCaseName,
) {
  // Create directory structure
  createDir('$path/entity', recursive: true);
  createDir('$path/service', recursive: true);
  createDir('$path/data', recursive: true);

  // component.xml
  '$path/component.xml'.write(_moquiComponentXml(componentName));

  // Entity definition
  '$path/entity/${pascalCaseName}Entities.xml'.write(
    _moquiEntityXml(baseName, pascalCaseName),
  );

  // Service definition
  '$path/service/${pascalCaseName}Services.xml'.write(
    _moquiServiceXml(baseName, pascalCaseName),
  );

  // REST API - package-specific endpoint
  '$path/service/$baseName.rest.xml'.write(
    _moquiRestXml(baseName, pascalCaseName),
  );

  // Seed data
  '$path/data/${pascalCaseName}SeedData.xml'.write(
    _moquiSeedDataXml(baseName, pascalCaseName),
  );

  // Security data
  '$path/data/${pascalCaseName}SecurityData.xml'.write(
    _moquiSecurityDataXml(baseName, pascalCaseName, upperCaseName),
  );

  // README
  '$path/README.md'.write(
    '# $componentName\n\nMoqui component for $baseName functionality.\n',
  );

  _logger.i('  ✓ Created Moqui component: $path');
}

// ============================================================================
// Flutter Template Functions
// ============================================================================

String _flutterPubspec(String packageName, String baseName) =>
    '''
name: $packageName
description: GrowERP $baseName package
version: 1.0.0
homepage: https://www.growerp.com
repository: https://github.com/growerp/growerp

environment:
  sdk: ^3.9.0
  flutter: ^3.33.0

dependencies:
  growerp_core:
    path: ../growerp_core
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.4
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  dio: ^5.4.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^2.4.8
  freezed: ^3.2.0
  json_serializable: ^6.10.0
  retrofit_generator: 10.0.6
  flutter_lints: ^6.0.0

# Override to use local packages during development
dependency_overrides:
  growerp_models:
    path: ../growerp_models
  growerp_core:
    path: ../growerp_core
  growerp_chat:
    path: ../growerp_chat
  growerp_activity:
    path: ../growerp_activity

flutter:
  uses-material-design: true
  generate: true
''';

String _flutterBuildYaml() => '''
targets:
  \$default:
    sources:
      include:
        - lib/**
      exclude:
        - example/**
    builders:
      retrofit_generator:
        enabled: true
        generate_for:
          include:
            - lib/**
      freezed:
        enabled: true
        generate_for:
          include:
            - lib/**
      json_serializable:
        enabled: true
        generate_for:
          include:
            - lib/**
''';

String _flutterMainExport(String baseName, String pascalCaseName) => '''
export 'src/models/models.dart';
export 'src/bloc/bloc.dart';
export 'src/repository/repository.dart';
export 'src/views/views.dart';
export 'src/integration_test/demo_test.dart';
''';

String _flutterDemoModel(String pascalCaseName) =>
    '''
import 'package:freezed_annotation/freezed_annotation.dart';

part 'demo_model.freezed.dart';
part 'demo_model.g.dart';

@freezed
abstract class ${pascalCaseName}Demo with _\$${pascalCaseName}Demo {
  ${pascalCaseName}Demo._();
  factory ${pascalCaseName}Demo({
    String? demoId,
    String? pseudoId,
    required String message,
    String? description,
    DateTime? createdDate,
  }) = _${pascalCaseName}Demo;

  factory ${pascalCaseName}Demo.fromJson(Map<String, dynamic> json) =>
      _\$${pascalCaseName}DemoFromJson(json);
}
''';

String _flutterDemoRepository(String baseName, String pascalCaseName) =>
    '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'demo_repository.g.dart';

@RestApi()
abstract class ${pascalCaseName}Repository {
  factory ${pascalCaseName}Repository(Dio dio, {String? baseUrl}) = _${pascalCaseName}Repository;

  @GET('/rest/s1/$baseName/100/${pascalCaseName}Demo')
  Future<String> getDemos({
    @Query('start') int? start,
    @Query('limit') int? limit,
  });

  @POST('/rest/s1/$baseName/100/${pascalCaseName}Demo')
  Future<String> createDemo(@Body() Map<String, dynamic> body);

  @PATCH('/rest/s1/$baseName/100/${pascalCaseName}Demo')
  Future<String> updateDemo(@Body() Map<String, dynamic> body);

  @DELETE('/rest/s1/$baseName/100/${pascalCaseName}Demo')
  Future<String> deleteDemo({@Query('demoId') required String demoId});
}
''';

String _flutterDemoBloc(String pascalCaseName) =>
    '''
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/models.dart';
import '../repository/repository.dart';

// Events
abstract class ${pascalCaseName}DemoEvent extends Equatable {
  const ${pascalCaseName}DemoEvent();

  @override
  List<Object?> get props => [];
}

class ${pascalCaseName}DemoFetch extends ${pascalCaseName}DemoEvent {}

class ${pascalCaseName}DemoCreate extends ${pascalCaseName}DemoEvent {
  final ${pascalCaseName}Demo demo;
  const ${pascalCaseName}DemoCreate(this.demo);

  @override
  List<Object?> get props => [demo];
}

class ${pascalCaseName}DemoUpdate extends ${pascalCaseName}DemoEvent {
  final ${pascalCaseName}Demo demo;
  const ${pascalCaseName}DemoUpdate(this.demo);

  @override
  List<Object?> get props => [demo];
}

class ${pascalCaseName}DemoDelete extends ${pascalCaseName}DemoEvent {
  final String demoId;
  const ${pascalCaseName}DemoDelete(this.demoId);

  @override
  List<Object?> get props => [demoId];
}

// States
abstract class ${pascalCaseName}DemoState extends Equatable {
  const ${pascalCaseName}DemoState();

  @override
  List<Object?> get props => [];
}

class ${pascalCaseName}DemoInitial extends ${pascalCaseName}DemoState {}

class ${pascalCaseName}DemoLoading extends ${pascalCaseName}DemoState {}

class ${pascalCaseName}DemoLoaded extends ${pascalCaseName}DemoState {
  final List<${pascalCaseName}Demo> demos;
  const ${pascalCaseName}DemoLoaded(this.demos);

  @override
  List<Object?> get props => [demos];
}

class ${pascalCaseName}DemoError extends ${pascalCaseName}DemoState {
  final String message;
  const ${pascalCaseName}DemoError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ${pascalCaseName}DemoBloc extends Bloc<${pascalCaseName}DemoEvent, ${pascalCaseName}DemoState> {
  final ${pascalCaseName}Repository repository;

  ${pascalCaseName}DemoBloc({required this.repository}) : super(${pascalCaseName}DemoInitial()) {
    on<${pascalCaseName}DemoFetch>(_onFetch);
    on<${pascalCaseName}DemoCreate>(_onCreate);
    on<${pascalCaseName}DemoUpdate>(_onUpdate);
    on<${pascalCaseName}DemoDelete>(_onDelete);
  }

  Future<void> _onFetch(
    ${pascalCaseName}DemoFetch event,
    Emitter<${pascalCaseName}DemoState> emit,
  ) async {
    emit(${pascalCaseName}DemoLoading());
    try {
      final response = await repository.getDemos();
      final data = json.decode(response) as Map<String, dynamic>;
      final demoList = (data['demos'] as List?)
          ?.map((e) => ${pascalCaseName}Demo.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      emit(${pascalCaseName}DemoLoaded(demoList));
    } catch (e) {
      emit(${pascalCaseName}DemoError(e.toString()));
    }
  }

  Future<void> _onCreate(
    ${pascalCaseName}DemoCreate event,
    Emitter<${pascalCaseName}DemoState> emit,
  ) async {
    try {
      await repository.createDemo({
        'demo': {
          'message': event.demo.message,
          'description': event.demo.description,
        }
      });
      add(${pascalCaseName}DemoFetch()); // Refresh list
    } catch (e) {
      emit(${pascalCaseName}DemoError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    ${pascalCaseName}DemoUpdate event,
    Emitter<${pascalCaseName}DemoState> emit,
  ) async {
    try {
      await repository.updateDemo({
        'demo': {
          'demoId': event.demo.demoId,
          'message': event.demo.message,
          'description': event.demo.description,
        }
      });
      add(${pascalCaseName}DemoFetch()); // Refresh list
    } catch (e) {
      emit(${pascalCaseName}DemoError(e.toString()));
    }
  }

  Future<void> _onDelete(
    ${pascalCaseName}DemoDelete event,
    Emitter<${pascalCaseName}DemoState> emit,
  ) async {
    try {
      await repository.deleteDemo(demoId: event.demoId);
      add(${pascalCaseName}DemoFetch()); // Refresh list
    } catch (e) {
      emit(${pascalCaseName}DemoError(e.toString()));
    }
  }
}
''';

String _flutterDemoListScreen(String pascalCaseName) =>
    '''
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';
import '../models/models.dart';

class ${pascalCaseName}DemoListScreen extends StatefulWidget {
  const ${pascalCaseName}DemoListScreen({super.key});

  @override
  State<${pascalCaseName}DemoListScreen> createState() => _${pascalCaseName}DemoListScreenState();
}

class _${pascalCaseName}DemoListScreenState extends State<${pascalCaseName}DemoListScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data when screen loads
    context.read<${pascalCaseName}DemoBloc>().add(${pascalCaseName}DemoFetch());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
            tooltip: 'Add Demo Item',
          ),
        ],
      ),
      body: BlocBuilder<${pascalCaseName}DemoBloc, ${pascalCaseName}DemoState>(
        builder: (context, state) {
          if (state is ${pascalCaseName}DemoLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ${pascalCaseName}DemoError) {
            return Center(child: Text('Error: \${state.message}'));
          }
          if (state is ${pascalCaseName}DemoLoaded) {
            if (state.demos.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.waving_hand, size: 64, color: Colors.blue),
                    SizedBox(height: 16),
                    Text(
                      'Hello World!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('No demo items yet. Tap + in the app bar to create one!'),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: state.demos.length,
              itemBuilder: (context, index) {
                final demo = state.demos[index];
                return ListTile(
                  title: Text(demo.message),
                  subtitle: Text(demo.description ?? demo.pseudoId ?? ''),
                  leading: const Icon(Icons.message),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditDialog(context, demo),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _showDeleteDialog(context, demo),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final messageController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('AddDemoDialog'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        title: const Text('Add Demo Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message *',
                hintText: 'Enter a message',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter a description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                context.read<${pascalCaseName}DemoBloc>().add(
                      ${pascalCaseName}DemoCreate(
                        ${pascalCaseName}Demo(
                          message: messageController.text,
                          description: descriptionController.text.isNotEmpty
                              ? descriptionController.text
                              : null,
                        ),
                      ),
                    );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, ${pascalCaseName}Demo demo) {
    final messageController = TextEditingController(text: demo.message);
    final descriptionController = TextEditingController(text: demo.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('EditDemoDialog'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        title: const Text('Edit Demo Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message *',
                hintText: 'Enter a message',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter a description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                context.read<${pascalCaseName}DemoBloc>().add(
                      ${pascalCaseName}DemoUpdate(
                        ${pascalCaseName}Demo(
                          demoId: demo.demoId,
                          pseudoId: demo.pseudoId,
                          message: messageController.text,
                          description: descriptionController.text.isNotEmpty
                              ? descriptionController.text
                              : null,
                        ),
                      ),
                    );
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ${pascalCaseName}Demo demo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('DeleteDemoDialog'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        title: const Text('Delete Demo Item'),
        content: Text('Are you sure you want to delete "\${demo.message}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (demo.demoId != null) {
                context.read<${pascalCaseName}DemoBloc>().add(
                      ${pascalCaseName}DemoDelete(demo.demoId!),
                    );
              }
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
''';

String _flutterExamplePubspec(String packageName, String baseName) =>
    '''
name: ${packageName}_example
description: Example app for $packageName

publish_to: 'none'

environment:
  sdk: ^3.9.0
  flutter: ^3.33.0

dependencies:
  $packageName:
    path: ../
  growerp_core:
    path: ../../growerp_core
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.4
  dio: ^5.4.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0

# Override to use local packages during development
dependency_overrides:
  growerp_models:
    path: ../../growerp_models
  growerp_core:
    path: ../../growerp_core
  growerp_chat:
    path: ../../growerp_chat
  growerp_activity:
    path: ../../growerp_activity

flutter:
  uses-material-design: true
  assets:
  - assets/cfg/
''';

String _flutterExampleAppSettings() => '''
{
    "appName": "", "packageName":"", "version": "", "build": "",
    "classificationId": "AppAdmin",
    "_________________comment__backend": "moqui / ofbiz",
    "backend": "moqui",
    "_________________comment__production url NOT _end forwardslash!": "https://rest.example.com",
    "databaseUrl": "https://backend.growerp.local",
    "chatUrl": "wss://chat.growerp.local",
    "__________________leave empty for local system, use https://test.growerp.org for our test system":"",
    "databaseUrlDebug": "",
    "chatUrlDebug": "",
    "____________": "show debug banner on top right ",
    "test": false,
    "_____________": "If defined the system is used for a single company and this is the partyId of the main internal organization",
    "singleCompany": "",
    "_________________comment__time outs on rest interface connect, receive___": "in seconds for development and production",
    "connectTimeoutProd": 30,
    "receiveTimeoutProd": 300,
    "connectTimeoutTest": 30,
    "receiveTimeoutTest": 600,
    "_________________comment_restRequestsLogs": "show logging of requests",
    "restRequestLogs": false,
    "_________________comment_restResponseLogs": "show logging of responses",
    "restResponseLogs": false 
}
''';

String _flutterExampleMain(String packageName, String pascalCaseName) =>
    '''
/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

// ignore_for_file: depend_on_referenced_packages
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:$packageName/$packageName.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GlobalConfiguration().loadFromAsset('app_settings');

  Bloc.observer = AppBlocObserver();
  final dio = await buildDioClient();
  RestClient restClient = RestClient(dio);
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  runApp(
    TopApp(
      restClient: restClient,
      classificationId: 'AppAdmin',
      chatClient: chatClient,
      notificationClient: notificationClient,
      title: 'GrowERP $pascalCaseName Example',
      router: create${pascalCaseName}ExampleRouter(dio),
      extraBlocProviders: get${pascalCaseName}BlocProviders(dio),
    ),
  );
}

/// Get BLoC providers for $pascalCaseName
List<BlocProvider> get${pascalCaseName}BlocProviders(Dio dio) {
  final repository = ${pascalCaseName}Repository(dio);
  return [
    BlocProvider<${pascalCaseName}DemoBloc>(
      create: (context) => ${pascalCaseName}DemoBloc(repository: repository),
    ),
  ];
}

/// Static menu configuration
const ${pascalCaseName.toLowerCase()}MenuConfig = MenuConfiguration(
  menuConfigurationId: '${pascalCaseName.toUpperCase()}_EXAMPLE',
  appId: '${pascalCaseName.toLowerCase()}_example',
  name: '$pascalCaseName Example Menu',
  menuItems: [
    MenuItem(
      menuItemId: '${pascalCaseName.toUpperCase()}_MAIN',
      title: 'Dashboard',
      route: '/',
      iconName: 'dashboard',
      sequenceNum: 10,
      widgetName: '${pascalCaseName}Dashboard',
    ),
    MenuItem(
      menuItemId: '${pascalCaseName.toUpperCase()}_DEMOS',
      title: 'Demo Items',
      route: '/demos',
      iconName: 'list',
      sequenceNum: 20,
      widgetName: '${pascalCaseName}DemoListScreen',
    ),
  ],
);

/// Creates a static go_router for the example app
GoRouter create${pascalCaseName}ExampleRouter(Dio dio) {
  return createStaticAppRouter(
    menuConfig: ${pascalCaseName.toLowerCase()}MenuConfig,
    appTitle: 'GrowERP $pascalCaseName Example',
    dashboard: const ${pascalCaseName}Dashboard(),
    widgetBuilder: (route) => switch (route) {
      '/demos' => const ${pascalCaseName}DemoListScreen(),
      _ => const ${pascalCaseName}Dashboard(),
    },
  );
}

/// Simple dashboard for example
class ${pascalCaseName}Dashboard extends StatelessWidget {
  const ${pascalCaseName}Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status != AuthStatus.authenticated) {
          return const LoadingIndicator();
        }

        final dashboardItems = ${pascalCaseName.toLowerCase()}MenuConfig.menuItems
            .where((item) => item.route != '/' && item.route != null)
            .toList();

        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              const Text(
                'Welcome to $pascalCaseName Demo!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: DashboardGrid(
                  itemCount: dashboardItems.length,
                  itemBuilder: (context, index) {
                    final item = dashboardItems[index];
                    return DashboardCard(
                      title: item.title,
                      iconName: item.iconName ?? 'dashboard',
                      route: item.route!,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
''';

String _flutterIntegrationTest(String packageName, String pascalCaseName) =>
    '''
import 'package:flutter_test/flutter_test.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:$packageName/$packageName.dart';
import 'package:integration_test/integration_test.dart';
import 'package:${packageName}_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GlobalConfiguration().loadFromAsset('app_settings');
  });

  testWidgets('$pascalCaseName Demo CRUD Test', (WidgetTester tester) async {
    final dio = await buildDioClient();
    RestClient restClient = RestClient(dio);
    await CommonTest.startTestApp(
      tester,
      create${pascalCaseName}ExampleRouter(dio),
      ${pascalCaseName.toLowerCase()}MenuConfig,
      const [],
      restClient: restClient,
      blocProviders: get${pascalCaseName}BlocProviders(dio),
      title: 'GrowERP $pascalCaseName Demo Test',
      clear: true,
    );

    await CommonTest.createCompanyAndAdmin(tester);

    // Navigate to demo list
    await ${pascalCaseName}DemoTest.selectDemos(tester);

    // Test data
    final demos = [
      ${pascalCaseName}Demo(
        message: 'Test Demo 1',
        description: 'This is the first test demo',
      ),
      ${pascalCaseName}Demo(
        message: 'Test Demo 2',
        description: 'This is the second test demo',
      ),
    ];

    // Add demos
    await ${pascalCaseName}DemoTest.addDemos(tester, demos);

    // Update demos
    await ${pascalCaseName}DemoTest.updateDemos(tester, demos);

    // Delete a demo
    await ${pascalCaseName}DemoTest.deleteDemos(tester, 1);

    // Logout
    await CommonTest.logout(tester);
  });
}
''';

String _flutterDemoTestClass(String pascalCaseName) =>
    '''
/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import '../models/models.dart';

class ${pascalCaseName}DemoTest {
  static Future<void> selectDemos(WidgetTester tester) async {
    await CommonTest.selectOption(
      tester,
      '/demos',
      '${pascalCaseName}DemoListScreen',
      null,
    );
  }

  static Future<void> addDemos(
    WidgetTester tester,
    List<${pascalCaseName}Demo> demos, {
    bool check = true,
  }) async {
    for (${pascalCaseName}Demo demo in demos) {
      await CommonTest.tapByKey(tester, 'addDemo', seconds: CommonTest.waitTime);
      await CommonTest.checkWidgetKey(tester, 'AddDemoDialog');
      
      await CommonTest.enterText(tester, 'message', demo.message);
      if (demo.description != null) {
        await CommonTest.enterText(tester, 'description', demo.description!);
      }
      
      await CommonTest.tapByKey(tester, 'addButton', seconds: CommonTest.waitTime);
      await CommonTest.waitForSnackbarToGo(tester);
    }
    
    if (check) {
      await checkDemos(tester, demos);
    }
  }

  static Future<void> updateDemos(
    WidgetTester tester,
    List<${pascalCaseName}Demo> demos,
  ) async {
    for (int index = 0; index < demos.length; index++) {
      ${pascalCaseName}Demo demo = demos[index];
      
      await CommonTest.tapByKey(tester, 'edit\$index', seconds: CommonTest.waitTime);
      await CommonTest.checkWidgetKey(tester, 'EditDemoDialog');
      
      await CommonTest.enterText(tester, 'message', '\${demo.message}u');
      if (demo.description != null) {
        await CommonTest.enterText(tester, 'description', '\${demo.description}u');
      }
      
      await CommonTest.tapByKey(tester, 'updateButton', seconds: CommonTest.waitTime);
      await CommonTest.waitForSnackbarToGo(tester);
    }
  }

  static Future<void> deleteDemos(WidgetTester tester, int count) async {
    // Count items before delete by checking indexed keys
    int itemCount = 0;
    while (await CommonTest.doesExistKey(tester, 'demoItem\$itemCount')) {
      itemCount++;
    }
    
    await CommonTest.tapByKey(tester, 'delete0', seconds: CommonTest.waitTime);
    await CommonTest.checkWidgetKey(tester, 'DeleteDemoDialog');
    await CommonTest.tapByKey(tester, 'confirmDelete', seconds: CommonTest.waitTime);
    await CommonTest.waitForSnackbarToGo(tester);
    
    // Count items after delete
    int newCount = 0;
    while (await CommonTest.doesExistKey(tester, 'demoItem\$newCount')) {
      newCount++;
    }
    
    expect(newCount, equals(itemCount - 1));
  }

  static Future<void> checkDemos(
    WidgetTester tester,
    List<${pascalCaseName}Demo> demos,
  ) async {
    // Verify items appear in the list
    for (${pascalCaseName}Demo demo in demos) {
      expect(find.text(demo.message), findsWidgets);
      if (demo.description != null) {
        expect(find.text(demo.description!), findsWidgets);
      }
    }
  }
}
''';

String _flutterL10nYaml(String baseName) =>
    '''
arb-dir: lib/l10n
template-arb-file: intl_en.arb
output-localization-file: ${baseName}_localizations.dart
output-class: ${_toPascalCase(baseName)}Localizations
''';

String _flutterArbFile(String baseName, String pascalCaseName) =>
    '''
{
  "@@locale": "en",
  "demoTitle": "$pascalCaseName Demo",
  "helloWorld": "Hello World!"
}
''';

// ============================================================================
// Moqui Template Functions
// ============================================================================

String _moquiComponentXml(String componentName) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/moqui-conf-2.1.xsd"
        name="$componentName" version="1.0.0">
        <depends-on name="growerp" />
        <depends-on name="mantle-udm" />
</component>
''';

String _moquiEntityXml(String baseName, String pascalCaseName) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!--
This software is in the public domain under CC0 1.0 Universal plus a 
Grant of Patent License.
-->
<entities xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/entity-definition-2.1.xsd">

    <entity entity-name="${pascalCaseName}Demo" package="growerp.$baseName"
            sequence-primary-prefix="demo">
        <field name="demoId" type="id" is-pk="true" />
        <field name="pseudoId" type="id" />
        <field name="message" type="text-medium" />
        <field name="description" type="text-long" />
        <field name="ownerPartyId" type="id">
            <description>The company owner, to separate companies.</description>
        </field>
        <relationship type="one" title="Owner" related="mantle.party.Party" short-alias="owner">
            <key-map field-name="ownerPartyId" />
        </relationship>
        <index name="${baseName.toUpperCase()}_DEMO_PSEUDOID" unique="false">
            <index-field name="pseudoId" />
        </index>
    </entity>

</entities>
''';

String _moquiServiceXml(String baseName, String pascalCaseName) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!--
This software is in the public domain under CC0 1.0 Universal plus a
Grant of Patent License.
-->
<services xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/service-definition-2.1.xsd">

    <service verb="get" noun="${pascalCaseName}Demo">
        <description>Get list of $pascalCaseName demo items</description>
        <in-parameters>
            <parameter name="demoId" />
            <parameter name="start" type="Integer" default="0" />
            <parameter name="limit" type="Integer" default="20" />
        </in-parameters>
        <out-parameters>
            <parameter name="demos" type="List">
                <parameter name="demo" type="Map">
                    <parameter name="demoId" />
                    <parameter name="pseudoId" />
                    <parameter name="message" />
                    <parameter name="description" />
                </parameter>
            </parameter>
        </out-parameters>
        <actions>
            <service-call name="growerp.100.GeneralServices100.get#RelatedCompanyAndOwner"
                out-map="context" />
            <entity-find entity-name="growerp.$baseName.${pascalCaseName}Demo" list="demoList"
                offset="start" limit="limit">
                <econdition field-name="ownerPartyId" />
                <econdition field-name="demoId" ignore-if-empty="true" />
                <order-by field-name="-lastUpdatedStamp" />
            </entity-find>
            <set field="demos" from="[]" />
            <iterate entry="demo" list="demoList">
                <script>demos.add([
                    demoId: demo.demoId,
                    pseudoId: demo.pseudoId,
                    message: demo.message,
                    description: demo.description,
                ])</script>
            </iterate>
        </actions>
    </service>

    <service verb="create" noun="${pascalCaseName}Demo">
        <description>Create a new $pascalCaseName demo item</description>
        <in-parameters>
            <parameter name="demo" type="Map" required="true">
                <parameter name="message" required="true" />
                <parameter name="description" />
            </parameter>
        </in-parameters>
        <out-parameters>
            <parameter name="demo" type="Map">
                <parameter name="demoId" />
                <parameter name="pseudoId" />
                <parameter name="message" />
                <parameter name="description" />
            </parameter>
        </out-parameters>
        <actions>
            <service-call name="growerp.100.GeneralServices100.get#RelatedCompanyAndOwner"
                out-map="context" />
            <!-- Generate pseudoId automatically -->
            <service-call name="growerp.100.GeneralServices100.getNext#PseudoId"
                in-map="[ownerPartyId: ownerPartyId, seqName: '${pascalCaseName}Demo']"
                out-map="seqResult" />
            <service-call name="create#growerp.$baseName.${pascalCaseName}Demo"
                in-map="[
                    message: demo.message,
                    description: demo.description,
                    pseudoId: seqResult.seqNum,
                    ownerPartyId: ownerPartyId
                ]" out-map="createResult" />
            <set field="demo" from="[
                demoId: createResult.demoId,
                pseudoId: seqResult.seqNum,
                message: demo.message,
                description: demo.description
            ]" />
        </actions>
    </service>

    <service verb="update" noun="${pascalCaseName}Demo">
        <description>Update a $pascalCaseName demo item</description>
        <in-parameters>
            <parameter name="demo" type="Map" required="true">
                <parameter name="demoId" required="true" />
                <parameter name="message" />
                <parameter name="description" />
            </parameter>
        </in-parameters>
        <out-parameters>
            <parameter name="demo" type="Map">
                <parameter name="demoId" />
                <parameter name="pseudoId" />
                <parameter name="message" />
                <parameter name="description" />
            </parameter>
        </out-parameters>
        <actions>
            <service-call name="growerp.100.GeneralServices100.get#RelatedCompanyAndOwner"
                out-map="context" />
            <entity-find-one entity-name="growerp.$baseName.${pascalCaseName}Demo" value-field="existing"
                for-update="true">
                <field-map field-name="demoId" from="demo.demoId" />
            </entity-find-one>
            <if condition="!existing">
                <return error="true" message="Demo item not found: \${demo.demoId}" />
            </if>
            <set field="existing.message" from="demo.message ?: existing.message" />
            <set field="existing.description" from="demo.description ?: existing.description" />
            <entity-update value-field="existing" />
            <set field="demo" from="[
                demoId: existing.demoId,
                pseudoId: existing.pseudoId,
                message: existing.message,
                description: existing.description
            ]" />
        </actions>
    </service>

    <service verb="delete" noun="${pascalCaseName}Demo">
        <description>Delete a $pascalCaseName demo item</description>
        <in-parameters>
            <parameter name="demoId" required="true" />
        </in-parameters>
        <actions>
            <service-call name="growerp.100.GeneralServices100.get#RelatedCompanyAndOwner"
                out-map="context" />
            <entity-find-one entity-name="growerp.$baseName.${pascalCaseName}Demo" value-field="existing">
                <field-map field-name="demoId" />
            </entity-find-one>
            <if condition="existing">
                <entity-delete value-field="existing" />
            </if>
        </actions>
    </service>

</services>
''';

String _moquiRestXml(String baseName, String pascalCaseName) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!--
This software is in the public domain under CC0 1.0 Universal plus a 
Grant of Patent License.
-->
<resource xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/rest-api-2.1.xsd"
    name="$baseName" require-authentication="anonymous-view">

    <resource name="100">
        <resource name="${pascalCaseName}Demo">
            <method type="get">
                <service name="${pascalCaseName}Services.get#${pascalCaseName}Demo" />
            </method>
            <method type="post">
                <service name="${pascalCaseName}Services.create#${pascalCaseName}Demo" />
            </method>
            <method type="patch">
                <service name="${pascalCaseName}Services.update#${pascalCaseName}Demo" />
            </method>
            <method type="delete">
                <service name="${pascalCaseName}Services.delete#${pascalCaseName}Demo" />
            </method>
        </resource>
    </resource>

</resource>
''';

String _moquiSeedDataXml(String baseName, String pascalCaseName) => '''
<?xml version="1.0" encoding="UTF-8"?>
<!--
This software is in the public domain under CC0 1.0 Universal plus a 
Grant of Patent License.
-->
<entity-facade-xml type="seed">

    <!-- Sample demo data for Hello World -->
    <!-- Note: Will be created per company via the frontend -->

</entity-facade-xml>
''';

String _moquiSecurityDataXml(
  String baseName,
  String pascalCaseName,
  String upperCaseName,
) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<!--
This software is in the public domain under CC0 1.0 Universal plus a 
Grant of Patent License.
-->
<entity-facade-xml type="seed-initial">

    <!-- Artifact group for $pascalCaseName REST API -->
    <moqui.security.ArtifactGroup artifactGroupId="GROWERP_${upperCaseName}_API"
        description="GrowERP $pascalCaseName REST API" />
    <moqui.security.ArtifactGroupMember artifactGroupId="GROWERP_${upperCaseName}_API"
        artifactTypeEnumId="AT_REST_PATH"
        inheritAuthz="Y" artifactName="/$baseName/100/${pascalCaseName}Demo" />

    <!-- Artifact group for $pascalCaseName Services -->
    <moqui.security.ArtifactGroup artifactGroupId="GROWERP_${upperCaseName}_SVC"
        description="GrowERP $pascalCaseName Services" />
    <moqui.security.ArtifactGroupMember artifactGroupId="GROWERP_${upperCaseName}_SVC"
        artifactTypeEnumId="AT_SERVICE" artifactName="${pascalCaseName}Services.*" />

    <!-- Authorization for admin group - REST API -->
    <moqui.security.ArtifactAuthz artifactAuthzId="GROWERP${upperCaseName}_AUTHZ_ADMIN"
        userGroupId="GROWERP_M_ADMIN"
        artifactGroupId="GROWERP_${upperCaseName}_API" 
        authzTypeEnumId="AUTHZT_ALWAYS" authzActionEnumId="AUTHZA_ALL" />

    <!-- Authorization for employee group - REST API -->
    <moqui.security.ArtifactAuthz artifactAuthzId="GROWERP${upperCaseName}_AUTHZ_EMPL"
        userGroupId="GROWERP_M_EMPLOYEE"
        artifactGroupId="GROWERP_${upperCaseName}_API" 
        authzTypeEnumId="AUTHZT_ALWAYS" authzActionEnumId="AUTHZA_ALL" />

    <!-- Authorization for admin group - Services -->
    <moqui.security.ArtifactAuthz artifactAuthzId="GROWERP${upperCaseName}_AUTHZ_ADMIN_SVC"
        userGroupId="GROWERP_M_ADMIN"
        artifactGroupId="GROWERP_${upperCaseName}_SVC" 
        authzTypeEnumId="AUTHZT_ALWAYS" authzActionEnumId="AUTHZA_ALL" />

    <!-- Authorization for employee group - Services -->
    <moqui.security.ArtifactAuthz artifactAuthzId="GROWERP${upperCaseName}_AUTHZ_EMPL_SVC"
        userGroupId="GROWERP_M_EMPLOYEE"
        artifactGroupId="GROWERP_${upperCaseName}_SVC" 
        authzTypeEnumId="AUTHZT_ALWAYS" authzActionEnumId="AUTHZA_ALL" />

</entity-facade-xml>
''';
