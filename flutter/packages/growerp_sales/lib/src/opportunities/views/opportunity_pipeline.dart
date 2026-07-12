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

import 'package:growerp_core/growerp_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';

import '../bloc/opportunity_bloc.dart';
import '../widgets/sales_funnel_chart.dart';
import 'opportunity_dialog.dart';

/// Kanban-style pipeline board: one column per stage, opportunities as
/// draggable cards. Dropping a card on another column updates its stage.
/// A funnel summary (count, total, weighted amount per stage) shows on top.
class OpportunityPipeline extends StatefulWidget {
  const OpportunityPipeline({super.key});

  @override
  OpportunityPipelineState createState() => OpportunityPipelineState();
}

class OpportunityPipelineState extends State<OpportunityPipeline> {
  late OpportunityBloc _opportunityBloc;

  @override
  void initState() {
    super.initState();
    _opportunityBloc = context.read<OpportunityBloc>()
      ..add(const OpportunityFetch(refresh: true, limit: 100))
      ..add(const OpportunitySummaryFetch());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OpportunityBloc, OpportunityState>(
      listener: (context, state) {
        if (state.status == OpportunityStatus.failure) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.red);
        }
        if (state.status == OpportunityStatus.success &&
            (state.message ?? '').isNotEmpty) {
          HelperFunctions.showMessage(context, '${state.message}', Colors.green);
        }
      },
      builder: (context, state) {
        if (state.status == OpportunityStatus.loading &&
            state.opportunities.isEmpty) {
          return const LoadingIndicator();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: SalesFunnelChart(summary: state.summary),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                key: const Key('pipelineBoard'),
                scrollDirection: Axis.horizontal,
                children: opportunityStages
                    .map((stage) => _stageColumn(context, state, stage))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _stageColumn(
    BuildContext context,
    OpportunityState state,
    String stage,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final stageOpportunities = state.opportunities
        .where((opportunity) => opportunity.stageId == stage)
        .toList();
    return DragTarget<Opportunity>(
      onWillAcceptWithDetails: (details) => details.data.stageId != stage,
      onAcceptWithDetails: (details) {
        _opportunityBloc
          ..add(OpportunityUpdate(details.data.copyWith(stageId: stage)))
          ..add(const OpportunitySummaryFetch());
      },
      builder: (context, candidates, rejected) {
        return Container(
          width: 230,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: candidates.isNotEmpty
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage,
                        key: Key('pipelineColumn$stage'),
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    CircleAvatar(
                      radius: 12,
                      child: Text(
                        '${stageOpportunities.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: stageOpportunities.length,
                  itemBuilder: (context, index) => _opportunityCard(
                    context,
                    stageOpportunities[index],
                    stage,
                    index,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _opportunityCard(
    BuildContext context,
    Opportunity opportunity,
    String stage,
    int index,
  ) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              opportunity.opportunityName ?? '',
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${opportunity.estAmount ?? ''} '
              '· ${opportunity.estProbability ?? ''}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (opportunity.leadUser != null)
              Text(
                '${opportunity.leadUser?.firstName ?? ''} '
                '${opportunity.leadUser?.lastName ?? ''}',
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
    return LongPressDraggable<Opportunity>(
      data: opportunity,
      feedback: Material(
        elevation: 4,
        child: SizedBox(width: 210, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: card),
      child: InkWell(
        key: Key('pipelineItem$stage$index'),
        onTap: () async {
          await showDialog(
            barrierDismissible: true,
            context: context,
            builder: (BuildContext context) => BlocProvider.value(
              value: _opportunityBloc,
              child: OpportunityDialog(opportunity),
            ),
          );
          _opportunityBloc.add(const OpportunitySummaryFetch());
        },
        child: card,
      ),
    );
  }
}
