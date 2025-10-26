import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:growerp_models/growerp_models.dart';
import '../bloc/landing_page_bloc.dart';
import '../bloc/landing_page_event.dart';
import '../bloc/landing_page_state.dart';
import 'landing_page_dialog.dart';

class LandingPageListScreen extends StatefulWidget {
  const LandingPageListScreen({super.key});

  @override
  State<LandingPageListScreen> createState() => _LandingPageListScreenState();
}

class _LandingPageListScreenState extends State<LandingPageListScreen> {
  late LandingPageBloc _landingPageBloc;
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _landingPageBloc = context.read<LandingPageBloc>();
    _scrollController.addListener(_onScroll);
    _landingPageBloc.add(const LandingPageLoad());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      _landingPageBloc.add(LandingPageLoad(
        start: _landingPageBloc.state.landingPages.length,
      ));
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onSearchChanged(String value) {
    _landingPageBloc.add(LandingPageLoad(search: value.isEmpty ? null : value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landing Pages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showLandingPageDialog(),
          ),
        ],
      ),
      body: BlocConsumer<LandingPageBloc, LandingPageState>(
        listener: (context, state) {
          if (state.status == LandingPageStatus.failure) {
            HelperFunctions.showMessage(
              context,
              state.message ?? 'An error occurred',
              Colors.red,
            );
          } else if (state.message != null &&
              state.status == LandingPageStatus.success) {
            HelperFunctions.showMessage(
              context,
              state.message!,
              Colors.green,
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search landing pages...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              // Landing pages list
              Expanded(
                child: _buildLandingPagesList(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLandingPagesList(LandingPageState state) {
    if (state.status == LandingPageStatus.loading &&
        state.landingPages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.landingPages.isEmpty) {
      return const Center(
        child: Text('No landing pages found'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.hasReachedMax
          ? state.landingPages.length
          : state.landingPages.length + 1,
      itemBuilder: (context, index) {
        if (index >= state.landingPages.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final landingPage = state.landingPages[index];
        return _buildLandingPageCard(landingPage);
      },
    );
  }

  Widget _buildLandingPageCard(LandingPage landingPage) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(landingPage.status),
          child: Text(
            landingPage.status.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          landingPage.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(landingPage.headline),
            const SizedBox(height: 4),
            Text(
              'ID: ${landingPage.pseudoId} • Status: ${landingPage.status}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, landingPage),
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
        onTap: () => _viewLandingPageDetail(landingPage),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'DRAFT':
        return Colors.orange;
      case 'INACTIVE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleMenuAction(String action, LandingPage landingPage) {
    switch (action) {
      case 'edit':
        _showLandingPageDialog(landingPage: landingPage);
        break;
      case 'duplicate':
        _duplicateLandingPage(landingPage);
        break;
      case 'delete':
        _confirmDelete(landingPage);
        break;
    }
  }

  void _showLandingPageDialog({LandingPage? landingPage}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocProvider.value(
        value: _landingPageBloc,
        child: LandingPageDialog(landingPage: landingPage),
      ),
    );
  }

  void _duplicateLandingPage(LandingPage landingPage) {
    final duplicatedPage = landingPage.copyWith(
      pageId: '', // Will be generated by server
      pseudoId: '${landingPage.pseudoId}_copy',
      title: '${landingPage.title} (Copy)',
      status: 'DRAFT',
    );
    _showLandingPageDialog(landingPage: duplicatedPage);
  }

  void _confirmDelete(LandingPage landingPage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Landing Page'),
        content: Text(
          'Are you sure you want to delete "${landingPage.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _landingPageBloc.add(LandingPageDelete(landingPage.pageId));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _viewLandingPageDetail(LandingPage landingPage) {
    Navigator.pushNamed(
      context,
      '/landing-page/detail',
      arguments: landingPage,
    );
  }
}
