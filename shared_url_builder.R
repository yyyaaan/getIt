require(magrittr)


# common base tool --------------------------------------------------------

dest_dict <- list(HEL = "Helsinki", ARN = "Stockholm", TLL = "Tallinn",   CPH = "Copenhagen", OSL = "Oslo",
                  BRU = "Brussels", WAW = "Warsaw",    GOT = "Gotenburg", AMS = "Amsterdam", 
                  SYD = "Sydney",   CBR = "Canberra",  ADL = "Adelaide",  MEL = "Melbourne",  BNE = "Brisbane", PER = "Perth",
                  NAN = "Nadi",     NOU = "Noumea",
                  PVG = "Shanghai", HND = "Haneda",    SIN = "Singapore", TYO = "Tokyo",     HKG = "Hong Kong")

dest_revdict <- as.list(names(dest_dict))
names(dest_revdict) <- tolower(dest_dict)

shared_encode_url <- function(prefix, suffix, params, sep_par = "&", sep_eq = "="){
  params %>% 
    paste (names(.), ., sep = sep_eq) %>% 
    paste (collapse = sep_par) %>%
    paste0(prefix, ., suffix)  
}

shared_validate_url_inputs <- function(dates, dests, allow_n = 0){
  if(allow_n >0 && !length(dates) == allow_n)
    stop(paste("Only", allow_n, "legs are valid. Check parameters"))
  if(!length(dates) == length(dests)/2) 
    stop("#dates and #dests mismatch. Dests should be 2 times the number dates.")
  
}
  
html_markup <- function(url, display){
  sprintf('<a href="%s" target="_blank">%s</a>', url, display)
}

# url generator -----------------------------------------------------------

flight_url_qatar_2legs <-  function(dates, dests, cabin = "B"){
  
  shared_validate_url_inputs(dates, dests, 2)
  
  # return and multi-trip need differentiate
  if(dests[3] != dests[2] || dests[1] != dests[4]){
    params <- list( widget = "MLC",
                    searchType = "S",
                    bookingClass = cabin,
                    minPurTime = "null",
                    tripType = "M",
                    allowRedemption = "Y",
                    selLang = "EN",
                    adults = "1",
                    children = "0",
                    infants = "0",
                    teenager = "0",
                    ofw = "0",
                    promoCode = "",
                    fromStation = dests[1],
                    toStation = dests[2],
                    departingHiddenMC = dates[1] %>% format.Date("%d-%b-%Y"),
                    departing = dates[1] %>% format.Date("%Y-%m-%d"),
                    fromStation = dests[3],
                    toStation = dests[4],
                    departingHiddenMC = dates[2] %>% format.Date("%d-%b-%Y"),
                    departing = dates[2] %>% format.Date("%Y-%m-%d"))
  }
  
  if(dests[2] == dests[3] && dests[1] == dests[4]){
    
    params <- list(widget = "QR",
                   searchType = "F",
                   addTaxToFare = "Y",
                   minPurTime = "0",
                   upsellCallId = "",
                   allowRedemption = "Y",
                   flexibleDate = "Off",
                   bookingClass = cabin,
                   tripType = "R",
                   selLang = "en",
                   fromStation = dests[1],
                   from = dest_dict[dests[1]] %>% unlist(),
                   toStation = dests[2],
                   to = dest_dict[dests[1]] %>% unlist(),
                   departingHidden = dates[1] %>% format.Date("%d-%b-%Y"),
                   departing = dates[1] %>% format.Date("%Y-%m-%d"),
                   returningHidden = dates[2] %>% format.Date("%d-%b-%Y"),
                   returning = dates[2] %>% format.Date("%Y-%m-%d"),
                   adults = "1",
                   children = "0",
                   infants = "0",
                   teenager = "0",
                   ofw = "0",
                   promoCode = "",
                   stopOver = "NA")
  }
  
  shared_encode_url(prefix = "https://booking.qatarairways.com/nsp/views/showBooking.action?",
                    suffix = "",
                    params = params,
                    sep_par = "&",
                    sep_eq  = "=")
}

flight_url_singapore_return <-  function(dates, dests, cabin = "B"){
  
  # only supports return trip, dests[3:4] are not used since return trip is supposed
  
  params <- list(cabinClassCode = ifelse(cabin == "B", "J", "Y"),
                 tripType       = "R",
                 numAdults      = 1,
                 numChildren    = 0,
                 numInfant      = 0,
                 affiliate_id   = 11075,
                 locale         = "en_UK",
                 #countryCode                      = "NO",
                 `ondCityCode%5B0%5D.origin`      = dests[1],
                 `ondCityCode%5B0%5D.destination` = dests[2],
                 `ondCityCode%5B0%5D.month`       = format(dates[1], "%m/%Y"), 
                 `ondCityCode%5B0%5D.day`         = format(dates[1], "%d"),
                 #flightNumber                     = "2651_351_241",
                 #bookingCode                      = ifelse(cabin == "B", "D", "W"),
                 carrierCode                      = "SQ",
                 `ondCityCode%5B1%5D.origin`      = dests[2],
                 `ondCityCode%5B1%5D.destination` = dests[1],
                 `ondCityCode%5B1%5D.month`       = format(dates[2], "%m/%Y"), 
                 `ondCityCode%5B1%5D.day`         = format(dates[2], "%d"),
                 #flightNumber1                    = "212_352_2638",
                 #bookingCode1                     = ifelse(cabin == "B", "D", "K"),
                 carrierCode1                     = "SQ")

  shared_encode_url(prefix = "https://www.singaporeair.com/flightsearch/externalFlightSearch.form?searchType=commercial&",
                    suffix = "",
                    params = params,
                    sep_par = "&",
                    sep_eq  = "=")
}

