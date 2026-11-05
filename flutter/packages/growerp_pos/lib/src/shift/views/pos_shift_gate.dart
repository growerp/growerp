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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';

import '../../../l10n/generated/pos_localizations.dart';
import '../blocs/pos_shift_bloc.dart';
import 'pos_shift_dialogs.dart';
import 'pos_z_report_dialog.dart';

/// Shows its child only while the till of this device has an open shift, and
/// otherwise the way to open it.
class PosShiftGate extends StatefulWidget {
  const PosShiftGate({
    super.key,
    required this.builder,
    this.needsShift = true,
  });
  final Widget Function(BuildContext context, String terminalName) builder;

  /// A waiter works without a till: only access is checked then.
  final bool needsShift;

  @override
  PosShiftGateState createState() => PosShiftGateState();
}

class PosShiftGateState extends State<PosShiftGate> {
  String _terminalName = 'Till 1';

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// A device stays the till it was opened as.
  Future<void> _load() async {
    final bloc = context.read<PosShiftBloc>();
    final stored = await PersistFunctions.getKeyValue(posTerminalKey);
    if (!mounted) return;
    setState(() => _terminalName = stored ?? _terminalName);
    bloc.add(PosShiftFetch(_terminalName));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PosShiftBloc, PosShiftState>(
      listener: (context, state) {
        if (state.shift?.terminalName != null &&
            state.shift!.terminalName != _terminalName) {
          setState(() => _terminalName = state.shift!.terminalName!);
        }
        // an open shift fails inside its dialog, which shows the message
        if (state.status == PosShiftStatus.failure && state.shift == null) {
          HelperFunctions.showMessage(context, state.message, Colors.red);
        }
      },
      builder: (context, shift) {
        if (shift.status == PosShiftStatus.noAccess) {
          return Center(
            key: const Key('posNoAccess'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                PosLocalizations.of(context)!.noTillAccess,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (shift.shift == null && widget.needsShift) {
          return shift.status == PosShiftStatus.initial ||
                  shift.status == PosShiftStatus.loading
              ? const Center(child: LoadingIndicator())
              : PosShiftOpenView(terminalName: _terminalName);
        }
        return widget.builder(context, _terminalName);
      },
    );
  }
}

/// The name of the till with what can be done to the drawer.
class PosTillBar extends StatelessWidget {
  const PosTillBar({
    super.key,
    required this.terminalName,
    required this.currencyId,
  });
  final String terminalName;
  final String currencyId;

  Future<void> _cashMovement(BuildContext context) async {
    final bloc = context.read<PosShiftBloc>();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const PosCashMovementDialog()),
    );
  }

  Future<void> _closeShift(BuildContext context) async {
    final bloc = context.read<PosShiftBloc>();
    final navigator = Navigator.of(context, rootNavigator: true);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const PosShiftCloseDialog()),
    );
    final report = bloc.state.report;
    if (report == null || bloc.state.shift != null || !navigator.mounted) {
      return;
    }
    await showDialog(
      context: navigator.context,
      builder: (_) => PosZReportDialog(report, currencyId: currencyId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = PosLocalizations.of(context)!;
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(child: Text(terminalName, key: const Key('posTill'))),
        IconButton(
          key: const Key('posCashMovement'),
          icon: const Icon(Icons.swap_vert),
          tooltip: localizations.cashMovement,
          onPressed: () => _cashMovement(context),
        ),
        IconButton(
          key: const Key('posCloseShift'),
          icon: const Icon(Icons.lock_outline),
          tooltip: localizations.closeTill,
          onPressed: () => _closeShift(context),
        ),
      ],
    );
  }
}
