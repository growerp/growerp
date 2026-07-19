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
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'app_blocks.dart';
import 'workspace_registry.dart';

final _logger = Logger(filter: ProductionFilter());

/// Donor app the scaffold copies platform/build boilerplate from.
const _donorApp = 'freelance';

/// File extensions treated as binary (copied byte-for-byte, no substitution).
const _binaryExtensions = {
  '.png', '.jpg', '.jpeg', '.gif', '.ico', '.webp', '.bmp', //
  '.ttf', '.otf', '.woff', '.woff2', //
  '.so', '.jar', '.war', '.keystore', '.jks', '.zip', '.gz', //
};

/// Relative paths (from the donor package root) skipped during the copy.
/// lib/, pubspec.yaml and app_settings.json are regenerated per-app.
bool _skipDonorPath(String rel) {
  final normalized = rel.replaceAll('\\', '/');
  const skipPrefixes = [
    'build/',
    '.dart_tool/',
    'lib/',
    'android/.gradle/',
    'ios/Pods/',
    'ios/.symlinks/',
    '.idea/',
  ];
  for (final pre in skipPrefixes) {
    if (normalized.startsWith(pre)) return true;
  }
  // Platform build artifacts (e.g. linux/flutter/ephemeral, ios/Flutter/
  // ephemeral) are regenerated per build and can be non-UTF-8 binaries.
  if (normalized.split('/').contains('ephemeral')) return true;
  const skipExact = [
    'pubspec.yaml',
    'pubspec.lock',
    'README.md',
    'assets/cfg/app_settings.json',
    '.flutter-plugins',
    '.flutter-plugins-dependencies',
    '.packages',
  ];
  if (skipExact.contains(normalized)) return true;
  if (normalized.endsWith('.iml')) return true;
  return false;
}

