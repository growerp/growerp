<div class="container container-top">
    <div class="row mt-4">
        <div class="customer-menu col col-lg-3 col-md-3 mb-5">
<#list storeInfo.menu1 as topMenu>
    <#if topMenu.title != 'obsidian'>
            <span class="modal-text"><a href="/content/${topMenu.path}#${topMenu.anchor}">${topMenu.title}</a></span>
            <ul class="customer-orders-ul">
            <#list topMenu.items as item>
                <li>
                    <a href="/content/${topMenu.path}#${item.anchor}">${item.text}</a>
                </li>
            </#list>
            </ul>
    <#else>
        <#list topMenu.items as item>
            <ul class="customer-orders-ul">
            <@showPage item />
            </ul>
        </#list>
    </#if>
</#list>

        </div>
        <div class="col col-lg-8 offset-lg-1 col-12">

<#macro showPage page>
    <li>
        <a href="/content/${page.path}">${page.title}</a>
    </li>
    <#list page.items as item>
        <ul class="customer-orders-ul">
        <@showPage item />
        </ul>
    </#list>
</#macro>
