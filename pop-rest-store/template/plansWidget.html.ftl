<#-- Shared pricing-plan renderer, included by both store.xml and website.xml.
     Page authors embed the plan table with <div data-growerp-plans></div> on any
     content page; this script fetches the GROWERP plan products and renders cards. -->
<style>
.growerp-plans{display:flex;flex-wrap:wrap;gap:16px;margin:16px 0;justify-content:center}
.growerp-plan{flex:1 1 220px;max-width:300px;border:1px solid #ddd;border-radius:12px;
  padding:20px;text-align:center;font-family:inherit;background:rgba(255,255,255,.85);color:#222}
.growerp-plan h3{margin:0 0 6px;font-size:18px}
.growerp-plan .growerp-plan-price{font-size:28px;font-weight:bold;margin:10px 0}
.growerp-plan .growerp-plan-price span{font-size:13px;font-weight:normal;color:#666}
.growerp-plan ul{list-style:none;padding:0;margin:10px 0;font-size:13px;color:#444;text-align:left}
.growerp-plan ul li{margin:4px 0}
</style>
<script>
(function(){
  function init(){
    var holders = document.querySelectorAll('[data-growerp-plans]');
    if (!holders.length) return;
    fetch(window.location.origin + '/rest/s1/growerp/100/SubscriptionPlans',
        {headers:{'Accept':'application/json'}})
      .then(function(r){ return r.ok ? r.json() : null; })
      .then(function(j){
        if (!j || !j.plans) return;
        holders.forEach(function(holder){
          if (holder.dataset.growerpPlansDone) return;
          holder.dataset.growerpPlansDone = '1';
          var wrap = document.createElement('div');
          wrap.className = 'growerp-plans';
          j.plans.forEach(function(p){
            var card = document.createElement('div');
            card.className = 'growerp-plan';
            var h = document.createElement('h3');
            h.textContent = p.productName || p.productId;
            card.appendChild(h);
            var price = document.createElement('div');
            price.className = 'growerp-plan-price';
            price.textContent = p.price;
            var per = document.createElement('span');
            per.textContent = ' ' + (p.currencyUomId||'') + '/month';
            price.appendChild(per);
            card.appendChild(price);
            if (p.description) {
              var ul = document.createElement('ul');
              String(p.description).split('|').forEach(function(line){
                if (!line.trim()) return;
                var li = document.createElement('li');
                li.textContent = '✓ ' + line.trim();
                ul.appendChild(li);
              });
              card.appendChild(ul);
            }
            wrap.appendChild(card);
          });
          holder.appendChild(wrap);
        });
      });
  }
  if (document.readyState === 'loading')
    document.addEventListener('DOMContentLoaded', init);
  else init();
})();
</script>
