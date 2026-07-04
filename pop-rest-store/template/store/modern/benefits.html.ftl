<!-- Background Ambient Glow -->
<div class="fixed inset-0 pointer-events-none -z-10 overflow-hidden">
    <div class="absolute top-[15%] left-[-10%] w-[45%] h-[45%] rounded-full bg-primary/5 blur-[120px]"></div>
    <div class="absolute top-[40%] right-[-10%] w-[40%] h-[40%] rounded-full bg-tertiary/5 blur-[100px]"></div>
</div>

<main class="pt-28 pb-16 overflow-x-hidden">
    <!-- Hero Section -->
    <section class="max-w-container mx-auto px-4 md:px-12 text-center mb-24 relative">
        <div class="inline-flex items-center gap-2 bg-surface-container-high px-4 py-1.5 rounded-full border border-white/5 mb-8">
            <span class="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
            <span class="font-label text-xs text-on-surface-variant uppercase tracking-widest">Enterprise Intelligence</span>
        </div>
        <h1 class="font-display text-4xl md:text-5xl font-bold tracking-tight mb-6 max-w-4xl mx-auto leading-tight text-on-surface">
            Why Choose <span class="l-gradient-text">GrowERP?</span>
        </h1>
        <p class="text-lg text-on-surface-variant max-w-2xl mx-auto">
            The intelligence and flexibility your enterprise needs to scale without limits.
        </p>
    </section>

    <!-- Bento Grid -->
    <section class="max-w-container mx-auto px-4 md:px-12 grid grid-cols-1 md:grid-cols-12 gap-6">

        <!-- Efficiency Card -->
        <div class="md:col-span-8 l-glass rounded-2xl p-8 flex flex-col md:flex-row gap-8 overflow-hidden group relative">
            <div class="absolute top-0 right-0 w-40 h-40 bg-primary/5 rounded-full blur-[50px] group-hover:bg-primary/10 transition-all"></div>
            <div class="flex-1 space-y-6">
                <div class="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center border border-primary/20">
                    <span class="material-symbols-outlined icon-fill text-primary">auto_mode</span>
                </div>
                <div>
                    <h3 class="font-display text-xl font-semibold text-primary mb-3">Efficiency: Automate the Mundane</h3>
                    <p class="text-on-surface-variant">
                        High-performance AI agents handle the complexity of modern business cycles. From autonomous invoicing to real-time data orchestration, we free your talent to focus on strategy.
                    </p>
                </div>
                <ul class="space-y-3 font-label text-sm text-on-surface">
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-sm">check_circle</span>
                        Autonomous Invoice Reconciliation
                    </li>
                    <li class="flex items-center gap-3">
                        <span class="material-symbols-outlined text-primary text-sm">check_circle</span>
                        AI-Driven Report Generation
                    </li>
                </ul>
            </div>
            <div class="flex-1 relative min-h-[200px] md:min-h-0 bg-surface-container-low rounded-lg border border-white/5 overflow-hidden">
                <div class="absolute inset-0 flex items-center justify-center">
                    <div class="w-4/5 h-3/4 bg-surface-container-highest/50 backdrop-blur-sm border border-white/10 rounded shadow-2xl p-4 flex flex-col gap-3 group-hover:translate-x-2 transition-transform duration-500">
                        <div class="w-full h-4 bg-primary/20 rounded-full overflow-hidden">
                            <div class="w-2/3 h-full bg-primary"></div>
                        </div>
                        <div class="space-y-2">
                            <div class="w-1/2 h-2 bg-white/10 rounded"></div>
                            <div class="w-full h-2 bg-white/10 rounded"></div>
                            <div class="w-3/4 h-2 bg-white/10 rounded"></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Transparency Card -->
        <div class="md:col-span-4 l-glass rounded-2xl p-8 flex flex-col justify-between group">
            <div class="space-y-6">
                <div class="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center border border-primary/20">
                    <span class="material-symbols-outlined icon-fill text-primary">visibility</span>
                </div>
                <div>
                    <h3 class="font-display text-xl font-semibold text-primary mb-3">Transparency</h3>
                    <p class="text-on-surface-variant leading-relaxed">
                        Open Source, Open Minds. Inspect the code, modify the logic, and host wherever you choose. Zero vendor lock-in, total architectural freedom.
                    </p>
                </div>
            </div>
            <div class="mt-8 pt-8 border-t border-white/5">
                <div class="flex items-center justify-between text-on-surface-variant font-label text-xs">
                    <span>CC-BY-4.0 License</span>
                    <span class="flex items-center gap-1"><span class="w-2 h-2 rounded-full bg-primary"></span> Security Audited</span>
                </div>
            </div>
        </div>

        <!-- Intelligence Card -->
        <div class="md:col-span-5 l-glass rounded-2xl p-8 overflow-hidden relative group">
            <div class="relative z-10 space-y-6 h-full flex flex-col">
                <div class="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center border border-primary/20">
                    <span class="material-symbols-outlined icon-fill text-primary">insights</span>
                </div>
                <div>
                    <h3 class="font-display text-xl font-semibold text-primary mb-3">Intelligence: Unified Visibility</h3>
                    <p class="text-on-surface-variant">
                        A single pane of glass for your entire operation. Real-time data synthesis across finance, inventory, and sales departments.
                    </p>
                </div>
                <div class="mt-auto pt-6">
                    <div class="flex gap-4">
                        <div class="w-10 h-10 rounded bg-surface-container-high border border-white/10 flex items-center justify-center">
                            <span class="material-symbols-outlined text-sm text-on-surface">finance_chip</span>
                        </div>
                        <div class="w-10 h-10 rounded bg-surface-container-high border border-white/10 flex items-center justify-center">
                            <span class="material-symbols-outlined text-sm text-on-surface">inventory</span>
                        </div>
                        <div class="w-10 h-10 rounded bg-surface-container-high border border-white/10 flex items-center justify-center">
                            <span class="material-symbols-outlined text-sm text-on-surface">payments</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Scalability Card -->
        <div class="md:col-span-7 l-glass rounded-2xl p-0 overflow-hidden group flex flex-col md:flex-row">
            <div class="flex-1 p-8 space-y-6">
                <div class="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center border border-primary/20">
                    <span class="material-symbols-outlined icon-fill text-primary">layers</span>
                </div>
                <div>
                    <h3 class="font-display text-xl font-semibold text-primary mb-3">Scalability: Grows With You</h3>
                    <p class="text-on-surface-variant">
                        From agile startups to global enterprises. Our modular architecture allows you to deploy only what you need, when you need it.
                    </p>
                </div>
                <a href="/modules" class="flex items-center gap-2 text-primary font-label text-sm font-medium group-hover:gap-4 transition-all">
                    Explore Modular Add-ons <span class="material-symbols-outlined">arrow_forward</span>
                </a>
            </div>
            <div class="flex-1 bg-surface-container-low min-h-[240px] relative p-8 flex items-end">
                <div class="absolute inset-0 bg-gradient-to-tr from-primary/10 to-transparent"></div>
                <div class="relative z-10 w-full bg-surface/60 backdrop-blur-md p-4 rounded border border-white/5">
                    <div class="flex justify-between items-end">
                        <div>
                            <p class="text-on-surface-variant font-label text-xs">Current Load</p>
                            <p class="font-display text-xl font-semibold text-on-surface">99.9% Uptime</p>
                        </div>
                        <div class="w-24 h-8 bg-primary/20 rounded-full border border-primary/20 flex items-center justify-center text-primary font-label text-xs">
                            Scaling...
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="max-w-container mx-auto px-4 md:px-12 mt-24">
        <div class="l-glass rounded-2xl p-12 text-center !border-primary/20 relative overflow-hidden">
            <div class="absolute inset-0 bg-primary/5 -z-10"></div>
            <h2 class="font-display text-3xl font-semibold tracking-tight mb-6 text-on-surface">Ready to redefine your operations?</h2>
            <p class="text-on-surface-variant text-lg max-w-xl mx-auto mb-10">
                Join the global businesses leveraging the power of GrowERP's intelligent ecosystem.
            </p>
            <div class="flex flex-col sm:flex-row gap-4 justify-center">
                <a href="https://admin.growerp.com" class="bg-primary hover:bg-primary/90 text-on-primary px-8 py-4 rounded-lg font-label text-sm font-semibold l-glow transition-all active:scale-95">Start Free Trial</a>
                <a href="/assessmentLanding?landingPageId=ERP_LANDING_PAGE" class="bg-surface-container-high px-8 py-4 rounded-lg border border-white/10 hover:bg-surface-container-highest transition-colors font-label text-sm font-semibold text-on-surface">Request Demo</a>
            </div>
        </div>
    </section>
</main>
