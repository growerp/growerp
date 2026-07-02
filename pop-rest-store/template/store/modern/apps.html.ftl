<style>
    .glass-card {
        background: rgba(255, 255, 255, 0.03);
        backdrop-filter: blur(12px);
        border: 1px solid rgba(255, 255, 255, 0.1);
        transition: all 0.3s ease;
    }

    .glass-card:hover {
        background: rgba(255, 255, 255, 0.05);
        border-color: rgba(5, 150, 105, 0.3);
        transform: translateY(-4px);
    }

    .mesh-gradient-bg {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: -1;
        overflow: hidden;
        background: radial-gradient(circle at 15% 50%, rgba(104, 219, 169, 0.08), transparent 25%),
                    radial-gradient(circle at 85% 30%, rgba(104, 219, 169, 0.05), transparent 25%);
    }

    .icon-box {
        width: 48px;
        height: 48px;
        background: rgba(104, 219, 169, 0.1);
        border: 1px solid rgba(104, 219, 169, 0.2);
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
    }
</style>

<div class="mesh-gradient-bg"></div>

<main class="pt-32 pb-stack-lg overflow-x-hidden relative">
    
    <!-- Header Section -->
    <section class="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop mb-12 flex justify-between items-end">
        <div>
            <h1 class="font-display-lg-mobile md:font-display-lg text-display-lg-mobile md:text-display-lg text-on-surface tracking-tight mb-2">Core ERP Modules</h1>
            <p class="font-body-lg text-body-lg text-on-surface-variant">Seamlessly integrated, independently powerful.</p>
        </div>
        <div class="hidden md:flex gap-4">
            <button class="w-10 h-10 rounded-full border border-white/10 flex items-center justify-center hover:bg-white/5 transition-colors text-on-surface">
                <span class="material-symbols-outlined text-sm">arrow_back_ios_new</span>
            </button>
            <button class="w-10 h-10 rounded-full border border-white/10 flex items-center justify-center hover:bg-white/5 transition-colors text-on-surface">
                <span class="material-symbols-outlined text-sm">arrow_forward_ios</span>
            </button>
        </div>
    </section>

    <!-- Apps Grid -->
    <section class="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop grid grid-cols-1 lg:grid-cols-2 gap-gutter mb-24">
        
        <!-- Inventory Card -->
        <div class="glass-card rounded-xl p-8 flex flex-col justify-between group h-full">
            <div class="flex items-start gap-4 mb-6">
                <div class="icon-box shrink-0">
                    <span class="material-symbols-outlined text-primary" style="font-variation-settings: 'FILL' 1;">inventory_2</span>
                </div>
                <div>
                    <h3 class="font-headline-sm text-headline-sm text-primary mb-2">Inventory</h3>
                    <p class="text-on-surface-variant font-body-sm text-body-sm leading-relaxed">
                        Complete control over your supply chain with intelligent stock forecasting and multi-warehouse management.
                    </p>
                </div>
            </div>
            
            <div class="flex flex-col sm:flex-row gap-6 items-end mt-auto">
                <ul class="space-y-3 font-label-md text-label-md text-on-surface flex-1">
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Real-time tracking
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Automated workflows
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> SKU Optimization
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Barcode Scanning
                    </li>
                </ul>
                <div class="w-full sm:w-[220px] rounded-lg overflow-hidden border border-white/10 shadow-2xl shrink-0 opacity-80 group-hover:opacity-100 transition-opacity">
                    <img src="https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=600&auto=format&fit=crop" alt="Inventory Dashboard" class="w-full h-auto object-cover opacity-70 mix-blend-luminosity hover:mix-blend-normal hover:opacity-100 transition-all duration-500">
                </div>
            </div>
            <a href="#" class="inline-flex items-center gap-2 text-primary font-label-md text-label-md mt-6 hover:gap-3 transition-all" style="text-decoration:none;">
                Learn More <span class="material-symbols-outlined text-[18px]">arrow_forward</span>
            </a>
        </div>

        <!-- CRM Card -->
        <div class="glass-card rounded-xl p-8 flex flex-col justify-between group h-full">
            <div class="flex items-start gap-4 mb-6">
                <div class="icon-box shrink-0">
                    <span class="material-symbols-outlined text-primary" style="font-variation-settings: 'FILL' 1;">groups</span>
                </div>
                <div>
                    <h3 class="font-headline-sm text-headline-sm text-primary mb-2">CRM</h3>
                    <p class="text-on-surface-variant font-body-sm text-body-sm leading-relaxed">
                        Drive sales with AI-powered customer insights and automated lead nurturing pipelines.
                    </p>
                </div>
            </div>
            
            <div class="flex flex-col sm:flex-row gap-6 items-end mt-auto">
                <ul class="space-y-3 font-label-md text-label-md text-on-surface flex-1">
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Unified Customer Profile
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Sales Pipeline Automation
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Sentiment Analysis
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Email Campaign Manager
                    </li>
                </ul>
                <div class="w-full sm:w-[220px] rounded-lg overflow-hidden border border-white/10 shadow-2xl shrink-0 opacity-80 group-hover:opacity-100 transition-opacity">
                    <img src="https://images.unsplash.com/photo-1460925895917-afdab827c52f?q=80&w=600&auto=format&fit=crop" alt="CRM Dashboard" class="w-full h-auto object-cover opacity-70 mix-blend-luminosity hover:mix-blend-normal hover:opacity-100 transition-all duration-500">
                </div>
            </div>
            <a href="#" class="inline-flex items-center gap-2 text-primary font-label-md text-label-md mt-6 hover:gap-3 transition-all" style="text-decoration:none;">
                Learn More <span class="material-symbols-outlined text-[18px]">arrow_forward</span>
            </a>
        </div>

        <!-- Finance Card -->
        <div class="glass-card rounded-xl p-8 flex flex-col justify-between group h-full">
            <div class="flex items-start gap-4 mb-6">
                <div class="icon-box shrink-0">
                    <span class="material-symbols-outlined text-primary" style="font-variation-settings: 'FILL' 1;">account_balance</span>
                </div>
                <div>
                    <h3 class="font-headline-sm text-headline-sm text-primary mb-2">Finance</h3>
                    <p class="text-on-surface-variant font-body-sm text-body-sm leading-relaxed">
                        Secure, automated financial operations from ledger management to complex tax reporting.
                    </p>
                </div>
            </div>
            
            <div class="flex flex-col sm:flex-row gap-6 items-end mt-auto">
                <ul class="space-y-3 font-label-md text-label-md text-on-surface flex-1">
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Multi-currency Support
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Automated Reconciliation
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Budget Forecasting
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Compliance Reports
                    </li>
                </ul>
                <div class="w-full sm:w-[220px] rounded-lg overflow-hidden border border-white/10 shadow-2xl shrink-0 opacity-80 group-hover:opacity-100 transition-opacity">
                    <img src="https://images.unsplash.com/photo-1554224155-6726b3ff858f?q=80&w=600&auto=format&fit=crop" alt="Finance Dashboard" class="w-full h-auto object-cover opacity-70 mix-blend-luminosity hover:mix-blend-normal hover:opacity-100 transition-all duration-500">
                </div>
            </div>
            <a href="#" class="inline-flex items-center gap-2 text-primary font-label-md text-label-md mt-6 hover:gap-3 transition-all" style="text-decoration:none;">
                Learn More <span class="material-symbols-outlined text-[18px]">arrow_forward</span>
            </a>
        </div>

        <!-- Analytics Card -->
        <div class="glass-card rounded-xl p-8 flex flex-col justify-between group h-full">
            <div class="flex items-start gap-4 mb-6">
                <div class="icon-box shrink-0">
                    <span class="material-symbols-outlined text-primary" style="font-variation-settings: 'FILL' 1;">monitoring</span>
                </div>
                <div>
                    <h3 class="font-headline-sm text-headline-sm text-primary mb-2">Analytics</h3>
                    <p class="text-on-surface-variant font-body-sm text-body-sm leading-relaxed">
                        Turn raw data into actionable intelligence with custom BI dashboards and AI predictive modeling.
                    </p>
                </div>
            </div>
            
            <div class="flex flex-col sm:flex-row gap-6 items-end mt-auto">
                <ul class="space-y-3 font-label-md text-label-md text-on-surface flex-1">
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> AI-Driven Insights
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Customizable Reports
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Real-time Monitoring
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-[18px]">check_circle</span> Cross-Module Data
                    </li>
                </ul>
                <div class="w-full sm:w-[220px] rounded-lg overflow-hidden border border-white/10 shadow-2xl shrink-0 opacity-80 group-hover:opacity-100 transition-opacity">
                    <img src="https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=600&auto=format&fit=crop" alt="Analytics Dashboard" class="w-full h-auto object-cover opacity-70 mix-blend-luminosity hover:mix-blend-normal hover:opacity-100 transition-all duration-500">
                </div>
            </div>
            <a href="#" class="inline-flex items-center gap-2 text-primary font-label-md text-label-md mt-6 hover:gap-3 transition-all" style="text-decoration:none;">
                Learn More <span class="material-symbols-outlined text-[18px]">arrow_forward</span>
            </a>
        </div>

    </section>

    <!-- Bottom CTA -->
    <section class="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop mb-24">
        <div class="glass-card rounded-xl p-12 text-center relative overflow-hidden flex flex-col items-center">
            <h2 class="font-display-lg-mobile md:font-display-lg text-display-lg-mobile md:text-display-lg text-on-surface mb-6 tracking-tight">
                Ready to modernize your <span class="text-primary">operations?</span>
            </h2>
            <p class="font-body-lg text-body-lg text-on-surface-variant max-w-2xl mb-10">
                Join over 2,000 enterprises that have transformed their productivity with GrowERP's modular intelligence.
            </p>
            <div class="flex gap-4">
                <button class="bg-primary hover:bg-primary-fixed-dim text-on-primary font-label-md text-label-md font-bold px-8 py-3.5 rounded-lg transition-all shadow-[0_0_15px_rgba(104,219,169,0.3)] hover:shadow-[0_0_25px_rgba(104,219,169,0.5)]">
                    Get Started Now
                </button>
                <button class="bg-transparent border border-white/10 hover:bg-white/5 text-on-surface font-label-md text-label-md font-bold px-8 py-3.5 rounded-lg transition-colors">
                    Request a Demo
                </button>
            </div>
        </div>
    </section>
</main>
