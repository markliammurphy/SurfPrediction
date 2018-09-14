library(dplyr)
library(purrr)
library(jsonlite)
library(lubridate)


# Data-getting Functions ======================================================

read_NDBC_data <- function(url) {
  header <- scan(url, nlines = 1, what = character())
  data <- read.table(url, skip = 2)
  names(data) <- header
  data
}

get_COOPS_data <- function(start_date, end_date) {
  
  gen_url <- function(x) {
    front_half <- "https://tidesandcurrents.noaa.gov/api/datagetter?"
    back_half <- "&station=8658163&product=water_level&datum=mllw&units=english&time_zone=lst&format=json"
    last_day <- x
    month(last_day) <- month(last_day) + 1
    last_day <- last_day - 1
    
    paste0(
      front_half, 
      "begin_date=", format(x, "%Y%m%d"), 
      "&end_date=", format(last_day, "%Y%m%d"), 
      back_half
    )
  }
  
  dates <- seq(ymd(start_date), ymd(end_date), by = "month")
  urls <- lapply(dates, gen_url)
  output <- 
    lapply(urls, 
      function(x) jsonlite::fromJSON(x, simplifyDataFrame = T)$data
    )
  output <- bind_rows(output)
  output
}


# Reading the data ============================================================

# Waves
station41110_raw <-
  read_NDBC_data(
      "https://www.ndbc.noaa.gov/view_text_file.php?filename=41110h2008.txt.gz&dir=data/historical/stdmet/"
  )

# Wind (Johnny Mercer's Pier)
jmpn7_raw <- 
  read_NDBC_data(
      "https://www.ndbc.noaa.gov/view_text_file.php?filename=jmpn7h2008.txt.gz&dir=data/historical/stdmet/"
  )

for (year in 2009:2017) {
  next_year_41110_url = sprintf(
    "https://www.ndbc.noaa.gov/view_text_file.php?filename=41110h%d.txt.gz&dir=data/historical/stdmet/", 
    year
  )
  next_year_41110_data = read_NDBC_data(next_year_41110_url)
  station41110_raw = rbind(station41110_raw, next_year_41110_data)
  
  next_year_jmpn7_url = sprintf(
    "http://www.ndbc.noaa.gov/view_text_file.php?filename=jmpn7h%d.txt.gz&dir=data/historical/stdmet/", 
    year
  )
  next_year_jmpn7_data = read_NDBC_data(next_year_jmpn7_url)
  jmpn7_raw = rbind(jmpn7_raw, next_year_jmpn7_data)
}

# Tide/water-level Data
wb_water_raw <- get_COOPS_data("2008-01-01", "2017-12-31")


# Tidying ====================================================================

# NDBC ------------------------------------------------------------------------

is_useful <- function(col) length(unique(col)) > 1 
jmpn7 <- select_if(jmpn7_raw, is_useful)
station41110 <- select_if(station41110_raw, is_useful)

find_replace_na <- function(col) {
  ifelse(col == max(col) & (col %in% c(99, 999, 9999)) , NA, col)
}

jmpn7 <- map_dfc(jmpn7, find_replace_na)
station41110 <- map_dfc(station41110, find_replace_na)

# jmpn7[rowSums(is.na(jmpn7)) > 0, ]

names(jmpn7)[1:5] <- c("year", "month", "day", "hour", "min")
names(station41110)[1:5] <- c("year", "month", "day", "hour", "min")

jmpn7 <- 
  jmpn7 %>% 
  mutate(datetime = ymd_hm(paste(year, month, day, hour, min))) %>%
  with_tz(tz = "America/New_York") 
station41110 <- 
  station41110 %>% 
  mutate(datetime = ymd_hm(paste(year, month, day, hour, min))) %>%
  with_tz(tz = "America/New_York")

# Drop old time columns/Re-order 
jmpn7 <- 
  jmpn7 %>% 
  select(datetime, WDIR:WTMP)
station41110 <- 
  station41110 %>%
  select(datetime, WVHT:WTMP)


# CO-OPS ----------------------------------------------------------------------

wb_water <- select(wb_water_raw, t, v) 
names(wb_water) <- c("datetime", "TIDE")
wb_water$datetime <- 
  as.POSIXct(
    wb_water$datetime, 
    format  = "%Y-%m-%d %H:%M",
    tz = "America/New_York"
  )


# Write out csv's ===============================================================

write.csv(
  station41110, 
  file = file.path(getwd(), "data", "station41110.csv"), 
  row.names = F
)

write.csv(
  jmpn7, 
  file = file.path(getwd(), "data", "jmpn7.csv"), 
  row.names = F
)

write.csv(
  wb_water, 
  file = file.path(getwd(), "data", "tide.csv"), 
  row.names = F
)
