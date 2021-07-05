let input_org = ((process.argv[2] !== 'undefined') ? process.argv[2] : 'helsi');
let input_dst = ((process.argv[3] !== 'undefined') ? process.argv[3] : 'tahiti');
let input_dep = ((process.argv[4] !== 'undefined') ? process.argv[4] : '25112021');
let input_ret = ((process.argv[5] !== 'undefined') ? process.argv[5] : '03122021');
let out_path = ['./cache/TN', 
                input_org.substr(0,3), input_dst.substr(0,3), 
                /*(new Date().toISOString())*/].join("_");
let req_url = 'https://www.airtahitinui.com/us-en';

const max_time  = 39000;
const wait_time = 3001;
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
    await page.waitForSelector('div#processing');
    
    await page.click("#popup-text > div:nth-child(3) > button")
    
    await page.click("#edit-depart-auto");
    await page.waitFor(wait_time);
    await page.type("#edit-depart-auto", input_org, {delay:99});
    await page.waitForSelector("#ui-id-1 > li")
    await page.keyboard.press('Enter');

    await page.click("#edit-dest-to-auto");
    await page.waitFor(wait_time);
    await page.type("#edit-dest-to-auto", input_dst, {delay:99});
    await page.waitForSelector("#ui-id-2 > li")
    await page.keyboard.press('Enter');

    let the_dep = "div.calendar-day-" + input_dep.substr(0,4) + "-" + input_dep.substr(4,2) + "-" + input_dep.substr(6,2);
    let the_ret = "div.calendar-day-" + input_ret.substr(0,4) + "-" + input_ret.substr(4,2) + "-" + input_ret.substr(6,2);
    await page.click("#edit-date-de");
    await page.waitForSelector("#departCalendar > div > div.monthes");
    
    // depature date
    let status = await page.$(the_dep);
    while(status === null){
      await page.click("#departCalendar > div > div.clndr-next-button > a");
      await page.waitFor(wait_time);
      status = await page.$(the_dep);
    }
    await page.click(the_dep);
    // return Date
    status = await page.$(the_ret);
    while(status === null){
      await page.click("#departCalendar > div > div.clndr-next-button > a");
      await page.waitFor(wait_time);
      status = await page.$(the_ret);
    }
    await page.click(the_ret);
    
    await page.waitFor(wait_time);
    await page.click("#edit-book-flight-submit-atn");
    await page.waitFor(9999);





    console.log("http://yan.fi/getIt" + out_path.substr(1) + ".png");
    // saving
    await page.screenshot({path: out_path+'.png'});
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


