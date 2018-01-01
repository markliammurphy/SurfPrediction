'''
Scrape surf reports from wblive, save result as a csv

Run as follows: 
    python3 wblive_scrape.py --start_date mm/dd/yy --end_date mm/dd/yy --data_dir [directory_path]
'''

import argparse
from bs4 import BeautifulSoup
import urllib
import requests


def get_data():
    pass


def crawl_archives():
    archive = 'http://www.wblivesurf.com/reports/'
    r = requests.get(archive, auth=('user', 'pass'))

    soup = BeautifulSoup(r.text, "html5lib")

    # find the dates specified in arguments
    for date in soup.find_all("div", class_="postDate"):
        print(date.text)


def main():
    crawl_archives()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--start_date',
                        type=str,
                        default='01/01/16',
                        help='Start date in form mm/dd/yy')
    parser.add_argument('--end_date',
                        type=str,
                        default='12/31/16',
                        help='Start date in form mm/dd/yy')
    parser.add_argument('--data_dir',
                        type=str,
                        default='./wblive_data',
                        help='Directory for csv to be saved')
    ARGS, _ = parser.parse_known_args()
    main()