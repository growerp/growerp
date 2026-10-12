<#-- Private renewal page behind a reminder link, see transition 'renew' in screen/store.xml.
     Mobile first, no app or login: confirm the vehicle, then renew, ask for a call or stop. -->
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
<title><@t "Gia hạn bảo hiểm" "Renew your insurance"/></title>
<style>
  :root { --ink:#14233B; --muted:#5A6676; --bg:#F4F2EC; --card:#FFFDF8; --line:#DCE3E6; --accent:#1B7F66; --accent-ink:#F7F5EF; --warn:#B3261E; }
  @media (prefers-color-scheme: dark) { :root { --ink:#E9EEF2; --muted:#A9B4C0; --bg:#12171E; --card:#1B222B; --line:#2E3946; --accent:#5CC7A6; --accent-ink:#0E1A16; --warn:#FFB4AB; } }
  * { box-sizing: border-box; }
  body { margin:0; font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; background:var(--bg); color:var(--ink); padding:16px; }
  main { max-width:460px; margin:0 auto; display:flex; flex-direction:column; gap:14px; }
  .brand { font-size:14px; color:var(--muted); display:flex; justify-content:space-between; }
  .brand a { color:var(--muted); }
  h1 { font-size:24px; margin:4px 0 0; line-height:1.25; }
  .card { background:var(--card); border:1px solid var(--line); border-radius:16px; padding:16px; }
  .row { display:flex; justify-content:space-between; gap:12px; padding:6px 0; border-bottom:1px solid var(--line); font-size:15px; }
  .row:last-child { border-bottom:none; }
  .row span:first-child { color:var(--muted); }
  .row b { text-align:right; overflow-wrap:anywhere; }
  .plate { font-family: ui-monospace, monospace; font-size:22px; letter-spacing:1px; }
  label { font-size:15px; display:block; margin-bottom:8px; }
  input[type=text] { width:100%; font-size:20px; padding:12px; border-radius:12px; border:1px solid var(--line); background:var(--bg); color:var(--ink); text-transform:uppercase; letter-spacing:2px; }
  select { width:100%; font-size:16px; padding:10px; border-radius:12px; border:1px solid var(--line); background:var(--bg); color:var(--ink); }
  button { width:100%; font-size:17px; padding:14px; border-radius:12px; border:none; cursor:pointer; font-weight:600; }
  .primary { background:var(--accent); color:var(--accent-ink); }
  .secondary { background:transparent; color:var(--ink); border:1px solid var(--line); }
  .links { display:flex; justify-content:space-between; font-size:14px; }
  .links a { color:var(--muted); }
  .msg { font-size:15px; padding:12px; border-radius:12px; background:var(--bg); }
  .err { color:var(--warn); font-size:14px; min-height:18px; }
  .hidden { display:none !important; }
  .svc { display:grid; grid-template-columns:1fr; gap:10px; }
  .svc div { display:flex; gap:10px; align-items:flex-start; font-size:15px; }
  .svc i { font-style:normal; font-size:20px; }
  small { color:var(--muted); font-size:13px; }
  .stack { display:flex; flex-direction:column; gap:10px; }
</style>
</head>
<body>
<main>
<#if !found>
  <div class="card"><h1><@t "Đường link không còn hiệu lực" "This link is no longer valid"/></h1>
    <p><@t "Vui lòng liên hệ đại lý bảo hiểm của bạn." "Please contact your insurance agency."/></p></div>
<#else>
  <div class="brand"><span>${(p.agencyName!"")?html}</span><a href="?lang=${vi?then('en','vi')}">${vi?then('English','Tiếng Việt')}</a></div>
  <h1><@t "Chào ${(p.firstName!'')?html}, gia hạn bảo hiểm xe chỉ với một chạm" "Hi ${(p.firstName!'')?html}, renew your car insurance in one tap"/></h1>

  <div class="card">
    <div class="row"><span><@t "Biển số" "Plate"/></span><b class="plate" id="plate">${(p.plateMasked!"")?html}</b></div>
    <#if p.vehicleDescription?has_content><div class="row"><span><@t "Xe" "Vehicle"/></span><b>${p.vehicleDescription?html}</b></div></#if>
    <div class="row"><span><@t "Loại" "Type"/></span><b><@t "Bảo hiểm TNDS bắt buộc" "Compulsory motor liability (TNDS)"/></b></div>
    <div class="row"><span><@t "Công ty bảo hiểm" "Insurer"/></span><b>${(p.carrierName!"")?html}</b></div>
    <div class="row"><span><@t "Hết hạn" "Cover ends"/></span><b>${p.expirationDate?string("dd/MM/yyyy")}</b></div>
  </div>

  <div class="card stack" id="done" <#if !p.lastAction?has_content>style="display:none"</#if>>
    <div class="msg" id="doneText">
      <#if (p.lastAction!"") == "InevRenewRequested"><@t "Bạn đã yêu cầu gia hạn. Đại lý sẽ phát hành giấy chứng nhận điện tử và gửi cho bạn." "You asked to renew. The agency will issue your digital certificate and send it to you."/>
      <#elseif (p.lastAction!"") == "InevCallback"><@t "Bạn đã yêu cầu được gọi lại. Nhân viên sẽ liên hệ sớm." "You asked for a call. A colleague will contact you soon."/>
      <#elseif (p.lastAction!"") == "InevOptOut"><@t "Bạn sẽ không nhận thêm nhắc nhở." "You will receive no more reminders."/>
      <#elseif (p.lastAction!"") == "InevRenewed"><@t "Bảo hiểm của bạn đã được gia hạn." "Your insurance has been renewed."/></#if>
    </div>
  </div>

  <div class="card stack" id="step1">
    <label for="plateEnd"><@t "Để bảo mật, nhập 3 ký tự cuối của biển số xe:" "For your security, enter the last 3 characters of your plate:"/></label>
    <input type="text" id="plateEnd" maxlength="5" autocomplete="off" inputmode="text" placeholder="•••">
    <div class="err" id="err1"></div>
    <button class="primary" id="confirmBtn"><@t "Xác nhận xe" "Confirm vehicle"/></button>
  </div>

  <div class="card stack hidden" id="step2">
    <button class="primary" id="renewBtn"><@t "Gia hạn ngay" "Renew now"/></button>
    <small><@t "Không cần thanh toán ở đây: đại lý xác nhận phí theo quy định và phát hành giấy chứng nhận điện tử." "Nothing to pay here: the agency confirms the regulated premium and issues the digital certificate."/></small>
    <button class="secondary" id="callToggle"><@t "Gọi cho tôi" "Call me"/></button>
    <div class="stack hidden" id="callBox">
      <label for="when"><@t "Thời gian thuận tiện:" "Best time:"/></label>
      <select id="when">
        <option><@t "Sáng (8–12h)" "Morning (8–12)"/></option>
        <option><@t "Chiều (13–17h)" "Afternoon (13–17)"/></option>
        <option selected><@t "Tối (18–21h)" "Evening (18–21)"/></option>
      </select>
      <label><input type="checkbox" id="consentCall"> <@t "Tôi đồng ý được đại lý gọi điện về việc gia hạn." "I agree that the agency calls me about the renewal."/></label>
      <button class="primary" id="callBtn"><@t "Yêu cầu cuộc gọi" "Request the call"/></button>
    </div>
    <button class="secondary" onclick="location.href='/voicecall/${renewalToken}?lang=${lang}'"><@t "Nói chuyện với trợ lý AI" "Talk to the AI assistant"/></button>
    <div class="err" id="err2"></div>
  </div>

  <div class="card">
    <b><@t "Dịch vụ đi kèm" "Services that come with it"/></b>
    <div class="svc" style="margin-top:10px">
      <div><i>📄</i><span><@t "Giấy chứng nhận điện tử: luôn trong điện thoại, kiểm tra được bằng mã QR." "Digital certificate: always on your phone, checkable by QR code."/></span></div>
      <div><i>🛟</i><span><@t "Hỗ trợ khi có sự cố: báo cáo bồi thường kèm ảnh, theo dõi từng bước." "Help after an accident: report a claim with photos and follow every step."/></span></div>
      <div><i>🔧</i><span><@t "Trung tâm dịch vụ gần bạn và cứu hộ đường bộ: hỏi đại lý." "Nearby service centre and roadside assistance: ask the agency."/></span></div>
    </div>
    <small><@t "Thông tin dịch vụ, không phải ưu đãi giá. Mọi ưu đãi cụ thể cần được xét duyệt tuân thủ." "Service information, not a price offer. Any specific offer needs compliance review."/></small>
  </div>

  <div class="links">
    <a href="#" id="soldLink"><@t "Tôi đã bán xe" "I sold the car"/></a>
    <a href="#" id="stopLink"><@t "Không nhận nhắc nhở nữa" "No more reminders"/></a>
  </div>
  <small><@t "Dữ liệu của bạn chỉ dùng cho việc gia hạn bảo hiểm này (Nghị định 13/2023)." "Your data is only used for this renewal (Decree 13/2023)."/></small>
</#if>
</main>
<#if found>
<script>
  const token = '${renewalToken?js_string}', t = '${(ec.web.requestParameters.t!"")?js_string}';
  const T = {
    mismatch: '<@t "Ba ký tự cuối chưa đúng. Vui lòng thử lại." "The last 3 characters do not match. Please try again."/>',
    renewed: '<@t "Cảm ơn bạn! Đại lý sẽ xác nhận phí theo quy định và gửi giấy chứng nhận điện tử qua Zalo hoặc email." "Thank you! The agency will confirm the regulated premium and send your digital certificate by Zalo or email."/>',
    called: '<@t "Đã ghi nhận. Nhân viên sẽ gọi cho bạn vào thời gian đã chọn." "Noted. A colleague will call you at the time you chose."/>',
    stopped: '<@t "Đã ghi nhận. Bạn sẽ không nhận thêm nhắc nhở." "Noted. You will receive no more reminders."/>',
    consent: '<@t "Vui lòng đánh dấu đồng ý để chúng tôi gọi cho bạn." "Please tick the box so we may call you."/>',
    error: '<@t "Có lỗi, vui lòng thử lại." "Something went wrong, please try again."/>'
  };
  const $ = id => document.getElementById(id);
  async function act(action, extra) {
    const r = await fetch('/rest/s1/growerp/100/RenewalAction', { method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(Object.assign({ renewalToken: token, action, plateEnd: $('plateEnd').value, t }, extra || {})) });
    return r.ok ? r.json() : { ok: false };
  }
  function finish(text) { $('step1').classList.add('hidden'); $('step2').classList.add('hidden');
    $('doneText').textContent = text; $('done').style.display = ''; }
  $('confirmBtn').onclick = async () => {
    const res = await act('confirm');
    if (!res.ok) { $('err1').textContent = res.message === 'plateMismatch' ? T.mismatch : T.error; return; }
    $('err1').textContent = ''; $('plate').textContent = res.vehiclePlate;
    $('step1').classList.add('hidden'); $('step2').classList.remove('hidden');
  };
  $('renewBtn').onclick = async () => { const res = await act('renew'); res.ok ? finish(T.renewed) : $('err2').textContent = T.error; };
  $('callToggle').onclick = () => $('callBox').classList.toggle('hidden');
  $('callBtn').onclick = async () => {
    if (!$('consentCall').checked) { $('err2').textContent = T.consent; return; }
    const res = await act('callback', { preferredTime: $('when').value });
    res.ok ? finish(T.called) : $('err2').textContent = T.error;
  };
  $('stopLink').onclick = async e => { e.preventDefault(); const res = await act('optout'); if (res.ok) finish(T.stopped); };
  $('soldLink').onclick = async e => { e.preventDefault(); const res = await act('sold'); if (res.ok) finish(T.stopped); };
</script>
</#if>
</body>
</html>
