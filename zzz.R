# https://cloud.google.com/bigquery/docs/reference/bq-cli-reference
# https://cloud.google.com/bigquery/docs/loading-data-local#loading_data_from_a_local_data_source
system("bq query --location='europe-north1' --use_legacy_sql=false \\
       'select tss, count(*) from `yyyaaannn.Explore.LUMO01` group by tss'")



library(jsonlite)
library(tidyverse)

stream_out(df[101:200,], con = file('./to_load.txt'))

data.frame(name = colnames(df),
           type = sapply(df, typeof)) %>%
  mutate(type = case_when(name %in% c("ddate", "tss") ~ "DATE",
                          type == "character" ~ "STRING",
                          type == "double" ~ "FLOAT64",
                          TRUE ~ type)) %>%
  toJSON(pretty = T) %>%
  writeLines('schema.json')


system("bq load \\
        --source_format=NEWLINE_DELIMITED_JSON \\
        yyyaaannn:Explore.AYT \\
        ./to_load.txt \\
        ./schema.json")



# ay01 --------------------------------------------------------------------



## below code does NOT check ts/tss
df_day <- df %>% 
  group_by(route, inout, from, to, ddate) %>%
  summarise(eur = min(eur)) %>% 
  left_join(df) %>%             
  group_by(route, inout, from, to, ddate) %>%
  summarise(eur = min(eur), fare = toString(unique(fare)))

df_route <- df_day %>% 
  filter(inout == "Outbound") %>%
  left_join(df %>% filter(inout == "Inbound") %>% 
              select(route, rdate=ddate, eur2=eur, fare2=fare)) %>%
  filter(rdate >= ddate + 7) %>%
  ungroup() %>%
  distinct() %>%
  select(route, ddate, rdate, fare1 = fare, eur1 = eur, fare2, eur2, eur) %>%
  mutate(eur = eur1 + eur2) %>%
  arrange(eur, ddate, rdate)

# visnetwork --------------------------------------------------------------


library(visNetwork)
fltdata <- gsheet::gsheet2tbl("https://docs.google.com/spreadsheets/d/1-4lfxpR_-V8iv4oErr7JNVqH4HrsxtBiZCJMJJiPM6Y/edit?usp=sharing")

cities <- c("SYD", "BNE", "NOU", "VLI", "NAN")
nodes <- data.frame(id    = cities, 
                    label = cities,
                    fixed = TRUE,
                    x     = c(-90, -85, -30,  30,  90) * 4,
                    y     = c( 50,  10, -30, -50, -10) * 4,
                    shape = "box")

fltdata %>%
  mutate(desc = paste0("<br/>", time, " [", flight, " on ",  availability, "]")) %>%
  group_by(from, to, direction) %>%
  summarise(price = min(price), text = toString(desc)) %>%
  mutate(title  = paste(from, to, price, text),
         arrows = "to",
         color  = ifelse(direction == "Eastbound", "Salmon", "Seagreen"),
         font.color = color,
         label  = paste(price, "€")) %>%
  visNetwork(nodes, .) 
