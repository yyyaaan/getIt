const req_url   = 'https://www.qatarairways.com/en-dk/homepage.html';
const req_froms = ['helsi', 'sydn', 'canber', 'helsi'];
const req_dates = ['22 mar 2021', '14 apr 2021'];
const puppeteer = require('puppeteer');
const filesave  = require('fs');
const wait_opts = {waitUntil: 'networkidle2'};
const ua_string = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36';

(async () => {
    // start browser    
    const browser = await puppeteer.launch({
        timeout: 19000,
        headless: false, 
        ignoreHTTPSErrors: true,
        defaultViewport: {width: 1080, height: 1330},
        args: ['--no-sandbox']
    });

    // block image and load the url
    const page = await browser.newPage();
    await page.setUserAgent(ua_string);
    await page.setRequestInterception(true);
    page.on('request', (request) => {
        if (request.resourceType() === 'image') request.abort();
        else request.continue();
    });
    await page.goto(req_url, wait_opts);
    
    // interactions
    await page.click('#booking-widget > div > label:nth-child(3)', wait_opts);
    await page.click('#T7-from');
    await page.keyboard.type(req_froms[0], {delay: 100}); 
    await page.keyboard.press('Tab');
    await page.keyboard.type(req_froms[1], {delay: 100}); 
    await page.keyboard.press('Tab');
    await page.keyboard.down('ControlLeft');
    await page.keyboard.press('KeyA');
    await page.keyboard.up('ControlLeft');
    await page.waitFor(999);
    await page.keyboard.type(req_dates[0], {delay: 100}); 
    await page.keyboard.press('Tab');

    await page.click('a#addFlight', wait_opts);
    await page.click('#T7-fromMultiFlight-Arrival1', wait_opts);
    await page.keyboard.type(req_froms[2], {delay: 100}); 
    await page.keyboard.press('Tab');
    await page.keyboard.type(req_froms[3], {delay: 100}); 
    await page.keyboard.press('Tab');
    await page.type('T7-departure_01', req_dates[1]);
    await page.keyboard.press('Tab');

    await page.click('premiumOnlydrop');
    await page.keyboar.press('ArrowDown');
    
    await page.watiFor(6000);



    // saving
    await page.screenshot({path: './cache/zzz.png'});
    filesave.writeFile('./cache/zzz.html', await page.content(), function(err) {}); 
    
    await browser.close()
})()


