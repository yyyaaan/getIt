/**
 * Responds to any HTTP request.
 * https://europe-west1-yyyaaannn.cloudfunctions.net/web-test?url=https%3A//www.ihg.com/intercontinental/hotels/gb/en/find-hotels/hotel/rates%3FqCiMy%3D72020%26qCiD%3D13%26qCoMy%3D72020%26qCoD%3D17%26qAdlt%3D2%26qChld%3D0%26qRms%3D1%26qRtP%3D6CBARC%26qIta%3D99502222%26qSlH%3DNANHA%26qSlRc%3DXLOG%26qAkamaiCC%3DFI%26qSrt%3DsBR%26qBrs%3Dre.ic.in.vn.cp.vx.hi.ex.rs.cv.sb.cw.ma.ul.ki.va.ii.sp.nd.ct%26qAAR%3D6CBARC%26qWch%3D0%26qSmP%3D1%26setPMCookies%3Dfalse%26qRad%3D30%26qRdU%3Dmi%26srb_u%3D1%26qSHBrC%3DIC
 * 
 * https%3A//www.google.com/flights%3Fhl%3Den%26gl%3DGB%26gsas%3D1%23flt%3DARN.NRT.2021-03-03%2ASYD.HEL.2021-03-23%3Bc%3AEUR%3Be%3A1%3Bsc%3Ab%3Bsd%3A1%3Bt%3Af%3Btt%3Am
 * htmltools::urlEncodePath
 * 
 * https://www.marriott.com/search/default.mi?roomCount=1&numAdultsPerRoom=2&fromDate=01%2F07%2F2021&toDate=01%2F14%2F2021&destinationAddress.city=Los+Angeles
 * @param {!express:Request} req HTTP request context.
 * @param {!express:Response} res HTTP response context.
 * 
 */


exports.runit = (async (req, res) => {
    const puppeteer = require('puppeteer');
    const browser = await puppeteer.launch({
        args: ['--no-sandbox']
    });


    const url = req.query.url;
    if (!url) { res.status(400).send('Invalid url');}

    try {
        const page = await browser.newPage();
        await page.goto(url, {waitUntil: 'networkidle2'});
        //const buffer = await page.screenshot({fullPage: true});
        const txt = await page.content();
        await browser.close();
        //res.type('image/png').send(buffer);
        res.send(txt);
    } catch (e) {
        await browser.close();
        res.status(500).send(e.toString());
    }
});