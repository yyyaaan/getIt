--- 

# Project Archived & Replaced by yCrawl

---

This project replace the `get` project using [puppeteer](!https://github.com/puppeteer/puppeteer/tree/v3.1.0) instead of [chromeless](!https://github.com/prisma-archive/chromeless)

Please note that the NodeJS packages are not included with possibly out-dated `package-lock.json`; install depedencies separately.

## Folder Structure

- (root): the triggers and programs + some shared ones that would be used outside this project
- src: the main codes including `R` and `js` that achieves the "goal". Utilities for Puppeteer and NodeJS are also located there.
- results: saves the organized output on daily basis.
- cache: stores the sources temporary `js` created. This folder is not under version control.

## Functions

`qr01` requires dates and destinations. Outputs are limited to lowest prices per day per flight segment.

`mrt01` requires dates, hotel meta. Outputs are detailed with conditions and types. Rates include fees and all taxes as reported. It has be recognized that the average rate was not correctly reported by mrt, and therefore, the average rate is now a calculated field.

`mrt02` requires specific URLs that composed of dates and location. It summarize all hotels' lowest advertised prices, taxes and fees inlcuded (at least expected to).

`acr01`, `hlt01` are similar with above

`ovi01` does not require parameter; results are incremental, and are saved to local only at this moment

`dog01` does not require parameter; results are repetitive.

`gflt01` requires dates, destinations, specified flight numbers. NOT recommended.

## Routines

The `scheduled.R` are executed daily, but the whole data is captured completely only once in a 4-day span. `subscheduled.R` will be fired by `scheduled.R` conditionally.

- 2020-09-30: QR&MRT tracking series replaced from Christmas 2020 to Summer 2021; QR destination removed ADL added AMS
- 2020-11-30: Added HLT for following up series. No defined series needed.
- 2020-12-07: HLT moved to US server.
- 2020-12-08: MRT tracking is now replaced by follow-up.
- 2020-12-13: QR tracking is disabled; partially replaced by follow-up.
- 2021-01-16: FSH added tracking.
- 2021-02-24: QR schedule altered due to QR website update, *output structure is affected and updated*.
- 2021-02-27: scheduled on different servers merged to single one, no function change.
- 2021-03-04: platform updated to latest (Ubuntu 20.04, Puppeteer 3.3.0)
- 2021-03-23: major change in AY running mode. *AY will be now run in a separated session*.
- 2021-06-02: AY schedule is now aligned with QR.
- 2021-09-16: pause AY and HLT; S01 optimized output.
