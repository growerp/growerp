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
                  widget.onImageButtonPressed(
                    result.files.single.path,
                    context: context,
                  );
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
