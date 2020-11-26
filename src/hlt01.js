const params  = ['https://www.hilton.com/en/book/reservation/rooms/?ctyhocn=PPTMLHI&arrivalDate=2021-04-07&departureDate=2021-04-12&room1NumAdults=2', 'hlt_tmp'];
const req_url   = params[0];
const req_name  = params[1];
const out_text  = params[2];
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle0'};
const max_time  = 19000;
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
    await page.waitForSelector('div#__next');
    
    // determing availability - currently skipped
    var availability = "available";
    if(availability.toLowerCase().search('sold out') >= 0) {
      out.push("<flag>Sold Out</flag>");
    }
    else {
      out.push("<flag>Available</flag>");
		  await page.waitForSelector('main.relative');
	  	out.push(await page.evaluate(() => document.querySelector('main').outerHTML));
    }

    // saving
    await page.screenshot({path: './cache/a_hlt01.png'});
		out.push('<exetime>' + (new Date() - exe_start)/1000 + '</exetime>\n');
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  } catch (e) {	
    out[0] = 'error';
    out.push(e);
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  }
  
  await browser.close()
})()