/// Creates a new GrowERP vertical application package.
///
/// [name] is the lowercase app id (e.g. 'bakery'). [requestedBlocks] are the
/// building-block keys to wire in (see [appBlocks]); when empty, [defaultBlocks]
/// is used. [growerpPath] is the GrowERP installation root. [appTitle]
/// overrides the default `GrowERP <Name>` title.
Future<void> createApp(
  String name,
  List<String> requestedBlocks,
  String growerpPath, {
  String? appTitle,
}) async {
  final validNameRegex = RegExp(r'^[a-z][a-z0-9_]*$');
  if (!validNameRegex.hasMatch(name)) {
    _logger.e(
      'Invalid app name: $name\n'
      'Must be lowercase, start with a letter, and contain only letters, '
      'numbers and underscores.',
    );
    exit(1);
  }

  final effectiveBlocks = resolveBlocks(
    requestedBlocks.isEmpty ? defaultBlocks : requestedBlocks,
  );
  final unknown = unknownBlockKeys(effectiveBlocks);
  if (unknown.isNotEmpty) {
    _logger.e(
      'Unknown block(s): ${unknown.join(', ')}\n'
      'Available blocks: ${appBlocks.keys.join(', ')}',
    );
    exit(1);
  }

  final pascal = _toPascalCase(name);
  final upper = name.toUpperCase();
  final applicationId = 'App$pascal';
  final configId = '${upper}_DEFAULT';
  final title = appTitle ?? 'GrowERP $pascal';

  final donorPath = p.join(growerpPath, 'flutter', 'packages', _donorApp);
  final appPath = p.join(growerpPath, 'flutter', 'packages', name);
  final seedPath = p.join(
    growerpPath,
    'moqui',
    'runtime',
    'component',
    'growerp',
    'data',
    'Growerp${pascal}AppSeedData.xml',
  );

  if (!Directory(donorPath).existsSync()) {
    _logger.e('Donor app not found: $donorPath');
    exit(1);
  }
  if (Directory(appPath).existsSync()) {
    _logger.e('App package already exists: $appPath');
    exit(1);
  }
  if (File(seedPath).existsSync()) {
    _logger.e('Seed file already exists: $seedPath');
    exit(1);
  }
  final collision = _findAppIdCollision(growerpPath, name, applicationId);
  if (collision != null) {
    _logger.e(
      'appId "$name" / applicationId "$applicationId" already used in '
      '$collision',
    );
    exit(1);
  }

  _logger.i('Creating GrowERP vertical: $name');
  _logger.i('  blocks: ${effectiveBlocks.join(', ')}');

  // Capture rename targets used by the donor-copy substitution helpers.
  _targetName = name;
  _targetPascal = pascal;
  _targetUpper = upper;

  // 1. Copy donor boilerplate (platform folders, build scripts) with rename.
  _copyDonor(donorPath, appPath);

  // 2. Generate the per-app files.
  final blocks = effectiveBlocks.map((k) => appBlocks[k]!).toList();
  File(p.join(appPath, 'pubspec.yaml'))
      .writeAsStringSync(_pubspec(name, blocks));
  File(p.join(appPath, 'assets', 'cfg', 'app_settings.json'))
      .writeAsStringSync(_appSettings(applicationId));
  Directory(p.join(appPath, 'lib', 'views')).createSync(recursive: true);
  File(p.join(appPath, 'lib', 'main.dart')).writeAsStringSync(
    _mainDart(name, pascal, configId, title, blocks),
  );
  File(p.join(appPath, 'lib', 'views', '${name}_db_form.dart'))
      .writeAsStringSync(_dashboardStub(pascal));
  File(p.join(appPath, 'README.md')).writeAsStringSync(
    '# GrowERP ${_capitalize(name)}\n\nA GrowERP vertical application.\n',
  );

  // 3. Emit the backend seed (Application + MenuConfiguration + MenuItems).
  File(seedPath).writeAsStringSync(
    _seedXml(name, pascal, applicationId, configId, blocks),
  );
  _logger.i('  ✓ Wrote seed: $seedPath');

  // 4. Register in the pub workspace.
  addPackageToWorkspace(growerpPath, 'packages/$name', _logger);

  _logger.i('\n✅ Vertical "$name" created successfully!');
  Zone.root.run(() {
    // ignore: avoid_print
    print('\nNext steps:');
    // ignore: avoid_print
    print('  1. cd $growerpPath/flutter && melos bootstrap');
    // ignore: avoid_print
    print(
      '  2. Load menu seed: cd $growerpPath/moqui && '
      'java -jar moqui.war load location=component://growerp/data/'
      'Growerp${pascal}AppSeedData.xml',
    );
    // ignore: avoid_print
    print('  3. Restart backend, then: cd $appPath && flutter run');
  });
}

/// Copies the donor package tree to [appPath], renaming donor-name path
/// segments and substituting the donor name (all case variants) in text files.
void _copyDonor(String donorPath, String appPath) {
  final donorDir = Directory(donorPath);
  for (final entity
      in donorDir.listSync(recursive: true, followLinks: false)) {
    final rel = p.relative(entity.path, from: donorPath);
    if (_skipDonorPath(rel)) continue;

    final renamedRel = _renameSegments(rel);
    final targetPath = p.join(appPath, renamedRel);

    if (entity is Directory) {
      Directory(targetPath).createSync(recursive: true);
    } else if (entity is File) {
      Directory(p.dirname(targetPath)).createSync(recursive: true);
      final ext = p.extension(entity.path).toLowerCase();
      if (_binaryExtensions.contains(ext)) {
        entity.copySync(targetPath);
      } else {
        final substituted = _substitute(entity.readAsStringSync());
        File(targetPath).writeAsStringSync(substituted);
      }
    }
  }
  _logger.i('  ✓ Copied platform/build files from $_donorApp');
}

/// Replaces path segments equal to the donor name with a placeholder-free
/// renamed segment (e.g. android/.../kotlin/org/growerp/freelance → .../bakery).
String _renameSegments(String rel) => rel
    .split(RegExp(r'[/\\]'))
    .map((s) => s == _donorApp ? _renameToken(s) : s)
    .join(Platform.pathSeparator);

// Renaming happens per-file; the target name is captured via closure below.
late String _targetName;
late String _targetPascal;
late String _targetUpper;

