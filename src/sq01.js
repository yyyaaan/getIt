const params  = ['https://www.singaporeair.com/flightsearch/externalFlightSearch.form?searchType=commercial&cabinClassCode=J&tripType=R&numAdults=1&numChildren=0&numInfant=0&affiliate_id=11075&locale=en_UK&ondCityCode%5B0%5D.origin=OSL&ondCityCode%5B0%5D.destination=MEL&ondCityCode%5B0%5D.month=12/2020&ondCityCode%5B0%5D.day=19&carrierCode=SQ&ondCityCode%5B1%5D.origin=MEL&ondCityCode%5B1%5D.destination=OSL&ondCityCode%5B1%5D.month=01/2021&ondCityCode%5B1%5D.day=02&carrierCode1=SQ', 'sq_tmp'];
const req_url   = params[0];
const req_name  = params[1];
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle0'};
const max_time  = 29000;
const ua_string = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36';
const exe_start = new Date();
var out = [];
out.push("output ok");
out.push("\n<qurl>" + req_url + '</qurl>\n<timestamp>' + (exe_start.toISOString()) + '</timestamp>\n');

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
//    await page.click('.geetest_radar_tip_content');
    await page.waitForSelector('.flight-segment-0');
    await page.click('a.monthly-view');
    await page.waitForSelector('table.fc-calendar-table');
    await page.waitFor(9000);
  
    out.push('<exetime>' + (new Date() - exe_start)/1000 + '</exetime>\n');
    out.push(await page.evaluate(() => document.querySelector('.fc-title').outerHTML));

    // saving
    await page.screenshot({path: './cache/a_sq01.png'});
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  } catch (e) {	
    out[0] = 'error';
    out.push(e);
    out.push(await page.content());
    await page.screenshot({path: './cache/a_sq01.png'});
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  }
  
  await browser.close()
})()
