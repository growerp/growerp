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
import 'package:growerp_marketing/growerp_marketing.dart';

class PublicLandingPageScreen extends StatefulWidget {
  const PublicLandingPageScreen({
    super.key,
    required this.landingPageId,
    this.ownerPartyId,
    this.onCtaPressed,
  });

  final String landingPageId;
  final String? ownerPartyId;
  final VoidCallback? onCtaPressed;

  @override
  State<PublicLandingPageScreen> createState() =>
      _PublicLandingPageScreenState();
}

class _PublicLandingPageScreenState extends State<PublicLandingPageScreen> {
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PublicLandingPageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload landing page only if the parameters changed
    if (widget.landingPageId != oldWidget.landingPageId ||
        widget.ownerPartyId != oldWidget.ownerPartyId) {
      context.read<LandingPageBloc>().add(
            LandingPageFetch(
              pseudoId: widget.landingPageId,
              ownerPartyId: widget.ownerPartyId,
            ),
          );
    }
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
                              pseudoId: widget.landingPageId,
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
          // 1. Hero Section (Hook + Subheading)
          _buildHeroSection(context, page),

          // 2. Page Sections (if available)
          if (page.sections != null && page.sections!.isNotEmpty) ...[
            const SizedBox(height: 32),
            // Display all sections ordered by sequence
            ...page.sections!.map((section) => _buildSection(context, section)),
          ],

          // 3. Credibility Section
          if (page.credibility != null) ...[
            const SizedBox(height: 32),
            _buildCredibilitySection(context, page.credibility!),
          ],

          // 4. Call to Action
          if (page.ctaActionType != null) ...[
            const SizedBox(height: 32),
            _buildCtaSection(context, page),
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
              ((Theme.of(context).primaryColor.r * 255.0).round() & 0xff),
              ((Theme.of(context).primaryColor.g * 255.0).round() & 0xff),
              ((Theme.of(context).primaryColor.b * 255.0).round() & 0xff),
            ),
            Color.fromARGB(
              (0.05 * 255).toInt(),
              ((Theme.of(context).primaryColor.r * 255.0).round() & 0xff),
              ((Theme.of(context).primaryColor.g * 255.0).round() & 0xff),
              ((Theme.of(context).primaryColor.b * 255.0).round() & 0xff),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            page.headline ?? 'Welcome',
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
            section.sectionTitle ?? '',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (section.sectionDescription != null &&
              section.sectionDescription!.isNotEmpty)
            Text(
              section.sectionDescription!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          if (section.sectionImageUrl != null &&
              section.sectionImageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                section.sectionImageUrl!,
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
    CredibilityInfo credibility,
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
            'Credibility',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Main credibility info with image and bio
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (credibility.creatorImageUrl != null &&
                  credibility.creatorImageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    credibility.creatorImageUrl!,
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
                    if (credibility.creatorBio != null &&
                        credibility.creatorBio!.isNotEmpty)
                      Text(
                        credibility.creatorBio!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    if (credibility.backgroundText != null &&
                        credibility.backgroundText!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        credibility.backgroundText!,
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
          // Display credibility statistics if available
          if (credibility.statistics != null &&
              credibility.statistics!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Key Statistics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: credibility.statistics!.map((stat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        stat.statistic ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).primaryColor,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCtaSection(BuildContext context, LandingPage page) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withAlpha((0.8 * 255).round()),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Get personalized recommendations in just 3 minutes - completely free!',
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
                // Use callback if provided
                if (widget.onCtaPressed != null) {
                  widget.onCtaPressed!();
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
              child: const Text(
                'Start Free Assessment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
