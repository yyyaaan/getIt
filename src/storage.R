library(jsonlite)
library(tidyverse)

# https://cloud.google.com/bigquery/docs/reference/bq-cli-reference
# https://cloud.google.com/bigquery/docs/loading-data-local#loading_data_from_a_local_data_source

bq_test_con <- function(){

  system("bq query --location='europe-north1' --use_legacy_sql=false \\
       'select tss, count(*) as N 
       from `yyyaaannn.Explore.LUMO01` 
       group by tss order by tss desc'")
}


df_to_txt <- function(df, 
                      fjson = './results/json', 
                      fcsvgz = './results/csv.gz',
                      fschema = './results/schema'){
  
  if(!is.na(fcsvgz)){ ## csv (compressed giving extension .gz)
    df %>% write_csv(fcsvgz)
  }
  
  if(!is.na(fjson)){ ## new line delimited json (compatible with bigquery)
    df %>% stream_out(con = file(fjson))
  }
  
  if(!is.na(fschema)){ ## auto schema for bigquery
    data.frame(name = colnames(df),
               type = sapply(df, class)) %>%
      mutate(type = case_when(type == "Date" ~ "DATE",
                              type == "character" ~ "STRING",
                              type == "numeric" ~ "FLOAT64",
                              TRUE ~ type)) %>%
      toJSON(pretty = T) %>%
      writeLines(fschema)
    
  }

}


bq_upload_cli <- function(fjson, fschema, fullname = 'yyyaaannn:Explore.AYT'){
  
  'bq load --source_format=NEWLINE_DELIMITED_JSON' %>%
    paste(fjson, fschema) %>%
    system()
}