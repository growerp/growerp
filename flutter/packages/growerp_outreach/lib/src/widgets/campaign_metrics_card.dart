import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';

class CampaignMetricsCard extends StatelessWidget {
  const CampaignMetricsCard({super.key, required this.metrics});

  final CampaignMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campaign Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    label: 'Messages Sent',
                    value: metrics.messagesSent.toString(),
                    icon: Icons.send,
                    color: Colors.blue,
                  ),
                ),
                Expanded(
                  child: _MetricItem(
                    label: 'Responses',
                    value: metrics.responsesReceived.toString(),
                    icon: Icons.reply,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricItem(
                    label: 'Leads Generated',
                    value: metrics.leadsGenerated.toString(),
                    icon: Icons.person_add,
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _MetricItem(
                    label: 'Response Rate',
                    value:
                        '${metrics.responseRate?.toStringAsFixed(1) ?? '0'}%',
                    icon: Icons.trending_up,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
