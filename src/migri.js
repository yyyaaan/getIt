const puppeteer = require('puppeteer');
const wait_opts = {waitUntil: 'networkidle0'};
const to_wait = 6999;
const max_time  = 19000;
const ua_string = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36';

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
    var btn_next = "#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_next";
    // (1) kansalaisuus (2) kansaliasuushakemus (3) En-ilman etukateen ole 
    // (4) Kylla-oleva passi  (5) Kylla-enter finaland (6) pvm
    var step1 = "#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_stageForm > div.processTypeRadioContainer > div:nth-child(3) > label > div.processTypeRadio__icon";
    var step2 = "#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_stageForm > div.queueCounter__list__item.js-processGuidance__viewStage > div:nth-child(4) > label";
    var step3 = "#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_stageForm > div.queueCounter__list__item.js-processGuidance__viewStage > div:nth-child(5) > label";
    var step4 = "#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_stageForm > div.queueCounter__list__item.js-processGuidance__viewStage > div:nth-child(5) > label";
    var step5 = "#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_stageForm > div.queueCounter__list__item.js-processGuidance__viewStage > div:nth-child(4) > label";
    var ttpvm = "#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_dateInput";
    var laske = "#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_stageForm > div.queueCounter__list__item.js-queueCounter__list__item > div.form-inline.col-md-4 > div > div > button";
    
    await page.goto("https://migri.fi/hakemisen-jalkeen", wait_opts);
    await page.click(step1); 
    await page.click(btn_next);
    await page.waitFor(to_wait); await page.click(step2); await page.click(btn_next);
    await page.waitFor(to_wait); await page.click(step3); await page.click(btn_next);
    await page.waitFor(to_wait); await page.click(step4); await page.click(btn_next);
    await page.waitFor(to_wait); await page.click(step5); await page.click(btn_next);
    await page.waitFor(to_wait); await page.type(ttpvm, "01.01.2021", {delay: 100});
    await page.click(laske); await page.waitFor(to_wait);
    
    var the_res = await page.evaluate(() => document.querySelector("#_fi_yja_process_guidance_calculator_controller_ApplicationCalculatorWebController_WAR_fiyjaprocessguidancecalculator_resultProcessOngoing > div:nth-child(2) > span").innerText);

    console.log(the_res);
    await page.screenshot({path: './cache/a_migri.png'});
  } catch (e) {	
    await page.screenshot({path: './cache/a_migri.png'});
    console.log(e)
  }
  
  await browser.close()
})()