flight_url_finnair_any <- function(dates, dests, cabin = "B"){
  
  shared_validate_url_inputs(dates, dests, 0)
  
  params = list(B_DATES     = dates %>% format.Date("%Y%m%d0000") %>% paste(collapse = ":"),
                E_DATES     = "",
                B_LOCS      = dests[seq(1, length(dests), by = 2)] %>% paste(collapse = ":"),
                E_LOCS      = dests[seq(2, length(dests), by = 2)] %>% paste(collapse = ":"),
                MAIN_PAX    = "ADT",
                NB_MAIN_PAX = "1",
                NB_CHD      = "0",
                NB_INF      = "0",
                CABIN       = cabin,
                IS_FLEX     = "false",
                IS_AWARD    = "false")
  
  
  shared_encode_url(prefix = "https://www.finnair.com/FI/GB/deeplink?PREFILLED_INPUT=TRIP_TYPE=multiple|",
                    suffix = "&utm_source=meta-search-engine&utm_medium=deeplink",
                    params = params,
                    sep_par  = "|",
                    sep_eq  = "=")
  
}

flight_url_cwt_3legs <- function(dates, dests){
  
  shared_validate_url_inputs(dates, dests, 3)
  
  dates_ok <- dates %>% format.Date("%d/%m/%Y")
  
  params <- list(DepartureDate  = dates_ok[1],
                 DepartureDate1 = dates_ok[2],
                 DepartureDate2 = dates_ok[3],
                 FlightType     = "MultiLeg",
                 From           = dests[1],
                 From1          = dests[3],
                 From2          = dests[5],
                 Method         = "Search",
                 ProviderList   = "OnlyAmadeus",
                 QFrom          = "A",
                 QFrom1         = "A",
                 QFrom2         = "C",
                 QTo            = "A",
                 QTo1           = "A",
                 QTo2           = "C",
                 To             = dests[2],
                 To1            = dests[4],
                 To2            = dests[6])
  
  shared_encode_url(prefix = "https://www.epower.amadeus.com/CWTKalevaTravel/#AdtCount=1&Culture=fi-FI&",
                    suffix = "",
                    params = params,
                    sep_par  = "&",
                    sep_eq  = "=")  
}

flight_url_google_any <- function(dates, dests){
  
  shared_validate_url_inputs(dates, dests, 0)
  
  # google flights has different params, and it supports any number of legs
  
  dates_ok = dates %>% format.Date("%Y-%m-%d")
  from     = dests[seq(1, length(dests), 2)]
  to       = dests[seq(2, length(dests), 2)]
  coded    = paste(from, to, dates_ok, sep = ".") %>% paste0(collapse = "*")
  
  shared_encode_url(prefix = "https://www.google.com/flights?hl=en&gl=GB&gsas=1#",
                    suffix = ";c:EUR;e:1;sd:1;t:f;tt:m",
                    params = list(flt = coded),
                    sep_par  = "&",
                    sep_eq  = "=")
}

flight_url_google_given <- function(base_url, dates){
  locs <- gregexpr("\\d{4}-\\d{2}-\\d{2}", base_url)[[1]]
  substr(base_url, locs[1], locs[1]+9) <- format.Date(dates[1], "%Y-%m-%d")
  substr(base_url, locs[2], locs[2]+9) <- format.Date(dates[2], "%Y-%m-%d")
  return(base_url)
}

hotel_url_marriott <- function(dates, country, city, extra = NA){

  shared_validate_url_inputs(dates, character(4), 2)
  
  params = list(roomCount        = "1",
                numAdultsPerRoom = "2",
                fromDate         = dates[1] %>% as.Date() %>% format.Date("%m/%d/%Y"),
                toDate           = dates[2] %>% as.Date() %>% format.Date("%m/%d/%Y"),
                countryName      = country,
                destinationAddress.city = gsub(" ", "+", city))
  
  if(!is.na(extra) && length(extra)==2) {
    params[['destinationAddress.longitude']] <- extra[1]
    params[['destinationAddress.latitude']]  <- extra[2]
  }
  
  shared_encode_url(prefix  = "https://www.marriott.com/search/default.mi?",
                    suffix  = "",
                    params  = params,
                    sep_par = "&",
                    sep_eq  = "=")
}

