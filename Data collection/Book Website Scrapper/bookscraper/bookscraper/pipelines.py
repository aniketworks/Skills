# Define your item pipelines here
#
# Don't forget to add your pipeline to the ITEM_PIPELINES setting
# See: https://docs.scrapy.org/en/latest/topics/item-pipeline.html


# useful for handling different item types with a single interface
from itemadapter import ItemAdapter


class BookscraperPipeline:
    def process_item(self, item, spider):
        adapter = ItemAdapter(item)

        #removing the whitespace
        field_names = adapter.field_names()
        for field_name in field_names:
            if field_name not in ['description']:
                value = adapter.get(field_name)
                adapter[field_name] = value.strip()
        
        # Category and product type switch to lowercase
        lowercase_keys = ['category', 'product_type']
        for lowercase_key in lowercase_keys:
            value = adapter.get(lowercase_key)
            adapter[lowercase_key] = value.lower()

        #price --> float
        price_keys = ['price', 'price_excl_tax', 'price_incl_tax', 'tax']
        for price_key in price_keys:
            value = adapter.get(price_key)
            value = value.replace('£', '')
            adapter[price_key] = float(value)

        #availabilty --> string to number
        availability_str = adapter.get('availability')
        split_str = availability_str.split('(')
        if len(split_str) < 2:
            adapter['availability'] = 0
        else:
            stock = split_str[1].split(' ')
            adapter['availability'] = int(stock[0])

        #num_reviews --> string to number
        num_reviews_str = adapter.get('num_reviews')
        adapter['num_reviews'] = int(num_reviews_str)

        #star rating --> text to number
        stars = adapter.get('stars')
        star_split = stars.split(' ')
        rating_txt = star_split[1].lower()
        if rating_txt == 'zero':
            adapter['stars'] = 0
        elif rating_txt == 'one':
            adapter['stars'] = 1
        elif rating_txt == 'two':
            adapter['stars'] = 2
        elif rating_txt == 'three':
            adapter['stars'] = 3
        elif rating_txt == 'four':
            adapter['stars'] = 4
        elif rating_txt == 'five':
            adapter['stars'] = 5

        return item
