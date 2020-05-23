const req_url   = 'https://www.marriott.com/search/default.mi?roomCount=1&numAdultsPerRoom=2&fromDate=01%2F07%2F2021&toDate=01%2F14%2F2021&destinationAddress.city=Los+Angeles';
const puppeteer = require('puppeteer');

(async () => {
    
    const browser = await puppeteer.launch({
        timeout: 19000,
        headless: false, 
        ignoreHTTPSErrors: true,
        defaultViewport: {width: 1280, height: 1880},
        args: ['--no-sandbox']
    });
    
    const page = await browser.newPage();
    await page.goto(req_url);
    await page.click('button.analytics-click.js-is-roomkey-enabled.m-button.m-button-primary');
    await page.waitForSelector('a.js-view-rate-btn-link.analytics-click.l-float-right');
    await page.click('a.js-view-rate-btn-link.analytics-click.l-float-right');
    await page.waitFor(9000);
    await page.screenshot({path: './cache/zzz.png'});
    
    await browser.close()
    
})()


