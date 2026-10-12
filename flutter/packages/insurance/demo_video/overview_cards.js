// GrowERP overview cards for the renewal video: one diagram (apps on top of building blocks on
// one open source backend), rendered twice with a different layer highlighted.
// Used by record_web.js; standalone: node overview_cards.js [outDir]
const path = require('path');

const apps = ['Insurance', 'Admin', 'Hotel', 'Rental', 'Freelance', 'Academy', 'Marketing', 'Support'];
const blocks = ['Insurance', 'Catalog', 'Orders & accounting', 'Inventory', 'Sales', 'Users & companies',
  'Marketing', 'HR', 'Courses', 'Website', 'Wiki', 'AI agents'];

function html(focus) {
  const chip = (t, on, accent) => `<div style="padding:7px 15px;border-radius:10px;font:600 19px Arial,sans-serif;
    background:${on ? (accent ? '#E3A13B' : '#F7F5EF') : 'rgba(247,245,239,.12)'};color:${on ? '#14233B' : '#C9D6E0'}">${t}</div>`;
  const layer = (label, sub, items, on) => `<div style="display:flex;gap:26px;align-items:center;padding:12px 24px;
    border-radius:18px;border:2px solid ${on ? '#E3A13B' : 'rgba(201,214,224,.25)'};opacity:${on ? 1 : .55}">
    <div style="width:210px;flex:none"><div style="font:700 26px Georgia,serif;color:#F7F5EF">${label}</div>
    <div style="font:400 18px Arial,sans-serif;color:#C9D6E0;margin-top:6px">${sub}</div></div>
    <div style="display:flex;flex-wrap:wrap;gap:10px">${items}</div></div>`;
  const title = focus === 'apps' ? 'One platform, a separate app per business'
    : 'Built from reusable building blocks';
  return `<html><body style="margin:0;width:1280px;height:720px;box-sizing:border-box;padding:30px 70px;
    background:#14233B;font-family:Georgia,serif;display:flex;flex-direction:column;gap:14px">
    <div style="font:600 20px Arial,sans-serif;letter-spacing:3px;text-transform:uppercase;color:#E3A13B">GrowERP · open source (Apache 2.0)</div>
    <div style="font-size:42px;font-weight:700;color:#F7F5EF;margin-bottom:4px">${title}</div>
    ${layer('Apps', 'web · Android · iOS · desktop', apps.map((a, i) => chip(a, focus === 'apps', i === 0)).join(''), focus === 'apps')}
    ${layer('Building blocks', 'Flutter packages: screens, tests, translations', blocks.map((b, i) => chip(b, focus === 'platform', i === 0)).join(''), focus === 'platform')}
    ${layer('Backend', 'one system for all apps', ['Moqui + Mantle ERP', 'REST API', 'multi-company', 'AI: Gemini, agents, MCP']
      .map(b => chip(b, true, false)).join(''), true)}
    </body></html>`;
}

async function render(browser, out) {
  for (const focus of ['platform', 'apps']) {
    const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
    await page.setContent(html(focus));
    await page.screenshot({ path: path.join(out, `card_${focus}.png`) });
    await page.close();
  }
}

module.exports = { render };

if (require.main === module) {
  const { chromium } = require('playwright');
  (async () => {
    const browser = await chromium.launch();
    await render(browser, path.resolve(process.argv[2] || path.join(__dirname, 'out_renewal')));
    await browser.close();
  })();
}