String _renameToken(String _) => _targetName;

String _substitute(String content) => content
    .replaceAll(_toPascalCase(_donorApp), _targetPascal)
    .replaceAll(_donorApp.toUpperCase(), _targetUpper)
    .replaceAll(_donorApp, _targetName);

String? _findAppIdCollision(
  String growerpPath,
  String appId,
  String applicationId,
) {
  final dataDir = Directory(
    p.join(growerpPath, 'moqui', 'runtime', 'component', 'growerp', 'data'),
  );
  if (!dataDir.existsSync()) return null;
  for (final f in dataDir.listSync()) {
    if (f is File && f.path.endsWith('.xml')) {
      final content = f.readAsStringSync();
      if (content.contains('appId="$appId"') ||
          content.contains('applicationId="$applicationId"')) {
        return p.basename(f.path);
      }
    }
  }
  return null;
}

String _toPascalCase(String input) => input
    .split('_')
    .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
    .join();

String _capitalize(String input) =>
    input.isEmpty ? input : input[0].toUpperCase() + input.substring(1);

// ---------------------------------------------------------------------------
// File templates
// ---------------------------------------------------------------------------

String _pubspec(String name, List<AppBlock> blocks) {
  final blockDeps = StringBuffer();
  for (final b in blocks) {
    blockDeps.writeln('  ${b.package}: ${b.version}');
  }
  return '''
name: $name
resolution: workspace
version: 1.0.0+1
publish_to: none

environment:
  sdk: ^3.10.0
  flutter: ^3.33.0

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^9.1.1
  flutter_localizations:
    sdk: flutter
  growerp_core: ^1.9.0
  growerp_models: ^1.11.6
${blockDeps.toString().trimRight()}
  universal_io: ^2.2.2
  global_configuration: ^2.0.0
  responsive_framework: ^1.4.0
  bloc_concurrency: ^0.3.0
  package_info_plus: ^9.0.0
  shared_preferences: ^2.3.2
  intl: ^0.20.2
  hive_flutter: ^1.1.0
  go_router: ^17.1.0
  dio: ^5.4.3
  web: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/cfg/
    - packages/growerp_core/images/growerp.png
    - packages/growerp_core/images/growerp.jpg
    - packages/growerp_core/images/growerpDark.jpg
    - packages/growerp_core/images/growerp100.png
    - packages/growerp_core/images/growerpDark100.png
flutter_intl:
  enabled: true
''';
}

String _appSettings(String applicationId) => '''
{
    "appName": "",
    "packageName": "",
    "version": "",
    "build": "",
    "applicationId": "$applicationId",
    "backend": "moqui",
    "databaseUrl": "https://backend.growerp.com",
    "chatUrl": "wss://backend.growerp.com",
    "databaseUrlDebug": "",
    "chatUrlDebug": "",
    "test": false,
    "singleCompany": "",
    "connectTimeoutProd": 30,
    "receiveTimeoutProd": 300,
    "connectTimeoutTest": 30,
    "receiveTimeoutTest": 600,
    "restRequestLogs": false,
    "restResponseLogs": false,
    "cacheMaxStaleMinutes": 10
}
''';

