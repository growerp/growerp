import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/credibility_bloc.dart';
import '../bloc/credibility_event.dart';
import '../bloc/credibility_state.dart';

class CredibilityManagementScreen extends StatefulWidget {
  final String pageId;
  final String pageTitle;

  const CredibilityManagementScreen({
    super.key,
    required this.pageId,
    required this.pageTitle,
  });

  @override
  State<CredibilityManagementScreen> createState() =>
      _CredibilityManagementScreenState();
}

class _CredibilityManagementScreenState
    extends State<CredibilityManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CredibilityBloc>().add(CredibilityLoad(pageId: widget.pageId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Credibility for ${widget.pageTitle}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<CredibilityBloc, CredibilityState>(
        listener: (context, state) {
          if (state.status == CredibilityStatus.failure &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
          if (state.status == CredibilityStatus.success &&
              state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == CredibilityStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Credibility Elements Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Credibility Elements',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showCredibilityDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Element'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (state.credibilityElements.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No credibility elements found. Add some to build trust with your visitors.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ...state.credibilityElements
                              .map((element) => _buildCredibilityCard(element)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Statistics Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Statistics',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showStatisticDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Statistic'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (state.credibilityStatistics.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No statistics found. Add some impressive numbers to showcase your achievements.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          )
                        else
                          ...state.credibilityStatistics
                              .map((stat) => _buildStatisticCard(stat)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCredibilityCard(CredibilityElement element) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.verified_user,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(element.title ?? 'Credibility'),
        subtitle:
            element.description != null ? Text(element.description!) : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCredibilityAction(value, element),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticCard(Map<String, dynamic> statistic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            Icons.trending_up,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(statistic['statistic']?.toString() ?? 'Unknown Statistic'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () =>
              _deleteStatistic(statistic['statisticId']?.toString() ?? ''),
        ),
      ),
    );
  }

  void _handleCredibilityAction(String action, CredibilityElement element) {
    switch (action) {
      case 'edit':
        _showCredibilityDialog(element: element);
        break;
      case 'delete':
        _deleteCredibilityElement(element.credibilityId);
        break;
    }
  }

  void _deleteCredibilityElement(String credibilityId) {
    context.read<CredibilityBloc>().add(
        CredibilityInfoDelete(pageId: widget.pageId, infoId: credibilityId));
  }

  void _deleteStatistic(String statisticId) {
    if (statisticId.isNotEmpty) {
      context
          .read<CredibilityBloc>()
          .add(CredibilityStatisticDelete(statisticId: statisticId));
    }
  }

  void _showCredibilityDialog({CredibilityElement? element}) {
    final titleController = TextEditingController(text: element?.title ?? '');
    final descriptionController =
        TextEditingController(text: element?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(element == null
            ? 'Add Credibility Element'
            : 'Edit Credibility Element'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., "Trusted by 10,000+ customers"',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Additional details...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                if (element == null) {
                  context.read<CredibilityBloc>().add(CredibilityInfoCreate(
                        pageId: widget.pageId,
                        infoTitle: titleController.text.trim(),
                        infoDescription:
                            descriptionController.text.trim().isNotEmpty
                                ? descriptionController.text.trim()
                                : null,
                      ));
                } else {
                  context.read<CredibilityBloc>().add(CredibilityInfoUpdate(
                        pageId: widget.pageId,
                        infoId: element.credibilityId,
                        infoTitle: titleController.text.trim(),
                        infoDescription:
                            descriptionController.text.trim().isNotEmpty
                                ? descriptionController.text.trim()
                                : null,
                      ));
                }
                Navigator.of(context).pop();
              }
            },
            child: Text(element == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _showStatisticDialog() {
    final labelController = TextEditingController();
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Statistic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g., "Happy Customers"',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'e.g., "10,000+"',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (labelController.text.trim().isNotEmpty &&
                  valueController.text.trim().isNotEmpty) {
                context.read<CredibilityBloc>().add(CredibilityStatisticCreate(
                      pageId: widget.pageId,
                      statLabel: labelController.text.trim(),
                      statValue: valueController.text.trim(),
                    ));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
