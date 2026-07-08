<#assign isMarketing = storeInfo.productStore.productStoreId == "100000">

<#macro productCard product>
    <a href="/product/${product.productId}" class="group block l-glass rounded-xl p-3 hover:border-primary/40 transition-all duration-300">
        <div class="aspect-square rounded-lg overflow-hidden bg-surface-container-high flex items-center justify-center mb-3">
            <#if product.mediumImageInfo??>
                <img class="max-h-full max-w-full object-contain group-hover:scale-105 transition-transform duration-300" src="/content/productImage/${product.mediumImageInfo.productContentId}" alt="${product.productName}">
            <#elseif product.smallImageInfo??>
                <img class="max-h-full max-w-full object-contain group-hover:scale-105 transition-transform duration-300" src="/content/productImage/${product.smallImageInfo.productContentId}" alt="${product.productName}">
            <#else>
                <span class="material-symbols-outlined text-outline text-[48px]">image</span>
            </#if>
        </div>
        <h6 class="text-sm font-medium text-on-surface line-clamp-2 min-h-[2.5rem] mb-1 group-hover:text-primary transition-colors">${product.productName}</h6>
        <#if product.numberOfRatings??>
        <div class="flex items-center gap-0.5 mb-1">
            <#list 1..5 as x>
                <#if (product.numberOfRatings >= x)>
                    <span class="material-symbols-outlined icon-fill text-tertiary text-[14px]">star</span>
                <#else>
                    <span class="material-symbols-outlined text-tertiary text-[14px]">star</span>
                </#if>
            </#list>
        </div>
        </#if>
        <div class="flex items-baseline gap-2">
            <#if product.price?? && product.price gt 0>
                <span class="text-primary font-semibold text-base">${ec.l10n.formatCurrency(product.price,product.priceUomId)}</span>
                <#if product.listPrice?? && product.listPrice gt product.price>
                    <span class="text-on-surface-variant text-sm line-through">${ec.l10n.formatCurrency(product.listPrice,product.priceUomId)}</span>
                </#if>
            <#elseif product.listPrice?? && product.listPrice gt 0>
                <span class="text-primary font-semibold text-base">${ec.l10n.formatCurrency(product.listPrice,product.priceUomId)}</span>
            <#else>
                <span class="text-primary font-semibold text-base">Free</span>
            </#if>
        </div>
    </a>
</#macro>

