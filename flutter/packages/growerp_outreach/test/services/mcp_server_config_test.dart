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
