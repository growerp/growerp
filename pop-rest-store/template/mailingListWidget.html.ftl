<#-- Homepage mailing-list overlay, included by store.xml. Only rendered when the tenant
     entered a mailing list provider form url (MailingListUrl in the website colorJson,
     like the social links) in the website dialog.
     Opens once on the first homepage visit; footer links with data-growerp-mailing-list
     reopen it. The visitor is recorded in GrowERP (SubscribeMailingList) and the same
     data is posted to the provider's form action in a new tab. -->
<#function l key><#return ec.l10n.localize(key)></#function>
<#assign mailingListUrl = MailingListUrl!''>
<#if mailingListUrl?has_content>
<style>
#growerp-ml-overlay{position:fixed;inset:0;z-index:10000;display:none;align-items:center;
  justify-content:center;padding:16px;background:rgba(0,0,0,.55);font-family:inherit}
#growerp-ml-overlay.growerp-ml-open{display:flex}
#growerp-ml-box{position:relative;width:100%;max-width:420px;box-sizing:border-box;
  padding:28px 24px 20px;border-radius:14px;background:#fff;color:#222;
  box-shadow:0 12px 40px rgba(0,0,0,.3)}
#growerp-ml-box h3{margin:0 0 8px;font-size:22px}
#growerp-ml-box p{margin:0 0 16px;font-size:14px;color:#555}
#growerp-ml-box input{display:block;width:100%;box-sizing:border-box;margin:0 0 10px;
  border:1px solid #ccc;border-radius:6px;padding:10px;font-size:15px;font-family:inherit}
#growerp-ml-box button[type=submit]{width:100%;background:#2962ff;color:#fff;border:none;
  border-radius:6px;padding:11px;font-size:15px;cursor:pointer}
#growerp-ml-box button[type=submit]:disabled{opacity:.6;cursor:default}
#growerp-ml-close{position:absolute;top:8px;right:12px;background:none;border:none;
  font-size:24px;line-height:1;color:#888;cursor:pointer}
#growerp-ml-later{display:block;margin:10px auto 0;background:none;border:none;
  font-size:13px;color:#888;cursor:pointer;text-decoration:underline}
#growerp-ml-status{font-size:13px;min-height:18px;margin-top:8px}
#growerp-ml-status.growerp-err{color:#c62828}
#growerp-ml-status.growerp-ok{color:#2e7d32}
</style>
<div id="growerp-ml-overlay" role="dialog" aria-modal="true" aria-labelledby="growerp-ml-title">
  <div id="growerp-ml-box">
    <button id="growerp-ml-close" type="button" aria-label="${l('GrowerpMailingListNoThanks')}">&times;</button>
    <h3 id="growerp-ml-title">${l('GrowerpMailingListTitle')}</h3>
    <p>${l('GrowerpMailingListIntro')}</p>
    <form id="growerp-ml-form" novalidate>
      <input id="growerp-ml-name" type="text" autocomplete="given-name"
        placeholder="${l('GrowerpMailingListFirstName')}" aria-label="${l('GrowerpMailingListFirstName')}">
      <input id="growerp-ml-email" type="email" autocomplete="email" required
        placeholder="${l('GrowerpMailingListEmail')}" aria-label="${l('GrowerpMailingListEmail')}">
      <button type="submit">${l('GrowerpMailingListSubscribe')}</button>
      <div id="growerp-ml-status"></div>
    </form>
    <button id="growerp-ml-later" type="button">${l('GrowerpMailingListNoThanks')}</button>
  </div>
