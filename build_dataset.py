import pandas as pd
import os
from supabase import create_client

# 1. Load all three tables
prices = pd.read_parquet('https://storage.data.gov.my/pricecatcher/pricecatcher_2026-08.parquet')
items = pd.read_parquet('https://storage.data.gov.my/pricecatcher/lookup_item.parquet')
premises = pd.read_parquet('https://storage.data.gov.my/pricecatcher/lookup_premise.parquet')

# 2. Drop the placeholder/null rows (-1 codes)
items = items[items['item_code'] != -1]
premises = premises[premises['premise_code'] != -1]

# 3. Join prices -> item info -> premise info
df = prices.merge(items, on='item_code', how='inner')
df = df.merge(premises, on='premise_code', how='inner')

# 4. Filter to a manageable slice for your prototype
states_to_keep = ['Selangor', 'W.P. Kuala Lumpur']
df = df[df['state'].isin(states_to_keep)]

# 5. Keep only the latest price per item/store
cutoff = df['date'].max() - pd.Timedelta(days=90)
df = df[df['date'] >= cutoff]

# 6. Reshape into ITEMS and PRICES separately (matches your two Supabase tables)
items_records = {}
prices_records = []

for _, row in df.iterrows():
    item_code = str(row['item_code'])
    if item_code not in items_records:
        items_records[item_code] = {
            'item_code': item_code,
            'item_name': row['item'],
            'unit': row['unit'],
            'category': row['item_category'],
        }
    prices_records.append({
        'item_code': item_code,
        'premise_code': str(row['premise_code']),
        'store_name': row['premise'],
        'price': float(row['price']),
        'date': row['date'].strftime('%Y-%m-%d'),
    })

items_list = list(items_records.values())
print(f'{len(items_list)} unique items, {len(prices_records)} price records')

# 7. Push to Supabase — use the SECRET key here, never the anon key
SUPABASE_URL = os.environ['SUPABASE_URL']
SERVICE_ROLE_KEY = os.environ['SUPABASE_SERVICE_ROLE_KEY']
supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

def push(table, data, batch=500):
    for i in range(0, len(data), batch):
        chunk = data[i:i+batch]
        supabase.table(table).upsert(chunk).execute()
        print(f'  {table}: {i+len(chunk)}/{len(data)}')

push('items', items_list)
push('prices', prices_records)
print('Done.')