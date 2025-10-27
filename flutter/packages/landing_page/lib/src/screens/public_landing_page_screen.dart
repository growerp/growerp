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
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_assessment/growerp_assessment.dart';

class PublicLandingPageScreen extends StatefulWidget {
  const PublicLandingPageScreen({
    super.key,
    required this.pageId,
    this.ownerPartyId,
    this.onCtaPressed,
  });

  final String pageId;
  final String? ownerPartyId;
  final Function(CallToAction)? onCtaPressed;

  @override
  State<PublicLandingPageScreen> createState() =>
      _PublicLandingPageScreenState();
}

class _PublicLandingPageScreenState extends State<PublicLandingPageScreen> {
  @override
  void initState() {
    super.initState();
    _loadLandingPage();
  }

  @override
  void didUpdateWidget(covariant PublicLandingPageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageId != oldWidget.pageId ||
        widget.ownerPartyId != oldWidget.ownerPartyId) {
      _loadLandingPage();
    }
  }

  void _loadLandingPage() {
    context.read<LandingPageBloc>().add(
      LandingPageFetch(widget.pageId, ownerPartyId: widget.ownerPartyId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Landing Page'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<LandingPageBloc, LandingPageState>(
        builder: (context, state) {
          if (state.status == LandingPageStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == LandingPageStatus.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading landing page',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message ?? 'Unknown error occurred',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<LandingPageBloc>().add(
                        LandingPageFetch(
                          widget.pageId,
                          ownerPartyId: widget.ownerPartyId,
                        ),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.status == LandingPageStatus.success &&
              state.selectedLandingPage != null) {
            return _buildLandingPageContent(
              context,
              state.selectedLandingPage!,
            );
          }

          return const Center(child: Text('Landing page not found'));
        },
      ),
    );
  }

  Widget _buildLandingPageContent(BuildContext context, LandingPage page) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Section
          _buildHeroSection(context, page),

          // Sections
          if (page.sections != null && page.sections!.isNotEmpty) ...[
            const SizedBox(height: 32),
            ...page.sections!.map((section) => _buildSection(context, section)),
          ],

          // Credibility Section
          if (page.credibilityElements != null &&
              page.credibilityElements!.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildCredibilitySection(context, page.credibilityElements!.first),
          ],

          // Call to Action
          if (page.callToAction != null) ...[
            const SizedBox(height: 32),
            _buildCtaSection(context, page.callToAction!),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, LandingPage page) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(
              (0.1 * 255).toInt(),
              ((Theme.of(context).primaryColor.red * 255.0).round() & 0xff),
              ((Theme.of(context).primaryColor.green * 255.0).round() & 0xff),
              ((Theme.of(context).primaryColor.blue * 255.0).round() & 0xff),
            ),
            Color.fromARGB(
              (0.05 * 255).toInt(),
              ((Theme.of(context).primaryColor.red * 255.0).round() & 0xff),
              ((Theme.of(context).primaryColor.green * 255.0).round() & 0xff),
              ((Theme.of(context).primaryColor.blue * 255.0).round() & 0xff),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.headline,
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (page.subheading != null && page.subheading!.isNotEmpty)
            Text(
              page.subheading!,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, LandingPageSection section) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (section.description != null && section.description!.isNotEmpty)
            Text(
              section.description!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          if (section.imageUrl != null && section.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                section.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCredibilitySection(
    BuildContext context,
    CredibilityElement credibility,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            credibility.title ?? 'Credibility',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (credibility.imageUrl != null &&
                  credibility.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    credibility.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 32,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (credibility.description != null &&
                        credibility.description!.isNotEmpty)
                      Text(
                        credibility.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    if (credibility.authorName != null &&
                        credibility.authorName!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '- ${credibility.authorName}${credibility.authorTitle != null ? ', ${credibility.authorTitle}' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context, CallToAction cta) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (cta.description != null && cta.description!.isNotEmpty)
            Text(
              cta.description!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Use callback if provided, otherwise use default navigation
                if (widget.onCtaPressed != null) {
                  widget.onCtaPressed!(cta);
                } else {
                  // Handle different action types
                  if (cta.actionType == 'assessment' ||
                      cta.actionTarget != null) {
                    Navigator.of(
                      context,
                    ).pushNamed(cta.actionTarget ?? '/assessment');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                cta.buttonText ?? 'Learn More',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
