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

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  static const List<String> postTypes = ['PAIN', 'NEWS', 'PRIZE', 'OTHER'];
  static const List<String> postStatuses = ['DRAFT', 'READY', 'PUBLISHED'];
  static const List<String> platforms = [
    'LINKEDIN',
    'TWITTER',
    'FACEBOOK',
    'INSTAGRAM'
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedScheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedScheduledDate) {
      setState(() {
        _selectedScheduledDate = picked;
      });
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
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('None'),
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
                      labelText: 'Headline',
                      hintText: 'Enter a catchy headline',
                    ),
                    controller: _headlineController,
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
                    child: const Text('Cancel'),
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
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledDateField() {
    return InkWell(
      key: const Key('scheduledDate'),
      onTap: () => _selectScheduledDate(context),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Scheduled Date',
          suffixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _selectedScheduledDate != null
              ? '${_selectedScheduledDate!.month}/${_selectedScheduledDate!.day}/${_selectedScheduledDate!.year}'
              : 'Select date',
        ),
      ),
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a marketing plan';
            }
            return null;
          },
          items: state.contentPlans.map((plan) {
            return DropdownMenuItem<String>(
              value: plan.planId,
              child: Text(
                '${plan.pseudoId} - ${plan.theme?.truncate(isPhone ? 25 : 40) ?? "No Theme"}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
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
