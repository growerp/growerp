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
import '../../common/bloc/menu_config_bloc.dart';
import '../../common/widgets/popup.dart';

/// Post-login onboarding assessment "Set up GrowERP for your business".
///
/// Loads the GROWERP-owned [ERP_ONBOARD] assessment, which profiles the new
/// customer's organisation so the onboarding agent can tailor the menu. The
/// result is GROWERP-owned (GROWERP uses it to understand each new customer);
/// the respondent company identifies the tenant. Self-contained: talks to
/// [RestClient] directly, no dedicated bloc.
class ErpAssessmentDialog extends StatefulWidget {
  const ErpAssessmentDialog({super.key, required this.authenticate});
  final Authenticate authenticate;

  /// Owner of the assessment, its thresholds, and the stored result (GROWERP
  /// consumes onboarding results to understand each new customer).
  static const String ownerPartyId = 'GROWERP';

  /// Assessment loaded for the post-login onboarding experience.
  static const String assessmentId = 'ERP_ONBOARD';

  @override
  State<ErpAssessmentDialog> createState() => _ErpAssessmentDialogState();
}

enum _Phase { loading, questions, result, error }

class _ErpAssessmentDialogState extends State<ErpAssessmentDialog> {
  _Phase _phase = _Phase.loading;
  String? _message;
  Assessment? _assessment;

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
      // Submit records the profile + (backend) ingests it into the GROWERP
      // onboarding knowledge. We don't show a score — just confirm and move on.
      await context.read<RestClient>().submitAssessment(
            assessmentId: ErpAssessmentDialog.assessmentId,
            answers: jsonEncode(_answers),
            respondentName: name.isEmpty ? 'Trial user' : name,
            respondentEmail: user?.email ?? '',
            respondentCompany: widget.authenticate.company?.name,
            ownerPartyId: ErpAssessmentDialog.ownerPartyId,
          );
      if (!mounted) return;
      _applyMenuFromAnswers();
      setState(() => _phase = _Phase.result);
    } catch (e) {
      final msg = await getDioError(e);
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _message = msg;
      });
    }
  }

  /// Tailor the menu from the onboarding answers: hide/minimise the areas the
  /// business said it doesn't use. Runs as the current (tenant) user via the live
  /// [MenuConfigBloc], which persists a per-user override and reloads. Rule-based
  /// and silent — no agent, no extra confirmation.
  void _applyMenuFromAnswers() {
    final bloc = context.read<MenuConfigBloc?>();
    final config = bloc?.state.menuConfiguration;
    if (bloc == null || config == null) return;

    final hide = <String>{};
    final minimize = <String>{};
    // Services-only (Q1=O2) or no stock (Q2=O2) → no Inventory.
    if (_answers['ERPO_Q1'] == 'ERPO_Q1_O2' ||
        _answers['ERPO_Q2'] == 'ERPO_Q2_O2') {
      hide.add('Inventory');
    }
    // Books kept in other software (Q3=O2) → no Accounting.
    if (_answers['ERPO_Q3'] == 'ERPO_Q3_O2') hide.add('Accounting');
    // No marketing/CRM (Q4=O2) → minimise Marketing.
    if (_answers['ERPO_Q4'] == 'ERPO_Q4_O2') minimize.add('Marketing');

    // Match a wanted area to a real top-level menu item by exact title, then by
    // a contains-match on title or menuItemId (e.g. 'Inventory' → ADMIN_INVENTORY).
    MenuItem? find(String kw) {
      final q = kw.toLowerCase();
      for (final m in config.menuItems) {
        if (m.title.toLowerCase() == q) return m;
      }
      for (final m in config.menuItems) {
        final t = m.title.toLowerCase();
        final id = (m.menuItemId ?? '').toLowerCase();
        if (t.contains(q) || q.contains(t) || id.contains(q)) return m;
      }
      return null;
    }

    for (final kw in hide) {
      final m = find(kw);
      if (m?.menuItemId != null && m!.isActive) {
        bloc.add(MenuItemToggleActive(m.menuItemId!));
      }
    }
    for (final kw in minimize) {
      final m = find(kw);
      if (m?.menuItemId != null && !m!.isMinimized) {
        bloc.add(MenuItemToggleMinimize(m.menuItemId!));
      }
    }
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: popUp(
        context: context,
        title: _assessment?.assessmentName ?? 'Set up GrowERP for your business',
        width: 600,
        height: MediaQuery.of(context).size.height * 0.85,
        actions: [
          TextButton(
            key: const Key('skipAssessment'),
            onPressed: _close,
            child: const Text('Skip'),
          ),
        ],
        child: ScaffoldMessenger(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: switch (_phase) {
                  _Phase.loading => const Center(child: CircularProgressIndicator()),
                  _Phase.error => _buildError(),
                  _Phase.questions => _buildQuestions(),
                  _Phase.result => _buildResult(),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error, size: 64),
              const SizedBox(height: 20),
              Text(_message ?? 'Could not load the assessment.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 28),
              FilledButton(
                key: const Key('closeAssessment'),
                onPressed: _close,
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );

  Widget _buildQuestions() {
    final theme = Theme.of(context);
    final questions = [...?_assessment?.questions]
      ..sort((a, b) =>
          (a.questionSequence ?? 0).compareTo(b.questionSequence ?? 0));
    final answered =
        questions.where((q) => _answers.containsKey(q.assessmentQuestionId)).length;
    final progress = questions.isEmpty ? 0.0 : answered / questions.length;
    return Column(
      children: [
        // Progress header.
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            children: [
              if (_assessment?.description != null) ...[
                Text(_assessment!.description!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Text('$answered of ${questions.length} answered',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: questions.length,
            itemBuilder: (context, index) =>
                _buildQuestion(questions[index], index),
          ),
        ),
        _buildBottomBar(
          child: FilledButton(
            key: const Key('seeResult'),
            onPressed: _allRequiredAnswered ? _submit : null,
            child: const Text('See result'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(AssessmentQuestion question, int index) {
    final theme = Theme.of(context);
    final qId = question.assessmentQuestionId ?? '';
    final options = [...?question.options]
      ..sort((a, b) =>
          (a.optionSequence ?? 0).compareTo(b.optionSequence ?? 0));
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text('${index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(question.questionText ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            for (final option in options)
              _buildOption(qId, option),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String qId, AssessmentQuestionOption option) {
    final theme = Theme.of(context);
    final optId = option.assessmentQuestionOptionId ?? '';
    final selected = _answers[qId] == optId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key('assessmentOption_${qId}_$optId'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _answers[qId] = optId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(option.optionText ?? '',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      )),
                ),
                const SizedBox(width: 20), // balances the leading icon
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    // Onboarding is a profiling step, not a scored quiz: don't show a score or
    // verdict. Confirm the profile was captured and that the menu will be tailored.
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            child: Icon(Icons.tune,
                size: 48, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 24),
          Text('Thanks — your answers are saved',
              key: const Key('assessmentDone'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(
            'We\'ll tailor your menu to match how your business works, '
            'so you only see what you need.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: const Key('doneAssessment'),
              onPressed: _close,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom action bar with a top divider, used under the question list.
  Widget _buildBottomBar({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }

}
