<div class="growerp-footer-cta">
    <div class="container text-center">
        <h3 class="growerp-footer-cta-title">Stop juggling spreadsheets.</h3>
        <p class="growerp-footer-cta-text">Join businesses running smarter with GrowERP.</p>
        <a href="https://admin.growerp.com" class="btn growerp-btn-primary" target="_blank">
            <i class="fas fa-rocket mr-2"></i>Start Free Trial
        </a>
    </div>
</div>
</#if>

<footer class="footer">
    <div class="container">
        <div class="row mb-5">
            <!-- Company Info -->
            <div class="col-lg-4 col-md-6 mb-4 mb-lg-0">
                <div class="d-flex align-items-center mb-3">
                    <img src="/getLogo" alt="Logo" class="footer-logo">
                    <span class="footer-brand-name">${storeInfo.productStore.storeName!''}</span>
                </div>
                <div class="social-links mt-4">
                    <#if (TwitterUrl!'')?has_content || (FacebookUrl!'')?has_content || (InstagramUrl!'')?has_content || (YouTubeUrl!'')?has_content || (LinkedInUrl!'')?has_content || (SubstackUrl!'')?has_content>
                    <span class="footer-follow-text d-block mb-3">FOLLOW US</span>
                    </#if>
                    <#if (TwitterUrl!'')?has_content>
                    <a href="${TwitterUrl}" target="_blank" rel="noopener" class="footer-icon-link"><i class="fab fa-twitter footer-icons"></i></a>
                    </#if>
                    <#if (FacebookUrl!'')?has_content>
                    <a href="${FacebookUrl}" target="_blank" rel="noopener" class="footer-icon-link"><i class="fab fa-facebook footer-icons"></i></a>
                    </#if>
                    <#if (InstagramUrl!'')?has_content>
                    <a href="${InstagramUrl}" target="_blank" rel="noopener" class="footer-icon-link"><i class="fab fa-instagram footer-icons"></i></a>
                    </#if>
                    <#if (YouTubeUrl!'')?has_content>
                    <a href="${YouTubeUrl}" target="_blank" rel="noopener" class="footer-icon-link"><i class="fab fa-youtube footer-icons"></i></a>
                    </#if>
                    <#if (LinkedInUrl!'')?has_content>
                    <a href="${LinkedInUrl}" target="_blank" rel="noopener" class="footer-icon-link"><i class="fab fa-linkedin footer-icons"></i></a>
                    </#if>
                    <#if (SubstackUrl!'')?has_content>
                    <a href="${SubstackUrl}" target="_blank" rel="noopener" class="footer-icon-link">
                        <svg class="footer-icons" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="1em" height="1em" fill="currentColor" style="vertical-align:middle"><path d="M22.539 8.242H1.46V5.406h21.08v2.836zM1.46 10.812V24L12 18.11 22.54 24V10.812H1.46zM22.54 0H1.46v2.836h21.08V0z"/></svg>
                    </a>
                    </#if>
                </div>
            </div>

            <!-- Quick Links -->
            <div class="col-lg-4 col-md-6 mb-4 mb-lg-0">
                <h5 class="footer-heading">Quick Links</h5>
                <ul class="footer-ul">
                    <li><a href="/" class="footer-a">Home</a></li>
                    <#list storeInfo.menu as topItem>
                    <#if !topItem.title?has_content || topItem.title?lower_case?starts_with('home')><#continue></#if>
                    <li>
                        <#if topItem.path == 'obsidian'>
                        <a href="/${topItem.path}" class="footer-a">${topItem.title!topItem.path}</a>
