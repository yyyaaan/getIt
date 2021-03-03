library(rvest)
library(tidyverse)

all_breeds <- read_html("https://www.hankikoira.fi/koirarodut") %>% html_nodes("span.breed")
all_puppies <- data.frame()

for(the_breed in all_breeds){
  the_nodes <- the_breed %>% html_children()
  
  # puppy found
  if(length(the_nodes) - 1){
    the_link <- html_attr(the_nodes[[1]], "href")
    the_page <- read_html(paste0("https://www.hankikoira.fi", the_link))
    the_name <- the_page %>% html_nodes("#block-hk-puppies-breeds-available-puppies > div > h3") %>% html_text()
    the_tbls <- the_page %>% html_table()
    for(the_tbl in the_tbls){
      the_tbl$nimi <- the_name
      all_puppies <- rbind(all_puppies, the_tbl[the_tbl$Kennel != "Yhteensä:",])
    }
  } 
}

all_puppies %>% 
  add_column(tss = Sys.Date()) %>%
  rbind(readRDS("./results/puppies.rds")) %>%
  distinct_all() %>%
  saveRDS("./results/puppies.rds")
