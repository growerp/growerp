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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';
import '../bloc/landing_page_state.dart';

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

class LandingPageDialog extends StatefulWidget {
  final LandingPage landingPage;
  const LandingPageDialog({Key? key, required this.landingPage})
      : super(key: key);

  @override
  LandingPageDialogState createState() => LandingPageDialogState();
}

class LandingPageDialogState extends State<LandingPageDialog> {
  late final GlobalKey<FormState> _landingPageFormKey;
  final _titleController = TextEditingController();
  final _headlineController = TextEditingController();
  final _subheadingController = TextEditingController();
  final _privacyPolicyUrlController = TextEditingController();

  late String _selectedStatus;
  late String? _selectedHookType;
  late LandingPage updatedLandingPage;
  late LandingPageBloc _landingPageBloc;
  late bool isPhone;
  late double bottom;
  double? right;
  late double top;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _landingPageFormKey = GlobalKey<FormState>();

    if (widget.landingPage.landingPageId != null) {
      _titleController.text = widget.landingPage.title;
      _headlineController.text = widget.landingPage.headline ?? '';
      _subheadingController.text = widget.landingPage.subheading ?? '';
      _privacyPolicyUrlController.text =
          widget.landingPage.privacyPolicyUrl ?? '';
    }

    _selectedStatus = widget.landingPage.status;
    _selectedHookType = _normalizeHookType(widget.landingPage.hookType);
    updatedLandingPage = widget.landingPage;
    _landingPageBloc = context.read<LandingPageBloc>();
    top = -100;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _headlineController.dispose();
    _subheadingController.dispose();
    _privacyPolicyUrlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isPhone = ResponsiveBreakpoints.of(context).isMobile;
    right = right ?? (isPhone ? 20 : 40);

    final String title = widget.landingPage.pseudoId ?? 'New Landing Page';

    return Dialog(
      key: const Key('LandingPageDialog'),
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: title,
        width: isPhone ? 400 : 900,
        height: isPhone ? 700 : 600,
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: isPhone ? null : _updateButton(),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
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
                      Navigator.of(context).pop(state.selectedLandingPage);
                    }
                  },
                  builder: (context, state) {
                    if (state.status == LandingPageStatus.loading) {
                      return const LoadingIndicator();
                    }
                    return _showForm();
                  },
                ),
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
                        FloatingActionButton(
                          key: const Key("delete"),
                          heroTag: "landingPageDelete",
                          backgroundColor: Colors.red,
                          onPressed: widget.landingPage.landingPageId == null
                              ? null
                              : () {
                                  showDialog(
                                    barrierDismissible: true,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Dialog(
                                        child: popUp(
                                          context: context,
                                          title: 'Delete landing page?',
                                          child: Column(
                                            children: [
                                              const Text(
                                                'Are you sure you want to delete this landing page?',
                                              ),
                                              const SizedBox(height: 20),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                      context,
                                                    ),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      _landingPageBloc.add(
                                                        LandingPageDelete(
                                                          widget.landingPage
                                                                  .landingPageId ??
                                                              '',
                                                        ),
                                                      );
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                          child: const Icon(Icons.delete_forever),
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

  Widget _showForm() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Form(
        key: _landingPageFormKey,
        child: Column(
          children: [
            _landingPageForm(),
            if (isPhone) const SizedBox(height: 20),
            if (isPhone) _updateButton(),
          ],
        ),
      ),
    );
  }

  Widget _landingPageForm() {
    return Column(
      children: [
        GroupingDecorator(
          labelText: 'Landing Page Information',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('id'),
                      decoration: const InputDecoration(
                        labelText: 'ID',
                      ),
                      controller: _titleController,
                      enabled: widget.landingPage.landingPageId == null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: const Key('status'),
                      decoration: const InputDecoration(labelText: 'Status'),
                      hint: const Text('Select status'),
                      initialValue: _selectedStatus.toUpperCase(),
                      items: ['DRAFT', 'ACTIVE', 'INACTIVE'].map((item) {
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
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('headline'),
                      decoration: const InputDecoration(labelText: 'Headline'),
                      controller: _headlineController,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      key: const Key('hookType'),
                      decoration: const InputDecoration(labelText: 'Hook Type'),
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
              TextFormField(
                key: const Key('subheading'),
                decoration: const InputDecoration(labelText: 'Subheading'),
                controller: _subheadingController,
                maxLines: 2,
              ),
              TextFormField(
                key: const Key('privacyPolicyUrl'),
                decoration: const InputDecoration(
                  labelText: 'Privacy Policy URL',
                ),
                controller: _privacyPolicyUrlController,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _updateButton() {
    return Column(
      children: [
        SizedBox(
          width: 300,
          child: ElevatedButton(
            key: const Key('update'),
            onPressed: () {
              if (_landingPageFormKey.currentState!.validate()) {
                updatedLandingPage = widget.landingPage.copyWith(
                  title: _titleController.text,
                  headline: _headlineController.text,
                  subheading: _subheadingController.text,
                  hookType: _selectedHookType,
                  status: _selectedStatus,
                  privacyPolicyUrl: _privacyPolicyUrlController.text,
                );

                if (widget.landingPage.landingPageId == null) {
                  _landingPageBloc.add(
                    LandingPageCreate(updatedLandingPage),
                  );
                } else {
                  _landingPageBloc.add(
                    LandingPageUpdate(updatedLandingPage),
                  );
                }
              }
            },
            child: Text(
              widget.landingPage.landingPageId == null ? 'Create' : 'Update',
            ),
          ),
        ),
      ],
    );
  }
}
