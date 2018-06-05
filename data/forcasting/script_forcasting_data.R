df1 <- read.csv("content/data/forcasting/unemployment_rate.csv",
                stringsAsFactors = FALSE)
df2 <- read.csv("content/data/forcasting/cpi.csv",
                stringsAsFactors = FALSE)
df3 <- read.csv("content/data/forcasting/exports.csv",
                stringsAsFactors = FALSE)

library(tidyverse)
df <- left_join(df1, df2, by = "DATE")
df <- left_join(df, df3, by = "DATE")
df <- df %>%
  filter(!is.na(cpi), !is.na(exports)) %>%
  mutate(DATE = as.numeric(gsub("-", "", DATE))) %>%
  gather(key = "measure", val = "value", 
         unemployment_rate, cpi, exports)

write.csv(df, file = "content/data/forcasting/forcasting.csv", quote = FALSE, row.names = FALSE)
