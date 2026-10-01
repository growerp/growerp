<#-- Homepage email list prompt, included by store.xml. Only rendered when the tenant
     entered the signup page url of an email list provider (MailingListUrl in the website
     colorJson, like the social links) in the website dialog.
     The signup page opens in a popup window half the size of the current window, from
     footer links with data-growerp-mailing-list or from the prompt shown on the first
     homepage visit (browsers block windows opened without a click, hence the prompt). -->
<#function l key><#return ec.l10n.localize(key)></#function>
<#assign mailingListUrl = MailingListUrl!''>
<#if mailingListUrl?has_content>
<style>
#growerp-ml-overlay{position:fixed;inset:0;z-index:10000;display:none;align-items:center;
  justify-content:center;padding:16px;background:rgba(0,0,0,.55);font-family:inherit}
#growerp-ml-overlay.growerp-ml-open{display:flex}
#growerp-ml-box{position:relative;width:100%;max-width:420px;box-sizing:border-box;
  padding:28px 24px 20px;border-radius:14px;background:#fff;color:#222;text-align:center;
  box-shadow:0 12px 40px rgba(0,0,0,.3)}
#growerp-ml-box h3{margin:0 0 8px;font-size:22px}
#growerp-ml-box p{margin:0 0 16px;font-size:14px;color:#555}
#growerp-ml-join{width:100%;background:#2962ff;color:#fff;border:none;
  border-radius:6px;padding:11px;font-size:15px;cursor:pointer}
#growerp-ml-close{position:absolute;top:8px;right:12px;background:none;border:none;
  font-size:24px;line-height:1;color:#888;cursor:pointer}
#growerp-ml-later{display:block;margin:10px auto 0;background:none;border:none;
  font-size:13px;color:#888;cursor:pointer;text-decoration:underline}
</style>
<div id="growerp-ml-overlay" role="dialog" aria-modal="true" aria-labelledby="growerp-ml-title">
  <div id="growerp-ml-box">
    <button id="growerp-ml-close" type="button" aria-label="${l('GrowerpMailingListNoThanks')}">&times;</button>
    <h3 id="growerp-ml-title">${l('GrowerpMailingListTitle')}</h3>
    <p>${l('GrowerpMailingListIntro')}</p>
    <button id="growerp-ml-join" type="button">${l('GrowerpMailingListSubscribe')}</button>
    <button id="growerp-ml-later" type="button">${l('GrowerpMailingListNoThanks')}</button>
  </div>
</div>
<script>
(function(){
  var productStoreId = "${productStoreId?js_string}";
  var signupUrl = "${mailingListUrl?js_string}";
  var seenKey = 'growerp_mailing_list_seen_' + productStoreId;
  var overlay = document.getElementById('growerp-ml-overlay');

  function markSeen(){ try { localStorage.setItem(seenKey, '1'); } catch (e) {} }
  function seen(){ try { return localStorage.getItem(seenKey) === '1'; } catch (e) { return true; } }
  function close(){ overlay.classList.remove('growerp-ml-open'); markSeen(); }

  // the signup page in a centered popup window half the size of the current window;
  // a new tab when popups are blocked
  function openSignup(){
    var w = Math.round(window.outerWidth / 2), h = Math.round(window.outerHeight / 2);
    var left = Math.round((window.screenX || 0) + (window.outerWidth - w) / 2);
    var top = Math.round((window.screenY || 0) + (window.outerHeight - h) / 2);
    var win = window.open(signupUrl, 'growerpEmailList',
      'popup=yes,width=' + w + ',height=' + h + ',left=' + left + ',top=' + top);
    if (win) win.focus(); else window.open(signupUrl, '_blank');
    markSeen();
  }

  document.getElementById('growerp-ml-join').addEventListener('click', function(){
    close();
    openSignup();
  });
  document.getElementById('growerp-ml-close').addEventListener('click', close);
  document.getElementById('growerp-ml-later').addEventListener('click', close);
  overlay.addEventListener('click', function(ev){ if (ev.target === overlay) close(); });
  document.addEventListener('keydown', function(ev){
    if (ev.key === 'Escape' && overlay.classList.contains('growerp-ml-open')) close();
  });

  // footer (or any content) links open the signup window directly
  document.addEventListener('click', function(ev){
    var a = ev.target.closest && ev.target.closest('[data-growerp-mailing-list]');
    if (!a) return;
    ev.preventDefault();
    openSignup();
  });

  // first visit of the homepage only
  var path = window.location.pathname.replace(/\/+$/, '');
  var homePath = "${(urlPrefix!'')?js_string}".replace(/\/+$/, '');
  if (path === homePath && !seen()) {
    setTimeout(function(){ overlay.classList.add('growerp-ml-open'); }, 3000);
  }
})();
</script>
</#if>
