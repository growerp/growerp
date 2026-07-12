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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

const List<String> socialEngagementTypes = [
  'LIKE',
  'COMMENT',
  'SHARE',
  'DM_REPLY',
];

/// Signals of interest on social posts; convert one into a Lead with a
/// follow-up to-do.
class SocialEngagementList extends StatefulWidget {
  const SocialEngagementList({super.key});

  @override
  SocialEngagementListState createState() => SocialEngagementListState();
}

class SocialEngagementListState extends State<SocialEngagementList> {
  List<SocialEngagement> engagements = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<RestClient>().getSocialEngagement(
        limit: 100,
      );
      if (mounted) setState(() => engagements = result.socialEngagements);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _record() async {
    final nameController = TextEditingController();
    final platformController = TextEditingController(text: 'LINKEDIN');
    final urlController = TextEditingController();
    final noteController = TextEditingController();
    String type = 'COMMENT';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('SocialEngagementDialog'),
        title: const Text('Record engagement'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('engagementUser'),
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Who (name)'),
              ),
              DropdownButtonFormField<String>(
                key: const Key('engagementType'),
                initialValue: type,
                items: socialEngagementTypes
                    .map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    )
                    .toList(),
                onChanged: (value) => type = value ?? 'COMMENT',
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              TextField(
                key: const Key('engagementPlatform'),
                controller: platformController,
                decoration: const InputDecoration(labelText: 'Platform'),
              ),
              TextField(
                key: const Key('engagementUrl'),
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Profile URL'),
              ),
              TextField(
                key: const Key('engagementNote'),
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('saveEngagement'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      await context.read<RestClient>().createSocialEngagement(
        socialEngagement: SocialEngagement(
          userName: nameController.text,
          engagementType: type,
          platform: platformController.text,
          userProfileUrl: urlController.text,
          note: noteController.text,
        ),
      );
      await _load();
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(context, 'Save failed: $e', Colors.red);
      }
    }
  }

  Future<void> _convert(SocialEngagement engagement) async {
    final emailController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Convert ${engagement.userName} to lead'),
        content: TextField(
          key: const Key('convertEmail'),
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email address of the lead',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmConvert'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Convert'),
          ),
        ],
      ),
    );
    if (confirmed != true || emailController.text.isEmpty || !mounted) return;
    try {
      await context.read<RestClient>().convertEngagementToLead(
        engagementId: engagement.engagementId,
        email: emailController.text,
      );
      await _load();
      if (mounted) {
        HelperFunctions.showMessage(
          context,
          'Lead created with follow-up task',
          Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        HelperFunctions.showMessage(context, 'Convert failed: $e', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && engagements.isEmpty) {
      return const Center(child: LoadingIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return Stack(
      children: [
        engagements.isEmpty
            ? const Center(
                child: Text(
                  'No engagement signals yet.\nRecord likes, comments and '
                  'DM replies on your posts and convert them into leads.',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.builder(
                key: const Key('socialEngagementList'),
                itemCount: engagements.length,
                itemBuilder: (context, index) {
                  final engagement = engagements[index];
                  return ListTile(
                    key: Key('engagementItem$index'),
                    leading: Icon(
                      engagement.status == 'NEW'
                          ? Icons.fiber_new
                          : Icons.check_circle_outline,
                      color: engagement.status == 'NEW'
                          ? Colors.blue
                          : Colors.green,
                    ),
                    title: Text(
                      '${engagement.userName} — ${engagement.engagementType} '
                      '(${engagement.platform})',
                    ),
                    subtitle: Text(
                      '${engagement.status}'
                      '${engagement.note.isNotEmpty ? ' · ${engagement.note}' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: engagement.status == 'NEW'
                        ? TextButton(
                            key: Key('convert$index'),
                            onPressed: () => _convert(engagement),
                            child: const Text('To lead'),
                          )
                        : null,
                  );
                },
              ),
        Positioned(
          right: 20,
          bottom: 50,
          child: FloatingActionButton(
            key: const Key('addNew'),
            onPressed: _record,
            tooltip: 'Record engagement',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
