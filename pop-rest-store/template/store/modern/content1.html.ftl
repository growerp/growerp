<div class="max-w-container mx-auto px-4 md:px-12 pt-24 pb-8">
    <div class="flex flex-col lg:flex-row gap-10 mt-4">
        <!-- Sidebar Navigation -->
        <aside class="lg:w-72 shrink-0">
            <div class="l-glass rounded-2xl p-6 lg:sticky lg:top-24">
                <h5 class="font-display font-semibold text-on-surface mb-4 flex items-center gap-2">
                    <span class="material-symbols-outlined text-primary text-[20px]">menu_book</span>Navigation
                </h5>
<#list storeInfo.menu1 as topMenu>
    <#if topMenu.title != 'obsidian'>
                <div class="mb-4">
                    <a href="/content/${topMenu.path}#${topMenu.anchor}" class="flex items-center gap-2 font-label text-sm font-medium text-on-surface hover:text-primary transition-colors">
                        <span class="material-symbols-outlined text-primary text-[16px]">folder</span>${topMenu.title}
                    </a>
                    <ul class="mt-2 ml-2 space-y-1 border-l border-white/10 pl-3">
                    <#list topMenu.items as item>
                        <li>
                            <a href="/content/${topMenu.path}#${item.anchor}" class="flex items-center gap-2 text-sm text-on-surface-variant hover:text-primary transition-colors">
                                <span class="material-symbols-outlined text-primary/60 text-[12px]">chevron_right</span>${item.text}
                            </a>
                        </li>
                    </#list>
                    </ul>
                </div>
    <#else>
        <#list topMenu.items as item>
                <ul class="space-y-1">
                <@showPage item />
                </ul>
        </#list>
    </#if>
</#list>
            </div>
        </aside>

        <!-- Main Content Area -->
        <article class="prose-lumina min-w-0 flex-1">

<#macro showPage page>
    <li>
        <a href="/content/${page.path}" class="flex items-center gap-2 text-sm text-on-surface-variant hover:text-primary transition-colors">
            <span class="material-symbols-outlined text-primary/60 text-[14px]">description</span>${page.title}
        </a>
    </li>
    <#list page.items as item>
        <ul class="ml-4 space-y-1">
        <@showPage item />
        </ul>
    </#list>
</#macro>
