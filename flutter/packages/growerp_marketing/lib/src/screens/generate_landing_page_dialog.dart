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
import '../bloc/landing_page_generation_bloc.dart';

class GenerateLandingPageDialog extends StatefulWidget {
  final Function(LandingPage) onSuccess;

  const GenerateLandingPageDialog({
    super.key,
    required this.onSuccess,
  });

  @override
  State<GenerateLandingPageDialog> createState() =>
      _GenerateLandingPageDialogState();
}

class _GenerateLandingPageDialogState extends State<GenerateLandingPageDialog> {
  final _descriptionController = TextEditingController();
  final _audienceController = TextEditingController();
  String? _selectedTone = 'professional';
  int _selectedSections = 5;

  @override
  Widget build(BuildContext context) {
    // Get RestClient from context before building the dialog
    final restClient = context.read<RestClient>();
    final isPhone = ResponsiveBreakpoints.of(context).isMobile;

    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: 'Generate Landing Page with AI',
        width: isPhone ? 400 : 600,
        height: isPhone ? 700 : 650,
        child: BlocProvider<LandingPageGenerationBloc>(
          create: (_) => LandingPageGenerationBloc(
            restClient: restClient,
            classificationId: 'AppAdmin',
          ),
          child: BlocConsumer<LandingPageGenerationBloc,
              LandingPageGenerationState>(
            listener: (context, state) {
              if (state.status == GenerationStatus.success) {
                if (state.generatedLandingPage != null) {
                  widget.onSuccess(state.generatedLandingPage!);
                  Navigator.of(context).pop();
                } else {
                  HelperFunctions.showMessage(
                    context,
                    'Error: Landing page was not created properly',
                    Colors.red,
                  );
                }
              } else if (state.status == GenerationStatus.failure) {
                // Show error message in a snackbar that appears above the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(state.message ?? 'Error generating landing page'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 5),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            builder: (context, state) {
              // Show progress view only for loading states, not for failure or success
              if (state.status == GenerationStatus.loading ||
                  state.status == GenerationStatus.researchingBusiness ||
                  state.status == GenerationStatus.generatingContent ||
                  state.status == GenerationStatus.creatingXml ||
                  state.status == GenerationStatus.importing) {
                return _buildProgressView(context, state);
              }

              // For initial, failure, and success (if dialog hasn't closed yet), show form
              return _buildFormView(context, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(
      BuildContext context, LandingPageGenerationState state) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Describe your business and let AI create a professional landing page',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Show error message if there was a failure
            if (state.status == GenerationStatus.failure) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.message ?? 'Error generating landing page',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Business Description
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Business Description*',
                hintText:
                    'E.g., I run a digital marketing agency helping small businesses with social media strategy...',
                helperText: 'Min 20 characters, Max 500 characters',
              ),
            ),
            const SizedBox(height: 16),

            // Target Audience
            TextField(
              controller: _audienceController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Target Audience (optional)',
                hintText: 'E.g., Small business owners with 1-10 employees...',
              ),
            ),
            const SizedBox(height: 16),

            // Advanced Options
            ExpansionTile(
              title: const Text('Advanced Options'),
              children: [
                Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTone,
                      items: ['professional', 'casual', 'inspirational']
                          .map((tone) => DropdownMenuItem(
                                value: tone,
                                child: Text(
                                    tone[0].toUpperCase() + tone.substring(1)),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedTone = value),
                      decoration: const InputDecoration(
                        labelText: 'Tone',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Page Sections: $_selectedSections'),
                        Slider(
                          value: _selectedSections.toDouble(),
                          min: 3,
                          max: 7,
                          divisions: 4,
                          label: '$_selectedSections',
                          onChanged: (value) =>
                              setState(() => _selectedSections = value.toInt()),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _descriptionController.text.length >= 20
                      ? () => _generateLandingPage(context)
                      : null,
                  child: const Text('Generate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressView(
      BuildContext context, LandingPageGenerationState state) {
    // For AI generation, use indeterminate spinner (no progress value)
    // For other states, show determinate progress
    final bool isAiGenerating =
        state.status == GenerationStatus.researchingBusiness;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indeterminate spinner for AI work, determinate for everything else
          SizedBox(
            width: 60,
            height: 60,
            child: isAiGenerating
                ? const CircularProgressIndicator(
                    strokeWidth: 4,
                  )
                : CircularProgressIndicator(
                    value: (state.progressPercent ?? 0) / 100,
                    strokeWidth: 4,
                  ),
          ),
          const SizedBox(height: 24),
          Text(
            state.message ?? 'Processing...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (!isAiGenerating)
            Text(
              '${state.progressPercent}%',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 16),
          // Show helpful hint for AI generation phase
          if (isAiGenerating) ...[
            const Text(
              'This may take 30-60 seconds...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'AI is analyzing your business and creating compelling content',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  void _generateLandingPage(BuildContext context) {
    context.read<LandingPageGenerationBloc>().add(
          GenerateLandingPageRequested(
            businessDescription: _descriptionController.text,
            targetAudience: _audienceController.text.isEmpty
                ? null
                : _audienceController.text,
            tone: _selectedTone,
            numSections: _selectedSections,
          ),
        );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _audienceController.dispose();
    super.dispose();
  }
}
