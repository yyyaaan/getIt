const params  = ['https://booking.qatarairways.com/nsp/views/showBooking.action?widget=QR&searchType=F&addTaxToFare=Y&minPurTime=0&upsellCallId=&allowRedemption=Y&flexibleDate=Off&bookingClass=E&tripType=R&selLang=en&fromStation=HEL&from=Helsinki&toStation=CBR&to=Helsinki&departingHidden=29-Mar-2021&departing=2021-03-29&returningHidden=17-Apr-2021&returning=2021-04-17&adults=1&children=0&infants=0&teenager=0&ofw=0&promoCode=&stopOver=NA', 'qr_tmp'];
const req_url   = params[0];
const req_name  = params[1];
const out_text  = params[2];
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle0'};
const max_time  = 99000;
const ua_string = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36';
const out_meta  = "\n<qurl>" + req_url + '</qurl>\n<timestamp>' + (new Date().toISOString()) + '</timestamp>\n';

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
    await page.waitForSelector('#outbound_tripDetails1');
    
    await page.click('#flightDetailForm_outbound\\:calendarInitiator_OutBound')
    //await page.waitFor(29000);
    await page.waitForSelector('.calenderTitle');
    await page.waitForSelector('span.taxInMonthCal');

    // endpoints and extracting
    // try outer/innerHTML/Text, textContent
    
    const text1 = await page.evaluate(() => document.querySelector('#monthlyCalendarForm\\:calReturnFlow > div.modal-body').innerHTML);
    const text  = 'output ok' + out_meta + text1;
    
    // saving
    await page.screenshot({path: './cache/' + 'qr01_aaa' + '.png'});
    filesave.writeFile('./cache/' + req_name + '.txt', text, function(err) {}); 
  } catch (e) {	
    filesave.writeFile('./cache/' + req_name + '.txt', 'error' + out_meta + e, function(err) {}); 
  }
  
  await browser.close()
})()
