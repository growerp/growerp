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
import 'package:growerp_core/growerp_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

/// Plays the narrated video of a module. video_player has no Linux or
/// Windows implementation: there the video opens in the browser instead.
Future<void> showCourseVideo(
  BuildContext context, {
  required String title,
  required String videoUrl,
}) async {
  // the backend returns the path; the app knows where its backend is
  final dio = await buildDioClient();
  final base = dio.options.baseUrl.replaceAll(RegExp(r'/$'), '');
  final url = Uri.parse('$base$videoUrl');
  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      key: const Key('courseVideoDialog'),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: dialogContext,
        title: title,
        width: 900,
        height: 620,
        child: _canPlayInApp
            ? _VideoPlayerView(url: url)
            : Center(
                child: ElevatedButton.icon(
                  key: const Key('openVideoExternal'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Play the video in the browser'),
                  onPressed: () => launchUrl(url),
                ),
              ),
      ),
    ),
  );
}

bool get _canPlayInApp =>
    kIsWeb ||
    const [
      TargetPlatform.android,
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    ].contains(defaultTargetPlatform);

class _VideoPlayerView extends StatefulWidget {
  final Uri url;
  const _VideoPlayerView({required this.url});

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  late final VideoPlayerController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(widget.url)
      ..addListener(() {
        if (mounted) setState(() {});
      });
    _controller.initialize().then(
      (_) => _controller.play(),
      onError: (e) {
        if (mounted) setState(() => _error = e.toString());
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Could not play the video: $_error'));
    }
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final playing = _controller.value.isPlaying;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        VideoProgressIndicator(_controller, allowScrubbing: true),
        Row(
          children: [
            IconButton(
              key: const Key('videoPlayPause'),
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              onPressed: () =>
                  playing ? _controller.pause() : _controller.play(),
            ),
            Text(
              '${_format(_controller.value.position)} / '
              '${_format(_controller.value.duration)}',
            ),
          ],
        ),
      ],
    );
  }

  String _format(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
