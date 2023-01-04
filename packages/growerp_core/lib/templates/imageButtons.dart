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
import 'package:image_picker/image_picker.dart';

Widget imageButtons(BuildContext context, _onImageButtonPressed) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.start,
    children: <Widget>[
      SizedBox(height: 100),
      FloatingActionButton(
        key: Key('gallery'),
        onPressed: () {
          _onImageButtonPressed(ImageSource.gallery, context: context);
        },
        heroTag: 'image0',
        tooltip: 'Pick Image from gallery',
        child: const Icon(Icons.photo_library),
      ),
      SizedBox(height: 20),
      Visibility(
        visible: !kIsWeb,
        child: FloatingActionButton(
          key: Key('camera'),
          onPressed: () {
            _onImageButtonPressed(ImageSource.camera, context: context);
          },
          heroTag: 'image1',
          tooltip: 'Take a Photo',
          child: const Icon(Icons.camera_alt),
        ),
      )
    ],
  );
}
