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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io' show Platform;

class ImageButtons extends StatefulWidget {
  final Function onImageButtonPressed;
  final ScrollController scrollController;
  const ImageButtons(
    this.scrollController,
    this.onImageButtonPressed, {
    super.key,
  });

  @override
  State<ImageButtons> createState() => _ImageButtonsState();
}

class _ImageButtonsState extends State<ImageButtons> {
  late bool isVisible;

  @override
  void initState() {
    isVisible = true;
    widget.scrollController.addListener(() {
      if (isVisible != false &&
          widget.scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        if (mounted) {
          setState(() {
            isVisible = false;
          });
        }
      }
      if (isVisible != true &&
          widget.scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        if (mounted) {
          setState(() {
            isVisible = true;
          });
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool showCameraButton = false;
    final isDesktop =
        !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
    // Only show camera button on Android and iOS
    if (!kIsWeb) {
      switch (Theme.of(context).platform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          showCameraButton = true;
          break;
        default:
          showCameraButton = false;
      }
    }
    return Visibility(
      visible: isVisible,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 100),
          FloatingActionButton(
            key: const Key('gallery'),
            onPressed: () async {
              if (isDesktop) {
                // Use file_picker for desktop platforms
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.image,
                );
                if (!mounted) return;
                if (result != null && result.files.single.path != null) {
                  widget.onImageButtonPressed(result.files.single.path);
                }
              } else {
                // Use image_picker for mobile/web
                widget.onImageButtonPressed(
                  ImageSource.gallery,
                  context: context,
                );
              }
            },
            heroTag: 'image0',
            tooltip: 'Pick Image from gallery',
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 20),
          if (showCameraButton)
            FloatingActionButton(
              key: const Key('camera'),
              onPressed: () {
                widget.onImageButtonPressed(
                  ImageSource.camera,
                  context: context,
                );
              },
              heroTag: 'image1',
              tooltip: 'Take a Photo',
              child: const Icon(Icons.camera_alt),
            ),
        ],
      ),
    );
  }
}
