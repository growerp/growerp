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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../../../services/get_dio_error.dart';

/// Post-login assessment "Do you need an ERP system?".
///
/// Replaces the old onboarding assistant. Loads the GROWERP-owned [ERP_NEED]
/// assessment, lets the (already authenticated) user answer the questions and
/// shows the scored result at the end. Self-contained: talks to [RestClient]
/// directly, no dedicated bloc.
class ErpAssessmentDialog extends StatefulWidget {
  const ErpAssessmentDialog({super.key, required this.authenticate});
  final Authenticate authenticate;

  /// Owner of the assessment and its scoring thresholds.
  static const String ownerPartyId = 'GROWERP';

  /// Assessment loaded for the post-login experience.
  static const String assessmentId = 'ERP_NEED';

  @override
  State<ErpAssessmentDialog> createState() => _ErpAssessmentDialogState();
}

enum _Phase { loading, questions, result, error }

class _ErpAssessmentDialogState extends State<ErpAssessmentDialog> {
  _Phase _phase = _Phase.loading;
  String? _message;
  Assessment? _assessment;
  AssessmentResult? _result;

  /// Selected option per question: questionId -> optionId.
  final Map<String, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadAssessment();
  }

  Future<void> _loadAssessment() async {
    try {
      final assessment =
          await context.read<RestClient>().getAssessmentComplete(
                assessmentId: ErpAssessmentDialog.assessmentId,
                ownerPartyId: ErpAssessmentDialog.ownerPartyId,
              );
      if (!mounted) return;
      setState(() {
        _assessment = assessment;
        _phase = (assessment.questions?.isNotEmpty ?? false)
            ? _Phase.questions
            : _Phase.error;
        if (_phase == _Phase.error) {
          _message = 'This assessment has no questions yet.';
        }
      });
    } catch (e) {
      final msg = await getDioError(e);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _message = msg;
      });
    }
  }

  bool get _allRequiredAnswered {
    final questions = _assessment?.questions ?? [];
    for (final q in questions) {
      if ((q.isRequired ?? false) &&
          !_answers.containsKey(q.assessmentQuestionId)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => _phase = _Phase.loading);
    final user = widget.authenticate.user;
    final name =
        '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim();
    try {
      final result = await context.read<RestClient>().submitAssessment(
            assessmentId: ErpAssessmentDialog.assessmentId,
            answers: jsonEncode(_answers),
            respondentName: name.isEmpty ? 'Trial user' : name,
            respondentEmail: user?.email ?? '',
            respondentCompany: widget.authenticate.company?.name,
            ownerPartyId: ErpAssessmentDialog.ownerPartyId,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _phase = _Phase.result;
      });
    } catch (e) {
      final msg = await getDioError(e);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _message = msg;
      });
    }
  }

  /// Threshold whose [minScore, maxScore] range contains [score].
  ScoringThreshold? _thresholdFor(double? score) {
    if (score == null) return null;
    for (final t in _assessment?.thresholds ?? <ScoringThreshold>[]) {
      if ((t.minScore ?? 0) <= score && score <= (t.maxScore ?? 0)) {
        return t;
      }
    }
    return null;
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _assessment?.assessmentName ?? 'Do you need an ERP system?',
          ),
          actions: [
            // 'Skip' lets the user (and integration tests) dismiss the dialog.
            TextButton(
              key: const Key('skipAssessment'),
              onPressed: _close,
              child: const Text('Skip'),
            ),
          ],
        ),
        body: switch (_phase) {
          _Phase.loading => const Center(child: CircularProgressIndicator()),
          _Phase.error => _buildError(),
          _Phase.questions => _buildQuestions(),
          _Phase.result => _buildResult(),
        },
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 56),
              const SizedBox(height: 16),
              Text(_message ?? 'Could not load the assessment.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('closeAssessment'),
                onPressed: _close,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );

  Widget _buildQuestions() {
    final questions = [...?_assessment?.questions]
      ..sort((a, b) =>
          (a.questionSequence ?? 0).compareTo(b.questionSequence ?? 0));
    return Column(
      children: [
        if (_assessment?.description != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_assessment!.description!,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: questions.length,
            itemBuilder: (context, index) =>
                _buildQuestion(questions[index], index),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('seeResult'),
                onPressed: _allRequiredAnswered ? _submit : null,
                child: const Text('See result'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(AssessmentQuestion question, int index) {
    final qId = question.assessmentQuestionId ?? '';
    final options = [...?question.options]
      ..sort((a, b) =>
          (a.optionSequence ?? 0).compareTo(b.optionSequence ?? 0));
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. ${question.questionText ?? ''}',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            RadioGroup<String>(
              groupValue: _answers[qId],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _answers[qId] = value);
              },
              child: Column(
                children: [
                  for (final option in options)
                    RadioListTile<String>(
                      key: Key(
                          'assessmentOption_${qId}_${option.assessmentQuestionOptionId}'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(option.optionText ?? ''),
                      value: option.assessmentQuestionOptionId ?? '',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final result = _result;
    final score = result?.score;
    final threshold = _thresholdFor(score);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.assignment_turned_in, size: 72, color: Colors.green),
          const SizedBox(height: 16),
          Text('Your result',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Score: ${score?.toStringAsFixed(0) ?? '0'}',
                      key: const Key('assessmentScore'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (result?.leadStatus != null) ...[
                    const SizedBox(height: 8),
                    Chip(label: Text(result!.leadStatus!)),
                  ],
                  if (threshold?.description != null) ...[
                    const SizedBox(height: 16),
                    Text(threshold!.description!,
                        key: const Key('assessmentAdvice'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('doneAssessment'),
              onPressed: _close,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
