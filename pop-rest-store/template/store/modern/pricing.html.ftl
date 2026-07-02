<!-- Background Ambient Glow -->
    <div class="fixed inset-0 pointer-events-none z-0 overflow-hidden">
        <div class="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] rounded-full bg-primary/5 blur-[120px]"></div>
        <div class="absolute bottom-[-20%] right-[-10%] w-[40%] h-[40%] rounded-full bg-secondary-container/10 blur-[100px]"></div>
    </div>
    
    <!-- Main Content -->
    <main class="flex-grow z-10 pt-[100px] pb-stack-lg px-margin-mobile md:px-margin-desktop max-w-container-max mx-auto w-full relative">
        <!-- Header Section -->
        <div class="text-center max-w-3xl mx-auto mb-16 pt-8">
            <h1 class="font-display-lg-mobile text-display-lg-mobile md:font-display-lg md:text-display-lg text-on-surface mb-stack-md tracking-tight">Simple, Transparent Pricing</h1>
            <p class="font-body-lg text-body-lg text-on-surface-variant">
                Pricing is configured as products in our catalog. Choose the plan that best fits your workflow.
            </p>
        </div>
        
        <!-- Pricing Cards Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-gutter mb-stack-lg">
            
            <!-- DIY Card -->
            <div class="glass-card rounded-xl p-8 flex flex-col hover:border-white/20 transition-all duration-300 relative group" style="background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.1);">
                <div class="absolute inset-0 bg-gradient-to-b from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-xl pointer-events-none"></div>
                <div class="mb-stack-lg">
                    <h3 class="font-headline-sm text-headline-sm text-on-surface mb-2">Do It Yourself (DIY)</h3>
                    <div class="flex items-baseline gap-1 mb-4">
                        <span class="font-display-lg-mobile text-display-lg-mobile md:font-display-lg md:text-display-lg text-white">$49.99</span>
                        <span class="font-body-sm text-body-sm text-on-surface-variant">/mo</span>
                    </div>
                    <p class="font-body-sm text-body-sm text-on-surface-variant">For self-starters who want full control over their deployment.</p>
                </div>
                <ul class="space-y-4 mb-stack-lg flex-grow">
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Full Platform Access</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Community Support</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Standard Documentation</span>
                    </li>
                </ul>
                <button class="w-full py-3 rounded-lg border border-white/20 text-on-surface font-label-md text-label-md hover:bg-white/5 transition-colors mt-auto">
                    Choose DIY
                </button>
            </div>
            
            <!-- DWY Card (Highlighted) -->
            <div class="glass-card rounded-xl p-8 flex flex-col border-[#059669]/50 relative group transform md:-translate-y-4" style="background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(12px); border: 1px solid rgba(5, 150, 105, 0.5);">
                <div class="absolute inset-0 bg-gradient-to-b from-[#059669]/10 to-transparent opacity-100 rounded-xl pointer-events-none"></div>
                <div class="absolute -top-3 left-1/2 -translate-x-1/2 bg-[#059669] text-white px-3 py-1 rounded-full font-label-md text-label-md text-xs tracking-wider uppercase">Most Popular</div>
                <div class="mb-stack-lg relative z-10">
                    <h3 class="font-headline-sm text-headline-sm text-on-surface mb-2">Do It With You (DWY)</h3>
                    <div class="flex items-baseline gap-1 mb-4">
                        <span class="font-display-lg-mobile text-display-lg-mobile md:font-display-lg md:text-display-lg text-[#059669]">$499</span>
                        <span class="font-body-sm text-body-sm text-on-surface-variant">/mo</span>
                    </div>
                    <p class="font-body-sm text-body-sm text-on-surface-variant">Guided implementation with our expert team alongside you.</p>
                </div>
                <ul class="space-y-4 mb-stack-lg flex-grow relative z-10">
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Everything in DIY</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Weekly Strategy Calls</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Priority Email Support</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Guided Data Migration</span>
                    </li>
                </ul>
                <button class="w-full py-3 rounded-lg bg-[#059669] text-white font-label-md text-label-md hover:bg-opacity-90 transition-all mt-auto relative z-10 shadow-[0_0_15px_rgba(5,150,105,0.3)] hover:shadow-[0_0_25px_rgba(5,150,105,0.5)]">
                    Choose DWY
                </button>
            </div>
            
            <!-- DFY Card -->
            <div class="glass-card rounded-xl p-8 flex flex-col hover:border-white/20 transition-all duration-300 relative group" style="background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.1);">
                <div class="absolute inset-0 bg-gradient-to-b from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-xl pointer-events-none"></div>
                <div class="mb-stack-lg">
                    <h3 class="font-headline-sm text-headline-sm text-on-surface mb-2">Do It For You (DFY)</h3>
                    <div class="flex items-baseline gap-1 mb-4">
                        <span class="font-display-lg-mobile text-display-lg-mobile md:font-display-lg md:text-display-lg text-white">$999</span>
                        <span class="font-body-sm text-body-sm text-on-surface-variant">/mo</span>
                    </div>
                    <p class="font-body-sm text-body-sm text-on-surface-variant">Turnkey solution. We handle everything from setup to launch.</p>
                </div>
                <ul class="space-y-4 mb-stack-lg flex-grow">
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Everything in DWY</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Dedicated Account Manager</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Custom Integrations</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">24/7 Phone Support</span>
                    </li>
                </ul>
                <button class="w-full py-3 rounded-lg border border-white/20 text-on-surface font-label-md text-label-md hover:bg-white/5 transition-colors mt-auto">
                    Choose DFY
                </button>
            </div>
            
            <!-- Enterprise Card -->
            <div class="glass-card rounded-xl p-8 flex flex-col hover:border-white/20 transition-all duration-300 relative group bg-gradient-to-br from-surface-container-high/50 to-surface-container-lowest/50" style="background: rgba(255, 255, 255, 0.03); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.1);">
                <div class="absolute inset-0 bg-gradient-to-b from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300 rounded-xl pointer-events-none"></div>
                <div class="mb-stack-lg">
                    <h3 class="font-headline-sm text-headline-sm text-on-surface mb-2">Enterprise</h3>
                    <div class="flex items-baseline gap-1 mb-4 h-[56px] items-center">
                        <span class="font-headline-md text-headline-md md:font-display-lg md:text-display-lg text-white">Custom</span>
                    </div>
                    <p class="font-body-sm text-body-sm text-on-surface-variant">Tailored architecture for large scale operations and complex requirements.</p>
                </div>
                <ul class="space-y-4 mb-stack-lg flex-grow">
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Unlimited Scalability</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">On-Premise Deployment Options</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">Advanced Security Audits</span>
                    </li>
                    <li class="flex items-start gap-3">
                        <span class="material-symbols-outlined text-[#059669] text-xl mt-0.5">check_circle</span>
                        <span class="font-body-sm text-body-sm text-on-surface">SLA Guarantees</span>
                    </li>
                </ul>
                <button class="w-full py-3 rounded-lg bg-white/10 text-white font-label-md text-label-md hover:bg-white/20 transition-colors mt-auto border border-white/10">
                    Contact Sales
                </button>
            </div>
        </div>
    </main>
