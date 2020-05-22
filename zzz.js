const req_url   = 'https://www.marriott.com/search/default.mi?roomCount=1&numAdultsPerRoom=2&fromDate=01%2F07%2F2021&toDate=01%2F14%2F2021&destinationAddress.city=Los+Angeles';
const puppeteer = require('puppeteer');

(async () => {
    
    const browser = await puppeteer.launch({
        timeout: 19000,
        headless: true, 
        ignoreHTTPSErrors: true,
        defaultViewport: {width: 1280, height: 1880},
        args: ['--no-sandbo']
    });
    
    const page = await browser.newPage();
    await page.goto(req_url);
    await page.waitFor(5000);
    await page.screenshot({path: './cache/zzz.png'});
    
    await browser.close()
    
})()


