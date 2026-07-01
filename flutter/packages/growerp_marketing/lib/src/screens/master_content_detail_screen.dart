/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/master_content_bloc.dart';
import '../bloc/master_content_event.dart';
import '../bloc/master_content_state.dart';
import '../bloc/social_post_bloc.dart';
import 'social_post_detail_screen.dart';

class MasterContentDetailScreen extends StatefulWidget {
  final MasterContent? masterContent;

  const MasterContentDetailScreen({super.key, this.masterContent});

  @override
  MasterContentDetailScreenState createState() =>
      MasterContentDetailScreenState();
}

class MasterContentDetailScreenState
    extends State<MasterContentDetailScreen> {
  late ScrollController _scrollController;
  late bool isPhone;
  late bool isVisible;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _pseudoIdController;
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _ctaController;
  late TextEditingController _urlController;

  String _selectedContentType = 'POSTING';
  String _selectedPnpType = 'OTHER';
  String _selectedStatus = 'DRAFT';

  late MasterContentBloc _bloc;

  // The 6 supported platforms; user picks a subset to adapt to.
  static const List<String> allPlatforms = [
    'LINKEDIN',
    'TWITTER',
    'FACEBOOK',
    'MEDIUM',
    'SUBSTACK',
    'EMAIL',
  ];
  final Set<String> _selectedPlatforms = {...allPlatforms};

  static const List<String> contentTypes = ['POSTING', 'ARTICLE', 'MESSAGE'];
  static const List<String> pnpTypes = ['PAIN', 'NEWS', 'PRIZE', 'OTHER'];
  static const List<String> statuses = ['DRAFT', 'APPROVED', 'ADAPTED'];

  /// The adapted per-platform SocialPost children of this master piece.
  Future<SocialPosts>? _variantsFuture;

  void _loadVariants() {
    final id = widget.masterContent?.masterContentId;
    if (id == null) return;
    setState(() {
      _variantsFuture = _bloc.restClient.getSocialPosts(masterContentId: id);
    });
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    isVisible = true;

    _pseudoIdController =
        TextEditingController(text: widget.masterContent?.pseudoId ?? '');
    _titleController =
        TextEditingController(text: widget.masterContent?.title ?? '');
    _bodyController =
        TextEditingController(text: widget.masterContent?.body ?? '');
    _ctaController =
        TextEditingController(text: widget.masterContent?.callToAction ?? '');
    _urlController =
        TextEditingController(text: widget.masterContent?.targetUrl ?? '');

    _selectedContentType = widget.masterContent?.contentType ?? 'POSTING';
    _selectedPnpType = widget.masterContent?.pnpType ?? 'OTHER';
    _selectedStatus = widget.masterContent?.status ?? 'DRAFT';

    _bloc = context.read<MasterContentBloc>();
    _loadVariants();

    _scrollController.addListener(() {
      if (isVisible &&
          _scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        if (mounted) setState(() => isVisible = false);
      }
      if (!isVisible &&
          _scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        if (mounted) setState(() => isVisible = true);
      }
    });
  }

  @override
  void dispose() {
    _pseudoIdController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _ctaController.dispose();
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;

    return Dialog(
      key: Key('MasterContentDetail${widget.masterContent?.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title:
            "Master Content #${widget.masterContent?.pseudoId ?? 'New'}",
        width: isPhone ? 400 : 800,
        height: isPhone ? 700 : 750,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                BlocConsumer<MasterContentBloc, MasterContentState>(
                  listener: (context, state) {
                    if (state.status == MasterContentStatus.failure) {
                      HelperFunctions.showMessage(
                          context, state.message ?? 'Error', Colors.red);
                    }
                    if (state.status == MasterContentStatus.success &&
                        state.message != null) {
                      // Adapt keeps the dialog open (shows results); create/update close it.
                      if (state.message!.contains('created') ||
                          state.message!.contains('updated') ||
                          state.message!.contains('deleted')) {
                        Navigator.of(context).pop();
                      } else {
                        HelperFunctions.showMessage(
                            context, state.message!, Colors.green);
                        // an adapt run just finished — reload the variants list
                        _loadVariants();
                      }
                    }
                  },
                  builder: (context, state) {
                    if (state.status == MasterContentStatus.loading) {
                      return const LoadingIndicator();
                    }
                    return _buildContent(state);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(MasterContentState state) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const Key('masterContentDetailListView'),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GroupingDecorator(
              labelText: 'Content Information',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('pseudoId'),
                          decoration: const InputDecoration(
                            labelText: 'ID',
                            hintText: 'Leave empty to auto-generate',
                          ),
                          controller: _pseudoIdController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('contentType'),
                          decoration:
                              const InputDecoration(labelText: 'Content Type *'),
                          initialValue: _selectedContentType,
                          items: contentTypes
                              .map((t) => DropdownMenuItem<String>(
                                  value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedContentType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('pnpType'),
                          decoration:
                              const InputDecoration(labelText: 'PNP Angle'),
                          initialValue: _selectedPnpType,
                          items: pnpTypes
                              .map((t) => DropdownMenuItem<String>(
                                  value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedPnpType = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('status'),
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          initialValue: _selectedStatus,
                          items: statuses
                              .map((t) => DropdownMenuItem<String>(
                                  value: t, child: Text(t)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedStatus = v!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GroupingDecorator(
              labelText: 'Platform-neutral content',
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('title'),
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Enter a title',
                    ),
                    controller: _titleController,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('body'),
                    decoration: const InputDecoration(
                      labelText: 'Body *',
                      hintText:
                          'Canonical content — no hashtags/platform styling',
                      alignLabelWithHint: true,
                    ),
                    controller: _bodyController,
                    maxLines: 8,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Body is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('callToAction'),
                    decoration: const InputDecoration(
                      labelText: 'Call to action',
                    ),
                    controller: _ctaController,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('targetUrl'),
                    decoration: const InputDecoration(
                      labelText: 'Target URL',
                      hintText: 'Withheld for LinkedIn/DM on adaptation',
                    ),
                    controller: _urlController,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('masterContentDetailSave'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final mc = MasterContent(
                          masterContentId:
                              widget.masterContent?.masterContentId,
                          pseudoId: _pseudoIdController.text.isEmpty
                              ? null
                              : _pseudoIdController.text,
                          planId: widget.masterContent?.planId,
                          contentType: _selectedContentType,
                          pnpType: _selectedPnpType,
                          title: _titleController.text.isEmpty
                              ? null
                              : _titleController.text,
                          body: _bodyController.text.isEmpty
                              ? null
                              : _bodyController.text,
                          callToAction: _ctaController.text.isEmpty
                              ? null
                              : _ctaController.text,
                          targetUrl: _urlController.text.isEmpty
                              ? null
                              : _urlController.text,
                          status: _selectedStatus,
                        );
                        if (widget.masterContent?.masterContentId == null) {
                          _bloc.add(MasterContentCreate(mc));
                        } else {
                          _bloc.add(MasterContentUpdate(mc));
                        }
                      }
                    },
                    child: Text(
                        widget.masterContent?.masterContentId == null
                            ? 'Create'
                            : 'Update'),
                  ),
                ),
              ],
            ),
            if (widget.masterContent?.masterContentId != null) ...[
              const SizedBox(height: 20),
              _buildAdaptSection(state),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAdaptSection(MasterContentState state) {
    return GroupingDecorator(
      labelText: 'Adapt to platforms',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: allPlatforms.map((p) {
              final selected = _selectedPlatforms.contains(p);
              return FilterChip(
                key: Key('platformChip$p'),
                label: Text(p),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _selectedPlatforms.add(p);
                  } else {
                    _selectedPlatforms.remove(p);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('adaptButton'),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Adapt to selected platforms'),
              onPressed: _selectedPlatforms.isEmpty
                  ? null
                  : () => _bloc.add(
                        MasterContentAdaptForPlatform(
                          masterContentId:
                              widget.masterContent!.masterContentId!,
                          platforms: _selectedPlatforms.toList(),
                        ),
                      ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Platform variants',
              style: Theme.of(context).textTheme.titleSmall),
          _buildVariants(),
        ],
      ),
    );
  }

  /// Lists the adapted per-platform SocialPost children. Tap a variant to
  /// edit/publish it via the existing Social Post dialog.
  Widget _buildVariants() {
    return FutureBuilder<SocialPosts>(
      future: _variantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8),
            child: LinearProgressIndicator(),
          );
        }
        final posts = snapshot.data?.socialPosts ?? const <SocialPost>[];
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No platform variants yet — adapt to create them.'),
          );
        }
        return Column(
          children: posts.map((post) {
            return ListTile(
              key: Key('variant${post.platform}'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.subdirectory_arrow_right, size: 18),
              title: Text(post.platform ?? '-'),
              subtitle: post.publishError != null &&
                      post.publishError!.isNotEmpty
                  ? Text(post.publishError!,
                      style: TextStyle(color: Colors.red[700], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)
                  : Text(post.publishedUrl ?? '',
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              trailing: Text(post.status,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              onTap: () async {
                await showDialog(
                  barrierDismissible: true,
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: context.read<SocialPostBloc>(),
                    child: SocialPostDetailScreen(socialPost: post),
                  ),
                );
                _loadVariants();
              },
            );
          }).toList(),
        );
      },
    );
  }
}
