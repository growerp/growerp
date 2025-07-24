import 'package:flutter/material.dart';
import 'package:growerp_models/growerp_models.dart';

class SubscriptionDialog extends StatelessWidget {
  final Subscription subscription;
  const SubscriptionDialog(this.subscription, {super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Subscription Details',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: subscription.description ?? '',
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Subscriber'),
              items: const [
                DropdownMenuItem(
                    value: 'subscriber1', child: Text('Subscriber 1')),
                DropdownMenuItem(
                    value: 'subscriber2', child: Text('Subscriber 2')),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Save logic here
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SearchSubscriptionList extends StatelessWidget {
  const SearchSubscriptionList({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Search Subscriptions',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Search'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
