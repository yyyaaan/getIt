the_id <- "M1579526345"

the_html <- the_id %>% paste("https://www.etuovi.com/kohde/21181097?haku=", .) %>% read_html()
the_divs <- the_html %>% html_nodes("div") %>% html_attrs() %>% unlist()

f_get_attr <- . %>% unique() %>% str_split(" ") %>% unlist() %>% last() %>% paste0(".", .)
att_key <- the_divs[str_detect(the_divs, "ItemHeader")] %>% f_get_attr()
att_val <- the_divs[str_detect(the_divs, "CompactInfoRow")] %>% f_get_attr()


df <- data.frame(aid = the_id,
                 key = the_html %>% html_nodes(att_key) %>% html_text(),
                 val = the_html %>% html_nodes(att_val) %>% html_text())
