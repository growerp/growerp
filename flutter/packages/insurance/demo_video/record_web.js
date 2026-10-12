// Customer side of the renewal demo video, recorded with Playwright (npm i playwright):
// the Zalo reminder preview and the renewal page as phone-size videos, the AI call as a
// still per turn with the assistant's own speech, and the title/problem/close cards.
// Waits for out_renewal/links.json (written by integration_test/renewal_video_test.dart),
// writes out_renewal/web_done when finished so the staff scenes continue.
// Usage: node record_web.js [outDir]
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
const overview = require('./overview_cards');

const out = path.resolve(process.argv[2] || path.join(__dirname, 'out_renewal'));
const sleep = ms => new Promise(r => setTimeout(r, ms));
const phone = { width: 420, height: 760 };

const cards = {
  title: ['GrowERP Insurance × Tasco', 'Renewal that customers are glad to act on',
          'The right reminder · the right moment · the right channel · a person when wanted'],
  problem: ['Same cover. Same price.', 'TNDS renewal is won on timing, clarity and an easy next step',
            'never on discounts'],
  voiceintro: ['AI call, in Vietnamese', 'Permission first · vehicle check · answers from the policy · hand-over',
               'Subtitles: English translation of the call'],
  close: ['People decide. AI assists.', 'Explainable scores · consent and opt-out at every step',
          'Free & open source — pay only for production, enhancements and support'],
};

async function card(browser, id) {
  const [h1, h2, small] = cards[id];
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  await page.setContent(`<html><body style="margin:0;width:1280px;height:720px;display:flex;flex-direction:column;
    justify-content:center;padding:0 110px;box-sizing:border-box;background:${id === 'close' ? '#1B7F66' : '#14233B'};
    color:#F7F5EF;font-family:Georgia,serif">
    <div style="font:600 22px Arial,sans-serif;letter-spacing:3px;text-transform:uppercase;color:#E3A13B">Tasco × GenAI Fund · AI for Insurance</div>
    <div style="font-size:68px;font-weight:700;margin:24px 0 18px;line-height:1.1">${h1}</div>
    <div style="font:400 32px Arial,sans-serif;color:#C9D6E0;line-height:1.4">${h2}</div>
    <div style="font:400 24px Arial,sans-serif;color:#C9D6E0;margin-top:28px">${small}</div></body></html>`);
  await page.screenshot({ path: path.join(out, `card_${id}.png`) });
  await page.close();
}

async function phoneVideo(browser, name, url, actions) {
  const context = await browser.newContext({ viewport: phone, deviceScaleFactor: 1,
    recordVideo: { dir: path.join(out, 'pw'), size: phone } });
  const page = await context.newPage();
  await page.goto(url);
  await actions(page);
  const video = page.video();
  await context.close();
  fs.renameSync(await video.path(), path.join(out, `web_${name}.webm`));
}

(async () => {
  const linksFile = path.join(out, 'links.json');
  while (!fs.existsSync(linksFile)) await sleep(1000);
  const links = JSON.parse(fs.readFileSync(linksFile, 'utf8'));
  const browser = await chromium.launch({ args: ['--autoplay-policy=no-user-gesture-required'] });

  for (const id of Object.keys(cards)) await card(browser, id);
  await overview.render(browser, out);

  await phoneVideo(browser, 'zalo', links.previewUrl, async page => {
    await sleep(4000);
    await page.mouse.wheel(0, 300);
    await sleep(4000);
  });

  const clean = (links.plate || '').replace(/[^A-Za-z0-9]/g, '');
  await phoneVideo(browser, 'renew', links.renewalUrl, async page => {
    await sleep(2500);
    await page.click('#plateEnd');
    await page.keyboard.type(clean.slice(-3), { delay: 350 });
    await sleep(800);
    await page.click('#confirmBtn');
    await sleep(2500);
    await page.mouse.wheel(0, 380);
    await sleep(3000);
    await page.mouse.wheel(0, 420);
    await sleep(3500);
    await page.mouse.wheel(0, -800);
    await sleep(1200);
    await page.click('#renewBtn');
    await sleep(3500);
  });

  // the AI call: a still after every line, the assistant's speech from its responses
  const callPlate = (links.callPlate || '').replace(/[^A-Za-z0-9]/g, '');
  const script = ['Dạ, được ạ', `Ba ký tự cuối là ${callPlate.slice(-3)}`,
    'Bảo hiểm này bồi thường tối đa bao nhiêu cho người bị thương?',
    'Cho tôi nói chuyện với nhân viên tư vấn'];
  const page = await browser.newPage({ viewport: phone });
  const turns = [];
  let shot = 0;
  await page.exposeFunction('onBubble', async (role, text) => {
    await sleep(150);
    const file = `voice_${String(++shot).padStart(2, '0')}.png`;
    await page.screenshot({ path: path.join(out, file) });
    turns.push({ role, text, still: file });
  });
  page.on('response', async resp => {
    if (!resp.url().includes('/VoiceBot')) return;
    try {
      const json = await resp.json();
      if (json.audio) {
        const file = `voice_bot_${String(turns.length + 1).padStart(2, '0')}.wav`;
        fs.writeFileSync(path.join(out, file), Buffer.from(json.audio, 'base64'));
        turns.push({ role: 'audio', text: json.reply, audio: file });
      }
    } catch (e) { /* not json */ }
  });
  await page.goto(`${links.voiceCallUrl}?script=${encodeURIComponent(script.join('|'))}`);
  await page.evaluate(() => {
    new MutationObserver(ms => ms.forEach(m => m.addedNodes.forEach(n => {
      if (n.classList && n.classList.contains('b')) window.onBubble(n.classList.contains('me') ? 'customer' : 'ai', n.textContent);
    }))).observe(document.getElementById('log'), { childList: true });
  });
  await page.screenshot({ path: path.join(out, 'voice_00.png') });
  await page.click('#startBtn');
  for (let i = 0; i < 360; i++) {
    if (await page.isVisible('#outcome')) break;
    await sleep(500);
  }
  await sleep(1500);
  await page.screenshot({ path: path.join(out, 'voice_end.png') });
  fs.writeFileSync(path.join(out, 'voice_turns.json'), JSON.stringify({ script, turns }, null, 2));
  await browser.close();
  fs.writeFileSync(path.join(out, 'web_done'), 'done');
  console.log('WEB_DONE');
})();
