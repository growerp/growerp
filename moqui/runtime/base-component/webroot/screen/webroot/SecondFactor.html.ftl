<p class="text-strong text-center">${ec.l10n.localize("Enter an Authentication Code")}</p>
<p class="text-center">${ec.l10n.localize("An authentication code is required for your account, you have these options:")}</p>
<ul class="form-signin" style="padding-left:40px;">
    <#list factorTypeDescriptions as factorType>
        <li>${factorType}</li>
    </#list>
</ul>

<#-- Form for Code entry -->
<form method="post" action="${sri.buildUrl("verifyUserAuthcFactor").url}" class="form-signin">
    <input name="moquiSessionToken" type="hidden" value="${ec.web.sessionToken}">
    <input name="code" type="text" inputmode="numeric" autocomplete="one-time-code" required="required"
           placeholder="${ec.l10n.localize("Authentication Code")}" class="form-control"
           aria-label="${ec.l10n.localize("Authentication Code")}">
    <button class="btn btn-lg btn-primary btn-block" type="submit">${ec.l10n.localize("Verify Code")}</button>
</form>

<#list sendableFactors as userAuthcFactor>
    <div class="text-center">
        <form method="post" action="${sri.buildUrl("sendOtp").url}" class="form-signin">
            <input type="hidden" name="factorId" value="${userAuthcFactor.factorId}">
            <input type="hidden" name="moquiSessionToken" value="${ec.web.sessionToken}">
            <button class="btn btn-lg btn-primary" type="submit">${ec.l10n.localize("Send code to")} ${userAuthcFactor.factorOption!}</button>
        </form>
    </div>
</#list>
