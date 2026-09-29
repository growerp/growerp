<#include "component://PopRestStore/template/store/modern/shopMessages.ftl">
<#-- The customer's orders, see screen/store/orders.xml -->
<div class="max-w-3xl mx-auto px-4 pt-28 pb-12">
    <h1 class="font-display text-2xl font-bold text-on-surface mb-6">My orders</h1>
    <#if !orderList?has_content>
        <div class="l-glass rounded-2xl p-12 text-center text-on-surface-variant">You have no orders yet.</div>
    <#else>
        <ul class="space-y-3">
            <#list orderList as order>
                <li>
                    <a href="/order/${order.orderId}" id="order${order?index}"
                       class="l-glass rounded-2xl p-5 flex items-center justify-between gap-4 hover:border-primary/40 transition-colors">
                        <span>
                            <span class="block font-semibold text-on-surface">Order ${order.orderId}</span>
                            <span class="block text-sm text-on-surface-variant"><#if order.entryDate??>${ec.l10n.format(order.entryDate, 'yyyy-MM-dd')}</#if> · ${order.statusDescription!order.statusId!''}</span>
                        </span>
                        <span class="font-semibold text-on-surface">${money(order.grandTotal, order.currencyUomId)}</span>
                    </a>
                </li>
            </#list>
        </ul>
    </#if>
</div>
