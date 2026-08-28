import os
import pandas as pd
from supabase import create_client

# ---------------------------------------------------------
# 1. LOAD ALL PARQUET FILES
# ---------------------------------------------------------
print("Downloading parquet files...")
prices = pd.read_parquet('https://storage.data.gov.my/pricecatcher/pricecatcher_2026-08.parquet')
items = pd.read_parquet('https://storage.data.gov.my/pricecatcher/lookup_item.parquet')
premises = pd.read_parquet('https://storage.data.gov.my/pricecatcher/lookup_premise.parquet')

# ---------------------------------------------------------
# 2. CLEAN & FILTER PREMISES (Store Module)
# ---------------------------------------------------------
premises = premises[premises['premise_code'] != -1]

# State filter shared across all tables
states_to_keep = ['Selangor', 'W.P. Kuala Lumpur']
filtered_premises = premises[premises['state'].isin(states_to_keep)].copy()

# Store-specific type filter
relevant_types = ['Pasar Raya / Supermarket', 'Hypermarket']
store_premises = filtered_premises[filtered_premises['premise_type'].isin(relevant_types)].copy()

premises_records = [
    {
        'premise_code': int(row['premise_code']),
        'premise': row['premise'],
        'address': row['address'],
        'premise_type': row['premise_type'],
        'state': row['state'],
        'district': row['district'],
    }
    for _, row in store_premises.iterrows()
]

# ---------------------------------------------------------
# 3. JOIN & FILTER ITEMS & PRICES
# ---------------------------------------------------------
items = items[items['item_code'] != -1]

# Join prices -> items -> premises
df = prices.merge(items, on='item_code', how='inner')
df = df.merge(filtered_premises, on='premise_code', how='inner')

# Keep last 90 days of prices
cutoff = df['date'].max() - pd.Timedelta(days=90)
df = df[df['date'] >= cutoff]

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

print(f"Prepared Data:")
print(f"  - Premises: {len(premises_records)} records")
print(f"  - Items:    {len(items_list)} records")
print(f"  - Prices:   {len(prices_records)} records")

# ---------------------------------------------------------
# 4. INITIALIZE SUPABASE CLIENT & UPSERT DATA
# ---------------------------------------------------------
SUPABASE_URL = os.environ['SUPABASE_URL']
SERVICE_ROLE_KEY = os.environ['SUPABASE_SERVICE_ROLE_KEY']
supabase = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)

def push(table, data, batch=500):
    for i in range(0, len(data), batch):
        chunk = data[i:i + batch]
        supabase.table(table).upsert(chunk).execute()
        print(f'  {table}: {i + len(chunk)}/{len(data)}')

print("\nUploading to Supabase...")
push('premises', premises_records)
push('items', items_list)
push('prices', prices_records)

print('Done!')