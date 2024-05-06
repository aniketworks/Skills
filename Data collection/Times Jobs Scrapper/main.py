from bs4 import BeautifulSoup
from datetime import datetime, timedelta
import requests
import re
import pandas as pd
import time

start_page = 1
sequence = 1
data = []

base_url = 'https://www.timesjobs.com/candidate/job-search.html?from=submit&actualTxtKeywords=Advanced%20SQL&searchBy=0&rdoOperator=OR&searchType=personalizedSearch&luceneResultSize=25&postWeek=60&txtKeywords=advanced%20sql&pDate=I&sequence={}&startPage={}'


def get_days_since_posted(posted):
    if 'today' in posted:
        return 0
    elif 'few' in posted:
        return 1
    elif 'yesterday' in posted:
        return 1
    else:
        match = re.search(r'(\d+)? ?(day|week|month|year)s? ago', posted)
        if match:
            # for 'Posted a month ago' condition
            if match.group(1) == None:
                value = int(1)
            else:
                value = int(match.group(1))
            unit = match.group(2)
            if unit.startswith('day'):
                return value
            elif unit.startswith('week'):
                return value * 7
            elif unit.startswith('month'):
                return value * 30
            elif unit.startswith('year'):
                return value * 365
    return None

def scrape_data(soup):
     jobs = soup.find_all('li',class_ = 'clearfix job-bx wht-shd-bx')

     for job in jobs:
        # Name of the company
        company_name = job.find('h3',class_ = 'joblist-comp-name').text.strip()

        # Logic to extract Years of experience and location
        required_yoe_and_location_txt = job.find('ul',class_ = 'top-jd-dtl clearfix').text.strip()
        yoe_pattern = re.compile(r'(\d{1,2}-\d{1,2}|\d{1,2})\s+yrs')
        match_yoe = re.search(yoe_pattern, required_yoe_and_location_txt)

        if match_yoe:
                # Year of experience required
                yoe = str(match_yoe.group(0))
        else:
                yoe = None

        location_pattern = re.compile(r'location_on\s*(\S.*)')
        match_location = re.search(location_pattern, required_yoe_and_location_txt)

        if match_location:
                # Job location
                location = match_location.group(1)
        else:
                location = None

        # Skills required
        skills = job.find('span',class_ = 'srp-skills').text.strip()

        published_info = job.find('span', class_ = 'sim-posted').span.text
        # Job posting updated ago
        posted_days_ago = get_days_since_posted(published_info)

        job_data = {
                'Company Name': company_name,
                'Year of experience': yoe,
                'Job location': location,
                'Skills required': skills,
                'Publised days ago': posted_days_ago
        }

        data.append(job_data)


while True:
    # Send GET request to the URL
    response = requests.get(base_url.format(sequence, start_page))
    time.sleep(2)

    if response.status_code == 200:
        # Parse the HTML content with BeautifulSoup
        soup = BeautifulSoup(response.text, 'lxml')
        print(f'Extracting page: {sequence}')
        print(f'Extracting slot: {start_page}')
        scrape_data(soup)
        next_button = soup.find('em', class_ = 'nxtC')
        soup = []
        if next_button:
             if sequence % 10 == 0:
                start_page = sequence+1
             sequence += 1
        else:
             break
    else:
        print('Pages exhausted')
        break

df = pd.DataFrame(data)

df.to_csv('Job_data.csv', index = False)