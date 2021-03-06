const params  = ['https://booking.qatarairways.com/nsp/views/showBooking.action?widget=QR&searchType=F&addTaxToFare=Y&minPurTime=0&upsellCallId=&allowRedemption=Y&flexibleDate=Off&bookingClass=B&tripType=R&selLang=en&fromStation=HEL&from=Helsinki&toStation=CBR&to=Helsinki&departingHidden=29-Mar-2021&departing=2021-09-29&returningHidden=17-Apr-2021&returning=2021-10-17&adults=1&children=0&infants=0&teenager=0&ofw=0&promoCode=&stopOver=NA', 'qr_tmp'];
const req_url   = params[0];
const req_name  = params[1];
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle0'};
const max_time  = 39000;
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
    defaultViewport: {width: 1920, height: 1330},
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
    await page.waitForSelector('div.flightDetail')
    
    await page.click('div.cal-btn');
    await page.waitForSelector('h3.csJHeadDeprt');
    
    out.push('<exetime>' + (new Date() - exe_start)/1000 + '</exetime>\n');
    out.push(await page.evaluate(() => document.querySelector('div#previousSearch').outerHTML));
    out.push(await page.evaluate(() => document.querySelector('div.csRight').innerHTML));

    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
  } catch (e) {	
    await page.screenshot({path: './cache/a_qr_error.png'});
    out[0] = 'error';
    out.push(e);
    filesave.writeFile('./cache/' + req_name + '.pp', out.join(), function(err) {}); 
    
  }
  
  await browser.close()
})()

// 'https://booking.qatarairways.com/nsp/views/showBooking.action?widget=QR&searchType=F&addTaxToFare=Y&minPurTime=0&upsellCallId=&allowRedemption=Y&flexibleDate=Off&bookingClass=B&tripType=R&selLang=en&fromStation=HEL&from=Helsinki&toStation=CBR&to=Helsinki&departingHidden=29-Mar-2021&departing=2021-03-29&returningHidden=17-Apr-2021&returning=2021-04-17&adults=1&children=0&infants=0&teenager=0&ofw=0&promoCode=&stopOver=NA'
// 'https://booking.qatarairways.com/nsp/views/showBooking.action?widget=MLC&searchType=S&bookingClass=B&minPurTime=null&tripType=M&allowRedemption=Y&selLang=EN&adults=1&children=0&infants=0&teenager=0&ofw=0&promoCode=&fromStation=TLL&toStation=MEL&departingHiddenMC=07-May-2021&departing=2021-05-07&fromStation=ADL&toStation=HEL&departingHiddenMC=25-May-2021&departing=2021-05-25'