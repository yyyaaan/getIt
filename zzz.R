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
