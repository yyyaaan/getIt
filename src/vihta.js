const puppeteer = require('puppeteer');
const wait_opts = {waitUntil: 'networkidle0'};
const to_wait = 3999;
const max_time  = 19000;
const ua_string = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36';

(async () => {
  // start browser    
  const browser = await puppeteer.launch({
    headless: true, 
    ignoreHTTPSErrors: true,
    defaultViewport: {width: 600, height: 1330},
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
    let the_loc_n = process.argv[2]
    await page.goto("https://migri.vihta.com/public/migri/#/reservation", wait_opts);
    
    // Oleskelulupa
    await page.click("body > div.container.main > div.ng-scope > div > div.row.upper-content > div.col-xs-12.col-sm-4.col-lg-4.ng-scope > div:nth-child(5) > div:nth-child(2)")
    await page.click("body > div.container.main > div.ng-scope > div > div.row.upper-content > div.col-xs-12.col-sm-4.col-lg-4.ng-scope > div:nth-child(5) > div:nth-child(2) > div > div > ul > li:nth-child(4)")
    // Perhe
    await page.waitFor(to_wait)
    await page.click("body > div.container.main > div.ng-scope > div > div.row.upper-content > div.col-xs-12.col-sm-4.col-lg-4.ng-scope > div:nth-child(5) > div.ng-scope.ng-isolate-scope.ng-empty.ng-valid > div > button")
    await page.click("body > div.container.main > div.ng-scope > div > div.row.upper-content > div.col-xs-12.col-sm-4.col-lg-4.ng-scope > div:nth-child(5) > div.ng-scope.ng-isolate-scope.ng-empty.ng-valid > div > ul > li:nth-child(2)")
    // Location
    await page.waitFor(to_wait)
    await page.click("body > div.container.main > div.ng-scope > div > div.row.upper-content > div.col-xs-12.col-sm-4.col-lg-4.ng-scope > div.ng-isolate-scope.ng-empty.ng-valid > div > button")
    await page.click("body > div.container.main > div.ng-scope > div > div.row.upper-content > div.col-xs-12.col-sm-4.col-lg-4.ng-scope > div.ng-isolate-scope.ng-empty.ng-valid > div > ul > li:nth-child(" + the_loc_n + ")")
    
    // Show
    await page.waitFor(to_wait)
    await page.click("body > div.container.main > div.ng-scope > div > div.row.upper-content > div.col-xs-12.col-sm-4.col-lg-4.ng-scope > div.hidden-sm.hidden-md.hidden-lg.in.collapse > button")
    await page.waitFor(to_wait);
    await page.click("body > div.container.main > div.ng-scope > div > div.hidden-sm.hidden-md.hidden-lg.ng-scope > div > div.row.result-row.mobile-result.hidden-sm.hidden-md.hidden-lg > div > div > table > tbody > tr:nth-child(2) > td > div:nth-child(2)")
    
    
    await page.waitFor(to_wait);
    await page.screenshot({path: './cache/a_vihta.png'});

    var the_time = await page.evaluate(() => document.querySelector("body > div.container.main > div.ng-scope > div > div.hidden-sm.hidden-md.hidden-lg.ng-scope > div").innerText);
    var the_loc = await page.evaluate(() => document.querySelector("body > div.container.main > div.ng-scope > div > div.row.upper-content > div.col-xs-12.col-sm-4.col-lg-4.ng-scope > div.ng-isolate-scope.ng-valid.ng-not-empty.ng-dirty.ng-valid-parse > div > button").innerText);


    console.log(the_loc.split(":")[0] + " - " + the_time.replace(/(\r?\n)/gm, "/ "));
  } catch (e) {	
    await page.screenshot({path: './cache/a_vihta.png'});
    console.log(e)
  }
  
  await browser.close()
})()
