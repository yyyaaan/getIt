const url ='https://www.marriott.com/search/default.mi?roomCount=1&numAdultsPerRoom=2&fromDate=01%2F07%2F2021&toDate=01%2F14%2F2021&destinationAddress.city=Isle+of+Pines%2C+New+Caledonia';
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  await page.goto(url);
  await page.screenshot({path: './cache/zzz.png'});

  await browser.close();
})();