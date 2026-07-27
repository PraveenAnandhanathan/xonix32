// Generates store screenshots from the REAL running game at the exact
// resolutions Play/App Store require. Each target uses a CSS viewport
// plus deviceScaleFactor so the physical screenshot lands on the exact
// pixel size with crisp integer-scaled game pixels.
const { chromium } = require('playwright');

const OUT = process.env.OUT_DIR;
const URL = 'http://127.0.0.1:8321/';

// name, cssW, cssH, dsf  (physical = css * dsf)
const TARGETS = [
  ['android-phone', 960, 540, 2], // 1920x1080
  ['ios-6.9', 956, 440, 3], // 2868x1320
  ['ios-6.5', 896, 414, 3], // 2688x1242
  ['ipad-13', 1366, 1024, 2], // 2732x2048
  ['feature', 512, 250, 2], // 1024x500 Play feature graphic
];

async function boot(page) {
  let prev = await page.screenshot();
  for (let i = 0; i < 60; i++) {
    await page.waitForTimeout(1000);
    const shot = await page.screenshot();
    if (!shot.equals(prev)) return true;
    prev = shot;
  }
  return false;
}

(async () => {
  const browser = await chromium.launch({
    executablePath: '/opt/pw-browsers/chromium',
  });

  for (const [name, w, h, dsf] of TARGETS) {
    const context = await browser.newContext({
      viewport: { width: w, height: h },
      deviceScaleFactor: dsf,
    });
    const page = await context.newPage();
    await page.goto(URL, { waitUntil: 'load' });
    const ok = await boot(page);
    console.log(name, 'booted:', ok);
    await page.waitForTimeout(1500);

    const shot = (tag) =>
      page.screenshot({ path: `${OUT}/${name}_${tag}.png` });

    // 1: splash/demo
    await shot('1_splash');

    // Start a game, catch READY?
    await page.mouse.click(w / 2, h / 2);
    await page.waitForTimeout(900);
    await shot('2_ready');
    await page.waitForTimeout(2200);

    // A capture down the middle, then carve leftward
    await page.keyboard.press('ArrowDown');
    await page.waitForTimeout(4600);
    await page.keyboard.press('ArrowLeft');
    await page.waitForTimeout(1400);
    await page.keyboard.press('ArrowUp');
    await page.waitForTimeout(1600);
    await page.keyboard.press('ArrowLeft');
    await page.waitForTimeout(1000);
    await shot('3_play');

    // High-score table overlay (F7)
    await page.keyboard.press('F7');
    await page.waitForTimeout(600);
    await shot('4_scores');
    await page.keyboard.press('F7');

    // Options overlay (F5)
    await page.keyboard.press('F5');
    await page.waitForTimeout(600);
    await shot('5_options');

    await context.close();
  }

  await browser.close();
  console.log('done');
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