</div>
<script>
(function(){
  var productStoreId = "${productStoreId?js_string}";
  var providerUrl = "${mailingListUrl?js_string}";
  var T = {
    thanks: "${l('GrowerpMailingListThanks')?js_string}",
    invalidEmail: "${l('GrowerpMailingListInvalidEmail')?js_string}",
    failed: "${l('GrowerpWebsiteFormError')?js_string}"
  };
  var apiUrl = window.location.origin + '/rest/s1/growerp/100/SubscribeMailingList';
  var seenKey = 'growerp_mailing_list_seen_' + productStoreId;

  var overlay = document.getElementById('growerp-ml-overlay');
  var form = document.getElementById('growerp-ml-form');
  var nameEl = document.getElementById('growerp-ml-name');
  var emailEl = document.getElementById('growerp-ml-email');
  var statusEl = document.getElementById('growerp-ml-status');
  var submitBtn = form.querySelector('button[type=submit]');

  function markSeen(){ try { localStorage.setItem(seenKey, '1'); } catch (e) {} }
  function seen(){ try { return localStorage.getItem(seenKey) === '1'; } catch (e) { return true; } }
  function setStatus(msg, cls){ statusEl.textContent = msg || ''; statusEl.className = cls || ''; }

  function open(){
    setStatus('');
    overlay.classList.add('growerp-ml-open');
    setTimeout(function(){ nameEl.focus(); }, 50);
  }
  function close(){ overlay.classList.remove('growerp-ml-open'); markSeen(); }

  // post the same data to the provider's embedded form; field names differ per
  // provider (Mailchimp, MailerLite, Brevo, BirdSend ...), unknown fields are ignored by
  // them. Query parameters of the url (e.g. BirdSend ?meta_id=..&meta_user_id=..) are
  // sent as the form's hidden fields.
  function postToProvider(firstName, email){
    var f = document.createElement('form');
    var action = providerUrl.split('?');
    f.method = 'post'; f.action = action[0]; f.target = '_blank'; f.style.display = 'none';
    var fields = {};
    if (action[1]) action[1].split('&').forEach(function(pair){
      var kv = pair.split('=');
      if (kv[0]) fields[decodeURIComponent(kv[0])] = decodeURIComponent((kv[1] || '').replace(/\+/g, ' '));
    });
    var data = {EMAIL: email, FNAME: firstName, FIRSTNAME: firstName,
      email: email, name: firstName, 'fields[email]': email, 'fields[name]': firstName};
    for (var d in data) fields[d] = data[d];
    for (var k in fields) {
      var i = document.createElement('input');
      i.type = 'hidden'; i.name = k; i.value = fields[k];
      f.appendChild(i);
    }
    document.body.appendChild(f);
    f.submit();
    document.body.removeChild(f);
  }

  form.addEventListener('submit', function(ev){
    ev.preventDefault();
    var firstName = nameEl.value.trim();
    var email = emailEl.value.trim();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) { setStatus(T.invalidEmail, 'growerp-err'); return; }
    submitBtn.disabled = true;
    setStatus('');
    // open the provider tab synchronously so popup blockers allow it
    postToProvider(firstName, email);
    fetch(apiUrl, {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({productStoreId: productStoreId, firstName: firstName, email: email})
    }).then(function(r){
      if (!r.ok) throw new Error('HTTP ' + r.status);
      setStatus(T.thanks, 'growerp-ok');
      markSeen();
      setTimeout(close, 2000);
    }).catch(function(){
      setStatus(T.failed, 'growerp-err');
    }).then(function(){ submitBtn.disabled = false; });
  });

  document.getElementById('growerp-ml-close').addEventListener('click', close);
  document.getElementById('growerp-ml-later').addEventListener('click', close);
  overlay.addEventListener('click', function(ev){ if (ev.target === overlay) close(); });
  document.addEventListener('keydown', function(ev){
    if (ev.key === 'Escape' && overlay.classList.contains('growerp-ml-open')) close();
  });

  // footer (or any content) links reopen the overlay
  document.addEventListener('click', function(ev){
    var a = ev.target.closest && ev.target.closest('[data-growerp-mailing-list]');
    if (!a) return;
    ev.preventDefault();
    open();
  });

  // first visit of the homepage only
  var path = window.location.pathname.replace(/\/+$/, '');
  var homePath = "${(urlPrefix!'')?js_string}".replace(/\/+$/, '');
  if (path === homePath && !seen()) setTimeout(open, 3000);
})();
</script>
</#if>
