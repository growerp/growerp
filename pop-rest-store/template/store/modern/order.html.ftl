<#include "component://PopRestStore/template/store/modern/shopMessages.ftl">
<#-- One order of the customer, see screen/store/order.xml -->
<div class="max-w-3xl mx-auto px-4 pt-28 pb-12">
    <#if !lines?has_content>
        <div class="l-glass rounded-2xl p-12 text-center">
            <p class="text-on-surface-variant mb-6">This order was not found.</p>
            <a href="/orders" class="text-primary underline">My orders</a>
        </div>
    <#else>
        <#if (placed!'') == 'true'>
            <div class="l-glass !border-primary/40 rounded-2xl p-6 mb-6 flex items-start gap-3" id="orderPlaced">
                <span class="material-symbols-outlined text-primary text-[32px]">check_circle</span>
                <div>
                    <h1 class="font-display text-2xl font-bold text-on-surface">Thank you for your order</h1>
                    <p class="text-on-surface-variant">Order ${orderId} has been placed.</p>
                </div>
            </div>
        <#else>
            <h1 class="font-display text-2xl font-bold text-on-surface mb-6">Order ${orderId}</h1>
        </#if>

        <#if hasCourses>
            <div class="l-glass rounded-2xl p-6 mb-6" id="academyNotice">
                <h2 class="font-display font-semibold text-on-surface mb-2">Start learning</h2>
                <p class="text-sm text-on-surface-variant mb-4">Your courses are ready in the academy app. Log in
                    there with the email and password of this shop account.</p>
                <a href="${academyUrl}" id="academyLink"
                   class="inline-flex items-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-semibold px-6 py-3 rounded-lg l-glow transition-all active:scale-95">
                    <span class="material-symbols-outlined text-[18px]">school</span>Go to the academy</a>
            </div>
        </#if>

        <div class="l-glass rounded-2xl p-6">
            <div class="flex justify-between text-sm text-on-surface-variant mb-4">
                <span><#if entryDate??>${ec.l10n.format(entryDate, 'yyyy-MM-dd')}</#if></span>
                <span>${statusDescription!statusId!''}</span>
            </div>
            <ul class="space-y-2 mb-4">
                <#list lines as line>
                    <li class="flex justify-between gap-3 text-sm text-on-surface">
                        <a href="/product/${line.productId}" class="hover:text-primary">${line.name!}<#if line.quantity != 1> × ${line.quantity}</#if></a>
                        <span class="shrink-0">${money(line.lineTotal, currencyUomId)}</span>
                    </li>
                </#list>
            </ul>
            <#if shippingTotal gt 0>
                <div class="flex justify-between text-sm text-on-surface-variant mb-2"><span>Shipping</span><span>${money(shippingTotal, currencyUomId)}</span></div>
            </#if>
            <hr class="border-white/10 my-4">
            <div class="flex justify-between font-semibold text-on-surface text-lg">
                <span>Total</span><span>${money(grandTotal, currencyUomId)}</span></div>
        </div>
        <div class="flex justify-between mt-6 text-sm">
            <a href="/orders" class="text-primary underline">My orders</a>
            <a href="/" class="text-primary underline">Continue shopping</a>
        </div>
    </#if>
</div>
