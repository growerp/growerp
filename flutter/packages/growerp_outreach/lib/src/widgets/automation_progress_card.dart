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
import 'package:growerp_models/growerp_models.dart';

/// A card widget displaying automation progress for a campaign
class AutomationProgressCard extends StatelessWidget {
  final OutreachCampaign campaign;
  final CampaignProgress? progress;
  final bool isActive;
  final VoidCallback? onStart;
  final VoidCallback? onPause;
  final VoidCallback? onRefresh;

  const AutomationProgressCard({
    super.key,
    required this.campaign,
    this.progress,
    this.isActive = false,
    this.onStart,
    this.onPause,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with campaign name and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    campaign.name,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildStatusChip(colorScheme),
              ],
            ),
            const SizedBox(height: 8),

            // Platforms
            Wrap(
              spacing: 4,
              children: _parsePlatforms(campaign.platforms).map((platform) {
                return Chip(
                  label: Text(platform, style: const TextStyle(fontSize: 10)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Progress stats
            if (progress != null) ...[
              _buildProgressBar(colorScheme),
              const SizedBox(height: 8),
              _buildStatsRow(),
            ] else ...[
              // Show campaign stats if no live progress
              _buildCampaignStats(),
            ],
            const SizedBox(height: 12),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Refresh progress',
                  ),
                const SizedBox(width: 8),
                if (isActive && onPause != null)
                  FilledButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                    ),
                  )
                else if (onStart != null)
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ColorScheme colorScheme) {
    Color bgColor;
    String label;

    if (isActive) {
      bgColor = Colors.green;
      label = 'Running';
    } else {
      switch (campaign.status) {
        case 'MKTG_CAMP_INPROGRESS':
          bgColor = Colors.blue;
          label = 'In Progress';
          break;
        case 'MKTG_CAMP_APPROVED':
          bgColor = Colors.orange;
          label = 'Ready';
          break;
        case 'MKTG_CAMP_COMPLETED':
          bgColor = Colors.grey;
          label = 'Completed';
          break;
        case 'MKTG_CAMP_CANCELLED':
          bgColor = colorScheme.error;
          label = 'Cancelled';
          break;
        default:
          bgColor = Colors.grey.shade400;
          label = 'Planned';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(color: bgColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ColorScheme colorScheme) {
    final total = progress!.messagesSent +
        progress!.messagesPending +
        progress!.messagesFailed;
    final progressValue = total > 0 ? progress!.messagesSent / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Progress'),
            Text('${(progressValue * 100).toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progressValue,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.send, 'Sent', progress!.messagesSent.toString()),
        _buildStatItem(
            Icons.schedule, 'Pending', progress!.messagesPending.toString()),
        _buildStatItem(
            Icons.error_outline, 'Failed', progress!.messagesFailed.toString()),
        _buildStatItem(
            Icons.reply, 'Responses', progress!.responsesReceived.toString()),
      ],
    );
  }

  Widget _buildCampaignStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(Icons.send, 'Sent', campaign.messagesSent.toString()),
        _buildStatItem(
            Icons.reply, 'Responses', campaign.responsesReceived.toString()),
        _buildStatItem(
            Icons.people, 'Leads', campaign.leadsGenerated.toString()),
        _buildStatItem(Icons.speed, 'Daily Limit',
            campaign.dailyLimitPerPlatform.toString()),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  List<String> _parsePlatforms(String platforms) {
    return platforms
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