String _mainDart(
  String name,
  String pascal,
  String configId,
  String title,
  List<AppBlock> blocks,
) {
  final hasAdk = blocks.any((b) => b.isAdkFab);

  final imports = StringBuffer();
  for (final b in blocks) {
    imports.writeln("import '${b.importUri}';");
  }

  final delegates = blocks
      .where((b) => b.localizationsDelegate != null)
      .map((b) => '            ${b.localizationsDelegate},')
      .join('\n');

  final providers = blocks
      .where((b) => b.blocProvidersFn != null)
      .map(
        (b) => b.providerTakesAppId
            ? '              ...${b.blocProvidersFn}(widget.restClient, widget.applicationId),'
            : '              ...${b.blocProvidersFn}(widget.restClient),',
      )
      .join('\n');

  final widgets = blocks
      .where((b) => b.widgetsFn != null)
      .map((b) => '  ${b.widgetsFn}(),')
      .join('\n');

  final fab = hasAdk
      ? '''
                dashboardFabBuilder: (_) => Builder(
                  builder: (ctx) => FloatingActionButton(
                    key: const Key('adkChatFab'),
                    tooltip: 'AI Assistant',
                    onPressed: () => AdkChatDialog.show(ctx),
                    child: const Icon(Icons.smart_toy),
                  ),
                ),
'''
      : '';

  return '''
// ignore_for_file: depend_on_referenced_packages, avoid_print

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

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:go_router/go_router.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
${imports.toString().trimRight()}
import 'package:package_info_plus/package_info_plus.dart';
import 'views/${name}_db_form.dart';
//webactivate  import 'package:web/web.dart' as web;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GlobalConfiguration().loadFromAsset('app_settings');

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  GlobalConfiguration().updateValue('appName', packageInfo.appName);
  GlobalConfiguration().updateValue('packageName', packageInfo.packageName);
  GlobalConfiguration().updateValue('version', packageInfo.version);
  GlobalConfiguration().updateValue('build', packageInfo.buildNumber);

  String applicationId = GlobalConfiguration().get("applicationId");
  final forceUpdateInfo = await getBackendUrlOverride(
    applicationId,
    packageInfo.version,
  );

  Bloc.observer = AppBlocObserver();
  RestClient restClient = RestClient(await buildDioClient());
  WsClient chatClient = WsClient('chat');
  WsClient notificationClient = WsClient('notws');

  Company? company;
  if (kIsWeb) {
    String? hostName;
    //webactivate  hostName = web.window.location.hostname;
    // ignore: unnecessary_null_comparison
    if (hostName != null) {
      try {
        company = await restClient.getCompanyFromHost(hostName);
      } on DioException catch (e) {
        debugPrint("getting hostname error: \${await getDioError(e)}");
      }
      if (company?.partyId == null) company = null;
    }
  }

  runApp(
    ${pascal}App(
      restClient: restClient,
      applicationId: applicationId,
      chatClient: chatClient,
      notificationClient: notificationClient,
      company: company,
      forceUpdateInfo: forceUpdateInfo,
    ),
  );
}

class ${pascal}App extends StatefulWidget {
  const ${pascal}App({
    super.key,
    required this.restClient,
    required this.applicationId,
    required this.chatClient,
    required this.notificationClient,
    this.company,
    this.forceUpdateInfo,
  });

  final RestClient restClient;
  final String applicationId;
  final WsClient chatClient;
  final WsClient notificationClient;
  final Company? company;
  final ForceUpdateInfo? forceUpdateInfo;

  @override
  State<${pascal}App> createState() => _${pascal}AppState();
}

class _${pascal}AppState extends State<${pascal}App> {
  late MenuConfigBloc _menuConfigBloc;

  @override
  void initState() {
    super.initState();
    _menuConfigBloc = MenuConfigBloc(widget.restClient, '$name');
  }

  @override
  void dispose() {
    widget.chatClient.close();
    widget.notificationClient.close();
    _menuConfigBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _menuConfigBloc,
      child: BlocBuilder<MenuConfigBloc, MenuConfigState>(
        builder: (context, state) {
          GoRouter router;

          if (state.status == MenuConfigStatus.success &&
              state.menuConfiguration != null) {
            router = createDynamicAppRouter(
              [state.menuConfiguration!],
              config: DynamicRouterConfig(
                mainConfigId: '$configId',
                dashboardBuilder: () => const ${pascal}DbForm(),
                widgetLoader: WidgetRegistry.getWidget,
                appTitle: '$title',
${fab.isEmpty ? '' : fab.trimRight()}
              ),
              rootNavigatorKey: GlobalKey<NavigatorState>(),
            );
          } else {
            router = GoRouter(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: '$title',
                    appId: '$name',
                  ),
                ),
                GoRoute(
                  path: '/:path',
                  builder: (context, state) => AppSplashScreen.simple(
                    appTitle: '$title',
                    appId: '$name',
                  ),
                ),
              ],
            );
          }

          return TopApp(
            restClient: widget.restClient,
            applicationId: widget.applicationId,
            chatClient: widget.chatClient,
            notificationClient: widget.notificationClient,
            title: '$title',
            router: router,
            extraDelegates: const [
$delegates
            ],
            extraBlocProviders: [
$providers
            ],
            widgetRegistrations: ${name}WidgetRegistrations,
            forceUpdateInfo: widget.forceUpdateInfo,
          );
        },
      ),
    );
  }
}

/// Widget registrations for all packages used by the $pascal app.
List<Map<String, GrowerpWidgetBuilder>> ${name}WidgetRegistrations = [
$widgets
  // App-specific widgets
  {
    '${pascal}DbForm': (args) => const ${pascal}DbForm(),
    'AboutForm': (args) => const AboutForm(),
  },
];
''';
}

