'''
Pull hourly weather data from the Dark Sky API
Default location is Wrightsville Beach, NC

Run as follows:
    python3 darkSky.py --lat latitude --long longitude --start_date yyyy-mm-dd --end_date yyy-mm-dd --api_key api-key --data_dir directory
'''

import os
import json
import requests
import argparse
import numpy as np
import pandas as pd


def gen_urls():
   
    dateRange = pd.date_range(start=ARGS.start_date, end=ARGS.end_date, tz='US/Eastern')
    dateRange.astype(np.int64)
    dates = [day.value // 10 ** 9 for day in dateRange]

    urls = []
    for date in dates:
        url = ('https://api.darksky.net/forecast/' + ARGS.api_key + '/' 
               +  ARGS.lat + ',' + ARGS.long + ',' + str(date)
               + '?exclude=currently,minutely,daily,alerts,flags')
        urls.append(url)
    return(urls)


def get_data(api_urls):
    dfs = []
    for url in api_urls:
        result = requests.get(url)
        raw = json.loads(result.content)
        hourly = pd.DataFrame(raw['hourly']['data'])
        dfs.append(hourly)
    out = pd.concat(dfs, sort=False)
    out['time'] = pd.to_datetime(out['time'] - 60 * 60 * 5, unit='s')
    out.set_index('time', inplace = True)
    return(out)


def main():
    urls = gen_urls()
    data = get_data(urls)
    data.to_csv(os.path.join(ARGS.data_dir, 'darkSky.csv'))

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--lat',
                        type=str,
                        default='34.2085',
                        help='latitude')
    parser.add_argument('--long',
                        type=str,
                        default='-77.7964',
                        help='longitude (locations in western hemisphere should be negative)')
    parser.add_argument('--start_date',
                        type=str,
                        default='2018-01-01',
                        help='Start date in form yyyy-mm-dd')
    parser.add_argument('--end_date',
                        type=str,
                        default='2018-01-01',
                        help='End date in form yyyy-mm-dd')
    parser.add_argument('--api_key',
                        type=str,
                        help='No Default: Sign up for free at https://darksky.net/dev')
    parser.add_argument('--data_dir',
                        type=str,
                        default=os.getcwd(),
                        help='Directory for csv to be saved')
    ARGS, _ = parser.parse_known_args()
    main()
