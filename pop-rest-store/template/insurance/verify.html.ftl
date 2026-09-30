<#-- Public proof of insurance, see transition 'verify' in screen/store.xml.
     Bilingual Vietnamese/English: it is read by police and garage staff on the road. -->
<#assign v = verification>
<#macro dt ts><#if ts??>${ts?string("dd/MM/yyyy")}</#if></#macro>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>Xác minh bảo hiểm · Insurance check</title>
<style>
  :root { --ok: #1b7f3b; --bad: #b3261e; --ink: #1c1b1f; --muted: #5f5d66; --bg: #f4f4f6; --card: #fff; }
  @media (prefers-color-scheme: dark) {
    :root { --ok: #6fdc8c; --bad: #ffb4ab; --ink: #e6e1e5; --muted: #aaa6b0; --bg: #141218; --card: #1f1d24; }
  }
  * { box-sizing: border-box; }
  body { margin: 0; font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
         background: var(--bg); color: var(--ink); padding: 16px; }
  .card { max-width: 440px; margin: 24px auto; background: var(--card); border-radius: 16px;
          box-shadow: 0 2px 12px rgba(0,0,0,.12); overflow: hidden; }
  .banner { padding: 20px; color: #fff; text-align: center; }
  .banner.ok { background: var(--ok); } .banner.bad { background: var(--bad); }
  @media (prefers-color-scheme: dark) { .banner { color: #141218; } }
  .banner .big { font-size: 26px; font-weight: 700; }
  .banner .small { font-size: 15px; opacity: .9; margin-top: 4px; }
  dl { margin: 0; padding: 16px 20px; display: grid; grid-template-columns: auto 1fr; gap: 10px 16px; }
  dt { color: var(--muted); font-size: 13px; } dd { margin: 0; font-weight: 600; overflow-wrap: anywhere; }
  .plate { font-family: ui-monospace, monospace; font-size: 20px; letter-spacing: 1px; }
  footer { padding: 12px 20px 18px; color: var(--muted); font-size: 12px; border-top: 1px solid rgba(127,127,127,.2); }
</style>
</head>
<body>
<div class="card">
<#if !v.found>
  <div class="banner bad">
    <div class="big">Không tìm thấy</div>
    <div class="small">Policy not found. This code is not a valid proof of insurance.</div>
  </div>
<#else>
  <#if v.valid>
    <div class="banner ok">
      <div class="big">✓ Còn hiệu lực</div>
      <div class="small">Insured · valid until <@dt v.expirationDate/></div>
    </div>
  <#else>
    <div class="banner bad">
      <div class="big">✗ Hết hiệu lực</div>
      <div class="small">Not insured on this date<#if v.expirationDate??> · ended <@dt v.expirationDate/></#if></div>
    </div>
  </#if>
  <dl>
    <#if v.vehiclePlate?has_content><dt>Biển số<br>Plate</dt><dd class="plate">${v.vehiclePlate?html}</dd></#if>
    <#if v.vehicleDescription?has_content><dt>Xe<br>Vehicle</dt><dd>${v.vehicleDescription?html}</dd></#if>
    <dt>Loại<br>Type</dt><dd>${(v.policyType!"")?html}</dd>
    <dt>Số hợp đồng<br>Policy no.</dt><dd>${(v.policyNumber!"")?html}</dd>
    <dt>Hiệu lực<br>Period</dt><dd><@dt v.effectiveDate/> – <@dt v.expirationDate/></dd>
    <dt>Công ty bảo hiểm<br>Insurer</dt><dd>${(v.carrierName!"")?html}</dd>
    <#if v.agencyName?has_content><dt>Đại lý<br>Agency</dt><dd>${v.agencyName?html}</dd></#if>
  </dl>
</#if>
  <footer>Kiểm tra lúc · Checked ${v.checkedDate?string("dd/MM/yyyy HH:mm")} (UTC).
    Chỉ hiển thị thông tin cần thiết để xác minh · Only the data needed to verify insurance is shown.</footer>
</div>
</body>
</html>
