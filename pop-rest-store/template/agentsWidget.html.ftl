<#-- Shared AI agent catalog renderer, included by both store.xml and website.xml.
     Page authors embed the published shared-catalog agents with
     <div data-growerp-agents></div> on any content page; this script fetches
     /rest/s1/growerp/100/PublicAgentCatalog and renders cards grouped by category. -->
<#function l key><#return ec.l10n.localize(key)></#function>
<style>
/* colors inherit from the site theme (light or dark), so cards only tint the background */
.growerp-agents-group{margin:24px 0 8px;font-size:20px;font-weight:bold}
.growerp-agents{display:flex;flex-wrap:wrap;gap:16px;margin:8px 0 16px}
.growerp-agent{flex:1 1 260px;max-width:360px;border:1px solid rgba(127,127,127,.35);border-radius:12px;
  padding:16px;font-family:inherit;background:rgba(127,127,127,.08);color:inherit}
.growerp-agent h3{margin:0 0 4px !important;padding:0 !important;font-size:17px;color:inherit !important}
.growerp-agent .growerp-agent-team{font-size:12px;opacity:.7;margin-bottom:8px}
.growerp-agent p{margin:0 0 8px;font-size:14px;color:inherit}
.growerp-agent .growerp-agent-badge{display:inline-block;font-size:11px;border-radius:10px;
  padding:2px 8px;margin:2px 4px 0 0;background:rgba(80,130,255,.18);color:inherit}
</style>
<script>
(function(){
  var T = {
    scheduled: "${l('GrowerpWebsiteAgentScheduled')?js_string}",
    approval: "${l('GrowerpWebsiteAgentApproval')?js_string}",
    coordinator: "${l('GrowerpWebsiteAgentCoordinator')?js_string}",
    other: "${l('GrowerpWebsiteAgentOther')?js_string}"
  };
  function el(tag, cls, text){
    var e = document.createElement(tag);
    if (cls) e.className = cls;
    if (text) e.textContent = text;
    return e;
  }
  function init(){
    var holders = document.querySelectorAll('[data-growerp-agents]');
    if (!holders.length) return;
    fetch(window.location.origin + '/rest/s1/growerp/100/PublicAgentCatalog',
        {headers:{'Accept':'application/json'}})
      .then(function(r){ return r.ok ? r.json() : null; })
      .then(function(j){
        if (!j || !j.agents) return;
        // group by category, keeping the backend's category order
        var order = [], groups = {};
        j.agents.forEach(function(a){
          var c = a.catalogCategory || T.other;
          if (!groups[c]) { groups[c] = []; order.push(c); }
          groups[c].push(a);
        });
        holders.forEach(function(holder){
          if (holder.dataset.growerpAgentsDone) return;
          holder.dataset.growerpAgentsDone = '1';
          order.forEach(function(c){
            holder.appendChild(el('div', 'growerp-agents-group', c));
            var wrap = el('div', 'growerp-agents');
            groups[c].forEach(function(a){
              var card = el('div', 'growerp-agent');
              card.appendChild(el('h3', null, a.agentName));
              if (a.teamName) card.appendChild(el('div', 'growerp-agent-team', a.teamName));
              if (a.description) card.appendChild(el('p', null, a.description));
              if (a.agentRole === 'coordinator')
                card.appendChild(el('span', 'growerp-agent-badge', T.coordinator));
              if (a.scheduleEnabled)
                card.appendChild(el('span', 'growerp-agent-badge', T.scheduled));
              if (a.writePolicy === 'approve')
                card.appendChild(el('span', 'growerp-agent-badge', T.approval));
              wrap.appendChild(card);
            });
            holder.appendChild(wrap);
          });
        });
      });
  }
  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', init);
  else init();
})();
</script>
