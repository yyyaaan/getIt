This project replace the `get` project using [puppeteer](!https://github.com/puppeteer/puppeteer/tree/v3.1.0) instead of [chromeless](!https://github.com/prisma-archive/chromeless)

Please note that the NodeJS packages are not included; install separately.

# Folder Structure

- (root): the triggers and programs + some shared utilities that would be used outside this project
- src: the main codes including `R` and `js` that achieves the "goal""
- cache: stores the scraped webpages temporary `js` created. This folder is not under version control.

# Functions

`gflt01` requires dates, destinations, specified filght numbers


