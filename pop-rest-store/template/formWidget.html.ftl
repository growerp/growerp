<#-- Shared lead-capture form renderer, included by both store.xml and website.xml.
     Page authors embed a form with <div data-growerp-form="FORM_ID"></div> in any
     content page; this script fetches the form definition and renders it inline. -->
<style>
.growerp-form{max-width:480px;margin:16px 0;padding:18px;border:1px solid #ddd;
  border-radius:12px;font-family:inherit;background:rgba(255,255,255,.85);color:#222}
.growerp-form h3{margin:0 0 12px;font-size:18px}
.growerp-form label{display:block;font-size:13px;margin:10px 0 4px}
.growerp-form input,.growerp-form textarea{width:100%;box-sizing:border-box;
  border:1px solid #ccc;border-radius:6px;padding:8px;font-size:14px;font-family:inherit}
.growerp-form textarea{resize:vertical;min-height:72px}
.growerp-form button{margin-top:14px;background:#2962ff;color:#fff;border:none;
  border-radius:6px;padding:10px 18px;font-size:14px;cursor:pointer}
.growerp-form button:disabled{opacity:.6;cursor:default}
.growerp-form .growerp-form-status{font-size:13px;min-height:18px;margin-top:8px}
.growerp-form .growerp-form-status.growerp-err{color:#c62828}
.growerp-form .growerp-form-status.growerp-ok{color:#2e7d32}
</style>
<script>
(function(){
  var apiBase = window.location.origin + '/rest/s1/growerp/100/SubmitWebsiteForm';

  function el(tag, attrs, text){
    var e = document.createElement(tag);
    for (var k in (attrs||{})) e.setAttribute(k, attrs[k]);
    if (text) e.textContent = text;
    return e;
  }

  function renderForm(holder, def){
    var form = el('form', {'class':'growerp-form'});
    if (def.title) form.appendChild(el('h3', {}, def.title));
    (def.fields||[]).forEach(function(f){
      var id = 'growerp-ff-' + def.formId + '-' + f.fieldId;
      var label = el('label', {'for':id}, f.label + (f.isRequired==='Y' ? ' *' : ''));
      form.appendChild(label);
      var input;
      if (f.fieldType === 'textarea') input = el('textarea', {id:id});
      else input = el('input', {id:id,
        type: f.fieldType==='email' ? 'email' : (f.fieldType==='phone' ? 'tel' : 'text')});
      if (f.isRequired==='Y') input.setAttribute('required','required');
      input.dataset.fieldId = f.fieldId;
      form.appendChild(input);
    });
    var btn = el('button', {type:'submit'}, def.submitLabel || 'Send');
    form.appendChild(btn);
    var status = el('div', {'class':'growerp-form-status'});
    form.appendChild(status);
    form.addEventListener('submit', function(ev){
      ev.preventDefault();
      var values = {};
      form.querySelectorAll('[data-field-id]').forEach(function(i){
        values[i.dataset.fieldId] = i.value;
      });
      btn.disabled = true;
      status.className = 'growerp-form-status';
      status.textContent = '...';
      fetch(apiBase, {
        method: 'POST',
        headers: {'Content-Type':'application/json','Accept':'application/json'},
        body: JSON.stringify({formId: def.formId, valuesJson: JSON.stringify(values)})
      }).then(function(r){ return r.json().then(function(j){ return {ok:r.ok, j:j}; }); })
        .then(function(res){
          if (res.ok) {
            status.className = 'growerp-form-status growerp-ok';
            status.textContent = res.j.successMessage || def.successMessage || 'Thank you!';
            form.querySelectorAll('input,textarea').forEach(function(i){ i.value=''; });
          } else {
            status.className = 'growerp-form-status growerp-err';
            status.textContent = (res.j && res.j.errors) ? res.j.errors : 'Could not send, try again';
            btn.disabled = false;
          }
        }).catch(function(){
          status.className = 'growerp-form-status growerp-err';
          status.textContent = 'Could not send, try again';
          btn.disabled = false;
        });
    });
    holder.appendChild(form);
  }

  function init(){
    var holders = document.querySelectorAll('[data-growerp-form]');
    holders.forEach(function(holder){
      if (holder.dataset.growerpFormDone) return;
      holder.dataset.growerpFormDone = '1';
      var formId = holder.dataset.growerpForm;
      fetch(apiBase + '?formId=' + encodeURIComponent(formId),
          {headers:{'Accept':'application/json'}})
        .then(function(r){ return r.ok ? r.json() : null; })
        .then(function(j){ if (j && j.webForm) renderForm(holder, j.webForm); });
    });
  }
  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', init);
  else init();
})();
</script>
