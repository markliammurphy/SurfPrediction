'''
Scrape surf reports from wblive, save result as a csv
'''

import argparse


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