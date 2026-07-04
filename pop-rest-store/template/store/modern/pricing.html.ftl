<!-- Background Ambient Glow -->
<div class="fixed inset-0 pointer-events-none -z-10 overflow-hidden">
    <div class="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] rounded-full bg-primary/5 blur-[120px]"></div>
    <div class="absolute bottom-[-20%] right-[-10%] w-[40%] h-[40%] rounded-full bg-tertiary/5 blur-[100px]"></div>
</div>

<main class="pt-28 pb-16 px-4 md:px-12 max-w-container mx-auto w-full relative">
    <!-- Header Section -->
    <div class="text-center max-w-3xl mx-auto mb-16 pt-8">
        <h1 class="font-display text-4xl md:text-5xl font-bold tracking-tight text-on-surface mb-4">Simple, Transparent Pricing</h1>
        <p class="text-lg text-on-surface-variant">
            Choose the plan that best fits your workflow. Start free, upgrade when you're ready.
        </p>
    </div>

    <!-- Pricing Cards Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8 items-stretch">

        <!-- DIY Card -->
        <div class="l-glass rounded-xl p-8 flex flex-col hover:border-white/20 transition-all duration-300 relative group">
            <div class="mb-8">
                <h3 class="font-display text-xl font-semibold text-on-surface mb-2">Do It Yourself (DIY)</h3>
                <div class="flex items-baseline gap-1 mb-4">
                    <span class="font-display text-4xl font-bold text-on-surface">$49.99</span>
                    <span class="text-sm text-on-surface-variant">/mo</span>
                </div>
                <p class="text-sm text-on-surface-variant">For self-starters who want full control over their deployment.</p>
            </div>
            <ul class="space-y-4 mb-8 flex-grow">
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Full Platform Access</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Community Support</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Standard Documentation</span>
                </li>
            </ul>
            <a href="https://admin.growerp.com" class="w-full py-3 rounded-lg border border-white/20 text-on-surface font-label text-sm font-medium hover:bg-white/5 transition-colors mt-auto text-center">
                Choose DIY
            </a>
        </div>

        <!-- DWY Card (Highlighted) -->
        <div class="l-glass rounded-xl p-8 flex flex-col relative group md:-translate-y-4 !border-primary/50">
            <div class="absolute inset-0 bg-gradient-to-b from-primary/10 to-transparent rounded-xl pointer-events-none"></div>
            <div class="absolute -top-3 left-1/2 -translate-x-1/2 bg-primary text-on-primary px-3 py-1 rounded-full font-label text-xs font-semibold tracking-wider uppercase">Most Popular</div>
            <div class="mb-8 relative z-10">
                <h3 class="font-display text-xl font-semibold text-on-surface mb-2">Do It With You (DWY)</h3>
                <div class="flex items-baseline gap-1 mb-4">
                    <span class="font-display text-4xl font-bold text-primary">$499</span>
                    <span class="text-sm text-on-surface-variant">/mo</span>
                </div>
                <p class="text-sm text-on-surface-variant">Guided implementation with our expert team alongside you.</p>
            </div>
            <ul class="space-y-4 mb-8 flex-grow relative z-10">
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Everything in DIY</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Weekly Strategy Calls</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Priority Email Support</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Guided Data Migration</span>
                </li>
            </ul>
            <a href="https://admin.growerp.com" class="w-full py-3 rounded-lg bg-primary text-on-primary font-label text-sm font-medium hover:bg-primary/90 transition-all mt-auto relative z-10 l-glow text-center">
                Choose DWY
            </a>
        </div>

        <!-- DFY Card -->
        <div class="l-glass rounded-xl p-8 flex flex-col hover:border-white/20 transition-all duration-300 relative group">
            <div class="mb-8">
                <h3 class="font-display text-xl font-semibold text-on-surface mb-2">Do It For You (DFY)</h3>
                <div class="flex items-baseline gap-1 mb-4">
                    <span class="font-display text-4xl font-bold text-on-surface">$999</span>
                    <span class="text-sm text-on-surface-variant">/mo</span>
                </div>
                <p class="text-sm text-on-surface-variant">Turnkey solution. We handle everything from setup to launch.</p>
            </div>
            <ul class="space-y-4 mb-8 flex-grow">
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Everything in DWY</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Dedicated Account Manager</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Custom Integrations</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">24/7 Phone Support</span>
                </li>
            </ul>
            <a href="https://admin.growerp.com" class="w-full py-3 rounded-lg border border-white/20 text-on-surface font-label text-sm font-medium hover:bg-white/5 transition-colors mt-auto text-center">
                Choose DFY
            </a>
        </div>

        <!-- Enterprise Card -->
        <div class="l-glass rounded-xl p-8 flex flex-col hover:border-white/20 transition-all duration-300 relative group">
            <div class="mb-8">
                <h3 class="font-display text-xl font-semibold text-on-surface mb-2">Enterprise</h3>
                <div class="flex items-baseline gap-1 mb-4 h-[56px]">
                    <span class="font-display text-4xl font-bold text-on-surface">Custom</span>
                </div>
                <p class="text-sm text-on-surface-variant">Tailored architecture for large scale operations and complex requirements.</p>
            </div>
            <ul class="space-y-4 mb-8 flex-grow">
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Unlimited Scalability</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">On-Premise Deployment Options</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">Advanced Security Audits</span>
                </li>
                <li class="flex items-start gap-3">
                    <span class="material-symbols-outlined text-primary text-xl mt-0.5">check_circle</span>
                    <span class="text-sm text-on-surface">SLA Guarantees</span>
                </li>
            </ul>
            <a href="/content/contact" class="w-full py-3 rounded-lg bg-white/10 text-on-surface font-label text-sm font-medium hover:bg-white/20 transition-colors mt-auto border border-white/10 text-center">
                Contact Sales
            </a>
        </div>
    </div>

    <p class="text-center text-sm text-on-surface-variant/70">No credit card required &bull; 2 weeks free on all plans</p>
</main>
