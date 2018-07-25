'''
Scrape surf reports from wblive, save result as a csv

Run as follows: 
    python3 wblive_scrape.py --start_date mm/dd/yy --end_date mm/dd/yy --data_dir [directory_path]
'''

import os
import argparse
import pandas as pd
from time import time
from requests import get
from itertools import chain
from bs4 import BeautifulSoup


def get_soup(seconds=False, page=2):

    if seconds is False:
        url = ('http://www.wblivesurf.com/reports/?startdate=' + ARGS.start_date + 
               '&enddate=' + ARGS.end_date)
    else:
        url = ('http://www.wblivesurf.com/reports/page/' + str(page) + 
               '/?startdate=' + ARGS.start_date +
               '&enddate=' + ARGS.end_date)

    response = get(url)
    soup = BeautifulSoup(response.text, 'html5lib')
    return soup


def scrape_page(soup):

    dates = []
    times = []
    ratings = []

    reports = soup.find_all('article')
    
    for r in reports:
        date = r.find('div', class_='postDate')
        dates.append(date.text)

        t = r.find('div', class_='time')
        times.append(t.text[:8])

        star_jar = r.find('div', class_='current')
        full = len(star_jar.find_all('div'))
        half = len(star_jar.find_all('div', class_='ratingCell half'))
        rating = full - .5 * half
        ratings.append(rating)

    return dates, times, ratings


def crawl_archives():

    def append_data():

        return len(dates)

    def save_data():
        wblive_ratings = pd.DataFrame({'date': d,
                                       'time': t,
                                       'rating': r})
        wblive_ratings.to_csv(os.path.join(ARGS.data_dir, 'wblive_ratings.csv'),
                              index=False, columns=['date', 'time', 'rating'])
        print('Total run-time: {} seconds'.format(time() - start_time))
        raise SystemExit

    start_time = time()

    d = []
    t = []
    r = []

    soup = get_soup()
    dates, times, ratings = scrape_page(soup)
    d += dates
    t += times
    r += ratings

    n = len(dates)

    if n < 16:
        print("Saving ... fewer than 16 entries on page")
        save_data()
        
    soup = get_soup(seconds=True)
    title = soup.find('title')

    if "Page not found" not in title.text:
        page_max = int(title.text.split('/')[1].split()[0])
    else:
        save_data()

    append_data()

    for page in range(3, page_max + 1):
        if page % 5 == 0:
            print('On page {} of {}'.format(page, page_max))
        soup = get_soup(seconds=True, page=page)
        scrape_page(soup)
        dates, times, ratings = scrape_page(soup)
        d += dates
        t += times
        r += ratings

    save_data()

    
def main():
    crawl_archives()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--start_date',
                        type=str,
                        default='2016-01-01',
                        help='Start date in form yyyy-mm-dd')
    parser.add_argument('--end_date',
                        type=str,
                        default='2016-12-31',
                        help='Start date in form yyyy-mm-dd')
    parser.add_argument('--data_dir',
                        type=str,
                        default=os.getcwd(),
                        help='Directory for csv to be saved')
    ARGS, _ = parser.parse_known_args()
    main()
