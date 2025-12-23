<#if ec.web.request.pathInfo != "/" && ec.web.request.pathInfo != "/home">
<div class="container container-top">
    <div class="row mt-4">
        <!-- Sidebar Navigation -->
        <div class="customer-menu col-lg-3 col-md-4 mb-5">
            <h5 style="font-family: 'Outfit', sans-serif; font-weight: 600; color: var(--neutral-800); margin-bottom: 1rem;">
                <i class="fas fa-book-open mr-2" style="color: var(--primary-500);"></i>Navigation
            </h5>
<#list storeInfo.menu1 as topMenu>
    <#if topMenu.title != 'obsidian'>
            <div class="menu-section mb-3">
                <span class="modal-text" style="font-size: 1.1rem;">
                    <a href="/content/${topMenu.path}#${topMenu.anchor}" class="d-flex align-items-center">
                        <i class="fas fa-folder mr-2" style="font-size: 0.9rem;"></i>${topMenu.title}
                    </a>
                </span>
                <ul class="customer-orders-ul mt-2">
                <#list topMenu.items as item>
                    <li>
                        <a href="/content/${topMenu.path}#${item.anchor}" class="d-flex align-items-center">
                            <i class="fas fa-chevron-right mr-2" style="font-size: 0.7rem; color: var(--primary-400);"></i>
                            ${item.text}
                        </a>
                    </li>
                </#list>
                </ul>
            </div>
    <#else>
        <#list topMenu.items as item>
            <ul class="customer-orders-ul">
            <@showPage item />
            </ul>
        </#list>
    </#if>
</#list>
        </div>
        
        <!-- Main Content Area -->
        <div class="col-lg-8 offset-lg-1 col-md-8 col-12">
</#if>

<#macro showPage page>
    <li>
        <a href="/content/${page.path}" class="d-flex align-items-center">
            <i class="fas fa-file-alt mr-2" style="font-size: 0.85rem; color: var(--primary-400);"></i>${page.title}
        </a>
    </li>
    <#list page.items as item>
        <ul class="customer-orders-ul ml-3">
        <@showPage item />
        </ul>
    </#list>
</#macro>
