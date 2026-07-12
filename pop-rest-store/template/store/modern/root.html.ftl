<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <#-- per-page description (content front-matter) > store setting > legacy defaults -->
    <#if pageDescription?has_content>
    <meta name="description" content="${pageDescription?html}">
    <#elseif storeInfo.settings.PsstMetaDescription?has_content>
    <meta name="description" content="${storeInfo.settings.PsstMetaDescription?html}">
    <#elseif storeInfo.productStore.productStoreId == "100000">
    <meta name="description" content="GrowERP — Open Source AI-Powered ERP for Small & Medium Businesses. Manage accounting, inventory, orders, CRM, and marketing from one platform. Free 2-week trial.">
    <meta name="keywords" content="ERP, open source ERP, small business ERP, AI ERP, Flutter ERP, Moqui, GrowERP, business management">
    <#else>
    <meta name="description" content="Welcome to ${storeInfo.productStore.storeName} - Your trusted online store">
    </#if>
    <meta name="theme-color" content="${luminaSurfaceHex!'#0b1326'}">

    <#if pageTitle?has_content>
    <title>${pageTitle?html} — ${storeInfo.productStore.storeName}</title>
    <#else>
    <title>${storeInfo.productStore.storeName}</title>
    </#if>
    <meta property="og:type" content="website">
    <meta property="og:site_name" content="${storeInfo.productStore.storeName?html}">
    <meta property="og:title" content="${(pageTitle?has_content)?then(pageTitle?html, storeInfo.productStore.storeName?html)}">
    <#if pageDescription?has_content><meta property="og:description" content="${pageDescription?html}"></#if>
    <#if ec.web??><meta property="og:url" content="${ec.web.requestUrl?html}">
    <link rel="canonical" href="${ec.web.requestUrl?html}"></#if>

    <!-- Preconnect for performance -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

    <!-- Typography: Inter (display/body), Geist (labels/code), Material Symbols (icons) -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=Geist:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200&display=swap" rel="stylesheet">

    <!-- Per-store generated styles (includes --l-* Lumina design tokens);
         version query defeats the 24h browser cache so theme changes show immediately -->
    <link rel="stylesheet" href="/components/styles/${storeInfo.productStore.productStoreId}.css?v=${.now?long?c}">

    <!-- Anti-FOUC: paint the store surface before Tailwind CDN JIT runs -->
    <style>
        html { background: rgb(var(--l-surface, ${(lumina.surface)!'11 19 38'})); color: rgb(var(--l-on-surface, ${(lumina.onSurface)!'218 226 253'})); color-scheme: ${luminaBrightness!'dark'}; }
        .material-symbols-outlined { font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24; }
        .icon-fill { font-variation-settings: 'FILL' 1, 'wght' 400, 'GRAD' 0, 'opsz' 24; }
        ::-webkit-scrollbar { width: 8px; }
        ::-webkit-scrollbar-track { background: rgb(var(--l-surface, ${(lumina.surface)!'11 19 38'})); }
        ::-webkit-scrollbar-thumb { background: rgb(var(--l-surface-container-highest, ${(lumina.surfaceContainerHighest)!'45 52 73'})); border-radius: 4px; }
    </style>

    <!-- Tailwind CDN with Lumina token theme; colors reference the per-store CSS variables -->
    <script src="https://cdn.tailwindcss.com"></script>
    <#noparse>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        "surface": "rgb(var(--l-surface) / <alpha-value>)",
                        "surface-container-lowest": "rgb(var(--l-surface-container-lowest) / <alpha-value>)",
                        "surface-container-low": "rgb(var(--l-surface-container-low) / <alpha-value>)",
                        "surface-container": "rgb(var(--l-surface-container) / <alpha-value>)",
                        "surface-container-high": "rgb(var(--l-surface-container-high) / <alpha-value>)",
                        "surface-container-highest": "rgb(var(--l-surface-container-highest) / <alpha-value>)",
                        "on-surface": "rgb(var(--l-on-surface) / <alpha-value>)",
                        "on-surface-variant": "rgb(var(--l-on-surface-variant) / <alpha-value>)",
                        "primary": "rgb(var(--l-primary) / <alpha-value>)",
                        "on-primary": "rgb(var(--l-on-primary) / <alpha-value>)",
                        "primary-container": "rgb(var(--l-primary-container) / <alpha-value>)",
                        "secondary": "rgb(var(--l-secondary) / <alpha-value>)",
                        "tertiary": "rgb(var(--l-tertiary) / <alpha-value>)",
                        "error": "rgb(var(--l-error) / <alpha-value>)",
                        "outline": "rgb(var(--l-outline) / <alpha-value>)",
                        "outline-variant": "rgb(var(--l-outline-variant) / <alpha-value>)",
                        "white": "rgb(var(--l-contrast) / <alpha-value>)"
                    },
                    fontFamily: {
                        display: ["Inter", "sans-serif"],
                        body: ["Inter", "sans-serif"],
                        label: ["Geist", "sans-serif"]
                    },
                    borderRadius: {
                        sm: "0.25rem", DEFAULT: "0.5rem", lg: "0.75rem", xl: "1rem", "2xl": "1.5rem"
                    },
                    maxWidth: { container: "1440px" }
                }
            }
        }
    </script>
    </#noparse>

    <!-- Favicon -->
    <link rel="icon" type="image/png" href="/assets/favicon.png" sizes="32x32"/>
    <link rel="apple-touch-icon" href="/assets/favicon.png">

    <#-- Google Analytics -->
    <#if storeInfo.settings.measurementId?has_content>
        <!-- Google tag (gtag.js) -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=${storeInfo.settings.measurementId}"></script>
        <script>
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
            gtag('config', '${storeInfo.settings.measurementId}');
        </script>
    </#if>
