const puppeteer = require('puppeteer');
const filesave  = require('fs');
const req_url = 'https://www.hermes.com/fi/en/category/women/bags-and-small-leather-goods/bags-and-clutches/';

async function fetch_webpage(){
  // start browser and block pictures
  const browser = await puppeteer.launch({
    headless: true, 
    ignoreHTTPSErrors: true,
    defaultViewport: {width: 1023, height: 1366},
    args: ['--no-sandbox', '--lang=en-US,en']
  });
  const page = await browser.newPage();
  await page.setUserAgent('Mozilla/5.0 (iPad; CPU OS 12_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148');
  await page.setExtraHTTPHeaders({'Accept-Language': 'en'});
  await page.setRequestInterception(true);
  page.on('request', (request) => {
    if (['image', 'stylesheet', 'font', 'script'].indexOf(request.resourceType()) !== -1) {
      request.abort();
    } else {
      request.continue();
    }
  });
  
  // read web and get data
  await page.goto(req_url, {waitUntil: 'domcontentloaded'});
  var x = await page.content();
  filesave.writeFile('hermes.pp', x, function(err) {}); 
  
  //await page.waitForSelector('div.grid-results');
  await page.waitFor(999)
  await page.screenshot({path:'results.png', fullPage: true})
  
  var x = await page.content();
  await browser.close();
  return "done";
}


(async () => {
  var all_data = await fetch_webpage();
})()

