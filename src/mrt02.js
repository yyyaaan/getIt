const params  = ['https://www.marriott.com/search/default.mi?roomCount=1&numAdultsPerRoom=2&fromDate=12/03/2021&toDate=12/04/2021&destinationAddress.city=Las+Vegas%2C+NV%2C+USA', 'mrt_tmp'];
const req_url   = params[0];
const req_name  = params[1];
const out_text  = params[2];
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle0'};
const max_time  = 99000;
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
    await page.click('#advanced-search-form > div > div.l-s-col-4.l-xl-col-2.l-xl-last-col.l-hsearch-find > button');
    await page.waitForSelector('#main-body-wrapper');
    
    // click with taxes and fees
    await page.click("div.rates-with-taxes-wrapper")
    await page.waitForSelector('#main-body-wrapper');
    
	  out.push(await page.evaluate(() => document.querySelector('body').innerHTML));

    // saving
    await page.screenshot({path: './cache/a_mrt02.png'});
		out.push('<exetime>' + (new Date() - exe_start)/1000 + '</exetime>\n');
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  } catch (e) {	
    out[0] = 'error';
    out.push(e);
    await page.screenshot({path: './cache/a_mrt01.png'});
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  }
  
  await browser.close()
})()
