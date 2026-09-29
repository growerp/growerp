<#include "component://PopRestStore/template/store/modern/shopMessages.ftl">
<#-- Shopping cart, see screen/store/cart.xml; lines from CartServices.get#OrderDisplay -->
<div class="max-w-container mx-auto px-4 md:px-12 pt-24 pb-12">
    <h1 class="font-display text-3xl font-bold text-on-surface mb-6">Shopping cart</h1>
    <@shopErrors/>

    <#if !lines?has_content>
        <div class="l-glass rounded-2xl p-12 text-center">
            <span class="material-symbols-outlined text-outline text-[64px] mb-3">shopping_cart</span>
            <p class="text-on-surface-variant mb-6">Your cart is empty.</p>
            <a href="/" class="inline-flex items-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-medium px-6 py-3 rounded-lg transition-all active:scale-95">
                <span class="material-symbols-outlined text-[18px]">storefront</span>Continue shopping</a>
        </div>
    <#else>
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <ul class="lg:col-span-2 space-y-4" id="cartLines">
            <#list lines as line>
                <li class="l-glass rounded-2xl p-4 flex gap-4 items-center" id="cartLine${line?index}">
                    <a href="/product/${line.productId}" class="shrink-0">
                        <#if line.imageUrl??>
                            <img src="${line.imageUrl}" alt="${line.name!}" class="w-24 h-16 object-cover rounded-lg bg-surface-container">
                        <#else>
                            <span class="w-24 h-16 rounded-lg bg-surface-container flex items-center justify-center">
                                <span class="material-symbols-outlined text-outline">${line.isCourse?then('school', 'inventory_2')}</span></span>
                        </#if>
                    </a>
                    <div class="flex-1 min-w-0">
                        <a href="/product/${line.productId}" class="font-semibold text-on-surface hover:text-primary">${line.name!}</a>
                        <div class="text-sm text-on-surface-variant">${money(line.unitAmount, currencyUomId)}<#if line.isCourse> · online course</#if></div>
                    </div>
                    <#if !line.isCourse>
                        <form method="post" action="/cart/updateQuantity" class="flex items-center gap-2">
                            <input type="hidden" name="moquiSessionToken" value="${ec.web.sessionToken}">
                            <input type="hidden" name="orderId" value="${line.orderId}">
                            <input type="hidden" name="orderItemSeqId" value="${line.orderItemSeqId}">
                            <input type="number" name="quantity" min="1" value="${line.quantity?c}" aria-label="Quantity"
                                   onchange="this.form.submit()"
                                   class="w-16 bg-surface-container-high border border-white/10 rounded-lg px-2 py-1.5 text-on-surface text-sm">
                        </form>
                    </#if>
                    <div class="w-24 text-right font-semibold text-on-surface">${money(line.lineTotal, currencyUomId)}</div>
                    <form method="post" action="/cart/removeItem">
                        <input type="hidden" name="moquiSessionToken" value="${ec.web.sessionToken}">
                        <input type="hidden" name="orderId" value="${line.orderId}">
                        <input type="hidden" name="orderItemSeqId" value="${line.orderItemSeqId}">
                        <button type="submit" id="removeLine${line?index}" aria-label="Remove" title="Remove"
                                class="text-on-surface-variant hover:text-error transition-colors flex items-center">
                            <span class="material-symbols-outlined">delete</span></button>
                    </form>
                </li>
            </#list>
        </ul>

        <aside class="l-glass rounded-2xl p-6 h-fit lg:sticky lg:top-24">
            <h2 class="font-display text-lg font-semibold text-on-surface mb-4">Summary</h2>
            <div class="flex justify-between text-sm text-on-surface-variant mb-2">
                <span>${itemCount} item<#if itemCount != 1>s</#if></span><span>${money(productTotal, currencyUomId)}</span></div>
            <#if shippingRequired>
                <div class="flex justify-between text-sm text-on-surface-variant mb-2">
                    <span>Shipping</span><span>calculated at checkout</span></div>
            </#if>
            <hr class="border-white/10 my-4">
            <div class="flex justify-between font-semibold text-on-surface text-lg mb-6">
                <span>Total</span><span>${money(grandTotal, currencyUomId)}</span></div>
            <a href="/checkout" id="checkoutButton"
               class="w-full flex items-center justify-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-semibold px-6 py-3.5 rounded-lg l-glow transition-all active:scale-95">
                Checkout<span class="material-symbols-outlined text-[18px]">arrow_forward</span></a>
            <a href="/" class="block text-center text-sm text-primary mt-4">Continue shopping</a>
        </aside>
    </div>
    </#if>
</div>
