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

class ImageButtons extends StatefulWidget {
  final Function onImageButtonPressed;
  final ScrollController scrollController;
  const ImageButtons(this.scrollController, this.onImageButtonPressed,
      {super.key});

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
    return Visibility(
      visible: isVisible,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 100),
          FloatingActionButton(
            key: const Key('gallery'),
            onPressed: () {
              widget.onImageButtonPressed(ImageSource.gallery,
                  context: context);
            },
            heroTag: 'image0',
            tooltip: 'Pick Image from gallery',
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(height: 20),
          Visibility(
            visible: !kIsWeb,
            child: FloatingActionButton(
              key: const Key('camera'),
              onPressed: () {
                widget.onImageButtonPressed(ImageSource.camera,
                    context: context);
              },
              heroTag: 'image1',
              tooltip: 'Take a Photo',
              child: const Icon(Icons.camera_alt),
            ),
          )
        ],
      ),
    );
  }
}