hotel_url_accor <- function(dates, country, city, extra = NA){
  
  shared_validate_url_inputs(dates, character(4), 2)
  
  params = list(dateIn = dates[1] %>% as.Date() %>% format.Date("%Y-%m-%d"),
                nights = as.Date(dates[2]) - as.Date(dates[1]),
                compositions = 2,
                stayplus = "false")

  prefix = sprintf("https://all.accor.com/ssr/app/accor/hotels/%s-%s/index.en.shtml?", 
                   gsub(" ", "-", city), 
                   gsub(" ", "-", country))
  
  shared_encode_url(prefix  = prefix,
                    suffix  = "",
                    params  = params,
                    sep_par = "&",
                    sep_eq  = "=")
  
}

hotel_url_hilton <- function(dates, code, extra = NA){

  shared_validate_url_inputs(dates, character(4), 2)
  
  params = list(ctyhocn = code,
                arrivalDate = dates[1] %>% as.Date() %>% format.Date("%Y-%m-%d"),
                departureDate = dates[2] %>% as.Date() %>% format.Date("%Y-%m-%d"),
                room1NumAdults = 2)
  
  prefix = "https://www.hilton.com/en/book/reservation/rooms/?"
  
  shared_encode_url(prefix  = prefix,
                    suffix  = "",
                    params  = params,
                    sep_par = "&",
                    sep_eq  = "=")
  
  
}

hotel_url_ihg <- function(dates, dest, code, extra = NA){
  
  shared_validate_url_inputs(dates, character(4), 2)
  
  # ihg input month is 1 less
  mon <- dates %>% as.Date() %>% format.Date("%m") %>% as.numeric() - 1
  yr  <- dates %>% as.Date() %>% format.Date("%Y")
  
  params = list(fromRedirect = "true",
                qSrt  = "sBR",
                qDest = dest,
                qSlH  = code,
                qRms  = "01",
                qAdlt = "02",
                qChld = "00",
                qCiD  = dates[1] %>% as.Date() %>% format.Date("%d"),
                qCiMy = sprintf("%02d%s", mon[1], yr[1]),
                qCoD  = dates[2] %>% as.Date() %>% format.Date("%d"),
                qCoMy = sprintf("%02d%s", mon[1], yr[1]),
                setPMCookies = "false")
                # skipped pars qAAR = "6CBARC", qRtP = "6CBARC", qSHBrC = "IC", srb_u = "1"
  
  shared_encode_url(prefix  = "https://www.ihg.com/intercontinental/hotels/gb/en/find-hotels/hotel/rooms?",
                    suffix  = "",
                    params  = params,
                    sep_par = "&",
                    sep_eq  = "=")
}


# higher level function for convenience -----------------------------------

flight_url_qatar_by_data <- function(route, ddate, rdate){
  
  x <- route %>% tolower() %>% str_split(" |\\|", simplify = TRUE) %>% .[1, ]
  flight_url_qatar_2legs(dates = c(ddate, rdate),
                         dests = c(dest_revdict[[x[1]]], dest_revdict[[x[2]]], dest_revdict[[x[3]]], dest_revdict[[x[4]]]))
}


# calling example ---------------------------------------------------------

run_example <- function(){
  
  # 2-leg flights
  dates2 = as.Date(c("2021-01-05", "2021-01-25"))
  dests2 = c("HEL", "PVG", "PEK", "HEL")
  
  flight_url_finnair_2legs(dates2, dests2) %>% cat()
  flight_url_qatar_2legs  (dates2, dests2) %>% cat()  
  flight_url_google_any   (dates2, dests2) %>% cat()
  
  # 3-leg flights
  dates = as.Date(c("2021-01-08", "2021-01-18", "2021-01-20"))
  dests = c("HEL", "NAN", "SYD", "HKG", "HKG", "HEL")
  
  flight_url_cwt_3legs    (dates3, dests3) %>% cat()
  flight_url_google_any   (dates3, dests3) %>% cat()  
  
  # Google Fligth given flt.no. / may get blocked
  flight_url_google_given(base_url = 'https://www.google.com/flights?hl=en&gl=FI&gsas=1#flt=AMS.SYD.2021-03-30.AMSDOH0QR274~DOHSYD1QR906*SYD.HEL.2021-04-16.SYDDOH0QR907~DOHHEL1QR303;c:EUR;e:1;sc:b;sd:1;t:b;tt:m',
                          dates = as.Date(c('2021-02-05', '2021-02-27'))) %>% cat()
  
  # hotel dates are c(check-in check-out)
  dates = as.Date(c("2021-03-05", "2021-03-07"))
  
  hotel_url_marriott(dates, "AU", "Sydney")
  hotel_url_marriott(dates, 
                     country = "PF", 
                     city    = "Bora Bora", # parse lat,log for ordering
                     extra   = c(-151.736641, -16.497324)) 
  
  hotel_url_ihg(dates, 
                dest = "InterContinental%20Los%20Angeles%20Century%20City,%20Los%20Angeles,%20CA,%20United%20States",
                code = "LAXHA") %>% cat()
  
  hotel_url_accor(dates, 
                  country = "France",
                  city = "Nice") %>% cat()
  
  hotel_url_hilton(dates,
                   code = "PPTMLHI") %>% cat()  
}

