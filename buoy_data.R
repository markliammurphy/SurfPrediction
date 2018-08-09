# Running this script will output a .csv file containing the wave,
# wind, and tide data for Wrightsville Beach, NC in 2016. 

# Before running,specify your output directory below.

out_dir <- "~/Desktop/SurfPrediction"


# ------------------------------------------------------------------------------------------
# LOADING PACKAGES
# code borrowed from http://www.vikram-baliga.com/blog/2015/7/19/a-hassle-free-way-to-verify-that-r-packages-are-installed-and-loaded

packages <- c("dplyr", "lubridate", "jsonlite", "curl")

invisible(lapply(packages, FUN = function(x) {
  if(!require(x, character.only = T)) {
    install.packages(x)
    library(x, character.only = T)
  }
}))


# ------------------------------------------------------------------------------------------
# FUNCTIONS TO READ/GET DATA

# This function reads in historic buoy data from the NOAA National Data Buoy Center (NDBC)
# - To use, supply url to .txt file containing the data as a string

read_NDBC_data <- function(url) {
  header <- scan(url, nlines = 1, what = character())
  data <- read.table(url, skip = 2)
  names(data) <- header
  return(data)
}


# This function obtains data from the NOAA Center for Operational Oceanographic Products 
# and Services (CO-OPS) API (https://tidesandcurrents.noaa.gov/api/#requestResponse). Since the 
# CO-OPS API only allows access to 31 days of data at a time, the purpose of this function is 
# to simplify the process of obtaining data over longer periods.
# - To use, supply the desired start and end dates as strings
# - To get data from different stations or in different formats, time zones, etc. you can
#   modify the "back_half" string. The link provided above gives more information.

get_COOPS_data <- function(start_date, end_date) {
  
  gen_url <- function(x) {
    front_half <- "https://tidesandcurrents.noaa.gov/api/datagetter?"
    back_half <- "&station=8658163&product=water_level&datum=mllw&units=english&time_zone=lst&format=json"
    
    last_day <- x
    month(last_day) <- month(last_day) + 1
    last_day <- last_day - 1
    
    paste0(front_half, "begin_date=", format(x, "%Y%m%d"), "&end_date=", format(last_day, "%Y%m%d"), back_half)
  }
  
  dates <- seq(ymd(start_date), ymd(end_date), by = "month")
  urls <- lapply(dates, gen_url)
  
  output <- lapply(urls, function(x) jsonlite::fromJSON(x, simplifyDataFrame = T)$data)
  output <- bind_rows(output)
  return(output)
}

# ------------------------------------------------------------------------------------------
# READ DATA

# Swell Data
station41110_raw <- read_NDBC_data(
  "https://www.ndbc.noaa.gov/view_text_file.php?filename=41110h2008.txt.gz&dir=data/historical/stdmet/"
  )

# Wind Data (Johnny Mercer's Pier)
jmpn7_raw <- read_NDBC_data(
  "http://www.ndbc.noaa.gov/view_text_file.php?filename=jmpn7h2008.txt.gz&dir=data/historical/stdmet/"
  )


for (year in 2009:2017){
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


# ------------------------------------------------------------------------------------------
# CLEANING

# Remove columns that are the same for every obs.
# - NDBC data has missing values coded as "9", "99", "999", etc.

is_useful <- function(x) length(unique(x)) > 1 | !(unique(x)[1] %in% c(99, 999, 9999))
jmpn7 <- select_if(jmpn7_raw, is_useful)
station41110 <- select_if(station41110_raw, is_useful)

wb_water <- select(wb_water_raw, t, v) 

# Replace missing values with NA

jmpn7 <- data.frame(lapply(jmpn7, 
                                function(col) ifelse(col %in% c(99, 999, 9999), NA, col)))
station41110 <- data.frame(lapply(station41110, 
                                       function(col) ifelse(col %in% c(99, 999, 9999), NA, col)))

# Renaming columns

names(jmpn7)[1:5] <- c("year", "month", "day", "hour", "min")
names(station41110)[1:5] <- c("year", "month", "day", "hour", "min")

names(wb_water) <- c("datetime", "TIDE")

# Dates

wb_water$datetime <- as.POSIXct(wb_water$datetime, 
                                 format  = "%Y-%m-%d %H:%M",
                                 tz = "America/New_York")

# Note: NDBC Historical Data records time according to UTC
jmpn7 <- jmpn7 %>% 
  mutate(datetime = ymd_hm(paste(year, month, day, hour, min))) %>%
  with_tz(tz = "America/New_York") 
station41110 <- station41110 %>% 
  mutate(datetime = ymd_hm(paste(year, month, day, hour, min))) %>%
  with_tz(tz = "America/New_York")

# Drop/Re-order columns

jmpn7 <- jmpn7 %>% 
  select(datetime, WDIR:WTMP)
station41110 <- station41110 %>%
  select(datetime, WVHT:WTMP)

# On August 31, 2016 observations at station 41110 started being taken at 
# the 29th and 59th minute every hour, which doesn't match up with the wind data intervals. 
# To account for this, the "date" for each of these observations is rounded up 
# by 1 minute (below).

station41110[station41110$date > ymd("16-08-31"), ] <- station41110 %>% 
  filter(date > ymd("16-08-31")) %>% 
  mutate(date = round_date(date, "30 mins"))

# Combining the data

WV_WND <- inner_join(station41110, jmpn7, by = "datetime")
names(WV_WND)[c(6, 12)] <- c("WTMP_in", "WTMP_off") # inshore/offshore water temps.

WV_WND_TIDE <- inner_join(WV_WND, wb_water, by = "datetime")

# ------------------------------------------------------------------------------------------
# OUTPUT

write.csv(WV_WND_TIDE, file = file.path(out_dir, "wb_buoys.csv"), row.names = F)

