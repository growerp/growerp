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
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';
import '../bloc/landing_page_state.dart';
import '../bloc/assessment_bloc.dart';
import 'page_section_list.dart';
import 'credibility_info_list.dart';

/// Maps backend hookType format to dropdown values
/// Backend returns formats like 'ResultsHook', 'FrustrationHook'
/// Dropdown expects: 'frustration', 'results', 'custom'
String? _normalizeHookType(String? hookType) {
  if (hookType == null) return null;
  final lowerType = hookType.toLowerCase();
  if (lowerType.contains('frustr')) return 'frustration';
  if (lowerType.contains('result')) return 'results';
  if (lowerType.contains('custom')) return 'custom';
  return null;
}

class LandingPageDetailScreen extends StatefulWidget {
  final LandingPage landingPage;

  const LandingPageDetailScreen({
    super.key,
    required this.landingPage,
  });

  @override
  LandingPageDetailScreenState createState() => LandingPageDetailScreenState();
}

class LandingPageDetailScreenState extends State<LandingPageDetailScreen> {
  late ScrollController _scrollController;
  late bool isPhone;
  late double top;
  double? right;
  late bool isVisible;

  // Form controllers
  late TextEditingController _pseudoIdController;
  late TextEditingController _titleController;
  late TextEditingController _headlineController;
  late TextEditingController _subheadingController;
  late TextEditingController _privacyPolicyUrlController;
  late TextEditingController _ctaLinkController;
  late TextEditingController _assessmentSearchBoxController;

  late String _selectedStatus;
  late String? _selectedHookType;
  late String _selectedCtaActionType; // 'assessment' or 'url'
  late String? _selectedCtaAssessmentId;
  late LandingPage updatedLandingPage;
  late LandingPageBloc _landingPageBloc;
  late AssessmentBloc _assessmentBloc;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    top = 250; // Start lower on the screen
    isVisible = true;

    // Initialize form controllers
    _pseudoIdController =
        TextEditingController(text: widget.landingPage.pseudoId ?? '');
    _titleController = TextEditingController(text: widget.landingPage.title);
    _headlineController =
        TextEditingController(text: widget.landingPage.headline ?? '');
    _subheadingController =
        TextEditingController(text: widget.landingPage.subheading ?? '');
    _privacyPolicyUrlController =
        TextEditingController(text: widget.landingPage.privacyPolicyUrl ?? '');
    _ctaLinkController =
        TextEditingController(text: widget.landingPage.ctaButtonLink ?? '');
    _assessmentSearchBoxController = TextEditingController();

    _selectedStatus = widget.landingPage.status.toUpperCase();
    _selectedHookType = _normalizeHookType(widget.landingPage.hookType);
    _selectedCtaActionType = widget.landingPage.ctaActionType ?? 'assessment';
    _selectedCtaAssessmentId = widget.landingPage.ctaAssessmentId;
    updatedLandingPage = widget.landingPage;
    _landingPageBloc = context.read<LandingPageBloc>();
    _assessmentBloc = context.read<AssessmentBloc>();

