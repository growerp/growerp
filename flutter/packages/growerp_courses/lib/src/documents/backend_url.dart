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

import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';

/// Course media urls (cover image, video) come from the backend as a path,
/// so they also work on the website of the company: the app puts its backend
/// url in front.
Future<String>? _backendBase;

Future<Uri> backendUri(String url) async {
  if (!url.startsWith('/')) return Uri.parse(url);
  _backendBase ??= buildDioClient().then(
    (dio) => dio.options.baseUrl.replaceAll(RegExp(r'/$'), ''),
  );
  return Uri.parse('${await _backendBase}$url');
}

/// [Image.network] for a url that may be a backend path
class BackendImage extends StatelessWidget {
  final String url;
  final BoxFit? fit;
  final Widget fallback;

  const BackendImage({
    super.key,
    required this.url,
    this.fit,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uri>(
      future: backendUri(url),
      builder: (context, snapshot) => snapshot.hasData
          ? Image.network(
              snapshot.data.toString(),
              fit: fit,
              errorBuilder: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}
