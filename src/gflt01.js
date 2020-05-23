const req_url   = 'https://www.google.com/flights?hl=en&gl=FI&gsas=1#flt=AMS.SYD.2021-03-31.AMSDOH0QR274~DOHSYD1QR906*SYD.HEL.2021-04-13.SYDDOH0QR907~DOHHEL1QR303;c:EUR;e:1;sc:b;sd:1;t:b;tt:m';
const req_name  = 'zzz'; 
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle0'};
const max_time  = 9000;
const ua_string = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36';

(async () => {
  // start browser    
  const browser = await puppeteer.launch({
    headless: true, 
    ignoreHTTPSErrors: true,
    defaultViewport: {width: 1080, height: 1330},
    args: ['--no-sandbox']
  });
  
  // block image and load the url
  const page = await browser.newPage();
  await page.setUserAgent(ua_string);
  await page.setDefaultTimeout(max_time);
  await page.setDefaultNavigationTimeout(max_time);
  await page.setRequestInterception(true);
  page.on('request', (request) => {
    if (request.resourceType() === 'image') request.abort();
    else request.continue();
  });
  
  try {
    await page.goto(req_url, wait_opts);
    
    // try to click "reload" on one failure, otherwise giveup.
    try {
      await page.waitForSelector('div.flt-headline6.gws-flights-book__booking-options-heading');
    } catch (e) {
      if (e instanceof puppeteer.errors.TimeoutError) await page.click('fill-button');
      await page.waitForSelector('div.flt-headline6.gws-flights-book__booking-options-heading');
    }
    
    const text1 = await page.evaluate(() => document.querySelector('ol').outerHTML);
    const text2 = await page.evaluate(() => document.querySelector('table').outerHTML);
    const text  = text1 + text2;
    
    await page.screenshot({path: './cache/' + req_name + '.png'});
    filesave.writeFile('./cache/' + req_name + '.txt', text, function(err) {}); 
  } catch (e) {	
    filesave.writeFile('./cache/' + req_name + '.txt', 'error\n'+e, function(err) {}); 
  }
  
  await browser.close()
})()