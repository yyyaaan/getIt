const params  = ['https://www.etuovi.com/myytavat-asunnot?haku=M1581256611', 'etuovi'];
const req_url   = params[0];
const req_name  = params[1];
const maxn = 39;
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
    
    // sorting: uusimmat ensin (ilmoitettu)
    await page.click("button.almacmp-button.almacmp-button--primary-bold");
    await page.click('div[data-react-toolbox="dropdown"]');
    await page.click('ul > li:nth-child(3)');
    await page.screenshot({path: './cache/etuovi.png' , fullPage: true });

    var all_data = [];
    for (var i = 0; i < maxn; i++) {
        await page.waitFor(3399)
        
        var this_data = await page.evaluate(() => {
            var all_apts = document.querySelector('div#announcement-list').querySelectorAll('a');
            var this_data = [];
            for (var i = 0; i < all_apts.length; i++) {
                this_data[i] = {
                    id:   all_apts[i].getAttribute('id'),
                    href: all_apts[i].getAttribute('href')
                }
            }
            return this_data;
        });
        
        all_data = all_data.concat(this_data);
        console.log("Completed "+ i);
        await page.click('button#paginationNext');
    }
        
    
  	out.push(JSON.stringify(all_data, null, 2));
    console.log(all_data.length);

    await page.screenshot({path: './cache/etuovi.png' , fullPage: true });
  	out.push('<exetime>' + (new Date() - exe_start)/1000 + '</exetime>\n');
    filesave.writeFile("./cache/" + req_name + '.pp', out.join(), function(err) {}); 
  } catch (e) {	
    out[0] = 'error';
    out.push(e);
    filesave.writeFile("./cache/" + req_name + '.pp', out.join(), function(err) {}); 
  }
  
  await browser.close()
})()
