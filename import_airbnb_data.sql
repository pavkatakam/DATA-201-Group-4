-- ============================================================
-- DATA 201 Group Project: Airbnb Multi-City Database
-- Cities: Los Angeles (LA), San Diego (SD), San Francisco (SF)
--
--
-- HOW TO USE:
--   1. Clone the shared repo: https://github.com/pavkatakam/DATA-201-Group-4
--      You should end up with these files at the repo root:
--        listings_LA.csv, listings_SD.csv, listings_SF.csv
--   2. Find-and-replace the placeholder  /Users/gulina/sjsu-ADI/DATA-201/project/DATA-201-Group-4  everywhere in
--      this file with YOUR OWN absolute path to where you cloned that repo.
--      Example (Mac): /Users/yourname/sjsu-ADI/DATA-201/project/DATA-201-Group-4
--      (In MySQL Workbench: Cmd+F / Ctrl+F -> Replace, search
--       /Users/gulina/sjsu-ADI/DATA-201/project/DATA-201-Group-4, replace with your path, "Replace All".)
-- ============================================================

CREATE DATABASE IF NOT EXISTS airbnb_db;
USE airbnb_db;

-- ------------------------------------------------------------
-- Clean slate: drop in child-to-parent order (FK-safe)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS REVIEW;
DROP TABLE IF EXISTS REVIEWER;
DROP TABLE IF EXISTS LISTING;
DROP TABLE IF EXISTS NEIGHBORHOOD;
DROP TABLE IF EXISTS HOST;
DROP TABLE IF EXISTS CITY;
DROP TABLE IF EXISTS staging_listings_la;
DROP TABLE IF EXISTS staging_listings_sd;
DROP TABLE IF EXISTS staging_listings_sf;

-- ------------------------------------------------------------
-- Part 1: final normalized tables
-- ------------------------------------------------------------
CREATE TABLE CITY (
  city_id INT PRIMARY KEY,
  city_name VARCHAR(50)
);

CREATE TABLE HOST (
  host_id BIGINT PRIMARY KEY,
  host_profile_id BIGINT,
  host_name VARCHAR(100)
);

CREATE TABLE NEIGHBORHOOD (
  neighborhood_name VARCHAR(150),
  city_id INT,
  neighborhood_group VARCHAR(100),
  PRIMARY KEY (neighborhood_name, city_id),
  FOREIGN KEY (city_id) REFERENCES CITY(city_id)
);

CREATE TABLE LISTING (
  listing_id BIGINT PRIMARY KEY,
  host_id BIGINT,
  city_id INT,
  neighborhood_name VARCHAR(150),
  property_name VARCHAR(255),
  room_type VARCHAR(50),
  price VARCHAR(20),
  latitude DECIMAL(9,6),
  longitude DECIMAL(9,6),
  minimum_nights INT,
  license VARCHAR(100),
  availability_365 INT,
  FOREIGN KEY (host_id) REFERENCES HOST(host_id),
  FOREIGN KEY (city_id) REFERENCES CITY(city_id),
  FOREIGN KEY (neighborhood_name, city_id) REFERENCES NEIGHBORHOOD(neighborhood_name, city_id)
);

-- ------------------------------------------------------------
-- Part 2: staging tables (flat, mirror the raw CSV columns)
-- ------------------------------------------------------------
CREATE TABLE staging_listings_la (
  id BIGINT, name VARCHAR(255), host_id BIGINT, host_profile_id BIGINT, host_name VARCHAR(100),
  neighbourhood_group VARCHAR(100), neighbourhood VARCHAR(150), latitude DECIMAL(9,6), longitude DECIMAL(9,6),
  room_type VARCHAR(50), price VARCHAR(20), minimum_nights INT, number_of_reviews INT, last_review DATE,
  reviews_per_month DECIMAL(6,2), calculated_host_listings_count INT, availability_365 INT,
  number_of_reviews_ltm INT, license VARCHAR(100)
);
CREATE TABLE staging_listings_sd LIKE staging_listings_la;
CREATE TABLE staging_listings_sf LIKE staging_listings_la;

-- ------------------------------------------------------------
-- Part 3: load raw CSVs into staging tables
-- ------------------------------------------------------------
LOAD DATA LOCAL INFILE '/Users/gulina/sjsu-ADI/DATA-201/project/DATA-201-Group-4/listings_LA.csv'
INTO TABLE staging_listings_la
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/gulina/sjsu-ADI/DATA-201/project/DATA-201-Group-4/listings_SD.csv'
INTO TABLE staging_listings_sd
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE '/Users/gulina/sjsu-ADI/DATA-201/project/DATA-201-Group-4/listings_SF.csv'
INTO TABLE staging_listings_sf
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------------------------------
-- Part 4: populate final tables from staging
-- ------------------------------------------------------------
INSERT INTO CITY VALUES (1,'Los Angeles'), (2,'San Diego'), (3,'San Francisco');

INSERT INTO HOST (host_id, host_profile_id, host_name)
SELECT host_id, MAX(host_profile_id), MAX(host_name)
FROM (
  SELECT host_id, host_profile_id, host_name FROM staging_listings_la WHERE host_id IS NOT NULL
  UNION ALL
  SELECT host_id, host_profile_id, host_name FROM staging_listings_sd WHERE host_id IS NOT NULL
  UNION ALL
  SELECT host_id, host_profile_id, host_name FROM staging_listings_sf WHERE host_id IS NOT NULL
) AS combined_hosts
GROUP BY host_id;

INSERT INTO NEIGHBORHOOD (neighborhood_name, city_id, neighborhood_group)
SELECT DISTINCT neighbourhood, 1, neighbourhood_group FROM staging_listings_la WHERE neighbourhood IS NOT NULL;
INSERT INTO NEIGHBORHOOD (neighborhood_name, city_id, neighborhood_group)
SELECT DISTINCT neighbourhood, 2, neighbourhood_group FROM staging_listings_sd WHERE neighbourhood IS NOT NULL;
INSERT INTO NEIGHBORHOOD (neighborhood_name, city_id, neighborhood_group)
SELECT DISTINCT neighbourhood, 3, neighbourhood_group FROM staging_listings_sf WHERE neighbourhood IS NOT NULL;

INSERT INTO LISTING (listing_id, host_id, city_id, neighborhood_name, property_name, room_type, price, latitude, longitude, minimum_nights, license, availability_365)
SELECT id, host_id, 1, neighbourhood, name, room_type, price, latitude, longitude, minimum_nights, license, availability_365
FROM staging_listings_la;
INSERT INTO LISTING (listing_id, host_id, city_id, neighborhood_name, property_name, room_type, price, latitude, longitude, minimum_nights, license, availability_365)
SELECT id, host_id, 2, neighbourhood, name, room_type, price, latitude, longitude, minimum_nights, license, availability_365
FROM staging_listings_sd;
INSERT INTO LISTING (listing_id, host_id, city_id, neighborhood_name, property_name, room_type, price, latitude, longitude, minimum_nights, license, availability_365)
SELECT id, host_id, 3, neighbourhood, name, room_type, price, latitude, longitude, minimum_nights, license, availability_365
FROM staging_listings_sf;

-- ------------------------------------------------------------
-- Part 5: verify
-- ------------------------------------------------------------
SELECT (SELECT COUNT(*) FROM CITY) AS city_cnt,
       (SELECT COUNT(*) FROM HOST) AS host_cnt,
       (SELECT COUNT(*) FROM NEIGHBORHOOD) AS neighborhood_cnt,
       (SELECT COUNT(*) FROM LISTING) AS listing_cnt;
