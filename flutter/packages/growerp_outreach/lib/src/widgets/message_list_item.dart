import 'package:flutter/material.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';

class MessageListItem extends StatelessWidget {
  const MessageListItem({super.key, required this.message});

  final OutreachMessage message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(message.status),
          child: Icon(
            _getStatusIcon(message.status),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(message.recipientName ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platform: ${message.platform}'),
            if (message.sentDate != null)
              Text(
                'Sent: ${message.sentDate.toLocalizedString(context, format: 'MMM d, y HH:mm')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        trailing: Chip(
          label: Text(message.status, style: const TextStyle(fontSize: 11)),
          backgroundColor:
              _getStatusColor(message.status).withValues(alpha: 0.2),
          visualDensity: VisualDensity.compact,
        ),
        isThreeLine: true,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return Colors.green;
      case 'RESPONDED':
        return Colors.blue;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'SENT':
        return Icons.check;
      case 'RESPONDED':
        return Icons.reply;
      case 'FAILED':
        return Icons.error;
      default:
        return Icons.pending;
    }
  }
}
