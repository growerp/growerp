<#assign isMarketing = storeInfo.productStore.productStoreId == "100000">
<footer class="border-t border-white/10 bg-surface-container-lowest/60 mt-16">
    <div class="max-w-container mx-auto px-4 md:px-12 py-12">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-10 mb-10">
            <!-- Company Info -->
            <div>
                <div class="flex items-center gap-3 mb-4">
                    <img src="/getLogo" alt="Logo" class="h-8 w-8 object-contain rounded opacity-80">
                    <span class="font-display font-bold text-lg text-on-surface">${storeInfo.productStore.storeName!''}</span>
                </div>
                <#if (TwitterUrl!'')?has_content || (FacebookUrl!'')?has_content || (InstagramUrl!'')?has_content || (YouTubeUrl!'')?has_content || (LinkedInUrl!'')?has_content || (SubstackUrl!'')?has_content>
                <span class="block font-label text-xs uppercase tracking-widest text-outline mb-3">Follow Us</span>
                <div class="flex items-center gap-4">
                    <#if (TwitterUrl!'')?has_content>
                    <a href="${TwitterUrl}" target="_blank" rel="noopener" aria-label="Twitter" class="text-on-surface-variant hover:text-primary transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>
                    </a>
                    </#if>
                    <#if (FacebookUrl!'')?has_content>
                    <a href="${FacebookUrl}" target="_blank" rel="noopener" aria-label="Facebook" class="text-on-surface-variant hover:text-primary transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/></svg>
                    </a>
                    </#if>
                    <#if (InstagramUrl!'')?has_content>
                    <a href="${InstagramUrl}" target="_blank" rel="noopener" aria-label="Instagram" class="text-on-surface-variant hover:text-primary transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324zm0 10.162a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.406-11.845a1.44 1.44 0 1 0 0 2.881 1.44 1.44 0 0 0 0-2.881z"/></svg>
                    </a>
                    </#if>
                    <#if (YouTubeUrl!'')?has_content>
                    <a href="${YouTubeUrl}" target="_blank" rel="noopener" aria-label="YouTube" class="text-on-surface-variant hover:text-primary transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814zM9.545 15.568V8.432L15.818 12l-6.273 3.568z"/></svg>
                    </a>
                    </#if>
                    <#if (LinkedInUrl!'')?has_content>
                    <a href="${LinkedInUrl}" target="_blank" rel="noopener" aria-label="LinkedIn" class="text-on-surface-variant hover:text-primary transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433a2.062 2.062 0 1 1 0-4.124 2.062 2.062 0 0 1 0 4.124zM7.119 20.452H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.225 0z"/></svg>
                    </a>
                    </#if>
                    <#if (SubstackUrl!'')?has_content>
                    <a href="${SubstackUrl}" target="_blank" rel="noopener" aria-label="Substack" class="text-on-surface-variant hover:text-primary transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="20" height="20" fill="currentColor"><path d="M22.539 8.242H1.46V5.406h21.08v2.836zM1.46 10.812V24L12 18.11 22.54 24V10.812H1.46zM22.54 0H1.46v2.836h21.08V0z"/></svg>
                    </a>
                    </#if>
                </div>
                </#if>
            </div>

            <!-- Quick Links -->
            <div>
                <h5 class="font-display font-semibold text-on-surface mb-4">Quick Links</h5>
                <ul class="space-y-2">
                    <li><a href="/" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">Home</a></li>
                    <#if isMarketing>
                    <li><a href="/modules" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">Apps</a></li>
                    <li><a href="/benefits" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">Benefits</a></li>
                    <li><a href="/pricing" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">Pricing</a></li>
                    <li><a href="https://github.com/growerp/growerp" target="_blank" rel="noopener" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">GitHub</a></li>
                    </#if>
                    <#list storeInfo.menu as topItem>
                    <#if !topItem.title?has_content || topItem.title?lower_case?starts_with('home')><#continue></#if>
                    <li>
                        <#if topItem.path == 'obsidian'>
                        <a href="/${topItem.path}" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">${topItem.title!topItem.path}</a>
                        <#else>
                        <a href="/content/${topItem.path}" class="font-label text-sm text-on-surface-variant hover:text-primary transition-colors">${topItem.title!topItem.path}</a>
                        </#if>
                    </li>
                    </#list>
                </ul>
            </div>

            <!-- Contact Info -->
            <div>
                <h5 class="font-display font-semibold text-on-surface mb-4">Contact Us</h5>
                <ul class="space-y-3">
                    <#if companyPostalAddress?? && (companyPostalAddress.address1!'')?has_content>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-primary text-[20px] mt-0.5">location_on</span>
                        <span class="text-sm text-on-surface-variant">
                            ${companyPostalAddress.address1!''}
                            <#if (companyPostalAddress.address2!'')?has_content><br>${companyPostalAddress.address2}</#if>
                            <#if (companyPostalAddress.city!'')?has_content><br>${companyPostalAddress.city}<#if (companyPostalAddress.postalCode!'')?has_content> ${companyPostalAddress.postalCode}</#if></#if>
                        </span>
                    </li>
                    </#if>
                    <#if companyPhone?? && (companyPhone.contactNumber!'')?has_content>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[20px]">call</span>
                        <span class="text-sm text-on-surface-variant"><#if (companyPhone.countryCode!'')?has_content>+${companyPhone.countryCode} </#if><#if (companyPhone.areaCode!'')?has_content>${companyPhone.areaCode} </#if>${companyPhone.contactNumber}</span>
                    </li>
                    </#if>
                    <#if companyEmailMech?? && (companyEmailMech.infoString!'')?has_content>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[20px]">mail</span>
                        <a href="mailto:${companyEmailMech.infoString}" class="text-sm text-on-surface-variant hover:text-primary transition-colors">${companyEmailMech.infoString}</a>
                    </li>
                    </#if>
                </ul>
            </div>
        </div>

        <!-- Bottom Bar -->
        <div class="pt-6 border-t border-white/10 flex flex-col md:flex-row items-center justify-between gap-3">
            <p class="text-sm text-on-surface-variant/70">
                &copy; ${.now?string('yyyy')} ${storeInfo.productStore.storeName!''}. All rights reserved.
            </p>
            <p class="text-sm text-on-surface-variant/70 flex items-center gap-2">
                <a href="https://www.moqui.org" target="_blank" class="hover:text-primary transition-colors">Built with Moqui Framework</a>
                <span class="text-outline">|</span>
                <a href="https://www.growerp.com" target="_blank" class="hover:text-primary transition-colors">Powered by GrowERP</a>
            </p>
        </div>
    </div>
</footer>
