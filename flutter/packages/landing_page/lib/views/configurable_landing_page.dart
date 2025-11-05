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

// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:growerp_assessment/growerp_assessment.dart';
import '../src/screens/landing_page_assessment_flow_screen.dart';

class ConfigurableLandingPage extends StatefulWidget {
  const ConfigurableLandingPage({
    super.key,
    this.landingPageId,
    this.pseudoId,
    this.ownerPartyId,
  });

  /// System-wide unique identifier for landing page
  final String? landingPageId;

  /// Tenant-unique identifier for landing page (used in URLs)
  final String? pseudoId;

  /// Owner party ID for multi-tenancy
  final String? ownerPartyId;

  @override
  State<ConfigurableLandingPage> createState() =>
      _ConfigurableLandingPageState();
}

class _ConfigurableLandingPageState extends State<ConfigurableLandingPage> {
  @override
  void initState() {
    super.initState();
    _loadLandingPage();
  }

  @override
  void didUpdateWidget(covariant ConfigurableLandingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.landingPageId != oldWidget.landingPageId ||
        widget.pseudoId != oldWidget.pseudoId ||
        widget.ownerPartyId != oldWidget.ownerPartyId) {
      _loadLandingPage();
    }
  }

  void _loadLandingPage() {
    context.read<LandingPageBloc>().add(
      LandingPageFetch(
        landingPageId: widget.landingPageId,
        pseudoId: widget.pseudoId,
        ownerPartyId: widget.ownerPartyId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<LandingPageBloc, LandingPageState>(
        builder: (context, state) {
          if (state.status == LandingPageStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == LandingPageStatus.failure) {
            return _buildErrorState(context, state.message);
          }

          if (state.status == LandingPageStatus.success &&
              state.selectedLandingPage != null) {
            return _buildLandingPageContent(
              context,
              state.selectedLandingPage!,
            );
          }

          // Fallback to default content if no data available
          return _buildDefaultContent(context);
        },
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String? message) {
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
            message ?? 'Unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<LandingPageBloc>().add(
                LandingPageFetch(
                  landingPageId: widget.landingPageId,
                  pseudoId: widget.pseudoId,
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

  Widget _buildDefaultContent(BuildContext context) {
    return _GoogleStitchLandingPage(
      landingPage: const LandingPage(
        landingPageId: 'default',
        pseudoId: 'default',
        title: 'Business Assessment',
        status: 'ACTIVE',
        headline: 'Discover Your Business Potential',
        subheading:
            'Answer 15 questions to find out what\'s holding your business back and how to unlock its full potential.',
        ctaActionType: 'assessment',
        sections: [
          LandingPageSection(
            landingPageSectionId: 'section1',
            pseudoId: 'value-props',
            sectionTitle: 'Three Key Areas We Assess',
            sectionDescription:
                'Our comprehensive assessment evaluates your business across three critical dimensions: Business Strategy & Planning, Operations & Efficiency, and Market Position & Growth.',
          ),
        ],
        credibility: CredibilityInfo(
          credibilityInfoId: 'cred1',
          pseudoId: 'testimonial',
          creatorBio: 'Trusted by 1000+ Businesses',
          backgroundText:
              'Our assessment methodology is based on proven business frameworks and has helped over 1,000 businesses identify growth opportunities and overcome challenges.',
        ),
      ),
      landingPageId: widget.landingPageId,
      pseudoId: widget.pseudoId,
      ownerPartyId: widget.ownerPartyId,
      valuePropositions: const [
        'Business Strategy & Planning',
        'Operations & Efficiency',
        'Market Position & Growth',
      ],
    );
  }

  Widget _buildLandingPageContent(BuildContext context, LandingPage page) {
    // Extract value propositions from the section description
    List<String> valueProps = [];
    if (page.sections != null && page.sections!.isNotEmpty) {
      final section = page.sections!.first;
      if (section.sectionDescription != null) {
        // Simple parsing - in a real implementation, this could be more sophisticated
        // For now, split by commas or use default values
        if (section.sectionDescription!.contains(',')) {
          valueProps = section.sectionDescription!
              .split(',')
              .map((e) => e.trim())
              .toList();
        } else {
          // Default value propositions
          valueProps = [
            'Business Strategy & Planning',
            'Operations & Efficiency',
            'Market Position & Growth',
          ];
        }
      }
    }

    return _GoogleStitchLandingPage(
      landingPage: page,
      landingPageId: widget.landingPageId,
      pseudoId: widget.pseudoId,
      ownerPartyId: widget.ownerPartyId,
      valuePropositions: valueProps.isNotEmpty ? valueProps : null,
    );
  }
}

class _GoogleStitchLandingPage extends StatelessWidget {
  const _GoogleStitchLandingPage({
    required this.landingPage,
    this.landingPageId,
    this.pseudoId = 'default',
    this.ownerPartyId,
    this.valuePropositions,
  });

  final LandingPage landingPage;
  final String? landingPageId;
  final String? pseudoId;
  final String? ownerPartyId;
  final List<String>? valuePropositions;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 1200;
    final isTablet = screenSize.width > 768 && screenSize.width <= 1200;
    final isMobile = screenSize.width <= 768;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero Section - Google Stitch inspired design
          _buildHeroSection(context, isDesktop, isTablet, isMobile),

          // Value Proposition Section
          if (landingPage.sections != null && landingPage.sections!.isNotEmpty)
            _buildValuePropositionSection(
              context,
              isDesktop,
              isTablet,
              isMobile,
            ),

          // Credibility Section
          if (landingPage.credibility != null)
            _buildCredibilitySection(context, isDesktop, isTablet, isMobile),

          // CTA Section
          if (landingPage.ctaActionType != null)
            _buildPrimaryCta(
              context,
              landingPage,
              landingPageId ?? pseudoId ?? 'default',
              ownerPartyId,
            ),

          // Footer with Privacy Policy
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : (isTablet ? 40 : 20),
            vertical: isDesktop ? 120 : (isTablet ? 80 : 60),
          ),
          child: isDesktop
              ? _buildDesktopHeroLayout(context)
              : _buildMobileHeroLayout(context, isMobile),
        ),
      ),
    );
  }

  Widget _buildDesktopHeroLayout(BuildContext context) {
    return Row(
      children: [
        // Left side - Content
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [_buildHeroContent(context, isDesktop: true)],
          ),
        ),
        const SizedBox(width: 80),
        // Right side - Visual element or form preview
        Expanded(
          flex: 4,
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              color: Color.fromARGB(
                (0.1 * 255).toInt(),
                ((Colors.white.r * 255.0).round() & 0xff),
                ((Colors.white.g * 255.0).round() & 0xff),
                ((Colors.white.b * 255.0).round() & 0xff),
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Color.fromARGB(
                  (0.2 * 255).toInt(),
                  ((Colors.white.r * 255.0).round() & 0xff),
                  ((Colors.white.g * 255.0).round() & 0xff),
                  ((Colors.white.b * 255.0).round() & 0xff),
                ),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assessment,
                    size: 80,
                    color: Color.fromARGB(
                      (0.8 * 255).toInt(),
                      ((Colors.white.r * 255.0).round() & 0xff),
                      ((Colors.white.g * 255.0).round() & 0xff),
                      ((Colors.white.b * 255.0).round() & 0xff),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '15 Questions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick & Insightful',
                    style: TextStyle(
                      color: Color.fromARGB(
                        (0.8 * 255).toInt(),
                        ((Colors.white.r * 255.0).round() & 0xff),
                        ((Colors.white.g * 255.0).round() & 0xff),
                        ((Colors.white.b * 255.0).round() & 0xff),
                      ),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeroLayout(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildHeroContent(context, isDesktop: false),
        if (!isMobile) ...[
          const SizedBox(height: 40),
          Container(
            width: 300,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withAlpha((0.2 * 255).round()),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assessment,
                    size: 50,
                    color: Color.fromARGB(
                      (0.8 * 255).toInt(),
                      ((Colors.white.r * 255.0).round() & 0xff),
                      ((Colors.white.g * 255.0).round() & 0xff),
                      ((Colors.white.b * 255.0).round() & 0xff),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '15 Questions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeroContent(BuildContext context, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: isDesktop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        // Hook/Headline
        Text(
          landingPage.headline ?? 'Welcome',
          style: TextStyle(
            color: Colors.white,
            fontSize: isDesktop ? 48 : 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Subheading
        if (landingPage.subheading != null &&
            landingPage.subheading!.isNotEmpty)
          Text(
            landingPage.subheading!,
            style: TextStyle(
              color: Color.fromARGB(
                (0.9 * 255).toInt(),
                ((Colors.white.r * 255.0).round() & 0xff),
                ((Colors.white.g * 255.0).round() & 0xff),
                ((Colors.white.b * 255.0).round() & 0xff),
              ),
              fontSize: isDesktop ? 20 : 18,
              height: 1.5,
            ),
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          ),

        const SizedBox(height: 40),

        // Primary CTA Button
        if (landingPage.ctaActionType != null)
          _buildPrimaryCta(
            context,
            landingPage,
            landingPageId ?? pseudoId ?? 'default',
            ownerPartyId,
          ),
      ],
    );
  }

  Widget _buildPrimaryCta(
    BuildContext context,
    LandingPage landingPage,
    String landingPageId,
    String? ownerPartyId,
  ) {
    if (landingPage.ctaActionType == null) {
      return const SizedBox.shrink();
    }

    // Default button text
    String buttonText = 'Start Free Assessment';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(
                  (0.2 * 255).toInt(),
                  ((Colors.black.r * 255.0).round() & 0xff),
                  ((Colors.black.g * 255.0).round() & 0xff),
                  ((Colors.black.b * 255.0).round() & 0xff),
                ),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              // Navigate to assessment flow with current landing page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LandingPageAssessmentFlowScreen(
                    landingPageId: landingPageId,
                    ownerPartyId: ownerPartyId,
                    assessmentId: null, // Will be loaded from landing page
                    startAssessmentFlow: true,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF667eea),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Simple text message for CTA
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Color.fromARGB(
                (0.8 * 255).toInt(),
                ((Colors.white.r * 255.0).round() & 0xff),
                ((Colors.white.g * 255.0).round() & 0xff),
                ((Colors.white.b * 255.0).round() & 0xff),
              ),
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Get personalized recommendations in just 3 minutes - completely free!',
                style: TextStyle(
                  color: Color.fromARGB(
                    (0.8 * 255).toInt(),
                    ((Colors.white.r * 255.0).round() & 0xff),
                    ((Colors.white.g * 255.0).round() & 0xff),
                    ((Colors.white.b * 255.0).round() & 0xff),
                  ),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildValuePropositionSection(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    // Display all sections from the backend
    return Column(
      children: landingPage.sections!.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        return Container(
          width: double.infinity,
          color: index.isEven ? Colors.grey[50] : Colors.white,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : (isTablet ? 40 : 20),
              vertical: isDesktop ? 80 : (isTablet ? 60 : 50),
            ),
            child: Column(
              children: [
                // Section Title
                Text(
                  section.sectionTitle ?? 'Section',
                  style: TextStyle(
                    fontSize: isDesktop ? 36 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Section Description
                if (section.sectionDescription != null &&
                    section.sectionDescription!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 100 : (isTablet ? 50 : 20),
                    ),
                    child: Text(
                      section.sectionDescription!,
                      style: TextStyle(
                        fontSize: isDesktop ? 18 : 16,
                        color: Colors.grey[600],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCredibilitySection(
    BuildContext context,
    bool isDesktop,
    bool isTablet,
    bool isMobile,
  ) {
    final credibility = landingPage.credibility;

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 80 : (isTablet ? 40 : 20),
          vertical: isDesktop ? 100 : (isTablet ? 60 : 50),
        ),
        child: Column(
          children: [
            Text(
              'Credibility',
              style: TextStyle(
                fontSize: isDesktop ? 32 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  if (credibility != null &&
                      credibility.creatorBio != null &&
                      credibility.creatorBio!.isNotEmpty)
                    Text(
                      '"${credibility.creatorBio!}"',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  const SizedBox(height: 24),

                  if (credibility != null &&
                      credibility.backgroundText != null &&
                      credibility.backgroundText!.isNotEmpty)
                    Text(
                      '— ${credibility.backgroundText!}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Text(
              '© 2025 GrowERP. All rights reserved.',
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                // Show privacy policy dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Privacy Policy'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Data Collection',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'We collect information you provide directly, such as contact information, assessment responses, and business details.',
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Data Usage',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your information is used to provide assessment services, improve our platform, and communicate with you about your account.',
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Data Protection',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'We implement industry-standard security measures to protect your personal information.',
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
