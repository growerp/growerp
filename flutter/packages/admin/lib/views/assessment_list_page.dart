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
import 'package:growerp_assessment/growerp_assessment.dart';

/// Assessment Flow Wrapper
/// Wraps the assessment flow screen for use in menu navigation
class AssessmentFlowWrapper extends StatefulWidget {
  const AssessmentFlowWrapper({super.key});

  @override
  State<AssessmentFlowWrapper> createState() => _AssessmentFlowWrapperState();
}

class _AssessmentFlowWrapperState extends State<AssessmentFlowWrapper> {
  late String _assessmentId;
  bool _flowComplete = false;

  @override
  void initState() {
    super.initState();
    // Generate a new assessment ID for each flow
    _assessmentId = 'assessment_${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Widget build(BuildContext context) {
    if (_flowComplete) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Assessment Completed'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _flowComplete = false;
                  _assessmentId =
                      'assessment_${DateTime.now().millisecondsSinceEpoch}';
                });
              },
              child: const Text('Start New Assessment'),
            ),
          ],
        ),
      );
    }

    return AssessmentFlowScreen(
      assessmentId: _assessmentId,
      onComplete: () {
        setState(() => _flowComplete = true);
      },
    );
  }
}

/// Assessment Results Wrapper
/// Wraps the assessment results screen for use in menu navigation
class AssessmentResultsWrapper extends StatefulWidget {
  const AssessmentResultsWrapper({super.key});

  @override
  State<AssessmentResultsWrapper> createState() =>
      _AssessmentResultsWrapperState();
}

class _AssessmentResultsWrapperState extends State<AssessmentResultsWrapper> {
  late String _assessmentId;
  late String _respondentName;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _assessmentId = 'assessment_last';
    _respondentName = 'Respondent';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssessmentBloc, AssessmentState>(
      listener: (context, state) {
        if (state is AssessmentSubmitted) {
          setState(() {
            _showResults = true;
            _respondentName = state.result.respondentName;
            _assessmentId = state.result.assessmentId;
          });
        }
      },
      child: _showResults
          ? AssessmentResultsScreen(
              assessmentId: _assessmentId,
              respondentName: _respondentName,
              onComplete: () {
                setState(() => _showResults = false);
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_turned_in,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  const Text('No Assessment Results Available'),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete an assessment in the Lead Capture tab to view results',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to Lead Capture tab
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please complete an assessment first'),
                        ),
                      );
                    },
                    child: const Text('Go to Lead Capture'),
                  ),
                ],
              ),
            ),
    );
  }
}
