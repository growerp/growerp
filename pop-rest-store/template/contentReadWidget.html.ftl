<#-- Website read tracker for tagged content links (utm_campaign = MasterContent pseudoId,
     utm_source = platform), see growerp MasterContentServices100 adapt#ContentForPlatform.
     A visit is posted as 'land' on arrival and as 'read' once the page was visible for
     READ_SECONDS and scrolled READ_SCROLL percent: bots, link previews and mail privacy
     proxies do not do that, so reads count people. Inactive on pages without utm_campaign. -->
<script>
(function(){
  var params = new URLSearchParams(window.location.search);
  var campaign = params.get('utm_campaign');
  if (!campaign) return;
  var READ_SECONDS = 15, READ_SCROLL = 50;
  var endpoint = window.location.origin + '/rest/s1/growerp/100/ContentRead';

  var visitKey = null;
  try { visitKey = sessionStorage.getItem('growerpVisitKey'); } catch (e) {}
  if (!visitKey) {
    visitKey = '';
    for (var i = 0; i < 20; i++) visitKey += Math.floor(Math.random() * 36).toString(36);
    try { sessionStorage.setItem('growerpVisitKey', visitKey); } catch (e) {}
  }
  var base = {visitKey: visitKey, pagePath: window.location.pathname,
    utmSource: params.get('utm_source') || '', utmMedium: params.get('utm_medium') || '',
    utmCampaign: campaign};

  function post(event, extra){
    var body = Object.assign({event: event}, base, extra || {});
    var json = JSON.stringify(body);
    if (event === 'read' && navigator.sendBeacon &&
        navigator.sendBeacon(endpoint, new Blob([json], {type: 'application/json'}))) return;
    try {
      fetch(endpoint, {method: 'POST', keepalive: true,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: json}).catch(function(){});
    } catch (e) {}
  }

  post('land');

  // drop the utm parameters so a shared or bookmarked url is not counted again
  try {
    ['utm_source','utm_medium','utm_campaign','utm_content','utm_term'].forEach(function(k){ params.delete(k); });
    var q = params.toString();
    history.replaceState(history.state, '', window.location.pathname + (q ? '?' + q : '') + window.location.hash);
  } catch (e) {}

  var dwell = 0, maxScroll = 0, done = false;
  function scrollPct(){
    var doc = document.documentElement;
    var total = Math.max(doc.scrollHeight, document.body ? document.body.scrollHeight : 0);
    if (total <= window.innerHeight * 1.1) return 100; // short page: all of it is in view
    return Math.min(100, Math.round((window.scrollY + window.innerHeight) * 100 / total));
  }
  var timer = setInterval(function(){
    if (document.visibilityState !== 'visible') return;
    dwell++;
    maxScroll = Math.max(maxScroll, scrollPct());
    if (!done && dwell >= READ_SECONDS && maxScroll >= READ_SCROLL) {
      done = true;
      clearInterval(timer);
      post('read', {maxScrollPct: maxScroll, dwellSeconds: dwell});
    }
  }, 1000);
  window.addEventListener('scroll', function(){ maxScroll = Math.max(maxScroll, scrollPct()); }, {passive: true});
})();
</script>
