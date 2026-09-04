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

import 'dart:typed_data';
import 'package:cross_file/cross_file.dart';
import 'package:universal_io/io.dart';
import 'package:file_picker_platform_interface/file_picker_platform_interface.dart';

/// Backs [TestFilePicker.pickFile]'s result with the fixed file's bytes.
base class _TestPlatformFile extends PlatformFile {
  _TestPlatformFile(String path, Uint8List bytes)
    : name = path.split(Platform.pathSeparator).last,
      uri = Uri.file(path),
      _bytes = bytes;

  @override
  final String name;

  @override
  final Uri uri;

  final Uint8List _bytes;

  @override
  XFile get xFile => XFile.fromData(_bytes, name: name);

  @override
  int? lengthSync() => _bytes.length;

  @override
  Future<int> length() async => _bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(_bytes);
}

/// Answers the save and pick dialogs with a fixed file, so a test can drive an
/// up/download without a native file dialog. Install with
/// `FilePickerPlatform.instance = TestFilePicker(path)`.
class TestFilePicker extends FilePickerPlatform {
  TestFilePicker(this.path);

  /// the file the save dialog writes to and the pick dialog returns
  final String path;

  @override
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
    String? dialogTitle,
    String? initialDirectory,
    Function(FilePickerStatus)? onFileSaving,
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    // like the real desktop implementation: write the bytes to the fixed path
    await File(path).writeAsBytes(bytes);
    return Uri.file(path);
  }

  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    return _TestPlatformFile(path, bytes);
  }
}
