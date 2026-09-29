<#include "component://PopRestStore/template/store/modern/shopMessages.ftl">
<#-- Customer sign-up, see screen/store/signup.xml -->
<#assign back = (returnTo!ec.web.errorParameters.returnTo!'')>
<#assign prev = ec.web.errorParameters!{}>
<#assign field = "w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors">
<#assign label = "block font-label text-sm font-semibold text-on-surface mb-1">
<div class="max-w-md mx-auto px-4 pt-28 pb-12">
    <div class="l-glass rounded-2xl p-8">
        <h1 class="font-display text-2xl font-bold text-on-surface mb-1">Create an account</h1>
        <p class="text-sm text-on-surface-variant mb-6">To order in this shop. Online courses you buy are
            studied in the academy app with this same account.</p>
        <@shopErrors/>
        <form method="post" action="/signup/register" class="space-y-4">
            <input type="hidden" name="moquiSessionToken" value="${ec.web.sessionToken}">
            <input type="hidden" name="returnTo" value="${back}">
            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label for="firstName" class="${label}">First name</label>
                    <input id="firstName" name="firstName" required autocomplete="given-name" value="${prev.firstName!''}" class="${field}">
                </div>
                <div>
                    <label for="lastName" class="${label}">Last name</label>
                    <input id="lastName" name="lastName" required autocomplete="family-name" value="${prev.lastName!''}" class="${field}">
                </div>
            </div>
            <div>
                <label for="emailAddress" class="${label}">Email</label>
                <input id="emailAddress" name="emailAddress" type="email" required autocomplete="email" value="${prev.emailAddress!''}" class="${field}">
            </div>
            <div>
                <label for="password" class="${label}">Password</label>
                <input id="password" name="password" type="password" required autocomplete="new-password" class="${field}">
                <p class="text-xs text-on-surface-variant mt-1">At least 8 characters, with a number and a special character.</p>
            </div>
            <div>
                <label for="passwordVerify" class="${label}">Repeat password</label>
                <input id="passwordVerify" name="passwordVerify" type="password" required autocomplete="new-password" class="${field}">
            </div>
            <button id="signupButton" type="submit"
                    class="w-full bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-semibold px-6 py-3 rounded-lg l-glow transition-all active:scale-95">Create account</button>
        </form>
        <hr class="border-white/10 my-6">
        <p class="text-sm text-on-surface-variant">Already have an account?
            <a href="/login<#if back?has_content>?returnTo=${back?url('UTF-8')}</#if>" class="text-primary underline">Log in</a></p>
    </div>
</div>
