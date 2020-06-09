/**
 * Responds to any HTTP request.
 * @param {!express:Request} req HTTP request context.
 * @param {!express:Response} res HTTP response context.
 * 
 */
 

 // GCP saving
const {Storage} = require('@google-cloud/storage');
const gcs_option = {resumable: false, metadata: {contentType: 'application/text'}};
let gcs;

async function writeToGcs(filename, content) {
  gcs = gcs || new Storage();
  const bucket = gcs.bucket("getit-bucket");
  const file = bucket.file(filename);
  const gcs_filename = `gs://${bucket.name}/${file.name}`

  const stream = file.createWriteStream(gcs_option);
  return new Promise((resolve, reject) => {
    stream.end(content);
    stream.on('error', (err) => {
      console.error('Error writing GCS file: ' + err);
      reject(err);
    });
    stream.on('finish', () => {
      console.log('Created object: '+gcs_filename);
      resolve(200);
    });
  });
}


const max_time  = 39000;
const puppeteer = require('puppeteer');
const wait_opts = {waitUntil: 'networkidle0'};
const ua_string = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36';
const out_meta  = "\n<qurl>" + req_url + '</qurl>\n<timestamp>' + (new Date().toISOString()) + '</timestamp>\n';  

exports.runit = (async (req, res) => {

  const req_url   = req.query.url;
  const req_name  = req.query.name;
  if (!req_name) {res.status(400).send('Invalid name');}
  if (!req_url)  {res.status(400).send('Invalid url');}

  
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
    await writeToGcs(req_name + '.pp', text)
  } catch (e) {	
    filesave.writeFile('./cache/' + req_name + '.pp', 'error' + out_meta + e, function(err) {}); 
    await writeToGcs(req_name + '.pp', 'error' + out_meta + e)
  }
  
});