library(rvest)

the_page <- read_html("https://hok-elanto.fi/asiakasomistajapalvelu/ajankohtaista-asiakasomistajalle/")
the_h3s <- the_page %>% html_nodes("h3") %>% html_text()
the_id <- which(grepl("tuplana", the_h3s, ignore.case = TRUE))
  
  
the_block <- html_nodes(the_page, ".so-widget-sow-editor")[[the_id]]
the_text <- the_block %>% html_nodes("div.portlet-body") %>% html_text()

# send to line
gsub("\\n\\n", "", the_text[length(the_text)]) %>%
  gsub("\\n", "\\\\n", .) %>% line_to_user()

