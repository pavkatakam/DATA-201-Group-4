import pandas as pd
from sqlalchemy import create_engine, text

# 1. Connect to MySQL database
# Replace with your actual password
engine = create_engine("mysql+pymysql://YOURUSERNAME:PASSWORD@localhost:XXXX/MYSQLCONNECTIONNAME")

# Reset tables in child-first order to prevent foreign key errors on reruns
with engine.begin() as conn:
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 0;"))
    conn.execute(text("TRUNCATE TABLE Review;"))
    conn.execute(text("TRUNCATE TABLE Reviewer;"))
    conn.execute(text("TRUNCATE TABLE Listing;"))
    conn.execute(text("TRUNCATE TABLE Neighbourhood;"))
    conn.execute(text("TRUNCATE TABLE Host;"))
    conn.execute(text("SET FOREIGN_KEY_CHECKS = 1;"))
print("Database tables cleared for fresh import.")

# --- PART 1: LOAD & PROCESS LISTINGS ---

city_files = {
    'listings_LA.csv': 1,
    'listings_SD.csv': 2,
    'listings_SF.csv': 3
}

listings_dfs = []
for file_name, city_id in city_files.items():
    df = pd.read_csv(file_name)
    df['city_ID'] = city_id
    listings_dfs.append(df)

all_listings = pd.concat(listings_dfs, ignore_index=True)

# A. Insert into Host table
hosts = all_listings[['host_id', 'host_profile_id', 'host_name']].dropna(subset=['host_id']).drop_duplicates(subset=['host_id']).copy()
hosts['host_id'] = hosts['host_id'].astype('int64')
hosts.columns = ['host_ID', 'host_profile_ID', 'host_name']
hosts.to_sql('Host', con=engine, if_exists='append', index=False)
print("Host table loaded.")

# B. Insert into Neighbourhood table
neighbourhoods = all_listings[['neighbourhood', 'neighbourhood_group', 'city_ID']].drop_duplicates().reset_index(drop=True)
neighbourhoods['neighbourhood_id'] = neighbourhoods.index + 1
neighbourhoods.rename(columns={'neighbourhood': 'neighbourhood_name'}, inplace=True)

neighbourhoods[['neighbourhood_id', 'neighbourhood_name', 'neighbourhood_group', 'city_ID']].to_sql(
    'Neighbourhood', con=engine, if_exists='append', index=False
)
print("Neighbourhood table loaded.")

# C. Map neighbourhood_id back onto listings
all_listings = all_listings.merge(
    neighbourhoods[['neighbourhood_name', 'city_ID', 'neighbourhood_id']],
    left_on=['neighbourhood', 'city_ID'],
    right_on=['neighbourhood_name', 'city_ID'],
    how='left'
)

# D. Insert into Listing table
listings = all_listings[[
    'id', 'host_id', 'city_ID', 'neighbourhood_id', 'name', 
    'room_type', 'price', 'latitude', 'longitude', 
    'minimum_nights', 'license', 'availability_365'
]].drop_duplicates(subset=['id']).copy()

listings['id'] = listings['id'].astype('int64')
listings['host_id'] = listings['host_id'].astype('Int64')

listings.columns = [
    'listing_ID', 'host_ID', 'city_ID', 'neighbourhood_id', 'property_name',
    'room_type', 'price', 'latitude', 'longitude',
    'minimum_nights', 'license', 'availability_365'
]
listings.to_sql('Listing', con=engine, if_exists='append', index=False)
print("Listing table loaded.")

# --- PART 2: LOAD & PROCESS REVIEWS ---

review_files = ['reviews_LA.csv', 'reviews_SD.csv', 'reviews_SF.csv']
reviews_dfs = []

for file_name in review_files:
    df = pd.read_csv(file_name)
    reviews_dfs.append(df)

all_reviews = pd.concat(reviews_dfs, ignore_index=True)

# Drop missing IDs and ensure listing_id exists in Listing table
all_reviews = all_reviews.dropna(subset=['id', 'reviewer_id'])
valid_listing_ids = set(listings['listing_ID'])
all_reviews = all_reviews[all_reviews['listing_id'].isin(valid_listing_ids)]

# A. Insert into Reviewer table
reviewers = all_reviews[['reviewer_id', 'reviewer_name']].drop_duplicates(subset=['reviewer_id']).copy()
reviewers['reviewer_id'] = reviewers['reviewer_id'].astype('int64')
reviewers.columns = ['reviewer_ID', 'reviewer_name']
reviewers.to_sql('Reviewer', con=engine, if_exists='append', index=False, chunksize=10000)
print("Reviewer table loaded.")

# B. Insert into Review table
reviews = all_reviews[['id', 'reviewer_id', 'listing_id', 'date', 'comments']].drop_duplicates(subset=['id']).copy()
reviews['id'] = reviews['id'].astype('int64')
reviews['reviewer_id'] = reviews['reviewer_id'].astype('int64')
reviews['listing_id'] = reviews['listing_id'].astype('int64')

reviews.columns = ['review_ID', 'reviewer_ID', 'listing_ID', 'date', 'comments']
reviews.to_sql('Review', con=engine, if_exists='append', index=False, chunksize=10000)
print("Review table loaded.")

print("\n--- Data load complete ---")