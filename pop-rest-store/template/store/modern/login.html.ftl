<#include "component://PopRestStore/template/store/modern/shopMessages.ftl">
<#-- Customer log in, see screen/store/login.xml -->
<#assign back = (returnTo!ec.web.errorParameters.returnTo!'')>
<#assign field = "w-full bg-surface-container-high border border-white/10 rounded-lg px-3 py-2.5 text-on-surface text-sm outline-none focus:border-primary/50 transition-colors">
<div class="max-w-md mx-auto px-4 pt-28 pb-12">
    <div class="l-glass rounded-2xl p-8">
        <h1 class="font-display text-2xl font-bold text-on-surface mb-1">Log in</h1>
        <p class="text-sm text-on-surface-variant mb-6">With the account you use for this shop<#if back == '/checkout'> to finish your order</#if>.</p>
        <@shopErrors/>
        <#if (passwordSent!'') == 'true'>
            <div class="l-glass !border-primary/40 rounded-xl px-5 py-4 mb-6 text-sm text-on-surface" role="status">
                If that email address has an account, a new password is on its way.</div>
        </#if>
        <form method="post" action="/login/login" class="space-y-4">
            <input type="hidden" name="moquiSessionToken" value="${ec.web.sessionToken}">
            <input type="hidden" name="returnTo" value="${back}">
            <div>
                <label for="username" class="block font-label text-sm font-semibold text-on-surface mb-1">Email</label>
                <input id="username" name="username" type="email" required autocomplete="username"
                       value="${(ec.web.errorParameters.username)!''}" class="${field}">
            </div>
            <div>
                <label for="password" class="block font-label text-sm font-semibold text-on-surface mb-1">Password</label>
                <input id="password" name="password" type="password" required autocomplete="current-password" class="${field}">
            </div>
            <button id="loginButton" type="submit"
                    class="w-full bg-primary hover:bg-primary/90 text-on-primary font-label text-sm font-semibold px-6 py-3 rounded-lg l-glow transition-all active:scale-95">Log in</button>
        </form>
        <details class="mt-4 text-sm">
            <summary class="cursor-pointer text-primary">Forgot your password?</summary>
            <form method="post" action="/login/resetPassword" class="flex gap-2 mt-3">
                <input type="hidden" name="moquiSessionToken" value="${ec.web.sessionToken}">
                <input type="hidden" name="returnTo" value="${back}">
                <input name="username" type="email" required placeholder="Your email" class="${field}">
                <button type="submit" class="shrink-0 bg-surface-container-highest text-on-surface font-label text-sm px-4 rounded-lg">Send</button>
            </form>
        </details>
        <hr class="border-white/10 my-6">
        <p class="text-sm text-on-surface-variant">New here?
            <a id="signupLink" href="/signup<#if back?has_content>?returnTo=${back?url('UTF-8')}</#if>" class="text-primary underline">Create an account</a></p>
    </div>
</div>