</head>

<body class="lumina bg-surface text-on-surface font-body antialiased min-h-screen overflow-x-hidden selection:bg-primary/30">
    <div id="store-root">
        ${sri.renderSubscreen()}
    </div>

    <#noparse>
    <script>
        // Dropdown / mobile-menu toggles: <button data-menu-button="panelId"> toggles #panelId
        document.addEventListener('click', function(event) {
            var button = event.target.closest('[data-menu-button]');
            if (button) {
                var panel = document.getElementById(button.getAttribute('data-menu-button'));
                if (panel) {
                    var willOpen = panel.classList.contains('hidden');
                    closeAllPanels();
                    if (willOpen) {
                        panel.classList.remove('hidden');
                        button.setAttribute('aria-expanded', 'true');
                    }
                }
                return;
            }
            // click outside any open panel closes it (clicks inside a panel pass through)
            if (!event.target.closest('[data-dropdown-panel]')) closeAllPanels();
        });
        document.addEventListener('keydown', function(event) {
            if (event.key === 'Escape') closeAllPanels();
        });
        function closeAllPanels() {
            document.querySelectorAll('[data-dropdown-panel]').forEach(function(panel) {
                panel.classList.add('hidden');
            });
            document.querySelectorAll('[data-menu-button]').forEach(function(button) {
                button.setAttribute('aria-expanded', 'false');
            });
        }

        // Toast notifications (replaces bootstrap-notify)
        function luminaToast(message, kind) {
            var toast = document.createElement('div');
            toast.className = 'l-toast' + (kind === 'error' ? ' l-toast-error' : '');
            toast.textContent = message;
            document.body.appendChild(toast);
            setTimeout(function() { toast.remove(); }, 4000);
        }

        // Search form handler
        document.querySelectorAll('#form-search, #form-search-mobile').forEach(function(form) {
            form.addEventListener('submit', function(event) {
                event.preventDefault();
                var input = form.querySelector('input[name="search"]');
                if (input && input.value.trim()) {
                    window.location.href = '/search/' + encodeURIComponent(input.value.trim());
                }
            });
        });

        // Register Flutter admin service worker early
        if ('serviceWorker' in navigator) {
            window.addEventListener('load', function() {
                navigator.serviceWorker.register('/admin/flutter_service_worker.js', {
                    scope: '/admin/'
                }).then(function(registration) {
                    console.log('Flutter Admin Service Worker registered with scope:', registration.scope);
                }).catch(function(error) {
                    console.log('Flutter Admin Service Worker registration failed (normal if /admin/ not deployed):', error.message);
                });
            });
        }
    </script>
    </#noparse>

    <#-- Additional Scripts from subpages -->
    <#if footerScriptText?has_content>${footerScriptText}</#if>
</body>
</html>
