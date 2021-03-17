library(rvest)
library(tidyverse)
source("./src/utilities.R")

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
    
    if(length(the_name) == length(the_tbls)){
      for(i in 1:length(the_tbls)){
        the_tbl <- the_tbls[[i]]
        the_tbl$nimi <- the_name[i]
        all_puppies <- rbind(all_puppies, the_tbl[the_tbl$Kennel != "Yhteensä:",])
      }
    }
  } 
}

cat(nrow(all_puppies), "Puppies\n")

final_df <- all_puppies %>% 
  rename(Kasvattajat = `Kasvattaja(t)`) %>%
  add_column(tss =Sys.Date()) 

# today's dogs, it INCLUDES duplicate from previous days
saveRDS(final_df, file = paste0("./results/dog01_", Sys.time() %>% format("%Y%m%d_%H%M"), ".rds"))
util_bq_upload(final_df, "DOG01", silent = TRUE)


all_puppies %>% 
  rbind(readRDS("./results/puppies.rds")) %>%
  distinct_all() %>%
  saveRDS("./results/puppies.rds")

