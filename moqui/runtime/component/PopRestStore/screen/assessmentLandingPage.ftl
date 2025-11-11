<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${landingPage.title!}</title>
    
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }

        /* Hero Section */
        .hero-section {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 120px 20px 80px;
            text-align: center;
        }

        .hero-content {
            max-width: 800px;
            margin: 0 auto;
        }

        .hero-content h1 {
            font-size: 48px;
            font-weight: 700;
            margin-bottom: 24px;
            line-height: 1.2;
        }

        .hero-content p {
            font-size: 20px;
            margin-bottom: 40px;
            opacity: 0.95;
        }

        /* CTA Button */
        .cta-button {
            display: inline-block;
            background-color: white;
            color: #667eea;
            padding: 18px 48px;
            font-size: 18px;
            font-weight: 600;
            border-radius: 30px;
            text-decoration: none;
            transition: transform 0.2s, box-shadow 0.2s;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
            cursor: pointer;
            border: none;
        }

        .cta-button:hover {
            transform: translateY(-2px);
            box-shadow: 0 15px 35px rgba(0, 0, 0, 0.3);
        }

        .cta-info {
            margin-top: 16px;
            font-size: 14px;
            opacity: 0.85;
        }

        .cta-info svg {
            display: inline-block;
            width: 16px;
            height: 16px;
            vertical-align: middle;
            margin-right: 6px;
        }

        /* Sections */
        .section {
            padding: 80px 20px;
        }

        .section:nth-child(even) {
            background-color: #f8f9fa;
        }

        .section-content {
            max-width: 1000px;
            margin: 0 auto;
        }

        .section h2 {
            font-size: 36px;
            font-weight: 700;
            margin-bottom: 24px;
            text-align: center;
            color: #2d3748;
        }

        .section p {
            font-size: 18px;
            color: #4a5568;
            text-align: center;
            line-height: 1.8;
        }

        /* Credibility Section */
        .credibility-section {
            background-color: white;
            padding: 80px 20px;
        }

        .credibility-content {
            max-width: 800px;
            margin: 0 auto;
            padding: 40px;
            background-color: #f8f9fa;
            border-radius: 20px;
            border: 1px solid #e2e8f0;
        }

        .credibility-content blockquote {
            font-size: 20px;
            font-style: italic;
            color: #4a5568;
            margin-bottom: 24px;
            text-align: center;
            line-height: 1.6;
        }

        .credibility-content cite {
            display: block;
            font-size: 16px;
            font-weight: 600;
            color: #718096;
            text-align: center;
            font-style: normal;
        }

        /* Footer */
        .footer {
            background-color: #2d3748;
            color: #a0aec0;
            padding: 30px 20px;
            text-align: center;
        }

        .footer a {
            color: #a0aec0;
            text-decoration: underline;
            cursor: pointer;
        }

        .footer a:hover {
            color: #cbd5e0;
        }

        /* Privacy Policy Modal */
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.5);
        }

        .modal-content {
            background-color: white;
            margin: 5% auto;
            padding: 40px;
            border-radius: 10px;
            width: 90%;
            max-width: 600px;
            max-height: 80vh;
            overflow-y: auto;
        }

        .modal-close {
            color: #aaa;
            float: right;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }

        .modal-close:hover {
            color: #000;
        }

        .modal h2 {
            margin-bottom: 20px;
            color: #2d3748;
        }

        .modal h3 {
            margin-top: 20px;
            margin-bottom: 10px;
            color: #4a5568;
        }

        .modal p {
            margin-bottom: 15px;
            color: #718096;
        }

        /* Loading Indicator for Flutter */
        .flutter-loading {
            display: none;
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            z-index: 2000;
        }

        .flutter-loading.active {
            display: block;
        }

        .spinner {
            border: 4px solid #f3f3f3;
            border-top: 4px solid #667eea;
            border-radius: 50%;
            width: 50px;
            height: 50px;
            animation: spin 1s linear infinite;
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        /* Responsive Design */
        @media (max-width: 768px) {
            .hero-content h1 {
                font-size: 32px;
            }

            .hero-content p {
                font-size: 18px;
            }

            .section h2 {
                font-size: 28px;
            }

            .section p {
                font-size: 16px;
            }
        }
    </style>
</head>
<body>
    <!-- Hidden iframe to preload Flutter assessment in background -->
    <div id="flutter-assessment-container" style="display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; z-index: 1500; background: white;">
        <iframe id="assessment-iframe" style="width: 100%; height: 100%; border: none;"></iframe>
    </div>

    <!-- Hero Section -->
    <section class="hero-section">
        <div class="hero-content">
            <h1>${landingPage.headline!}</h1>
            <p>${landingPage.subheading!}</p>
            
            <#if ctaActionType?? && ctaActionType == 'assessment' && ctaAssessmentId??>
                <!-- Assessment CTA - launches Flutter app -->
                <button class="cta-button" onclick="launchAssessment('${ctaAssessmentId}')">
                    Start Free Assessment →
                </button>
            <#elseif ctaButtonLink??>
                <!-- Link CTA - follows external link -->
                <a href="${ctaButtonLink}" class="cta-button">
                    Get Started →
                </a>
            <#else>
                <!-- Default CTA -->
                <button class="cta-button" onclick="alert('No action configured')">
                    Learn More →
                </button>
            </#if>
            
            <div class="cta-info">
                <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                </svg>
                Get personalized recommendations in just 3 minutes - completely free!
            </div>
        </div>
    </section>

    <!-- Page Sections -->
    <#if sections?? && (sections?size > 0)>
        <#list sections as section>
            <section class="section">
                <div class="section-content">
                    <h2>${section.sectionTitle!}</h2>
                    <p>${section.sectionDescription!}</p>
                </div>
            </section>
        </#list>
    </#if>

    <!-- Credibility Section -->
    <#if credibility?? && credibility.creatorBio??>
        <section class="credibility-section">
            <div class="credibility-content">
                <blockquote>"${credibility.creatorBio!}"</blockquote>
                <#if credibility.backgroundText??>
                    <cite>— ${credibility.backgroundText!}</cite>
                </#if>
            </div>
        </section>
    </#if>

    <!-- Footer -->
    <footer class="footer">
        <p>© 2025 GrowERP. All rights reserved.</p>
        <p><a onclick="showPrivacyPolicy()">Privacy Policy</a></p>
    </footer>

    <!-- Privacy Policy Modal -->
    <div id="privacyModal" class="modal">
        <div class="modal-content">
            <span class="modal-close" onclick="closePrivacyPolicy()">&times;</span>
            <h2>Privacy Policy</h2>
            
            <h3>Data Collection</h3>
            <p>We collect information you provide directly, such as contact information, assessment responses, and business details.</p>
            
            <h3>Data Usage</h3>
            <p>Your information is used to provide assessment services, improve our platform, and communicate with you about your account.</p>
            
            <h3>Data Protection</h3>
            <p>We implement industry-standard security measures to protect your personal information.</p>
            
            <h3>Your Rights</h3>
            <p>You have the right to access, correct, or delete your personal information at any time.</p>
            
            <button class="cta-button" onclick="closePrivacyPolicy()" style="margin-top: 20px;">Close</button>
        </div>
    </div>

    <script>
        // Privacy Policy Modal Functions
        function showPrivacyPolicy() {
            document.getElementById('privacyModal').style.display = 'block';
        }

        function closePrivacyPolicy() {
            document.getElementById('privacyModal').style.display = 'none';
        }

        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('privacyModal');
            if (event.target == modal) {
                modal.style.display = 'none';
            }
        }

        // Build assessment URL
        function getAssessmentUrl(assessmentId) {
            // Store assessment parameters in sessionStorage for the iframe to access
            const assessmentData = {
                assessmentId: assessmentId,
                pseudoId: '${pseudoId!}',
                <#if landingPage.landingPageId??>
                landingPageId: '${landingPage.landingPageId}',
                </#if>
                <#if ownerPartyId??>
                ownerPartyId: '${ownerPartyId}'
                </#if>
            };
            window.sessionStorage.setItem('assessmentData', JSON.stringify(assessmentData));
            // Return just the path without query parameters - relative paths will resolve correctly
            return '/assessment/';
        }

        // Preload assessment in background iframe
        function preloadAssessment(assessmentId) {
            const iframe = document.getElementById('assessment-iframe');
            const url = getAssessmentUrl(assessmentId);
            console.log('Preloading assessment in background:', url);
            iframe.src = url;
        }

        // Launch Assessment Function - show preloaded assessment
        function launchAssessment(assessmentId) {
            console.log('Launching preloaded assessment:', assessmentId);
            
            // If iframe isn't loaded yet, load it
            const iframe = document.getElementById('assessment-iframe');
            if (!iframe.src) {
                preloadAssessment(assessmentId);
            }
            
            // Show the hidden container with the preloaded iframe
            document.getElementById('flutter-assessment-container').style.display = 'block';
        }

        // Add close button functionality
        function closeAssessment() {
            document.getElementById('flutter-assessment-container').style.display = 'none';
        }

        // Preload Flutter assessment in background when page loads (if assessment CTA exists)
        <#if ctaActionType?? && ctaActionType == 'assessment' && ctaAssessmentId??>
        window.addEventListener('load', function() {
            console.log('Page loaded - preloading assessment in background');
            preloadAssessment('${ctaAssessmentId}');
        });
        </#if>

        // Listen for messages from Flutter assessment to close when complete
        window.addEventListener('message', function(event) {
            // Handle messages from Flutter assessment
            if (event.data && event.data.type === 'assessment-complete') {
                console.log('Assessment completed:', event.data);
                closeAssessment();
                alert('Thank you for completing the assessment! You should receive your results shortly.');
            } else if (event.data && event.data.type === 'assessment-close') {
                console.log('Assessment closed by user');
                closeAssessment();
            }
        });
    </script>
</body>
</html>
