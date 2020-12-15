const params  = ['https://www.etuovi.com/myytavat-asunnot?haku=M1581256611', 'etuovi'];
const req_url   = params[0];
const req_name  = params[1];
const out_text  = params[2];
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle0'};
const max_time  = 19000;
const ua_string = 'Mozilla/5.0 (Linux; Android 7.0; SM-G930V Build/NRD90M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.125 Mobile Safari/537.36';
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

    await page.goto(req_url, {waitUntil: 'networkidle0'});
    await page.waitFor(2999);
    await page.click("button.almacmp-button.almacmp-button--primary-bold");
    await page.click('div[data-react-toolbox="dropdown"]');
    await page.click('ul > li:nth-child(3)');
    await page.waitFor(2999);
    
    // 1st page
    var all_data = await page.evaluate(() => {
      var all_apts = document.querySelector('div#announcement-list').querySelectorAll('a');
      var all_data = [];
      for (var i = 0; i < all_apts.length; i++) {
        all_data[i] = {
          id:   all_apts[i].getAttribute('id'),
          href: all_apts[i].getAttribute('href')
        }
      }
      return all_data;
    });
    
    var all_id = await page.evaluate(() => document.querySelector('div#announcement-list').querySelectorAll('a'));
    
    
    // 2nd Page
    await page.waitFor(3399)
    await page.click('button#paginationNext');
    all_id.concat(await page.evaluate(() => document.querySelector('div#announcement-list').querySelectorAll('a')));
    await page.waitFor(3399)
    
    // 3rd Page
    await page.waitFor(3399)
    await page.click('button#paginationNext');
    all_id.concat(await page.evaluate(() => document.querySelector('div#announcement-list').querySelectorAll('a')));
    await page.waitFor(3399)
    
  	out.push(await page.evaluate(() => document.querySelector('div#announcement-list').outerHTML));
  	console.log(all_id.length)
  	//console.log(JSON.stringify(all_id, null, 2));

    await page.screenshot({path: './cache/a_etuovi.png' , fullPage: true });
		out.push('<exetime>' + (new Date() - exe_start)/1000 + '</exetime>\n');
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  } catch (e) {	
    out[0] = 'error';
    out.push(e);
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  }
  
  await browser.close()
})()
