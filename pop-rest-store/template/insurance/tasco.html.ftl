<#-- Tasco "AI for Insurance" challenge demo landing page, see screen/store/tasco.xml.
     While the visitor reads, the insurance app at /insurance/ boots in a hidden iframe, so its
     scripts and engine files are in the browser cache when "Open the demo" is clicked. -->
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>GrowERP Insurance × Tasco</title>
<meta name="description" content="An AI renewal engine for TNDS: lead scoring, AI reminders on Zalo and VETC, a private renewal page, an AI voice call and a telesales queue. Working demo on synthetic data.">
<style>
  :root { --bg: #F7F5EF; --card: #FFFDF8; --ink: #14233B; --text: #3E4A5A; --muted: #6B7685;
          --accent: #1B7F66; --gold: #E3A13B; --line: #DCE3E6; --hero: #14233B; --hero-text: #F7F5EF;
          --hero-muted: #C9D6E0; }
  @media (prefers-color-scheme: dark) {
    :root { --bg: #0F1A2C; --card: #16243A; --ink: #F7F5EF; --text: #D5DDE5; --muted: #9AA7B5;
            --accent: #4FC3A1; --line: #2A3B55; --hero: #0B1424; }
  }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--bg); color: var(--text);
         font: 17px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif; }
  a { color: var(--accent); }
  .wrap { max-width: 1040px; margin: 0 auto; padding: 0 20px; }
  header { background: var(--hero); color: var(--hero-text); padding: 56px 0 64px; }
  .eyebrow { font-size: 13px; font-weight: 700; letter-spacing: 2px; text-transform: uppercase; color: var(--gold); }
  h1 { font: 700 clamp(34px, 6vw, 56px)/1.1 Georgia, serif; margin: 14px 0 18px; }
  header p { color: var(--hero-muted); font-size: 19px; max-width: 720px; margin: 0 0 28px; }
  .cta { display: flex; flex-wrap: wrap; gap: 14px; align-items: center; }
  .btn { display: inline-block; padding: 14px 26px; border-radius: 12px; font-weight: 700; text-decoration: none; }
  .btn.primary { background: var(--gold); color: #14233B; }
  .btn.ghost { border: 2px solid rgba(201,214,224,.5); color: var(--hero-text); }
  #appState { font-size: 14px; color: var(--hero-muted); }
  #appState .dot { display: inline-block; width: 9px; height: 9px; border-radius: 50%; background: var(--gold); margin-right: 6px; }
  #appState.ready .dot { background: #4FC3A1; }
  section { padding: 48px 0 8px; }
  h2 { font: 700 clamp(26px, 4vw, 34px)/1.2 Georgia, serif; color: var(--ink); margin: 0 0 18px; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(230px, 1fr)); gap: 16px; }
  .card { background: var(--card); border: 1px solid var(--line); border-radius: 16px; padding: 22px; }
  .card h3 { margin: 0 0 8px; color: var(--ink); font-size: 18px; }
  .card .tag { font-size: 12px; font-weight: 700; letter-spacing: 1px; text-transform: uppercase; color: var(--accent); }
  .card p { margin: 0; font-size: 16px; }
  ol { padding-left: 22px; margin: 0; } ol li { margin: 6px 0; }
  .login { font-family: ui-monospace, monospace; background: var(--bg); border: 1px solid var(--line);
           border-radius: 8px; padding: 2px 8px; overflow-wrap: anywhere; }
  .two { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 16px; }
  footer { margin-top: 56px; padding: 28px 0 40px; border-top: 1px solid var(--line); color: var(--muted); font-size: 15px; }
</style>
</head>
<body>
<header>
  <div class="wrap">
    <div class="eyebrow">BeyondPilot · AI for Insurance × Tasco</div>
    <h1>An AI renewal engine for TNDS</h1>
    <p>The right reminder, at the right moment, on the right channel: VETC, Zalo, an AI call, and a
      person whenever the customer wants one. A working system on synthetic data, not a mock-up.</p>
    <div class="cta">
      <a class="btn primary" id="openDemo" href="/insurance/">Open the demo</a>
      <a class="btn ghost" href="https://youtu.be/Dc9yygkDWfs" target="_blank" rel="noopener">Watch the video (4:49)</a>
      <span id="appState" hidden><span class="dot"></span><span id="appStateText">Preparing the demo app…</span></span>
    </div>
  </div>
</header>

