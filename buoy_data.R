library(dplyr)
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
    back_half <- 
      paste0(
        "&station=8658163&product=water_level", 
        "&datum=mllw&units=english&time_zone=lst&format=json"
      )
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

# Swell Data
station41110_2016_raw <-
  read_NDBC_data(
    paste0(
      "https://www.ndbc.noaa.gov/view_text_file.php?filename=",
      "41110h2016.txt.gz&dir=data/historical/stdmet/"
    )
  )


# Wind Data (Johnny Mercer's Pier)
jmpn7_2016_raw <- 
  read_NDBC_data(
    paste0(
      "https://www.ndbc.noaa.gov/view_text_file.php?filename=",
      "jmpn7h2016.txt.gz&dir=data/historical/stdmet/"
    )
  )

# Tide/water-level Data
wb_water_2016_raw <- get_COOPS_data("2016-01-01", "2016-12-31")


# Tidying ====================================================================

# NDBC ------------------------------------------------------------------------

is_useful <- function(col) {
  length(unique(col)) > 1 | !(unique(col)[1] %in% c(99, 999, 9999))
} 

jmpn7_2016 <- select_if(jmpn7_2016_raw, is_useful)
station41110_2016 <- select_if(station41110_2016_raw, is_useful)

find_9_replace_na <- function(col) ifelse(col %in% c(99, 999, 9999), NA, col)
jmpn7_2016 <- data.frame(lapply(jmpn7_2016, find_9_replace_na))
station41110_2016 <- data.frame(lapply(station41110_2016, find_9_replace_na))

names(jmpn7_2016)[1:5] <- c("year", "month", "day", "hour", "min")
names(station41110_2016)[1:5] <- c("year", "month", "day", "hour", "min")

jmpn7_2016 <- 
  jmpn7_2016 %>% 
  mutate(datetime = ymd_hm(paste(year, month, day, hour, min))) %>%
  with_tz(tz = "America/New_York") 
station41110_2016 <- 
  station41110_2016 %>% 
  mutate(datetime = ymd_hm(paste(year, month, day, hour, min))) %>%
  with_tz(tz = "America/New_York")

# Drop/Re-order columns
jmpn7_2016 <- 
  jmpn7_2016 %>% 
  select(datetime, WDIR:WTMP)
station41110_2016 <- 
  station41110_2016 %>%
  select(datetime, WVHT:WTMP)

# Rounding up one minute
station41110_2016[station41110_2016$date > ymd("16-08-31"), ] <- 
  station41110_2016 %>% 
  filter(date > ymd("16-08-31")) %>% 
  mutate(date = round_date(date, "30 mins"))


# CO-OPS ----------------------------------------------------------------------

wb_water_2016 <- select(wb_water_2016_raw, t, v) 
names(wb_water_2016) <- c("datetime", "TIDE")
wb_water_2016$datetime <- 
  as.POSIXct(
    wb_water_2016$datetime, 
    format  = "%Y-%m-%d %H:%M",
    tz = "America/New_York"
  )


# Combining the data ==========================================================

waves_wind_2016 <- inner_join(station41110_2016, jmpn7_2016, by = "datetime")

# distinguish inshore/offshore water temps.
names(waves_wind_2016)[c(6, 12)] <- c("WTMP_in", "WTMP_off") 

waves_wind_tide_2016 <- inner_join(waves_wind_2016, wb_water_2016, by = "datetime")


# Write out csv ===============================================================

write.csv(
  waves_wind_tide_2016, 
  file = file.path(getwd(), "data", "wb_buoys_2016.csv"), 
  row.names = F
)
