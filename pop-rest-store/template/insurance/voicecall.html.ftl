<#-- The AI renewal call, see transition 'voicecall' in screen/store.xml: a phone call screen.
     The assistant speaks (Gemini TTS from converse#VoiceBot); the customer answers by voice
     (browser speech recognition, vi-VN) or types. ?script=a|b|c plays a scripted customer for
     demos. In a pilot the same dialogue runs on a telephony line. -->
<#assign found = renewal.found!false>
<#assign p = renewal.page!{}>
<#assign vi = lang != "en">
<#macro t v e>${vi?then(v, e)}</#macro>
<!DOCTYPE html>
<html lang="${lang}">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title><@t "Cuộc gọi trợ lý AI" "AI assistant call"/></title>
<style>
  * { box-sizing: border-box; }
  body { margin:0; padding:16px; background:#11161D; color:#EEF2F5; font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; display:flex; justify-content:center; }
  .phone { width:380px; max-width:100%; min-height:680px; background:linear-gradient(180deg,#1B2A3A,#0F1720); border-radius:36px; border:10px solid #05070A; display:flex; flex-direction:column; padding:20px 16px; gap:12px; }
  .who { text-align:center; display:flex; flex-direction:column; align-items:center; gap:6px; }
  .avatar { width:76px; height:76px; border-radius:50%; background:#1B7F66; display:flex; align-items:center; justify-content:center; font-size:32px; }
  .name { font-size:20px; font-weight:600; } .status { font-size:14px; color:#A9B4C0; }
  .log { flex:1; overflow-y:auto; display:flex; flex-direction:column; gap:8px; padding:4px; max-height:380px; }
  .b { padding:10px 12px; border-radius:14px; font-size:15px; line-height:1.4; max-width:85%; }
  .ai { background:#24384D; align-self:flex-start; border-bottom-left-radius:4px; }
  .me { background:#1B7F66; align-self:flex-end; border-bottom-right-radius:4px; }
  .controls { display:flex; gap:8px; align-items:center; }
  .controls input { flex:1; font-size:16px; padding:12px; border-radius:24px; border:1px solid #2E3946; background:#0F1720; color:#EEF2F5; }
  .round { width:52px; height:52px; border-radius:50%; border:none; font-size:22px; cursor:pointer; flex:none; }
  .mic { background:#2E6BD8; color:#fff; } .mic.on { background:#E3A13B; } .end { background:#C8352B; color:#fff; }
  .start { width:100%; padding:16px; border-radius:28px; border:none; background:#1B7F66; color:#fff; font-size:18px; font-weight:600; cursor:pointer; }
  .outcome { text-align:center; font-size:15px; background:#24384D; border-radius:14px; padding:12px; }
  small { color:#8A97A5; font-size:12px; text-align:center; }
</style>
</head>
<body>
<div class="phone">
<#if !found>
  <p><@t "Đường link không còn hiệu lực." "This link is no longer valid."/></p>
<#else>
  <div class="who"><div class="avatar">🤖</div>
    <div class="name"><@t "Trợ lý AI" "AI assistant"/> · ${(p.agencyName!"")?html}</div>
    <div class="status" id="status"><@t "Cuộc gọi nhắc gia hạn bảo hiểm" "Insurance renewal call"/></div></div>
  <div class="log" id="log"></div>
  <div id="outcome" class="outcome" style="display:none"></div>
  <button class="start" id="startBtn"><@t "Bắt đầu cuộc gọi" "Start the call"/></button>
  <div class="controls" id="controls" style="display:none">
    <button class="round mic" id="micBtn" title="<@t "Nói" "Speak"/>">🎤</button>
    <input id="txt" placeholder="<@t "Hoặc nhập câu trả lời…" "Or type your answer…"/>">
    <button class="round end" id="endBtn" title="<@t "Kết thúc" "End"/>">✆</button>
  </div>
  <small><@t "Cuộc gọi do AI thực hiện và được ghi lại để nhân viên tiếp tục hỗ trợ. Nói “dừng” bất cứ lúc nào để không nhận cuộc gọi nữa." "This call is made by AI and recorded so a colleague can continue. Say “stop” at any time to receive no more calls."/></small>
</#if>
</div>
<#if found>
<script>
  const token = '${renewalToken?js_string}', lang = '${lang}';
  const script = (new URLSearchParams(location.search).get('script') || '').split('|').filter(s => s);
  const T = { listening: '<@t "Đang nghe…" "Listening…"/>', speaking: '<@t "Trợ lý đang nói…" "Assistant speaking…"/>',
    ended: '<@t "Cuộc gọi đã kết thúc" "Call ended"/>', thinking: '<@t "Đang xử lý…" "Thinking…"/>' };
  const OUT = { InocInterested: '<@t "Đã chuyển cho nhân viên tư vấn kèm tóm tắt cuộc gọi." "Handed over to a colleague with a summary of the call."/>',
    InocCallLater: '<@t "Nhân viên sẽ gọi lại sau." "A colleague will call back later."/>',
    InocNotInterested: '<@t "Khách hàng chưa muốn gia hạn." "The customer does not want to renew now."/>',
    InocOptOut: '<@t "Sẽ không gọi lại nữa." "No more calls."/>', InocSoldVehicle: '<@t "Khách hàng đã bán xe." "The customer sold the car."/>',
    InocWrongNumber: '<@t "Nhầm số." "Wrong number."/>' };
  const $ = id => document.getElementById(id);
  let state = '', done = false, rec = null, busy = false;
  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  function bubble(text, me) { const d = document.createElement('div'); d.className = 'b ' + (me ? 'me' : 'ai');
    d.textContent = text; $('log').appendChild(d); $('log').scrollTop = 1e6; }
  function afterReply() {
    if (done) return;
    if (script.length) { setTimeout(() => { const s = script.shift(); bubble(s, true); turn(s); }, 1200); return; }
    listen();
  }
  function play(audio) {
    return new Promise(resolve => {
      if (!audio) return resolve();
      $('status').textContent = T.speaking;
      const a = new Audio('data:audio/wav;base64,' + audio); a.onended = resolve; a.onerror = resolve;
      a.play().catch(resolve);
    });
  }
  async function turn(text) {
    if (busy) return; busy = true; $('status').textContent = T.thinking;
    try {
      const r = await fetch('/rest/s1/growerp/100/VoiceBot', { method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ renewalToken: token, text: text || '', stateJson: state, language: lang }) });
      const res = await r.json();
      state = res.stateJson || state; done = !!res.done;
      if (res.reply) bubble(res.reply, false);
      await play(res.audio);
      if (done) { $('status').textContent = T.ended; $('controls').style.display = 'none';
        $('outcome').textContent = OUT[res.outcomeEnumId] || T.ended; $('outcome').style.display = ''; }
    } finally { busy = false; }
    afterReply();
  }
  function listen() {
    if (!SR || done) { $('status').textContent = ''; $('txt').focus(); return; }
    rec = new SR(); rec.lang = lang === 'en' ? 'en-US' : 'vi-VN'; rec.interimResults = false; rec.maxAlternatives = 1;
    rec.onstart = () => { $('micBtn').classList.add('on'); $('status').textContent = T.listening; };
    rec.onend = () => { $('micBtn').classList.remove('on'); };
    rec.onresult = e => { const s = e.results[0][0].transcript; bubble(s, true); turn(s); };
    rec.onerror = () => { $('status').textContent = ''; };
    try { rec.start(); } catch (e) {}
  }
  $('startBtn').onclick = () => { $('startBtn').style.display = 'none'; $('controls').style.display = ''; turn(''); };
  $('micBtn').onclick = () => { if (rec) try { rec.stop(); } catch (e) {} listen(); };
  $('txt').onkeydown = e => { if (e.key === 'Enter' && $('txt').value.trim()) { const s = $('txt').value.trim();
    $('txt').value = ''; if (rec) try { rec.abort(); } catch (x) {} bubble(s, true); turn(s); } };
  $('endBtn').onclick = () => { done = true; if (rec) try { rec.abort(); } catch (e) {} $('status').textContent = T.ended; $('controls').style.display = 'none'; };
</script>
</#if>
</body>
</html>
