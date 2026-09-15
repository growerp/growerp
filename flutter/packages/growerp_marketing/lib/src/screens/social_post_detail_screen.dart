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
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../../growerp_marketing.dart';

class SocialPostDetailScreen extends StatefulWidget {
  final SocialPost? socialPost;

  const SocialPostDetailScreen({
    super.key,
    this.socialPost,
  });

  @override
  SocialPostDetailScreenState createState() => SocialPostDetailScreenState();
}

class SocialPostDetailScreenState extends State<SocialPostDetailScreen> {
  late ScrollController _scrollController;
  late bool isPhone;
  late double top;
  double? right;
  late bool isVisible;

  // Form key
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _pseudoIdController;
  late TextEditingController _headlineController;
  late TextEditingController _draftContentController;
  late TextEditingController _finalContentController;

  // Dropdown values
  String _selectedType = 'PAIN';
  String _selectedStatus = 'DRAFT';
  String? _selectedPlatform;
  DateTime? _selectedScheduledDate;
  String? _selectedPlanId;

  late SocialPost updatedSocialPost;
  late SocialPostBloc _socialPostBloc;

  /// Local hour a newly picked date defaults to, well inside working hours so a
  /// post never silently lands at midnight.
  static const int _defaultScheduleHour = 10;

  static const List<String> postTypes = ['PAIN', 'NEWS', 'PRIZE', 'OTHER'];
  static const List<String> postStatuses = ['DRAFT', 'READY', 'PUBLISHED'];
  static const List<String> platforms = [
    'LINKEDIN',
    'TWITTER',
    'FACEBOOK',
    'INSTAGRAM',
    'SUBSTACK',
    'SUBSTACK_NOTE',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    top = 250;
    isVisible = true;

    // Initialize form controllers
    _pseudoIdController =
        TextEditingController(text: widget.socialPost?.pseudoId ?? '');
    _headlineController =
        TextEditingController(text: widget.socialPost?.headline ?? '');
    _draftContentController =
        TextEditingController(text: widget.socialPost?.draftContent ?? '');
    _finalContentController =
        TextEditingController(text: widget.socialPost?.finalContent ?? '');

    // Initialize dropdown values
    _selectedType = widget.socialPost?.type ?? 'PAIN';
    _selectedStatus = widget.socialPost?.status ?? 'DRAFT';
    _selectedPlatform = widget.socialPost?.platform;
    _selectedScheduledDate = widget.socialPost?.scheduledDate;
    _selectedPlanId = widget.socialPost?.planId;

    updatedSocialPost = widget.socialPost ??
        const SocialPost(
          type: 'PAIN',
          status: 'DRAFT',
        );
    _socialPostBloc = context.read<SocialPostBloc>();
    context.read<ContentPlanBloc>().add(const ContentPlanFetch());

    _scrollController.addListener(() {
      if (isVisible &&
          _scrollController.position.userScrollDirection ==
              ScrollDirection.reverse) {
        if (mounted) {
          setState(() {
            isVisible = false;
          });
        }
      }
      if (!isVisible &&
          _scrollController.position.userScrollDirection ==
              ScrollDirection.forward) {
        if (mounted) {
          setState(() {
            isVisible = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pseudoIdController.dispose();
    _headlineController.dispose();
    _draftContentController.dispose();
    _finalContentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectScheduledDate(BuildContext context) async {
    final current = _selectedScheduledDate;
    final now = DateTime.now();
    // midnight, not now: with a firstDate carrying a time of day the picker
    // rejects today itself as out of range and keeps OK disabled
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    // showDatePicker returns midnight: keep the hour already chosen, otherwise
    // every post of a day lands in the same publish batch
    final withHour = DateTime(
      picked.year,
      picked.month,
      picked.day,
      current?.hour ?? _defaultScheduleHour,
    );
    if (withHour != current) {
      setState(() {
        _selectedScheduledDate = withHour;
      });
    }
  }

  /// Manual fallback for X/Twitter: posting normally goes through the API
  /// (publish#SocialPostToX). This copies the drafted text and opens X's
  /// compose intent so a post can still go out when the API call fails.
  Future<void> _copyAndOpenTwitter() async {
    final text = _finalContentController.text;
    await Clipboard.setData(ClipboardData(text: text));
    final uri = Uri.https('twitter.com', '/intent/tweet', {'text': text});
    final opened = await openExternalUrl(uri);
    if (mounted) {
      HelperFunctions.showMessage(
        context,
        opened
            ? 'Tweet copied — after posting, set status to PUBLISHED and Save'
            : 'Tweet copied, however could not open a browser, use: $uri',
        opened ? Colors.green : Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 40);

    return Dialog(
      key: Key('SocialPostDetail${widget.socialPost?.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: "Social Post #${widget.socialPost?.pseudoId ?? 'New'}",
        width: isPhone ? 400 : 800,
        height: isPhone ? 700 : 750,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                BlocConsumer<SocialPostBloc, SocialPostState>(
                  listener: (context, state) {
                    if (state.status == SocialPostStatus.failure) {
                      HelperFunctions.showMessage(
                        context,
                        state.message ?? 'Error',
                        Colors.red,
                      );
                    }
                    if (state.status == SocialPostStatus.success &&
                        state.message != null) {
                      Navigator.of(context).pop();
                    }
                  },
                  builder: (context, state) {
                    if (state.status == SocialPostStatus.loading) {
                      return const LoadingIndicator();
                    }
                    return _buildContent();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const Key('socialPostDetailListView'),
        child: Column(
          children: [
            const SizedBox(height: 10),
            GroupingDecorator(
              labelText: 'Post Information',
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
                          key: const Key('type'),
                          decoration: const InputDecoration(
                            labelText: 'Post Type *',
                          ),
                          initialValue: _selectedType,
                          items: postTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedType = newValue!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('status'),
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          initialValue: _selectedStatus,
                          items: postStatuses.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedStatus = newValue!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('platform'),
                          decoration: const InputDecoration(
                            labelText: 'Platform',
                            hintText: 'Select platform',
                          ),
                          initialValue: _selectedPlatform,
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text(MarketingLocalizations.of(context)!.none),
                            ),
                            ...platforms.map((platform) {
                              return DropdownMenuItem<String>(
                                value: platform,
                                child: Text(platform),
                              );
                            }),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedPlatform = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  isPhone
                      ? Column(
                          children: [
                            _buildScheduledDateField(),
                            const SizedBox(height: 10),
                            _buildMarketingPlanField(),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(child: _buildScheduledDateField()),
                            const SizedBox(width: 10),
                            Expanded(child: _buildMarketingPlanField()),
                          ],
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GroupingDecorator(
              labelText: 'Content',
              child: Column(
                children: [
                  TextFormField(
                    key: const Key('headline'),
                    decoration: const InputDecoration(
                      labelText: 'Headline *',
                      hintText: 'Enter a catchy headline',
                    ),
                    controller: _headlineController,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Headline is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('draftContent'),
                    decoration: const InputDecoration(
                      labelText: 'Draft Content',
                      hintText: 'Write or generate your post content...',
                      alignLabelWithHint: true,
                    ),
                    controller: _draftContentController,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    key: const Key('finalContent'),
                    decoration: const InputDecoration(
                      labelText: 'Final/Published Content',
                      hintText: 'Final version for publishing...',
                      alignLabelWithHint: true,
                    ),
                    controller: _finalContentController,
                    maxLines: 5,
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
                    child: Text(MarketingLocalizations.of(context)!.cancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('socialPostDetailSave'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final socialPost = SocialPost(
                          postId: widget.socialPost?.postId,
                          pseudoId: _pseudoIdController.text.isEmpty
                              ? null
                              : _pseudoIdController.text,
                          planId: _selectedPlanId,
                          type: _selectedType,
                          platform: _selectedPlatform,
                          headline: _headlineController.text.isEmpty
                              ? null
                              : _headlineController.text,
                          draftContent: _draftContentController.text.isEmpty
                              ? null
                              : _draftContentController.text,
                          finalContent: _finalContentController.text.isEmpty
                              ? null
                              : _finalContentController.text,
                          status: _selectedStatus,
                          scheduledDate: _selectedScheduledDate,
                        );

                        if (widget.socialPost?.postId == null) {
                          _socialPostBloc.add(SocialPostCreate(socialPost));
                        } else {
                          _socialPostBloc.add(SocialPostUpdate(socialPost));
                        }
                      }
                    },
                    child: Text(widget.socialPost?.postId == null
                        ? 'Create'
                        : 'Update'),
                  ),
                ),
              ],
            ),
            if (widget.socialPost?.postId != null &&
                (_selectedPlatform == 'SUBSTACK' ||
                    _selectedPlatform == 'SUBSTACK_NOTE' ||
                    _selectedPlatform == 'LINKEDIN' ||
                    _selectedPlatform == 'TWITTER')) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('publishButton'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPlatform == 'SUBSTACK' ||
                            _selectedPlatform == 'SUBSTACK_NOTE'
                        ? const Color(0xFFFF6719)
                        : _selectedPlatform == 'TWITTER'
                            ? Colors.black
                            : const Color(0xFF0A66C2),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send),
                  label: Text(
                    _selectedStatus == 'PUBLISHED'
                        ? 'Re-publish to $_selectedPlatform'
                        : 'Publish to $_selectedPlatform',
                  ),
                  onPressed: _finalContentController.text.isEmpty
                      ? null
                      : () => _socialPostBloc.add(
                            SocialPostPublish(
                                postId: widget.socialPost!.postId!),
                          ),
                ),
              ),
              if (widget.socialPost?.publishedUrl != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Published: ${widget.socialPost!.publishedUrl}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (widget.socialPost?.publishError != null &&
                  widget.socialPost!.publishError!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  'Last error: ${widget.socialPost!.publishError}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red[700],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
            if (widget.socialPost?.postId != null &&
                _selectedPlatform == 'TWITTER') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('copyAndOpenTwitter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(MarketingLocalizations.of(context)!.copyOpenX),
                  onPressed: _finalContentController.text.isEmpty
                      ? null
                      : () => _copyAndOpenTwitter(),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manual fallback — use this only if automated publishing fails. '
                'Post it yourself, then set status to PUBLISHED and Save.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledDateField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: InkWell(
            key: const Key('scheduledDate'),
            onTap: () => _selectScheduledDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText:
                    MarketingLocalizations.of(context)!.scheduledDateLabel,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                _selectedScheduledDate != null
                    ? _selectedScheduledDate.toLocalizedDateOnly(context)
                    : MarketingLocalizations.of(context)!.selectDate,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<int>(
            key: const Key('scheduledHour'),
            decoration: InputDecoration(
              labelText: MarketingLocalizations.of(context)!.scheduledHour,
            ),
            initialValue: _selectedScheduledDate?.hour,
            items: List.generate(
              24,
              (hour) => DropdownMenuItem<int>(
                value: hour,
                child: Text('${hour.toString().padLeft(2, '0')}:00'),
              ),
            ),
            onChanged: _selectedScheduledDate == null
                ? null
                : (hour) {
                    if (hour == null) return;
                    final date = _selectedScheduledDate!;
                    setState(() {
                      _selectedScheduledDate =
                          DateTime(date.year, date.month, date.day, hour);
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildMarketingPlanField() {
    return BlocBuilder<ContentPlanBloc, ContentPlanState>(
      builder: (context, state) {
        if (state.status == ContentPlanStatus.initial ||
            (state.status == ContentPlanStatus.loading &&
                state.contentPlans.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        // Ensure selected value exists in items
        String? value = _selectedPlanId;
        if (value != null &&
            !state.contentPlans.any((p) => p.planId == value)) {
          value = null;
        }
        return DropdownButtonFormField<String>(
          key: const Key('planId'),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Marketing Plan',
          ),
          initialValue: value,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(MarketingLocalizations.of(context)!.none),
            ),
            ...state.contentPlans.map((plan) => DropdownMenuItem<String>(
                  value: plan.planId,
                  child: Text(
                    '${plan.pseudoId} - ${plan.theme?.truncate(isPhone ? 25 : 40) ?? "No Theme"}',
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: (String? newValue) {
            setState(() {
              _selectedPlanId = newValue;
            });
          },
        );
      },
    );
  }
}
