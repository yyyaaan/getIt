This project replace the `get` project using [puppeteer](!https://github.com/puppeteer/puppeteer/tree/v3.1.0) instead of [chromeless](!https://github.com/prisma-archive/chromeless)

Please note that the NodeJS packages are not included; install separately.

# Folder Structure

- (root): the triggers and programs + some shared ones that would be used outside this project
- src: the main codes including `R` and `js` that achieves the "goal". Utilities for Puppeteer and NodeJS are also located there.
- results: saves the organized output on daily basis.
- cache: stores the scraped webpages temporary `js` created. This folder is not under version control.

# Functions

`gflt01` requires dates, destinations, specified filght numbers. NOT recommended.

`qr01` requires dates and destinations. Outputs are limited to lowest prices.

`mrt01` requires dates, hotel metas. Outputss are detailed with conditions and types.

# Routines

The `scheduled.R` are exectued daily, but the whole data is captured completely only once in a 4-day span.