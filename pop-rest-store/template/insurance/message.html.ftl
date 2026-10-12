<#-- A sent renewal reminder as the customer sees it on the phone (Zalo OA, VETC app push or
     SMS), see transition 'message' in screen/store.xml. A preview until the real gateways are
     connected in a pilot. -->
<#assign found = msg.found!false>
<#assign m = msg.preview!{}>
<#assign ch = m.channelEnumId!"">
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Reminder preview</title>
<style>
  * { box-sizing: border-box; }
  body { margin:0; padding:16px; background:#2B2F36; font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; display:flex; flex-direction:column; align-items:center; gap:12px; }
  .note { color:#C9D1DA; font-size:13px; text-align:center; max-width:380px; }
  .phone { width:360px; max-width:100%; min-height:640px; background:#F2F3F5; border-radius:36px; border:10px solid #0F1115; overflow:hidden; display:flex; flex-direction:column; }
  .bar { padding:14px 16px; color:#fff; display:flex; align-items:center; gap:10px; font-weight:600; }
  .zalo .bar { background:#0068FF; } .vetc .bar { background:#00875A; } .sms .bar { background:#3C4048; } .email .bar { background:#5A6676; }
  .avatar { width:36px; height:36px; border-radius:50%; background:rgba(255,255,255,.25); display:flex; align-items:center; justify-content:center; font-size:15px; }
  .sub { font-weight:400; font-size:12px; opacity:.85; }
  .body { padding:16px; display:flex; flex-direction:column; gap:8px; flex:1; }
  .bubble { background:#fff; color:#14233B; border-radius:16px 16px 16px 4px; padding:12px 14px; font-size:15px; line-height:1.45; box-shadow:0 1px 2px rgba(0,0,0,.08); white-space:pre-wrap; overflow-wrap:anywhere; }
  .bubble a { color:#0068FF; }
  .time { font-size:12px; color:#8A929C; }
  .push { background:#fff; border-radius:16px; padding:12px; box-shadow:0 2px 8px rgba(0,0,0,.12); display:flex; gap:10px; }
  .push .icon { width:40px; height:40px; border-radius:10px; background:#00875A; color:#fff; display:flex; align-items:center; justify-content:center; font-weight:700; font-size:13px; flex:none; }
  .push b { font-size:14px; color:#14233B; } .push p { margin:4px 0 0; font-size:14px; color:#3E4A5A; white-space:pre-wrap; overflow-wrap:anywhere; }
</style>
</head>
<body>
<#if !found>
  <p class="note">Message not found.</p>
<#else>
  <#assign cls = (ch == "InchZalo")?then("zalo", (ch == "InchVetc")?then("vetc", (ch == "InchSms")?then("sms", "email")))>
  <#assign chName = (ch == "InchZalo")?then("Zalo Official Account", (ch == "InchVetc")?then("VETC app", (ch == "InchSms")?then("SMS", "Email")))>
  <#-- the link in the text becomes clickable -->
  <#assign html = (m.messageText!"")?html?replace("(https?://[^\\s<]+)", "<a href=\"$1\">$1</a>", "r")>
  <p class="note">Bản xem trước tin nhắn ${chName} · Preview of the ${chName} reminder (simulated until the gateway is connected)</p>
  <div class="phone ${cls}">
    <div class="bar"><div class="avatar">${(m.agencyName!"A")?substring(0,1)?html}</div>
      <div>${(m.agencyName!"")?html}<div class="sub">${chName}</div></div></div>
    <div class="body">
      <#if cls == "vetc">
        <div class="push"><div class="icon">VETC</div><div><b>Nhắc gia hạn bảo hiểm</b><p>${html}</p></div></div>
      <#else>
        <div class="bubble">${html}</div>
      </#if>
      <span class="time">${m.touchDate?string("dd/MM/yyyy HH:mm")}</span>
    </div>
  </div>
</#if>
</body>
</html>