String _dashboardStub(String pascal) => '''
/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License. See the LICENSE.md file for details.
 */

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

class ${pascal}DbForm extends StatelessWidget {
  const ${pascal}DbForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final stats = authState.authenticate?.stats;

        return BlocBuilder<MenuConfigBloc, MenuConfigState>(
          builder: (context, menuState) {
            final menuConfig = menuState.menuConfiguration;

            if (menuConfig == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final dashboardOptions =
                menuConfig.menuItems
                    .where(
                      (option) =>
                          option.isActive &&
                          option.route != null &&
                          option.route != '/' &&
                          option.route != '/about',
                    )
                    .toList()
                  ..sort((a, b) => a.sequenceNum.compareTo(b.sequenceNum));

            return Scaffold(
              backgroundColor: Colors.transparent,
              body: DashboardGrid(
                items: dashboardOptions,
                stats: stats,
                onToggleMinimize: (id) => context
                    .read<MenuConfigBloc>()
                    .add(MenuItemToggleMinimize(id)),
              ),
            );
          },
        );
      },
    );
  }
}
''';

String _seedXml(
  String name,
  String pascal,
  String applicationId,
  String configId,
  List<AppBlock> blocks,
) {
  final menuItems = StringBuffer();
  // Dashboard root item.
  menuItems.writeln(
    '    <growerp.menu.MenuItem menuItemId="${name.toUpperCase()}_MAIN" '
    'menuConfigurationId="$configId"\n'
    '        title="Main" route="/" iconName="dashboard" '
    'widgetName="${pascal}DbForm" sequenceNum="10"/>',
  );
  var seq = 20;
  for (final b in blocks) {
    final m = b.menuItem;
    if (m == null) continue;
    menuItems.writeln(
      '    <growerp.menu.MenuItem menuItemId="${name.toUpperCase()}_${b.key.toUpperCase()}" '
      'menuConfigurationId="$configId"\n'
      '        title="${m.title}" route="${m.route}" iconName="${m.iconName}" '
      'widgetName="${m.widgetName}" sequenceNum="$seq"/>',
    );
    seq += 10;
  }
  // About item last.
  menuItems.writeln(
    '    <growerp.menu.MenuItem menuItemId="${name.toUpperCase()}_ABOUT" '
    'menuConfigurationId="$configId"\n'
    '        title="About" route="/about" iconName="info" '
    'widgetName="AboutForm" sequenceNum="$seq"/>',
  );

  return '''
<?xml version="1.0" encoding="UTF-8"?>
<!--
This software is in the public domain under CC0 1.0 Universal plus a
Grant of Patent License. See the LICENSE.md file for details.
-->
<entity-facade-xml type="seed">
    <!-- Application record -->
    <growerp.Application applicationId="$applicationId"
        description="GrowERP $pascal vertical app" />

    <!-- Menu configuration -->
    <growerp.menu.MenuConfiguration menuConfigurationId="$configId" appId="$name"
        name="$pascal Menu" description="Default $name application menu structure"/>

    <!-- Menu items -->
${menuItems.toString().trimRight()}
</entity-facade-xml>
''';
}