<#if isMarketing>
<!-- ==================== Marketing landing (GrowERP) ==================== -->
<main class="pt-24 pb-16 relative">
    <!-- Ambient background glows -->
    <div class="fixed inset-0 pointer-events-none -z-10 overflow-hidden">
        <div class="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] rounded-full bg-primary/5 blur-[120px]"></div>
        <div class="absolute bottom-[-20%] right-[-10%] w-[40%] h-[40%] rounded-full bg-tertiary/5 blur-[100px]"></div>
    </div>

    <!-- Hero Section -->
    <section class="max-w-container mx-auto px-4 md:px-12 min-h-[75vh] flex flex-col justify-center py-16 relative">
        <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] max-w-full h-[800px] bg-primary/10 rounded-full blur-[120px] pointer-events-none -z-10"></div>
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center w-full">
            <!-- Text Content -->
            <div class="lg:col-span-5 flex flex-col z-10">
                <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-surface-container border border-outline-variant/50 w-fit mb-6">
                    <span class="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
                    <span class="font-label text-xs text-on-surface-variant">v2.0 Open Source Released</span>
                </div>
                <h1 class="font-display text-4xl md:text-5xl font-bold tracking-tight leading-tight text-on-surface">
                    Feeling overwhelmed by your ERP?<br>
                    <span class="l-gradient-text">You're not alone.</span>
                </h1>
                <p class="text-lg text-on-surface-variant mt-6 max-w-xl leading-relaxed">
                    The open-source, AI-powered ERP that scales with you. Eliminate data silos, automate workflows, and
                    gain intelligent insights across your entire organization with unparalleled clarity.
                </p>
                <div class="flex flex-col sm:flex-row gap-4 mt-8">
                    <a href="https://admin.growerp.com" class="bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-8 py-4 rounded-lg l-glow transition-all active:scale-95 text-center">
                        Start Free Trial
                    </a>
                    <a href="/assessmentLanding?landingPageId=ERP_LANDING_PAGE" class="l-glass hover:bg-surface-container text-on-surface font-label text-sm font-medium px-8 py-4 rounded-lg transition-all active:scale-95 text-center flex items-center justify-center gap-2">
                        <span class="material-symbols-outlined text-[20px]">quiz</span>
                        Start the ERP Assessment
                    </a>
                </div>
                <p class="text-sm text-on-surface-variant/70 mt-4">No credit card required &bull; 2 weeks free</p>
            </div>

            <!-- Dashboard Mockup -->
            <div class="lg:col-span-7 relative z-10">
                <div class="relative rounded-2xl overflow-hidden border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.5)] bg-surface lg:rotate-1 hover:rotate-0 transition-transform duration-500">
                    <div class="absolute inset-0 bg-gradient-to-tr from-primary/5 to-transparent mix-blend-overlay z-10 pointer-events-none"></div>
                    <img class="w-full object-cover bg-surface h-auto" src="/assets/dashboard-screenshot.png" alt="GrowERP Admin Dashboard">
                </div>
                <!-- Mobile main menu -->
                <div class="absolute -bottom-10 -right-2 md:right-8 w-32 md:w-44 z-20 rotate-3 hover:rotate-0 transition-transform duration-500">
                    <div class="absolute inset-0 bg-primary/20 rounded-[2rem] blur-[30px] -z-10"></div>
                    <img class="w-full h-auto rounded-[1.5rem] border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.6)]"
                        src="/assets/mobile-main-menu.png" alt="GrowERP mobile main menu">
                </div>
            </div>
        </div>
    </section>

    <!-- Benefits Bento Grid -->
    <section id="benefits" class="max-w-container mx-auto px-4 md:px-12 py-24 relative">
        <div class="text-center mb-16 max-w-2xl mx-auto">
            <h2 class="font-display text-3xl font-semibold tracking-tight text-on-surface mb-4">Intelligence Engineered for Scale</h2>
            <p class="text-on-surface-variant">Built on modern architecture to provide unprecedented visibility and control over every facet of your enterprise.</p>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <div class="l-glass p-8 rounded-2xl flex flex-col gap-4 hover:bg-surface-container-low/60 transition-colors group relative overflow-hidden">
                <div class="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-[40px] group-hover:bg-primary/10 transition-all"></div>
                <div class="w-12 h-12 rounded-lg bg-surface-container flex items-center justify-center border border-outline-variant/30 text-primary mb-2">
                    <span class="material-symbols-outlined icon-fill text-[24px]">sync</span>
                </div>
                <h3 class="font-display text-xl font-semibold text-on-surface">All-in-One</h3>
                <p class="text-on-surface-variant leading-relaxed">Your whole business in sync. Connect sales, operations, and finance in a single unified workflow ecosystem.</p>
            </div>
            <div class="l-glass p-8 rounded-2xl flex flex-col gap-4 hover:bg-surface-container-low/60 transition-colors group relative overflow-hidden">
                <div class="absolute top-0 right-0 w-32 h-32 bg-tertiary/5 rounded-full blur-[40px] group-hover:bg-tertiary/10 transition-all"></div>
                <div class="w-12 h-12 rounded-lg bg-surface-container flex items-center justify-center border border-outline-variant/30 text-tertiary mb-2">
                    <span class="material-symbols-outlined icon-fill text-[24px]">psychology</span>
                </div>
                <h3 class="font-display text-xl font-semibold text-on-surface">AI-Powered</h3>
                <p class="text-on-surface-variant leading-relaxed">Intelligent insights at your fingertips. Predictive analytics and automated reporting out-of-the-box.</p>
            </div>
            <div class="l-glass p-8 rounded-2xl flex flex-col gap-4 hover:bg-surface-container-low/60 transition-colors group relative overflow-hidden">
                <div class="absolute top-0 right-0 w-32 h-32 bg-secondary/5 rounded-full blur-[40px] group-hover:bg-secondary/10 transition-all"></div>
                <div class="w-12 h-12 rounded-lg bg-surface-container flex items-center justify-center border border-outline-variant/30 text-secondary mb-2">
                    <span class="material-symbols-outlined icon-fill text-[24px]">code</span>
                </div>
                <h3 class="font-display text-xl font-semibold text-on-surface">Open Source</h3>
                <p class="text-on-surface-variant leading-relaxed">Full control and transparency. Inspect the code, customize modules, and truly own your infrastructure.</p>
            </div>
            <div class="l-glass p-8 rounded-2xl flex flex-col gap-4 hover:bg-surface-container-low/60 transition-colors group relative overflow-hidden">
                <div class="absolute top-0 right-0 w-32 h-32 bg-primary/5 rounded-full blur-[40px] group-hover:bg-primary/10 transition-all"></div>
                <div class="w-12 h-12 rounded-lg bg-surface-container flex items-center justify-center border border-outline-variant/30 text-primary mb-2">
                    <span class="material-symbols-outlined icon-fill text-[24px]">cloud_done</span>
                </div>
                <h3 class="font-display text-xl font-semibold text-on-surface">Run Anywhere</h3>
                <p class="text-on-surface-variant leading-relaxed">Cloud or on-premise flexibility. Deploy on our secure managed cloud or your own private servers instantly.</p>
            </div>
        </div>
    </section>

    <!-- Platform Downloads -->
    <section class="max-w-container mx-auto px-4 md:px-12 pb-8 relative">
        <div class="l-glass rounded-2xl p-8 text-center">
            <h3 class="font-display text-xl font-semibold text-on-surface mb-2">Get GrowERP on every platform</h3>
            <p class="text-sm text-on-surface-variant mb-6">One codebase, every device &mdash; your data syncs seamlessly.</p>
            <div class="flex flex-wrap justify-center gap-3">
                <a href="https://admin.growerp.com" target="_blank" rel="noopener" class="inline-flex items-center gap-2 border border-white/15 hover:border-primary/50 hover:text-primary text-on-surface font-label text-sm px-5 py-2.5 rounded-full transition-colors">
                    <span class="material-symbols-outlined text-[18px]">language</span>Web Browser
                </a>
                <a href="https://play.google.com/store/apps/details?id=org.growerp.admin" target="_blank" rel="noopener" class="inline-flex items-center gap-2 border border-white/15 hover:border-primary/50 hover:text-primary text-on-surface font-label text-sm px-5 py-2.5 rounded-full transition-colors">
                    <span class="material-symbols-outlined text-[18px]">android</span>Android
                </a>
                <a href="https://apps.apple.com/us/app/growerp-admin-open-source/id1545521755" target="_blank" rel="noopener" class="inline-flex items-center gap-2 border border-white/15 hover:border-primary/50 hover:text-primary text-on-surface font-label text-sm px-5 py-2.5 rounded-full transition-colors">
                    <span class="material-symbols-outlined text-[18px]">phone_iphone</span>iOS &amp; macOS
                </a>
                <a href="https://snapcraft.io/growerp-admin" target="_blank" rel="noopener" class="inline-flex items-center gap-2 border border-white/15 hover:border-primary/50 hover:text-primary text-on-surface font-label text-sm px-5 py-2.5 rounded-full transition-colors">
                    <span class="material-symbols-outlined text-[18px]">terminal</span>Linux
                </a>
                <a href="https://apps.microsoft.com/detail/9nwx6kftjnql" target="_blank" rel="noopener" class="inline-flex items-center gap-2 border border-white/15 hover:border-primary/50 hover:text-primary text-on-surface font-label text-sm px-5 py-2.5 rounded-full transition-colors">
                    <span class="material-symbols-outlined text-[18px]">grid_view</span>Windows
                </a>
            </div>
        </div>
    </section>
