const params  = ['https://all.accor.com/ssr/app/accor/rates/9924/index.en.shtml?dateIn=2022-02-06&nights=4&compositions=2&stayplus=false', 'acr_tmpx'];
const req_url   = params[0];
const req_name  = params[1];
const out_text  = params[2];
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle2'};
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
    await page.waitForSelector('.default__main');
    
    // cookie setting confirmation
    // let status = await page.$("#onetrust-close-btn-container > button > strong");
    // if(status !== null){
    //  await page.click("#onetrust-close-btn-container > button > strong");
    // }

    
    // determing availability
    var availability = await page.evaluate(() => document.querySelector('.default__main').innerText);
    if(availability.toLowerCase().search('sorry') >= 0) {
      out.push("<flag>Sold Out</flag>");
    }
    else {
      out.push("<flag>Available</flag>");
	  	out.push(await page.evaluate(() => document.querySelector('ul.rooms-list').outerHTML));
	  	out.push(await page.evaluate(() => document.querySelector('div.basket-hotel-info').outerHTML));
    }

    // saving
    await page.screenshot({path: './cache/a_acr01.png'});
		out.push('<exetime>' + (new Date() - exe_start)/1000 + '</exetime>\n');
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  } catch (e) {	
    out[0] = 'error';
    out.push(e);
    await page.screenshot({path: './cache/a_acr01.png'});
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  }
  
  await browser.close()
})()
