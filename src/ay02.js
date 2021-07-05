let input_org = ((process.argv[2] !== 'undefined') ? process.argv[2] : 'helsi');
let input_dst = ((process.argv[3] !== 'undefined') ? process.argv[3] : 'tahiti');
let input_dep = ((process.argv[4] !== 'undefined') ? process.argv[4] : '25112021');
let input_ret = ((process.argv[5] !== 'undefined') ? process.argv[5] : '03122021');
let out_path = ['./cache/ay/AY', 
                input_org.substr(0,3), input_dst.substr(0,3), 
                (new Date().toISOString())].join("_");
let req_url = 'https://www.finnair.com/en';

const max_time  = 39000;
const wait_time = 2999;
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle0'};
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
    await page.waitForSelector('div.locations');
    
    await page.click('div.bw-origin');
    await page.waitForSelector('#origin-input');
    await page.type('#origin-input', input_org, {delay:99});
    await page.waitForSelector("#origin-locations-0 > div > div > div.ts-xsmall.capitalize")
    await page.keyboard.press('Enter');
    
    await page.waitFor(wait_time);
    
    await page.click('div.bw-destination');
    await page.waitForSelector('#destination-input');
    await page.type('#destination-input', input_dst, {delay:99});
    await page.waitForSelector("#destination-locations-0 > div > div > div.ts-xsmall.capitalize")
    await page.keyboard.press('Enter');
    
    await page.waitFor(wait_time);
    
    await page.click('div.bw-departure');
    await page.waitForSelector('#bw-departureInput');
    await page.type('#bw-departureInput', input_dep, {delay:139});
    await page.keyboard.press('Tab');
    await page.waitFor(wait_time);
    await page.type('#bw-returnInput', input_ret, {delay:139});
    await page.keyboard.press('Tab');
    
    // is it already flixble dates?
    const opt_txt = await page.evaluate(() => document.querySelector("body > fin-app > div > fin-set-language > span > fin-layout > main > fin-front-page > fin-booking-entry > div > div > fin-booking-widget > div > div > div.relative.bw-vertical-content.pr-xlarge-y.padding-left-gutter.flex.flex--wrap > div > div.relative > div:nth-child(2) > div > div.bw-42.white-bg.fill.bw-43 > div > div.ps-large-x.bw-47.flex--nogrow.ice-10-bg.fill.ps-small-y.flex--center.bw-48.flex.flex--middle.fill > div > div > div.bw-91.flex").innerText);
    
    if(opt_txt.includes("Direct")){
      await page.click('body > fin-app > div > fin-set-language > span > fin-layout > main > fin-front-page > fin-booking-entry > div > div > fin-booking-widget > div > div > div.relative.bw-vertical-content.pr-xlarge-y.padding-left-gutter.flex.flex--wrap > div > div.relative > div:nth-child(2) > div > div.bw-42.white-bg.fill.bw-43 > div > div.ps-large-x.bw-47.flex--nogrow.ice-10-bg.fill.ps-small-y.flex--center.bw-48.flex.flex--middle.fill > div > div > div.bw-91.flex > div:nth-child(2)')
    }

    await page.click('body > fin-app > div > fin-set-language > span > fin-layout > main > fin-front-page > fin-booking-entry > div > div > fin-booking-widget > div > div > div.relative.bw-vertical-content.pr-xlarge-y.padding-left-gutter.flex.flex--wrap > div > div.relative > div:nth-child(2) > div > div.bw-42.white-bg.fill.bw-43 > div > div.ps-large-x.bw-47.flex--nogrow.ice-10-bg.fill.ps-small-y.flex--center.flex.flex--middle.fill > button')


    await page.waitFor(wait_time);
    
    await page.click('body > fin-app > div > fin-set-language > span > fin-layout > main > fin-front-page > fin-booking-entry > div > div > fin-booking-widget > div > div > div.relative.bw-vertical-content.pr-xlarge-y.padding-left-gutter.flex.flex--wrap > div > div.relative > div.bw-selections.bw-5.pr-medium.rounded-medium > div.bw-cta.callToAction > button > div > span');
    
    
    // the 7-day table
    const the_element = 'div.flex-1.white-bg.fill.ps-xsmall-b';
    await page.waitForSelector(the_element);
    await page.waitFor(999); //let the transition complete
    const element = await page.$(the_element);
    await element.screenshot({path: out_path +'.png'});
    const tbl_txt = (await page.evaluate(() => document.querySelector('div.flex-1.white-bg.fill.ps-xsmall-b').innerHTML));
    out.push(tbl_txt);
    

    console.log("http://yan.fi/getIt" + out_path.substr(1) + ".png");
    // saving
		out.push('<exetime>' + (new Date() - exe_start)/1000 + '</exetime>\n');
    filesave.writeFile(out_path + '.pp', out.join(), function(err) {}); 
  } catch (e) {	
    out[0] = 'error';
    out.push(e);
    await page.screenshot({path: out_path+'_XXX.png'});
    filesave.writeFile(out_path + '.pp', out.join(), function(err) {}); 
  }
  
  await browser.close()
})()