</main>

<#else>
<!-- ==================== Commerce home ==================== -->
<main class="pt-24 pb-8 max-w-container mx-auto px-4 md:px-12">
    <#-- This Week's Deals Section -->
    <#if promoProductList?has_content>
        <div class="mb-6 mt-8">
            <h2 class="font-display text-2xl font-semibold text-on-surface flex items-center gap-2">
                <span class="material-symbols-outlined icon-fill text-primary text-[28px]">local_fire_department</span>
                This Week's Deals
            </h2>
            <p class="text-on-surface-variant mt-1">Don't miss out on these exclusive offers</p>
        </div>
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
            <#list promoProductList as product>
                <#if product?index < 4>
                    <@productCard product=product/>
                </#if>
            </#list>
        </div>
        <#if promoProductList?size gt 4>
        <div class="text-center mt-6 mb-4">
            <#if (storeInfo.categoryByType.PsctPromotions.productCategoryId)??>
                <a href="/category/${storeInfo.categoryByType.PsctPromotions.productCategoryId}" class="inline-flex items-center gap-2 border border-primary/50 text-primary hover:bg-primary/10 font-label text-sm font-medium px-6 py-3 rounded-lg transition-colors">
                    View All Deals <span class="material-symbols-outlined text-[18px]">arrow_forward</span>
                </a>
            </#if>
        </div>
        </#if>
    </#if>

    <#-- Separator -->
    <#if promoProductList?has_content && featureProductList?has_content>
        <hr class="my-10 border-white/10">
    </#if>

    <#-- Featured Products Section -->
    <#if featureProductList?has_content>
        <div class="mb-6 mt-8">
            <h2 class="font-display text-2xl font-semibold text-on-surface flex items-center gap-2">
                <span class="material-symbols-outlined icon-fill text-tertiary text-[28px]">star</span>
                Featured Products
            </h2>
            <p class="text-on-surface-variant mt-1">Handpicked selections just for you</p>
        </div>
        <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4 md:gap-6">
            <#list featureProductList as product>
                <#if product?index < 4>
                    <@productCard product=product/>
                </#if>
            </#list>
        </div>
        <#if featureProductList?size gt 4>
        <div class="text-center mt-6 mb-4">
            <#if (storeInfo.categoryByType.PsctFeatured.productCategoryId)??>
                <a href="/category/${storeInfo.categoryByType.PsctFeatured.productCategoryId}" class="inline-flex items-center gap-2 border border-primary/50 text-primary hover:bg-primary/10 font-label text-sm font-medium px-6 py-3 rounded-lg transition-colors">
                    View All Featured <span class="material-symbols-outlined text-[18px]">arrow_forward</span>
                </a>
            </#if>
        </div>
        </#if>
    </#if>
</main>
</#if>
