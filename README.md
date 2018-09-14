# SurfPrediction
The goal of this project is to use the surfer-adjudicated star ratings from [WB Live Surf](http://www.wblivesurf.com) to forecast how fun the waves will be at Wrightsville Beach, NC.

This README gives directions for running all the files included in this repository, as well as an overview of what each one does. For more detailed documentation consult the SurfPrediction wiki.

## Data-getting Scripts

**_wblive_scrape.py_**

This script scrapes historical rating data from [WB Live Surf](http://www.wblivesurf.com). It can be run from the command line as follows:

```
$ python3 wblive_scrape.py --start_date yyyy-mm-dd --end_date yyyy-mm-dd --data_dir directory_path
```

By default, this script will scrape all 2016 WB Live ratings and output them as a csv in the current working directory. To change this behavior, simply supply the optional arguments as shown above.

**_darksky.py_**

This script generates a series of calls to [Dark Sky's weather API](https://darksky.net/dev) and outputs the returned data as a csv. Run as follows:

```
$ python3 darkSky.py --api_key api-key --lat latitude --long longitude --start_date yyyy-mm-dd --end_date yyy-mm-dd --data_dir directory
```

Note that `--api_key` is a required argument. Sign up is free on [Dark Sky's website](https://darksky.net/dev) and includes 1,000 free calls per day (i.e. 1,000 days worth of hourly data = 24,000 rows per day). 

The default arguments output a csv in the current working directory containing hourly weather data for Wrigthsville Beach on January 1, 2018.

**_buoy_data.R_**

Running this script will output three csv's containing wind, wave, and tide data for Wrightsville Beach from 2008 through 2017. 
