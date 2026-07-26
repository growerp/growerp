/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

@TestOn('vm')
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
// Import native implementation directly for testing
import 'package:growerp_outreach/src/services/flutter_mcp_browser_service_native.dart';

void main() {
  group('McpServerConfig', () {
    test('should create config with explicit paths', () {
      const config = McpServerConfig(
        nodePath: '/usr/bin/node',
        playwrightMcpPath: '/path/to/playwright/cli.js',
        homeDir: '/home/testuser',
        pathEnv: '/usr/bin:/bin',
      );

      expect(config.nodePath, equals('/usr/bin/node'));
      expect(config.playwrightMcpPath, equals('/path/to/playwright/cli.js'));
      expect(config.homeDir, equals('/home/testuser'));
      expect(config.pathEnv, equals('/usr/bin:/bin'));
    });

    test('linux factory should set correct nvm-based paths', () {
      final config = McpServerConfig.linux(
        homeDir: '/home/testuser',
        nodeVersion: 'v24.11.1',
      );

      expect(config.nodePath,
          equals('/home/testuser/.nvm/versions/node/v24.11.1/bin/node'));
      expect(
          config.playwrightMcpPath,
          equals(
              '/home/testuser/.nvm/versions/node/v24.11.1/lib/node_modules/@playwright/mcp/cli.js'));
      expect(config.homeDir, equals('/home/testuser'));
    });

    test('linux factory should support custom node version', () {
      final config = McpServerConfig.linux(
        homeDir: '/home/dev',
        nodeVersion: 'v20.0.0',
      );

      expect(config.nodePath,
          equals('/home/dev/.nvm/versions/node/v20.0.0/bin/node'));
      expect(
          config.playwrightMcpPath,
          equals(
              '/home/dev/.nvm/versions/node/v20.0.0/lib/node_modules/@playwright/mcp/cli.js'));
    });

    test('config should include PATH with node bin directory', () {
      final config = McpServerConfig.linux(
        homeDir: '/home/user',
        nodeVersion: 'v24.11.1',
      );

      expect(config.pathEnv,
          contains('/home/user/.nvm/versions/node/v24.11.1/bin'));
      expect(config.pathEnv, contains('/usr/bin'));
    });
  },
      skip: !Platform.isLinux && !Platform.isMacOS && !Platform.isWindows
          ? 'Only runs on desktop platforms'
          : null);
}
