<!DOCTYPE html>
<html lang="en"<#if theme?? && theme == 'dark'> class="theme-dark"</#if>>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${landingPage.title!}</title>

    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }

        /* ── Light theme (default) ── */
        :root {
            --bg: #ffffff;
            --surface: #f8f9fa;
            --card: #ffffff;
            --border: #e2e8f0;
            --accent1: #667eea;
            --accent2: #764ba2;
            --text: #2d3748;
            --muted: #4a5568;
            --footer-bg: #2d3748;
            --footer-text: #a0aec0;
        }

        /* ── Dark theme ── */
        html.theme-dark {
            --bg: #09090f;
            --surface: #12121e;
            --card: #181828;
            --border: rgba(255,255,255,0.08);
            --accent1: #6c47ff;
            --accent2: #00d4aa;
            --text: #f0f0f8;
            --muted: #8888aa;
            --footer-bg: #05050a;
            --footer-text: #8888aa;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: var(--text);
            background: var(--bg);
        }

        /* Hero */
        .hero-section {
            background: linear-gradient(135deg, var(--accent1) 0%, var(--accent2) 100%);
            color: white;
            padding: 120px 20px 80px;
            text-align: center;
        }
        .hero-content { max-width: 800px; margin: 0 auto; }
        .hero-content h1 { font-size: 48px; font-weight: 700; margin-bottom: 24px; line-height: 1.2; }
        .hero-content p { font-size: 20px; margin-bottom: 40px; opacity: 0.95; }

        .cta-button {
            display: inline-block; background-color: white; color: var(--accent1);
            padding: 18px 48px; font-size: 18px; font-weight: 600; border-radius: 30px;
            text-decoration: none; transition: transform 0.2s, box-shadow 0.2s;
            box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2); cursor: pointer; border: none;
        }
        .cta-button:hover { transform: translateY(-2px); box-shadow: 0 15px 35px rgba(0, 0, 0, 0.3); }
        .cta-info { margin-top: 16px; font-size: 14px; opacity: 0.85; }
        .cta-info svg { display: inline-block; width: 16px; height: 16px; vertical-align: middle; margin-right: 6px; }

        /* Sections */
        .section { padding: 80px 20px; background: var(--bg); }
        .section:nth-child(even) { background-color: var(--surface); }
        .section-content { max-width: 1000px; margin: 0 auto; }
        .section h2 { font-size: 36px; font-weight: 700; margin-bottom: 24px; text-align: center; color: var(--text); }
        .section p { font-size: 18px; color: var(--muted); text-align: center; line-height: 1.8; }

        /* Stats bar */
        .stats-bar {
            display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 1px;
            background: var(--border); border: 1px solid var(--border); border-radius: 16px;
            overflow: hidden; margin-top: 40px;
        }
        .stat { background: var(--card); padding: 28px 20px; text-align: center; }
        .stat-value { font-size: 2.2rem; font-weight: 800; color: var(--accent1); line-height: 1; }
        .stat-label { color: var(--muted); font-size: .85rem; margin-top: 6px; }

        /* Card grid */
        .cards-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 24px; margin-top: 20px; }
        .outline-card { background: var(--card); border: 1px solid var(--border); border-radius: 16px; padding: 28px; text-align: left; }
        .outline-card .tag { font-size: .72rem; font-weight: 700; letter-spacing: .08em; text-transform: uppercase; color: var(--accent2); margin-bottom: 10px; }
        .outline-card h3 { font-size: 1.15rem; font-weight: 700; margin-bottom: 12px; color: var(--text); }
        .outline-card p { font-size: .92rem; color: var(--muted); text-align: left; margin-bottom: 14px; }
        .outline-card ul { list-style: none; display: flex; flex-direction: column; gap: 6px; margin-bottom: 12px; }
        .outline-card li { font-size: .88rem; color: var(--muted); }
        .outline-card li::before { content: '\2713'; color: var(--accent2); font-weight: 700; margin-right: 8px; }
        .outline-card .footer-tag { display: inline-block; font-size: .72rem; font-weight: 600; color: var(--accent1); }

        /* Timeline */
        .timeline-track { position: relative; max-width: 720px; margin: 30px auto 0; }
        .timeline-track::before {
            content: ''; position: absolute; left: 24px; top: 0; bottom: 0; width: 2px;
            background: linear-gradient(to bottom, var(--accent1), var(--accent2));
        }
        .tl-item { display: flex; gap: 24px; margin-bottom: 32px; text-align: left; }
        .tl-dot {
            width: 48px; height: 48px; border-radius: 50%; flex-shrink: 0;
            background: linear-gradient(135deg, var(--accent1), var(--accent2)); color: #fff;
            display: flex; align-items: center; justify-content: center; font-weight: 800; z-index: 1;
        }
        .tl-content h4 { font-size: 1.05rem; font-weight: 700; margin-bottom: 6px; color: var(--text); }
        .tl-content p { font-size: .9rem; color: var(--muted); text-align: left; }

        /* Benefits */
        .benefits-list { list-style: none; display: flex; flex-direction: column; gap: 14px; margin-top: 20px; text-align: left; max-width: 520px; margin-left: auto; margin-right: auto; }
        .benefits-list li { display: flex; align-items: center; gap: 12px; font-size: .95rem; color: var(--text); }
        .benefit-icon { font-size: 1.3rem; flex-shrink: 0; }

        /* Two-column benefits+form pairing */
        .split-section { display: grid; grid-template-columns: 1fr 1fr; gap: 48px; align-items: start; max-width: 1000px; margin: 0 auto; }
        @media (max-width: 768px) { .split-section { grid-template-columns: 1fr; } }

        /* Credibility */
        .credibility-section { background-color: var(--card); padding: 80px 20px; }
        .credibility-content { max-width: 800px; margin: 0 auto; padding: 40px; background-color: var(--surface); border-radius: 20px; border: 1px solid var(--border); }
        .credibility-content blockquote { font-size: 20px; font-style: italic; color: var(--muted); margin-bottom: 24px; text-align: center; line-height: 1.6; }
        .credibility-content cite { display: block; font-size: 16px; font-weight: 600; color: var(--muted); text-align: center; font-style: normal; }
        .credibility-stats { display: flex; flex-wrap: wrap; justify-content: center; gap: 16px; margin-top: 24px; }
        .credibility-stats span { background: var(--card); border: 1px solid var(--border); border-radius: 8px; padding: 8px 16px; font-size: .88rem; color: var(--text); }

        /* Footer */
        .footer { background-color: var(--footer-bg); color: var(--footer-text); padding: 30px 20px; text-align: center; }
        .footer a { color: var(--footer-text); text-decoration: underline; cursor: pointer; }
        .footer a:hover { color: #cbd5e0; }

        /* Privacy Policy Modal */
        .modal { display: none; position: fixed; z-index: 1000; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(0, 0, 0, 0.5); }
        .modal-content { background-color: var(--card); margin: 5% auto; padding: 40px; border-radius: 10px; width: 90%; max-width: 600px; max-height: 80vh; overflow-y: auto; color: var(--text); }
        .modal-close { color: var(--muted); float: right; font-size: 28px; font-weight: bold; cursor: pointer; }
        .modal-close:hover { color: var(--text); }
        .modal h2 { margin-bottom: 20px; color: var(--text); }
        .modal h3 { margin-top: 20px; margin-bottom: 10px; color: var(--text); }
        .modal p { margin-bottom: 15px; color: var(--muted); }

        /* Loading indicator for Flutter */
        .flutter-loading { display: none; position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); z-index: 2000; }
        .flutter-loading.active { display: block; }
        .spinner { border: 4px solid #f3f3f3; border-top: 4px solid var(--accent1); border-radius: 50%; width: 50px; height: 50px; animation: spin 1s linear infinite; }
        @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }

        @media (max-width: 768px) {
            .hero-content h1 { font-size: 32px; }
            .hero-content p { font-size: 18px; }
            .section h2 { font-size: 28px; }
            .section p { font-size: 16px; }
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
                <button id="cta-button" class="cta-button" onclick="launchAssessment('${ctaAssessmentId}')" disabled>
                    <span id="button-loader" style="display: none; width: 16px; height: 16px; border: 2px solid var(--accent1); border-top-color: transparent; border-radius: 50%; animation: spin 0.8s linear infinite; display: inline-block; margin-right: 8px; vertical-align: middle;"></span>
                    Start Free Assessment →
                </button>
            <#elseif ctaActionType?? && ctaActionType == 'form' && ctaFormId??>
                <a href="#growerp-form-section" class="cta-button">Get Started →</a>
            <#elseif ctaButtonLink??>
                <a href="${ctaButtonLink}" class="cta-button">Get Started →</a>
            <#else>
                <button class="cta-button" onclick="alert('No action configured')">Learn More →</button>
            </#if>

            <div class="cta-info">
                <svg fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
                </svg>
                <#if ctaActionType?? && ctaActionType == 'assessment'>
                    Get personalized recommendations in just 3 minutes - completely free!
                <#else>
                    Takes less than a minute
                </#if>
            </div>
        </div>
    </section>

    <!-- Page Sections -->
    <#if sections?? && (sections?size > 0)>
        <#list sections as section>
            <#assign lastSectionIsBenefits = (section_index == (sections?size - 1)) && section.sectionType == 'benefits'>
            <#-- when the CTA is a form and this is the last section and it's a benefits
                 list, pair it two-column with the form instead of rendering it alone -->
            <#if !(ctaActionType?? && ctaActionType == 'form' && ctaFormId?? && lastSectionIsBenefits)>
                <section class="section">
                    <div class="section-content">
                        <#if section.sectionTitle?has_content><h2>${section.sectionTitle}</h2></#if>
                        <#if section.sectionDescription?has_content><p>${section.sectionDescription}</p></#if>

                        <#if section.sectionType == 'stats'>
                            <div class="stats-bar">
                                <#list section.rows as row>
                                    <div class="stat">
                                        <div class="stat-value">${row.value!}</div>
                                        <div class="stat-label">${row.label!}</div>
                                    </div>
                                </#list>
                            </div>
                        <#elseif section.sectionType == 'cards'>
                            <div class="cards-grid">
                                <#list section.rows as row>
                                    <div class="outline-card">
                                        <#if row.tag??><div class="tag">${row.tag}</div></#if>
                                        <h3>${row.title!}</h3>
                                        <#if row.description??><p>${row.description}</p></#if>
                                        <#if row.points?? && (row.points?size > 0)>
                                            <ul><#list row.points as point><li>${point}</li></#list></ul>
                                        </#if>
                                        <#if row.footer??><span class="footer-tag">${row.footer}</span></#if>
                                    </div>
                                </#list>
                            </div>
                        <#elseif section.sectionType == 'timeline'>
                            <div class="timeline-track">
                                <#list section.rows as row>
                                    <div class="tl-item">
                                        <div class="tl-dot">${row_index + 1}</div>
                                        <div class="tl-content">
                                            <h4>${row.title!}</h4>
                                            <#if row.description??><p>${row.description}</p></#if>
                                        </div>
                                    </div>
                                </#list>
                            </div>
                        <#elseif section.sectionType == 'benefits'>
                            <ul class="benefits-list">
                                <#list section.rows as row>
                                    <li><span class="benefit-icon">${row.icon!}</span><span>${row.text!}</span></li>
                                </#list>
                            </ul>
                        </#if>
                    </div>
                </section>
            </#if>
        </#list>
    </#if>

    <!-- CTA: form section (bottom), paired with the last benefits section when present -->
    <#if ctaActionType?? && ctaActionType == 'form' && ctaFormId??>
        <section class="section" id="growerp-form-section">
            <div class="section-content">
                <#assign benefitsSection = "">
                <#list sections as s><#if s.sectionType == 'benefits'><#assign benefitsSection = s></#if></#list>
                <#if benefitsSection?is_hash>
                    <div class="split-section">
                        <div>
                            <#if benefitsSection.sectionTitle?has_content><h2 style="text-align:left;">${benefitsSection.sectionTitle}</h2></#if>
                            <#if benefitsSection.sectionDescription?has_content><p style="text-align:left;">${benefitsSection.sectionDescription}</p></#if>
                            <ul class="benefits-list" style="margin-left:0;">
                                <#list benefitsSection.rows as row>
                                    <li><span class="benefit-icon">${row.icon!}</span><span>${row.text!}</span></li>
                                </#list>
                            </ul>
                        </div>
                        <div id="growerp-form-holder" data-growerp-form="${ctaFormId}"></div>
                    </div>
                <#else>
                    <div style="max-width:480px;margin:0 auto;">
                        <div id="growerp-form-holder" data-growerp-form="${ctaFormId}"></div>
                    </div>
                </#if>
            </div>
        </section>
    <#elseif ctaActionType?? && ctaActionType == 'assessment' && ctaAssessmentId??>
        <section class="section" style="padding: 60px 20px;">
            <div class="section-content" style="text-align: center;">
                <button id="cta-button-bottom" class="cta-button" onclick="launchAssessment('${ctaAssessmentId}')" style="font-size: 16px; padding: 16px 40px;" disabled>
                    <span id="button-loader-bottom" style="display: none; width: 14px; height: 14px; border: 2px solid var(--accent1); border-top-color: transparent; border-radius: 50%; animation: spin 0.8s linear infinite; display: inline-block; margin-right: 8px; vertical-align: middle;"></span>
                    Start Free Assessment →
                </button>
            </div>
        </section>
    </#if>

    <!-- Credibility Section -->
    <#if credibility?? && credibility.creatorBio??>
        <section class="credibility-section">
            <div class="credibility-content">
                <blockquote>"${credibility.creatorBio!}"</blockquote>
                <#if credibility.backgroundText??>
                    <cite>— ${credibility.backgroundText!}</cite>
                </#if>
                <#if credibility.statistics?? && (credibility.statistics?size > 0)>
                    <div class="credibility-stats">
                        <#list credibility.statistics as stat>
                            <span>${stat.statistic!}</span>
                        </#list>
                    </div>
                </#if>
            </div>
        </section>
    </#if>

    <!-- Footer -->
    <footer class="footer">
        <p>© ${.now?string('yyyy')} GrowERP. All rights reserved.</p>
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
        // Track assessment loading state
        let assessmentLoaded = false;
        let assessmentLoading = false;
        let flutterReadyReceived = false;
        let assessmentDisplayed = false;

        window.addEventListener('message', function(event) {
            if (!event.data || typeof event.data !== 'object') return;
            if (event.data.type === 'flutter-ready') {
                flutterReadyReceived = true;
                assessmentLoaded = true;
                assessmentLoading = false;
                hideSpinner();
                enableAssessmentButtons();
            } else if (assessmentDisplayed && event.data.type === 'assessment-complete') {
                closeAssessment();
                alert('Thank you for completing the assessment! You should receive your results shortly.');
            } else if (assessmentDisplayed && event.data.type === 'assessment-close') {
                closeAssessment();
            }
        });

        function showPrivacyPolicy() { document.getElementById('privacyModal').style.display = 'block'; }
        function closePrivacyPolicy() { document.getElementById('privacyModal').style.display = 'none'; }
        window.onclick = function(event) {
            const modal = document.getElementById('privacyModal');
            if (event.target == modal) modal.style.display = 'none';
        }

        function getAssessmentUrl(assessmentId) {
            const assessmentData = {
                assessmentId: assessmentId,
                pseudoId: '${pseudoId!}',
                <#if landingPage.landingPageId??>landingPageId: '${landingPage.landingPageId}',</#if>
                <#if party??>ownerPartyId: '${party.ownerPartyId}'</#if>
            };
            window.sessionStorage.setItem('assessmentData', JSON.stringify(assessmentData));
            return '/assessment/';
        }

        function preloadAssessment(assessmentId) {
            if (assessmentLoading || assessmentLoaded) return;
            assessmentLoading = true;
            const iframe = document.getElementById('assessment-iframe');
            const url = getAssessmentUrl(assessmentId);

            iframe.onload = function() {
                if (flutterReadyReceived) return;
                let checkAttempts = 0;
                const maxAttempts = 100;
                const checkFlutterReady = setInterval(() => {
                    checkAttempts++;
                    if (flutterReadyReceived) { clearInterval(checkFlutterReady); return; }
                    try {
                        const iframeDoc = iframe.contentDocument || iframe.contentWindow.document;
                        const hasCanvas = iframeDoc.querySelector('canvas');
                        const hasFlutterElements = iframeDoc.querySelector('flt-glass-pane, flt-scene-host, [flt-renderer]');
                        const bodyHasContent = iframeDoc.body && iframeDoc.body.children.length > 1;
                        if (hasCanvas || hasFlutterElements || bodyHasContent) {
                            clearInterval(checkFlutterReady);
                            assessmentLoaded = true;
                            assessmentLoading = false;
                            hideSpinner();
                            enableAssessmentButtons();
                            return;
                        }
                    } catch (e) { /* cross-origin, rely on postMessage/timeout */ }
                    if (checkAttempts >= maxAttempts) {
                        clearInterval(checkFlutterReady);
                        assessmentLoaded = true;
                        assessmentLoading = false;
                        hideSpinner();
                        enableAssessmentButtons();
                    }
                }, 200);
            };
            iframe.onerror = function() {
                assessmentLoading = false;
                hideSpinner();
                alert('Failed to load assessment. Please try again.');
            };
            iframe.src = url;
        }

        function enableAssessmentButtons() {
            setTimeout(function() {
                const button = document.getElementById('cta-button');
                const buttonBottom = document.getElementById('cta-button-bottom');
                if (button) button.disabled = false;
                if (buttonBottom) buttonBottom.disabled = false;
            }, 1000);
        }

        function hideSpinner() {
            const loader = document.getElementById('button-loader');
            const loaderBottom = document.getElementById('button-loader-bottom');
            if (loader) loader.style.display = 'none';
            if (loaderBottom) loaderBottom.style.display = 'none';
        }

        function launchAssessment(assessmentId) {
            const loader = document.getElementById('button-loader');
            const loaderBottom = document.getElementById('button-loader-bottom');
            const button = document.getElementById('cta-button');
            const buttonBottom = document.getElementById('cta-button-bottom');
            if (!assessmentLoaded && !assessmentLoading) {
                preloadAssessment(assessmentId);
                if (loader) loader.style.display = 'inline-block';
                if (loaderBottom) loaderBottom.style.display = 'inline-block';
                if (button) button.disabled = true;
                if (buttonBottom) buttonBottom.disabled = true;
            }
            if (assessmentLoaded) {
                if (loader) loader.style.display = 'none';
                if (loaderBottom) loaderBottom.style.display = 'none';
                document.getElementById('flutter-assessment-container').style.display = 'block';
                assessmentDisplayed = true;
                if (button) button.disabled = false;
                if (buttonBottom) buttonBottom.disabled = false;
            }
        }

        function closeAssessment() {
            document.getElementById('flutter-assessment-container').style.display = 'none';
            assessmentDisplayed = false;
            hideSpinner();
            const button = document.getElementById('cta-button');
            const buttonBottom = document.getElementById('cta-button-bottom');
            if (button) button.disabled = false;
            if (buttonBottom) buttonBottom.disabled = false;
            assessmentLoaded = false;
            assessmentLoading = false;
            flutterReadyReceived = false;
        }

        <#if ctaActionType?? && ctaActionType == 'assessment' && ctaAssessmentId??>
        window.addEventListener('load', function() {
            preloadAssessment('${ctaAssessmentId}');
        });
        </#if>
    </script>
</body>
</html>
