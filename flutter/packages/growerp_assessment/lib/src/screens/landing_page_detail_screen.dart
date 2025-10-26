import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';
import '../bloc/landing_page_state.dart';
import 'landing_page_dialog.dart';
import 'page_section_management_screen.dart';
import 'credibility_management_screen.dart';
import 'cta_management_screen.dart';

class LandingPageDetailScreen extends StatefulWidget {
  final LandingPage landingPage;

  const LandingPageDetailScreen({
    super.key,
    required this.landingPage,
  });

  @override
  State<LandingPageDetailScreen> createState() =>
      _LandingPageDetailScreenState();
}

class _LandingPageDetailScreenState extends State<LandingPageDetailScreen> {
  late LandingPageBloc _landingPageBloc;

  @override
  void initState() {
    super.initState();
    _landingPageBloc = context.read<LandingPageBloc>();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LandingPageBloc, LandingPageState>(
      listener: (context, state) {
        if (state.status == LandingPageStatus.success &&
            state.message != null) {
          if (state.message!.contains('deleted')) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Landing page "${widget.landingPage.title}" deleted successfully'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.message!.contains('updated')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Landing page "${widget.landingPage.title}" updated successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.landingPage.title),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editLandingPage();
                    break;
                  case 'duplicate':
                    _duplicateLandingPage();
                    break;
                  case 'delete':
                    _deleteLandingPage();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: ListTile(
                    leading: Icon(Icons.copy),
                    title: Text('Duplicate'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Info Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.web,
                            size: 32,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.landingPage.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                        widget.landingPage.status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.landingPage.status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.landingPage.description?.isNotEmpty ==
                          true) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.landingPage.description!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Content Overview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 8),
                          Text(
                            'Content Overview',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Pseudo ID', widget.landingPage.pseudoId),
                      _buildInfoRow('Headline', widget.landingPage.headline),
                      _buildInfoRow(
                          'Subheading', widget.landingPage.subheading),
                      _buildInfoRow('Hook Type', widget.landingPage.hookType),
                      _buildInfoRow(
                          'Hero Image URL', widget.landingPage.heroImageUrl),
                      if (widget.landingPage.createdDate != null)
                        _buildInfoRow('Created',
                            _formatDate(widget.landingPage.createdDate!)),
                      if (widget.landingPage.lastUpdated != null)
                        _buildInfoRow('Last Updated',
                            _formatDate(widget.landingPage.lastUpdated!)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Management Actions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.settings),
                          const SizedBox(width: 8),
                          Text(
                            'Management Actions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildActionTile(
                        icon: Icons.view_module,
                        title: 'Manage Page Sections',
                        subtitle: 'Configure content sections and layout',
                        onTap: () => _navigateToPageSections(),
                      ),
                      const Divider(),
                      _buildActionTile(
                        icon: Icons.verified,
                        title: 'Manage Credibility Elements',
                        subtitle: 'Configure trust signals and testimonials',
                        onTap: () => _navigateToCredibility(),
                      ),
                      const Divider(),
                      _buildActionTile(
                        icon: Icons.call_to_action,
                        title: 'Manage Call-to-Actions',
                        subtitle: 'Configure buttons and conversion elements',
                        onTap: () => _navigateToCTA(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _editLandingPage,
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.red;
      case 'DRAFT':
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editLandingPage() {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _landingPageBloc,
        child: LandingPageDialog(landingPage: widget.landingPage),
      ),
    );
  }

  void _duplicateLandingPage() {
    // Create a copy without the ID for duplication
    final duplicatedPage = LandingPage(
      pageId: '', // Will be assigned by backend
      pseudoId: '${widget.landingPage.pseudoId}_copy',
      title: '${widget.landingPage.title} (Copy)',
      headline: widget.landingPage.headline,
      subheading: widget.landingPage.subheading,
      description: widget.landingPage.description,
      heroImageUrl: widget.landingPage.heroImageUrl,
      hookType: widget.landingPage.hookType,
      status: 'DRAFT', // Always start duplicates as draft
    );

    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _landingPageBloc,
        child: LandingPageDialog(landingPage: duplicatedPage),
      ),
    );
  }

  void _deleteLandingPage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Landing Page'),
        content: Text(
          'Are you sure you want to delete "${widget.landingPage.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _landingPageBloc
                  .add(LandingPageDelete(widget.landingPage.pageId));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToPageSections() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PageSectionManagementScreen(
          pageId: widget.landingPage.pageId,
          pageTitle: widget.landingPage.title,
        ),
      ),
    );
  }

  void _navigateToCredibility() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CredibilityManagementScreen(
          pageId: widget.landingPage.pageId,
          pageTitle: widget.landingPage.title,
        ),
      ),
    );
  }

  void _navigateToCTA() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CTAManagementScreen(
          pageId: widget.landingPage.pageId,
          pageTitle: widget.landingPage.title,
        ),
      ),
    );
  }
}