<main class="wrap">
  <section>
    <h2>Try it in five minutes</h2>
    <div class="two">
      <div class="card">
        <h3>Log in as the agency</h3>
        <p>User <span class="login">test150296@example.com</span><br>
          Password <span class="login">qqqqqq9!</span></p>
        <p style="margin-top:10px">A synthetic book of 60 TNDS customers due in the next 60 days.</p>
      </div>
      <div class="card">
        <h3>What to look at</h3>
        <ol>
          <li><b>Renewals → Cockpit:</b> every customer scored, with plain reasons.</li>
          <li>Open a customer: <b>AI draft</b> writes the reminder in Vietnamese.</li>
          <li><b>Open preview</b> shows it as a Zalo or VETC message; <b>Renewal page</b> is what the customer gets.</li>
          <li><b>AI call</b>: a Vietnamese voice call (Chrome, allow the microphone).</li>
          <li><b>Renewals → Telesales:</b> hand-overs with the AI summary; record the outcome.</li>
        </ol>
      </div>
    </div>
  </section>

  <section>
    <h2>The four tracks of the briefing</h2>
    <div class="grid">
      <div class="card"><div class="tag">B · Lead scoring</div><h3>Who, when, where</h3>
        <p>An explainable score from renewal history, reactions, consent and profile, plus the next
          best channel and the hour this customer reads messages.</p></div>
      <div class="card"><div class="tag">C · Renewal engine</div><h3>One easy next step</h3>
        <p>AI drafts the reminder from policy facts only: no urgency, no discount. A private renewal
          page: confirm the car by plate, then renew, ask for a call, or stop.</p></div>
      <div class="card"><div class="tag">A · AI voice bot</div><h3>A respectful call</h3>
        <p>Permission first, vehicle check, answers from the policy only, and a hand-over to a person
          with a summary, transcript and CRM outcome code.</p></div>
      <div class="card"><div class="tag">D · Beyond discount</div><h3>Service, not price</h3>
        <p>A digital certificate with a live QR check, guided claims with photo triage, roadside and
          service-centre help. Offers marked for compliance review.</p></div>
    </div>
  </section>

  <section>
    <h2>Built on GrowERP, free and open source</h2>
    <div class="two">
      <div class="card"><h3>Building blocks, separate apps</h3>
        <p>GrowERP is assembled from reusable packages (catalog, orders and accounting, inventory,
          AI agents, and now insurance). From them we compose a separate app per business, on web,
          Android, iOS and desktop, all on one Moqui backend through a REST API. More blocks, such as
          accounting or claims, switch on later in the same system.</p></div>
      <div class="card"><h3>What Tasco pays for</h3>
        <p>The software is Apache 2.0 licensed: no licence fee. Tasco pays only for the production
          environment, enhancements (such as the Zalo, VETC and telephony integrations) and support.
          AI usage is passed through at cost under a monthly budget.</p></div>
    </div>
  </section>
</main>

<footer>
  <div class="wrap">
    Hans Bakker · GrowERP · <a href="mailto:h.bakker@antwebsystems.com">h.bakker@antwebsystems.com</a> · +66-81-7523157<br>
    Source: <a href="https://github.com/growerp/growerp">https://github.com/growerp/growerp</a> (branch tasco) ·
    Videos: <a href="https://youtu.be/Dc9yygkDWfs">renewal</a>, <a href="https://www.youtube.com/watch?v=3j92jqFwI_Y">claims</a> ·
    All customer data in this demo is synthetic.
  </div>
</footer>

<#noparse>
<script>
  // Boot the insurance app off-screen while the visitor reads, so "Open the demo" starts warm.
  // In the viewport at a real size, but transparent and behind the page: Chrome throttles
  // rendering of display:none and off-screen iframes, and the Flutter engine then never starts.
  (function () {
    if (navigator.connection && navigator.connection.saveData) return;
    var state = document.getElementById('appState'), text = document.getElementById('appStateText');
    window.addEventListener('load', function () {
      setTimeout(function () {
        var frame = document.createElement('iframe');
        frame.src = '/insurance/';
        frame.title = 'demo app preload';
        frame.setAttribute('aria-hidden', 'true');
        frame.tabIndex = -1;
        frame.style.cssText = 'position:fixed;left:0;top:0;width:100vw;height:100vh;border:0;opacity:0;pointer-events:none;z-index:-1';
        document.body.appendChild(frame);
        state.hidden = false;
        var tries = 0, poll = setInterval(function () {
          var ready = false;
          try { ready = !!frame.contentDocument.querySelector('flutter-view'); } catch (e) {}
          if (ready) { clearInterval(poll); state.className = 'ready'; text.textContent = 'Demo app ready'; }
          else if (++tries > 240) { clearInterval(poll); state.hidden = true; }
        }, 500);
      }, 800);
    });
  })();
</script>
</#noparse>
</body>
</html>
