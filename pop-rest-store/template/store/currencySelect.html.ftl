<#--
Display currency: shows the prices marked with data-price-amount (and data-price-currency,
the currency they are in) in another currency, converted with the central weekly exchange
rates. The store currency is the default. Display only: the cart and checkout keep the
company currency. Needs currencyRatesJson, currencyIds and storeCurrencyId from store.xml.

currencySelect: a dropdown; header ones (header=true) stay hidden on pages without prices.
currencyScript: once per page, after the content (footer); keeps all dropdowns in sync.
-->
<#macro currencySelect header=false>
<#if currencyRatesJson?? && currencyIds?size gt 1>
    <select class="js-currency-select" aria-label="Currency"<#if header> data-currency-header</#if>
            style="<#if header>display:none;</#if>padding:.15rem .4rem;border-radius:.5rem;background:transparent;color:inherit;border:1px solid currentColor;font-size:.875rem;">
        <#list currencyIds as currencyId>
            <option value="${currencyId}" style="color:#000;"<#if currencyId == storeCurrencyId> selected</#if>>${currencyId}</option>
        </#list>
    </select>
</#if>
</#macro>

<#macro currencyScript>
<#if currencyRatesJson?? && currencyIds?size gt 1>
<script>
(function () {
    var rates = ${currencyRatesJson};
    var baseCurrency = '${storeCurrencyId}';
    var storageKey = 'growerp_display_currency';
    var selects = document.querySelectorAll('.js-currency-select');
    var notes = document.querySelectorAll('.js-currency-note');
    var prices = document.querySelectorAll('[data-price-amount]');
    if (!prices.length) return;
    document.querySelectorAll('[data-currency-header]').forEach(function (el) { el.style.display = ''; });
    prices.forEach(function (el) { el.setAttribute('data-price-text', el.textContent.trim()); });

    function show(currencyId) {
        if (!rates[currencyId]) currencyId = baseCurrency;
        selects.forEach(function (el) { el.value = currencyId; });
        notes.forEach(function (el) { el.style.display = currencyId === baseCurrency ? 'none' : 'block'; });
        var format = new Intl.NumberFormat(document.documentElement.lang || undefined,
            { style: 'currency', currency: currencyId });
        prices.forEach(function (el) {
            var fromRate = rates[el.getAttribute('data-price-currency') || baseCurrency];
            el.textContent = currencyId === baseCurrency || !fromRate
                ? el.getAttribute('data-price-text')
                : format.format(parseFloat(el.getAttribute('data-price-amount')) * rates[currencyId] / fromRate);
        });
    }

    selects.forEach(function (el) {
        el.addEventListener('change', function () {
            try { localStorage.setItem(storageKey, el.value); } catch (e) {}
            show(el.value);
        });
    });
    var saved = null;
    try { saved = localStorage.getItem(storageKey); } catch (e) {}
    if (saved) show(saved);
})();
</script>
</#if>
</#macro>