    // Load assessments if not already loaded
    if (_assessmentBloc.state.assessments.isEmpty) {
      _assessmentBloc.add(const AssessmentFetch());
    }

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
    _titleController.dispose();
    _headlineController.dispose();
    _subheadingController.dispose();
    _privacyPolicyUrlController.dispose();
    _ctaLinkController.dispose();
    _assessmentSearchBoxController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 40);

    return Dialog(
      key: Key('LandingPageDetail${widget.landingPage.pseudoId}'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: "Landing Page #${widget.landingPage.pseudoId ?? 'New'}",
        width: isPhone ? 400 : 900,
        height: isPhone ? 700 : 600,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                BlocConsumer<LandingPageBloc, LandingPageState>(
                  listener: (context, state) {
                    if (state.status == LandingPageStatus.failure) {
                      HelperFunctions.showMessage(
                        context,
                        state.message ?? 'Error',
                        Colors.red,
                      );
                    }
                    if (state.status == LandingPageStatus.success) {
                      Navigator.of(context).pop(
                        state.selectedLandingPage,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state.status == LandingPageStatus.loading) {
                      return const LoadingIndicator();
                    }
                    return _buildContent();
                  },
                ),
                if (!isPhone)
                  Positioned(
                    right: right,
                    top: top,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          top += details.delta.dy;
                          right = right! - details.delta.dx;
                        });
                      },
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            key: const Key("sections"),
                            tooltip: 'Page Sections',
                            heroTag: "pageSections",
                            backgroundColor:
                                widget.landingPage.landingPageId == null
                                    ? Colors.grey
                                    : null,
                            onPressed: widget.landingPage.landingPageId == null
                                ? () {
                                    HelperFunctions.showMessage(
                                      context,
                                      'Please save the landing page first',
                                      Colors.orange,
                                    );
                                  }
                                : () async => await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          child: popUp(
                                            context: context,
                                            title: 'Page Sections',
                                            height: 600,
                                            width: 800,
                                            child: _buildSectionsPlaceholder(),
                                          ),
                                        );
                                      },
                                    ),
                            child: const Icon(Icons.view_list),
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton(
                            key: const Key("credibility"),
                            tooltip: 'Credibility Info',
                            heroTag: "credibilityInfo",
                            backgroundColor:
                                widget.landingPage.landingPageId == null
                                    ? Colors.grey
                                    : null,
                            onPressed: widget.landingPage.landingPageId == null
                                ? () {
                                    HelperFunctions.showMessage(
                                      context,
                                      'Please save the landing page first',
                                      Colors.orange,
                                    );
                                  }
                                : () async => await showDialog(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          child: popUp(
                                            context: context,
                                            title: 'Credibility Information',
                                            height: 600,
                                            width: 800,
                                            child:
                                                _buildCredibilityPlaceholder(),
                                          ),
                                        );
                                      },
                                    ),
                            child: const Icon(Icons.verified_user),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
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
      child: SingleChildScrollView(
        controller: _scrollController,
        key: const Key('landingPageDetailListView'),
        child: Column(
          children: [
            const SizedBox(height: 10),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Landing Page Information',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('id'),
                          decoration: const InputDecoration(labelText: 'ID'),
                          controller: _pseudoIdController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'ID is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          key: const Key('status'),
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          hint: const Text('Select status'),
                          initialValue: _selectedStatus.toUpperCase(),
                          items: ['DRAFT', 'ACTIVE', 'INACTIVE', 'PUBLISHED']
                              .map((item) {
                            return DropdownMenuItem<String>(
                              value: item,
                              child: Text(item),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedStatus = newValue ?? 'DRAFT';
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('title'),
                          decoration: const InputDecoration(labelText: 'Title'),
                          controller: _titleController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Title is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          key: const Key('hookType'),
                          decoration:
                              const InputDecoration(labelText: 'Hook Type'),
                          hint: const Text('Select hook type'),
                          initialValue: _selectedHookType,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('None'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'frustration',
                              child: Text('Frustration'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'results',
                              child: Text('Results'),
                            ),
                            const DropdownMenuItem<String>(
                              value: 'custom',
                              child: Text('Custom'),
                            ),
                          ].toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedHookType = newValue;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('headline'),
                          decoration:
                              const InputDecoration(labelText: 'Headline'),
                          controller: _headlineController,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('subheading'),
                          decoration:
                              const InputDecoration(labelText: 'Subheading'),
                          controller: _subheadingController,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('privacyPolicyUrl'),
                          decoration: const InputDecoration(
                              labelText: 'Privacy Policy URL'),
                          controller: _privacyPolicyUrlController,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Call-to-Action Configuration',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex:
                            ResponsiveBreakpoints.of(context).isMobile ? 1 : 2,
                        child: DropdownButtonFormField<String>(
                          key: const Key('ctaActionType'),
                          decoration: const InputDecoration(
                            labelText: 'CTA Action Type',
                            prefixIcon: Icon(Icons.touch_app),
                          ),
                          initialValue: _selectedCtaActionType,
                          items: const [
                            DropdownMenuItem<String>(
                              value: 'assessment',
                              child: Text('Launch Assessment'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'url',
                              child: Text('Open URL/Webpage'),
                            ),
                          ],
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCtaActionType = newValue ?? 'assessment';
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                      if (!ResponsiveBreakpoints.of(context).isMobile)
                        const SizedBox(width: 10),
                      if (!ResponsiveBreakpoints.of(context).isMobile)
                        Expanded(
                          flex: 3,
                          child: _selectedCtaActionType == 'assessment'
                              ? BlocBuilder<AssessmentBloc, AssessmentState>(
                                  builder: (context, state) {
                                    // Find the selected CTA assessment from the list
                                    Assessment? selectedCtaAssessment;
                                    if (_selectedCtaAssessmentId != null &&
                                        state.assessments.isNotEmpty) {
                                      try {
                                        selectedCtaAssessment =
                                            state.assessments.firstWhere(
                                          (a) =>
                                              a.assessmentId ==
                                              _selectedCtaAssessmentId,
                                          orElse: () => throw Exception(
                                              'Assessment not found'),
                                        );
                                      } catch (e) {
                                        // Assessment not found in list
                                        selectedCtaAssessment = null;
                                      }
                                    }

                                    return DropdownSearch<Assessment>(
                                      key: const Key('ctaAssessmentDropdown'),
                                      selectedItem: selectedCtaAssessment,
                                      items: state.assessments,
                                      itemAsString: (Assessment a) =>
                                          '${a.pseudoId} - ${a.assessmentName}',
                                      popupProps: PopupProps.menu(
                                        showSearchBox: true,
                                        searchFieldProps: const TextFieldProps(
                                          autofocus: true,
                                          decoration: InputDecoration(
                                            labelText: 'Search assessments...',
                                            prefixIcon: Icon(Icons.search),
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(8),
                                              ),
                                            ),
                                          ),
                                        ),
                                        menuProps: MenuProps(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          elevation: 8,
                                        ),
                                      ),
                                      dropdownDecoratorProps:
                                          DropDownDecoratorProps(
                                        dropdownSearchDecoration:
                                            InputDecoration(
                                          labelText: 'CTA Assessment',
                                          hintText:
                                              'Select assessment to launch',
                                          prefixIcon: const Icon(Icons.quiz),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                      onChanged: (Assessment? newValue) {
                                        setState(() {
                                          _selectedCtaAssessmentId =
                                              newValue?.assessmentId;
                                        });
                                      },
                                    );
                                  },
                                )
                              : TextFormField(
                                  key: const Key('ctaLink'),
                                  decoration: InputDecoration(
                                    labelText: 'CTA URL',
                                    hintText: 'https://example.com/page',
                                    prefixIcon: const Icon(Icons.link),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  controller: _ctaLinkController,
                                ),
                        ),
                    ],
                  ),
                  if (ResponsiveBreakpoints.of(context).isMobile)
                    const SizedBox(height: 10),
                  if (ResponsiveBreakpoints.of(context).isMobile &&
                      _selectedCtaActionType == 'assessment')
                    Row(
                      children: [
                        Expanded(
                          child: BlocBuilder<AssessmentBloc, AssessmentState>(
                            builder: (context, state) {
                              // Find the selected CTA assessment from the list
                              Assessment? selectedCtaAssessment;
                              if (_selectedCtaAssessmentId != null &&
                                  state.assessments.isNotEmpty) {
                                try {
                                  selectedCtaAssessment =
                                      state.assessments.firstWhere(
                                    (a) =>
                                        a.assessmentId ==
                                        _selectedCtaAssessmentId,
                                    orElse: () =>
                                        throw Exception('Assessment not found'),
                                  );
                                } catch (e) {
                                  selectedCtaAssessment = null;
                                }
                              }

                              return DropdownSearch<Assessment>(
                                key: const Key('ctaAssessmentDropdown'),
                                selectedItem: selectedCtaAssessment,
                                items: state.assessments,
                                itemAsString: (Assessment a) =>
                                    '${a.pseudoId} - ${a.assessmentName}',
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: const TextFieldProps(
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      labelText: 'Search assessments...',
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                  ),
                                  menuProps: MenuProps(
                                    borderRadius: BorderRadius.circular(20.0),
                                  ),
                                  title: popUp(
                                    context: context,
                                    title: 'Select CTA Assessment',
                                    height: 50,
                                  ),
                                  emptyBuilder: (context, searchEntry) =>
                                      const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Text(
                                        'No assessments found',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                dropdownDecoratorProps:
                                    const DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'CTA Assessment',
                                    hintText: 'Select assessment to launch',
                                    prefixIcon: Icon(Icons.quiz),
                                  ),
                                ),
                                onChanged: (Assessment? newValue) {
                                  setState(() {
                                    _selectedCtaAssessmentId =
                                        newValue?.assessmentId;
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  if (ResponsiveBreakpoints.of(context).isMobile &&
                      _selectedCtaActionType == 'url')
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const Key('ctaLink'),
                            decoration: const InputDecoration(
                              labelText: 'CTA URL',
                              hintText: 'https://example.com/page',
                              prefixIcon: Icon(Icons.link),
                            ),
                            controller: _ctaLinkController,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (isPhone) _buildMobileActionButtons(),
            if (isPhone) const SizedBox(height: 20),
            _updateButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _updateButton() {
    return Padding(
      padding: ResponsiveBreakpoints.of(context).isMobile
          ? const EdgeInsets.all(10)
          : const EdgeInsets.only(left: 10, right: 10, top: 5, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const Key("landingPageDetailDelete"),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
              ),
              child: const Text('Delete'),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete Landing Page'),
                      content: const Text(
                        'Are you sure you want to delete this landing page?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
                if (confirmed == true && mounted) {
                  _landingPageBloc.add(
                    LandingPageDelete(widget.landingPage.landingPageId ?? ''),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton(
              key: const Key("landingPageDetailSave"),
              child: const Text('Save'),
              onPressed: () async {
                updatedLandingPage = widget.landingPage.copyWith(
                  pseudoId: _pseudoIdController.text,
                  title: _titleController.text,
                  headline: _headlineController.text,
                  subheading: _subheadingController.text,
                  hookType: _selectedHookType,
                  status: _selectedStatus,
                  privacyPolicyUrl: _privacyPolicyUrlController.text,
                  ctaActionType: _selectedCtaActionType,
                  ctaAssessmentId: _selectedCtaActionType == 'assessment'
                      ? _selectedCtaAssessmentId
                      : null,
                  ctaButtonLink: _selectedCtaActionType == 'url'
                      ? _ctaLinkController.text
                      : null,
                );
                _landingPageBloc.add(LandingPageUpdate(updatedLandingPage));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key("mobileSections"),
              icon: const Icon(Icons.view_list),
              label: const Text('Sections'),
              style: widget.landingPage.landingPageId == null
                  ? OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                    )
                  : null,
              onPressed: widget.landingPage.landingPageId == null
                  ? () {
                      HelperFunctions.showMessage(
                        context,
                        'Please save the landing page first',
                        Colors.orange,
                      );
                    }
                  : () async => await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: popUp(
                              context: context,
                              title: 'Page Sections',
                              height: 600,
                              width: 400,
                              child: _buildSectionsPlaceholder(),
                            ),
                          );
                        },
                      ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              key: const Key("mobileCredibility"),
              icon: const Icon(Icons.verified_user),
              label: const Text('Credibility'),
              style: widget.landingPage.landingPageId == null
                  ? OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                    )
                  : null,
              onPressed: widget.landingPage.landingPageId == null
                  ? () {
                      HelperFunctions.showMessage(
                        context,
                        'Please save the landing page first',
                        Colors.orange,
                      );
                    }
                  : () async => await showDialog(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            child: popUp(
                              context: context,
                              title: 'Credibility Info',
                              height: 600,
                              width: 400,
                              child: _buildCredibilityPlaceholder(),
                            ),
                          );
                        },
                      ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsPlaceholder() {
    return PageSectionList(
      landingPageId: widget.landingPage.landingPageId ?? '',
    );
  }

  Widget _buildCredibilityPlaceholder() {
    return CredibilityInfoListScreen(
      landingPageId: widget.landingPage.landingPageId ?? '',
    );
  }
}
