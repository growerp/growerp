import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/cta_bloc.dart';
import '../bloc/cta_event.dart';
import '../bloc/cta_state.dart';

class CTAManagementScreen extends StatefulWidget {
  final String pageId;
  final String pageTitle;

  const CTAManagementScreen({
    super.key,
    required this.pageId,
    required this.pageTitle,
  });

  @override
  State<CTAManagementScreen> createState() => _CTAManagementScreenState();
}

class _CTAManagementScreenState extends State<CTAManagementScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CTABloc>().add(CTALoad(pageId: widget.pageId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Call-to-Action for ${widget.pageTitle}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<CTABloc, CTAState>(
        listener: (context, state) {
          if (state.status == CTAStatus.failure && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
          if (state.status == CTAStatus.success && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message!)),
            );
          }
        },
        builder: (context, state) {
          if (state.status == CTAStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with create button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Primary Call-to-Action',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (state.callToAction == null)
                      ElevatedButton.icon(
                        onPressed: () => _showCTADialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create CTA'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // CTA Display/Management
                Expanded(
                  child: state.callToAction == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No Call-to-Action configured',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Create a compelling call-to-action to guide your visitors',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : _buildCTACard(state.callToAction!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCTACard(CallToAction cta) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Call-to-Action',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleCTAAction(value, cta),
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
              ],
            ),
            const SizedBox(height: 16),
            // CTA Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: ElevatedButton(
                      onPressed: null, // Disabled for preview
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Text(
                        cta.buttonText ?? 'Learn More',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // CTA Details
            _buildDetailRow('Button Text', cta.buttonText ?? 'N/A'),
            _buildDetailRow('Action Type', cta.actionType ?? 'N/A'),
            if (cta.actionTarget != null)
              _buildDetailRow('Action Target', cta.actionTarget!),
            if (cta.buttonStyle != null)
              _buildDetailRow('Button Style', cta.buttonStyle!),
            if (cta.description != null)
              _buildDetailRow('Description', cta.description!),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _handleCTAAction(String action, CallToAction cta) {
    switch (action) {
      case 'edit':
        _showCTADialog(cta: cta);
        break;
      case 'delete':
        _showDeleteConfirmation(cta);
        break;
    }
  }

  void _showDeleteConfirmation(CallToAction cta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Call-to-Action'),
        content: const Text(
            'Are you sure you want to delete this call-to-action? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Note: We don't have the CTA ID in the model, so we'll use a placeholder
              context.read<CTABloc>().add(CTADelete(
                  pageId: widget.pageId, ctaId: 'cta_id_placeholder'));
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCTADialog({CallToAction? cta}) {
    final buttonTextController =
        TextEditingController(text: cta?.buttonText ?? '');
    final actionTypeController =
        TextEditingController(text: cta?.actionType ?? '');
    final actionTargetController =
        TextEditingController(text: cta?.actionTarget ?? '');
    final buttonStyleController =
        TextEditingController(text: cta?.buttonStyle ?? '');
    final descriptionController =
        TextEditingController(text: cta?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cta == null
                        ? 'Create Call-to-Action'
                        : 'Edit Call-to-Action',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: buttonTextController,
                        decoration: const InputDecoration(
                          labelText: 'Button Text *',
                          hintText: 'e.g., "Get Started", "Start Assessment"',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: actionTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Action Type *',
                          hintText:
                              'e.g., "assessment", "form", "external_link"',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: actionTargetController,
                        decoration: const InputDecoration(
                          labelText: 'Action Target',
                          hintText: 'URL or route target',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: buttonStyleController,
                        decoration: const InputDecoration(
                          labelText: 'Button Style',
                          hintText: 'CSS class or style name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Additional CTA description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (buttonTextController.text.trim().isNotEmpty &&
                          actionTypeController.text.trim().isNotEmpty) {
                        if (cta == null) {
                          context.read<CTABloc>().add(CTACreate(
                                pageId: widget.pageId,
                                buttonText: buttonTextController.text.trim(),
                                actionType: actionTypeController.text.trim(),
                                actionTarget: actionTargetController.text
                                        .trim()
                                        .isNotEmpty
                                    ? actionTargetController.text.trim()
                                    : null,
                                buttonStyle:
                                    buttonStyleController.text.trim().isNotEmpty
                                        ? buttonStyleController.text.trim()
                                        : null,
                              ));
                        } else {
                          context.read<CTABloc>().add(CTAUpdate(
                                pageId: widget.pageId,
                                ctaId:
                                    'cta_id_placeholder', // We don't have the CTA ID in the model
                                buttonText: buttonTextController.text.trim(),
                                actionType: actionTypeController.text.trim(),
                                actionTarget: actionTargetController.text
                                        .trim()
                                        .isNotEmpty
                                    ? actionTargetController.text.trim()
                                    : null,
                                buttonStyle:
                                    buttonStyleController.text.trim().isNotEmpty
                                        ? buttonStyleController.text.trim()
                                        : null,
                              ));
                        }
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(cta == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
