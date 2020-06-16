# Sys.getenv("PATH")
# system("which gcloud")
# Sys.setenv(PATH = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin")
library(magrittr)
text <- "log initiated"
log_name <- "getIt"
paste("/snap/bin/gcloud logging write", log_name, "'", text, "' --severity=INFO") %>% system()

