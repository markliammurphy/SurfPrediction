'''
Scrape surf reports from wblive, save result as a csv
'''

import argparse
from bs4 import BeautifulSoup
import urllib
import requests


def get_data():
    pass


def crawl():
    archive = 'http://www.wblivesurf.com/reports/'
    r = requests.get(archive, auth=('user', 'pass'))

    soup = BeautifulSoup(r.text, "html5lib")

    # find the dates we want
    for date in soup.find_all("div", class_="postDate"):
        print(date.text)


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
    ARGS, _ = parser.parse_known_args()
    crawl()