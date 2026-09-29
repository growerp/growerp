<#-- Errors of the last shop form (cart, login, sign-up, checkout): saved in the session by
     the transition's error-response, or raised while rendering this page -->
<#macro shopErrors>
    <#assign shopErrorList = (ec.web.savedErrors![]) + (ec.message.errors![])>
    <#if shopErrorList?has_content>
        <div class="l-glass !border-error/40 rounded-xl px-5 py-4 mb-6 text-sm text-error" role="alert">
            <#list shopErrorList as shopError><p>${shopError}</p></#list>
        </div>
    </#if>
</#macro>
<#-- the store currency amount, e.g. $49.00 -->
<#function money amount currency><#return ec.l10n.formatCurrency(amount!0, currency!'USD')></#function>
