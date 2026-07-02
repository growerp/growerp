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

    .primary-button {
        background-color: #059669;
        color: white;
        transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .primary-button:hover {
        background-color: #047857;
        transform: scale(1.02);
        box-shadow: 0 0 20px rgba(5, 150, 105, 0.3);
    }

    .text-gradient {
        background: linear-gradient(135deg, #68dba9 0%, #4edea3 100%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
    }

    .mesh-gradient-bg {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        z-index: -1;
        overflow: hidden;
    }

    @keyframes float {
        0% { transform: translateY(0px) rotate(0deg); }
        50% { transform: translateY(-20px) rotate(2deg); }
        100% { transform: translateY(0px) rotate(0deg); }
    }

    .floating {
        animation: float 6s ease-in-out infinite;
    }
</style>

<div class="mesh-gradient-bg"></div>

<main class="pt-32 pb-stack-lg overflow-x-hidden">
    <!-- Hero Section -->
    <section class="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop text-center mb-24 relative">
        <div class="inline-flex items-center gap-2 bg-surface-container-high px-4 py-1.5 rounded-full border border-white/5 mb-8">
            <span class="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
            <span class="font-label-md text-label-md text-on-surface-variant uppercase tracking-widest">Enterprise Intelligence</span>
        </div>
        <h1 class="font-display-lg-mobile md:font-display-lg text-display-lg-mobile md:text-display-lg mb-6 max-w-4xl mx-auto leading-tight text-on-surface">
            Why Choose <span class="text-gradient">GrowERP?</span>
        </h1>
        <p class="font-body-lg text-body-lg text-on-surface-variant max-w-2xl mx-auto">
            The intelligence and flexibility your enterprise needs to scale without limits.
        </p>
    </section>

    <!-- Main Content Bento Grid -->
    <section class="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop grid grid-cols-1 md:grid-cols-12 gap-gutter">
        
        <!-- Efficiency Card -->
        <div class="md:col-span-8 glass-card rounded-xl p-8 flex flex-col md:flex-row gap-8 overflow-hidden group">
            <div class="flex-1 space-y-6">
                <div class="w-12 h-12 bg-primary-container/20 rounded-lg flex items-center justify-center border border-primary/20">
                    <span class="material-symbols-outlined text-primary" style="font-variation-settings: 'FILL' 1;">auto_mode</span>
                </div>
                <div>
                    <h3 class="font-headline-sm text-headline-sm text-primary mb-3">Efficiency: Automate the Mundane</h3>
                    <p class="text-on-surface-variant font-body-md text-body-md">
                        High-performance AI agents handle the complexity of modern business cycles. From autonomous invoicing to real-time data orchestration, we free your talent to focus on strategy.
                    </p>
                </div>
                <ul class="space-y-3 font-label-md text-label-md text-on-surface">
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
                <div class="absolute inset-0 opacity-40"></div>
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
        <div class="md:col-span-4 glass-card rounded-xl p-8 flex flex-col justify-between group">
            <div class="space-y-6">
                <div class="w-12 h-12 bg-primary-container/20 rounded-lg flex items-center justify-center border border-primary/20">
                    <span class="material-symbols-outlined text-primary" style="font-variation-settings: 'FILL' 1;">visibility</span>
                </div>
                <div>
                    <h3 class="font-headline-sm text-headline-sm text-primary mb-3">Transparency</h3>
                    <p class="text-on-surface-variant font-body-md text-body-md leading-relaxed">
                        Open Source, Open Minds. Inspect the code, modify the logic, and host wherever you choose. Zero vendor lock-in, total architectural freedom.
                    </p>
                </div>
            </div>
            <div class="mt-8 pt-8 border-t border-white/5">
                <div class="flex items-center justify-between text-on-surface-variant font-code text-code">
                    <span>MIT License</span>
                    <span class="flex items-center gap-1"><span class="w-2 h-2 rounded-full bg-primary"></span> Security Audited</span>
                </div>
            </div>
        </div>

        <!-- Intelligence Section -->
        <div class="md:col-span-5 glass-card rounded-xl p-8 overflow-hidden relative group">
            <div class="relative z-10 space-y-6 h-full flex flex-col">
                <div class="w-12 h-12 bg-primary-container/20 rounded-lg flex items-center justify-center border border-primary/20">
                    <span class="material-symbols-outlined text-primary" style="font-variation-settings: 'FILL' 1;">insights</span>
                </div>
                <div>
                    <h3 class="font-headline-sm text-headline-sm text-primary mb-3">Intelligence: Unified Visibility</h3>
                    <p class="text-on-surface-variant font-body-md text-body-md">
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
            <div class="absolute bottom-[-10%] right-[-10%] w-64 h-64 opacity-20 pointer-events-none"></div>
        </div>

        <!-- Scalability Card -->
        <div class="md:col-span-7 glass-card rounded-xl p-0 overflow-hidden group flex flex-col md:flex-row">
            <div class="flex-1 p-8 space-y-6">
                <div class="w-12 h-12 bg-primary-container/20 rounded-lg flex items-center justify-center border border-primary/20">
                    <span class="material-symbols-outlined text-primary" style="font-variation-settings: 'FILL' 1;">layers</span>
                </div>
                <div>
                    <h3 class="font-headline-sm text-headline-sm text-primary mb-3">Scalability: Grows With You</h3>
                    <p class="text-on-surface-variant font-body-md text-body-md">
                        From agile startups to global enterprises. Our modular architecture allows you to deploy only what you need, when you need it.
                    </p>
                </div>
                <button class="flex items-center gap-2 text-primary font-label-md text-label-md group-hover:gap-4 transition-all">
                    Explore Modular Add-ons <span class="material-symbols-outlined">arrow_forward</span>
                </button>
            </div>
            <div class="flex-1 bg-surface-container-low min-h-[300px] relative p-8 flex items-end">
                <img class="w-full h-full object-cover absolute inset-0 opacity-60 group-hover:scale-105 transition-transform duration-700" alt="Scalability" src="https://lh3.googleusercontent.com/aida-public/AB6AXuBoqm7xNixDvq1aKKwnWgGRY_15AsxwXUXQN-hq8MM8OTdlKuKgFx4vg_DzHGoJ19-U_yYKvFfNxFGo9HaTvCOZ-qAsh0dD40mQ8F0TUaUJrlFuRajH75Wk1tgqg5_8hj7SSvLIABG26gIneD4Bb0aFPaah3L2zZ-m-nd1L6TkOPWmmPREGKTevi9hSPiZaV-oBwN3J-qHt0ri0lfpom2RkblRzKcEvnkGViaAB2ilWRkCDdFCvBr77CA_HRBgJWq3u2hH1X89llQ"/>
                <div class="relative z-10 w-full bg-background/60 backdrop-blur-md p-4 rounded border border-white/5">
                    <div class="flex justify-between items-end">
                        <div>
                            <p class="text-on-surface-variant font-label-md text-label-md">Current Load</p>
                            <p class="font-headline-sm text-headline-sm text-on-surface">99.9% Uptime</p>
                        </div>
                        <div class="w-24 h-8 bg-primary/20 rounded-full border border-primary/20 flex items-center justify-center text-primary font-code text-code">
                            Scaling...
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- CTA Section -->
    <section class="max-w-container-max mx-auto px-margin-mobile md:px-margin-desktop mt-24">
        <div class="glass-card rounded-xl p-12 text-center border-primary/20 relative overflow-hidden">
            <div class="absolute inset-0 bg-primary/5 -z-10"></div>
            <h2 class="font-headline-md text-headline-md mb-6 text-on-surface">Ready to redefine your operations?</h2>
            <p class="text-on-surface-variant font-body-lg text-body-lg max-w-xl mx-auto mb-10">
                Join 2,500+ global enterprises leveraging the power of GrowERP's intelligent ecosystem.
            </p>
            <div class="flex flex-col sm:flex-row gap-4 justify-center">
                <button class="primary-button px-8 py-4 rounded-lg font-label-md text-label-md font-bold text-lg" style="text-decoration:none;">Start Free Trial</button>
                <button class="bg-surface-container-high px-8 py-4 rounded-lg border border-white/10 hover:bg-surface-bright transition-colors font-label-md text-label-md font-bold text-lg text-on-surface" style="text-decoration:none;">Request Demo</button>
            </div>
        </div>
    </section>
</main>
