
library(rvest)
the_file <- "./cache/qr_tmp.txt"
the_html <- read_html(the_file)

two_routes <- the_html %>% html_nodes(".md-details")
out_df <- data.frame()

for(the_route in two_routes){
  out_df <- rbind(out_df, data.frame(
    route = the_route %>% html_nodes(".calenderTitle") %>% html_text(),
    date  = the_route %>% html_nodes(".cdate") %>% html_text(),
    price = the_route %>% html_nodes(".taxInMonthCalFnSizeAmount") %>% html_text()))
}

apply(out_df, 2, function(x) gsub("\\\t|\\\n| ", "", x))