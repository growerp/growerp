<#include "component://PopRestStore/template/store/modern/shopMessages.ftl">
<#-- One page checkout, see screen/store/checkout.xml -->
<#assign prev = ec.web.errorParameters!{}>
<#assign field = "w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors">
<#assign label = "block font-label text-sm font-semibold text-on-surface mb-1">
<#macro countrySelect name id selected>
    <select id="${id}" name="${name}" class="${field}">
        <option value="">Country</option>
        <#list countryList![] as country>
            <option value="${country.geoId}"<#if country.geoId == selected> selected</#if>>${country.geoName}</option>
        </#list>
    </select>
</#macro>
<div class="max-w-container mx-auto px-4 md:px-12 pt-24 pb-12">
    <h1 class="font-display text-3xl font-bold text-on-surface mb-6">Checkout</h1>
    <@shopErrors/>
    <form method="post" action="/checkout/placeOrder" id="checkoutForm" class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <input type="hidden" name="moquiSessionToken" value="${ec.web.sessionToken}">
        <div class="lg:col-span-2 space-y-6">
            <#if shippingRequired>
                <section class="l-glass rounded-2xl p-6" id="shippingSection">
                    <h2 class="font-display text-lg font-semibold text-on-surface mb-4">Shipping address</h2>
                    <div class="space-y-2 mb-4">
                        <#list addressList as address>
                            <label class="flex items-start gap-3 text-sm text-on-surface">
                                <input type="radio" name="postalContactMechId" value="${address.postalContactMechId}"<#if address?index == 0> checked</#if>>
                                <span>${(address.postalAddress.toName)!''} ${address.postalAddress.address1!''}, ${address.postalAddress.postalCode!''} ${address.postalAddress.city!''}</span>
                            </label>
                        </#list>
                        <label class="flex items-center gap-3 text-sm text-on-surface">
                            <input type="radio" name="postalContactMechId" value=""<#if !addressList?has_content> checked</#if>> A new address
                        </label>
                    </div>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div class="sm:col-span-2"><label for="toName" class="${label}">Name</label>
                            <input id="toName" name="toName" value="${prev.toName!''}" class="${field}"></div>
                        <div class="sm:col-span-2"><label for="address1" class="${label}">Address</label>
                            <input id="address1" name="address1" value="${prev.address1!''}" class="${field}"></div>
                        <div><label for="postalCode" class="${label}">Postal code</label>
                            <input id="postalCode" name="postalCode" value="${prev.postalCode!''}" class="${field}"></div>
                        <div><label for="city" class="${label}">City</label>
                            <input id="city" name="city" value="${prev.city!''}" class="${field}"></div>
                        <div class="sm:col-span-2"><label for="countryGeoId" class="${label}">Country</label>
                            <@countrySelect name="countryGeoId" id="countryGeoId" selected=(prev.countryGeoId!'')/></div>
                    </div>
                    <h3 class="font-semibold text-on-surface mt-6 mb-2">Shipping method</h3>
                    <#if shippingOptions?has_content>
                        <#-- preselected: Ground Parcel when offered (as the old checkout did), else the first -->
                        <#assign groundOptions = shippingOptions?filter(o -> o.shipmentMethodEnumId == 'ShMthGround')>
                        <#assign defaultMethod = groundOptions?has_content?then(groundOptions[0], shippingOptions[0]).shipmentMethodEnumId>
                        <div class="space-y-2">
                            <#list shippingOptions as option>
                                <label class="flex items-center justify-between gap-3 text-sm text-on-surface">
                                    <span class="flex items-center gap-3">
                                        <input type="radio" name="carrierShipment" value="${option.carrierPartyId}:${option.shipmentMethodEnumId}"<#if option.shipmentMethodEnumId == defaultMethod> checked</#if>>
                                        ${option.shipmentMethodDescription!option.shipmentMethodEnumId}</span>
                                    <span><#if option.shippingTotal??>${money(option.shippingTotal, currencyUomId)}</#if></span>
                                </label>
                            </#list>
                        </div>
                    <#else>
                        <p class="text-sm text-on-surface-variant">Enter your address first; the shipping methods for it show after the next step.</p>
                    </#if>
                </section>
            </#if>

            <#if needsPayment>
                <section class="l-glass rounded-2xl p-6" id="paymentSection">
                    <h2 class="font-display text-lg font-semibold text-on-surface mb-4">Payment</h2>
                    <div class="space-y-2 mb-4">
                        <#list cardList as card>
                            <label class="flex items-center gap-3 text-sm text-on-surface">
                                <input type="radio" name="paymentMethodId" value="${card.paymentMethodId}"<#if card?index == 0> checked</#if>>
                                <span>${(card.paymentMethod.description)!'Card'} ${(card.creditCard.cardNumber)!''}</span>
                            </label>
                        </#list>
                        <label class="flex items-center gap-3 text-sm text-on-surface">
                            <input type="radio" name="paymentMethodId" value=""<#if !cardList?has_content> checked</#if>> A new card
                        </label>
                    </div>
                    <div class="grid grid-cols-2 gap-3">
                        <div><label for="firstNameOnAccount" class="${label}">First name on card</label>
                            <input id="firstNameOnAccount" name="firstNameOnAccount" value="${prev.firstNameOnAccount!''}" class="${field}"></div>
                        <div><label for="lastNameOnAccount" class="${label}">Last name on card</label>
                            <input id="lastNameOnAccount" name="lastNameOnAccount" value="${prev.lastNameOnAccount!''}" class="${field}"></div>
                        <div class="col-span-2"><label for="cardNumber" class="${label}">Card number</label>
                            <input id="cardNumber" name="cardNumber" inputmode="numeric" autocomplete="cc-number" class="${field}"></div>
                        <div><label for="expireMonth" class="${label}">Expiry month</label>
                            <input id="expireMonth" name="expireMonth" placeholder="MM" inputmode="numeric" maxlength="2" class="${field}"></div>
                        <div><label for="expireYear" class="${label}">Expiry year</label>
                            <input id="expireYear" name="expireYear" placeholder="YYYY" inputmode="numeric" maxlength="4" class="${field}"></div>
                        <div class="col-span-2"><label for="billingAddress1" class="${label}">Billing address</label>
                            <input id="billingAddress1" name="billingAddress1" value="${prev.billingAddress1!''}" class="${field}"></div>
                        <div><label for="billingPostalCode" class="${label}">Postal code</label>
                            <input id="billingPostalCode" name="billingPostalCode" value="${prev.billingPostalCode!''}" class="${field}"></div>
                        <div><label for="billingCity" class="${label}">City</label>
                            <input id="billingCity" name="billingCity" value="${prev.billingCity!''}" class="${field}"></div>
                        <div class="col-span-2"><label for="billingCountryGeoId" class="${label}">Country</label>
                            <@countrySelect name="billingCountryGeoId" id="billingCountryGeoId" selected=(prev.billingCountryGeoId!'')/></div>
                    </div>
                    <div class="mt-4 max-w-[10rem]">
                        <label for="cardSecurityCode" class="${label}">Security code (CVV)</label>
                        <input id="cardSecurityCode" name="cardSecurityCode" inputmode="numeric" maxlength="4" autocomplete="cc-csc" class="${field}">
                    </div>
                </section>
            </#if>

            <#if hasCourses>
                <p class="text-sm text-on-surface-variant">Online courses in this order open in the academy
                    app right after you place the order: log in there with this same account.</p>
            </#if>
        </div>

        <aside class="l-glass rounded-2xl p-6 h-fit lg:sticky lg:top-24">
            <h2 class="font-display text-lg font-semibold text-on-surface mb-4">Your order</h2>
            <ul class="space-y-2 mb-4">
                <#list lines as line>
                    <li class="flex justify-between gap-3 text-sm text-on-surface">
                        <span>${line.name!}<#if line.quantity != 1> × ${line.quantity}</#if></span>
                        <span class="shrink-0">${money(line.lineTotal, currencyUomId)}</span>
                    </li>
                </#list>
            </ul>
            <#if shippingTotal gt 0>
                <div class="flex justify-between text-sm text-on-surface-variant mb-2"><span>Shipping</span><span>${money(shippingTotal, currencyUomId)}</span></div>
            </#if>
            <hr class="border-white/10 my-4">
            <div class="flex justify-between font-semibold text-on-surface text-lg mb-6">
                <span>Total</span><span>${money(grandTotal, currencyUomId)}</span></div>
            <button id="placeOrder" type="submit"
                    onclick="this.disabled=true; this.textContent='Placing order…'; this.form.submit();"
                    class="w-full flex items-center justify-center gap-2 bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-semibold px-6 py-3.5 rounded-lg l-glow transition-all active:scale-95">
                Place order</button>
            <a href="/cart" class="block text-center text-sm text-primary mt-4">Back to cart</a>
        </aside>
    </form>
</div>
