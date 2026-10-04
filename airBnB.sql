DROP DATABASE IF EXISTS group_project;
CREATE DATABASE group_project;
USE group_project;

CREATE TABLE Host (
    host_ID BIGINT PRIMARY KEY,
    host_profile_ID VARCHAR(100) NULL,
    host_name VARCHAR(100) NULL
);

CREATE TABLE City (
    city_ID INT PRIMARY KEY,
    city_name VARCHAR(100) NOT NULL UNIQUE
);

INSERT INTO City (city_ID, city_name) VALUES
('1', 'Los Angeles'), 
('2', 'San Diego'), 
('3', 'San Francisco');

CREATE TABLE Neighbourhood (
    neighbourhood_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    neighbourhood_name VARCHAR(250),
    neighbourhood_group VARCHAR(250) NULL,
    city_ID INT, 
    CONSTRAINT fk_city_ID
        FOREIGN KEY (city_ID) REFERENCES City(city_ID)
);

CREATE TABLE Listing (
    listing_ID BIGINT PRIMARY KEY,
    host_ID BIGINT,
    CONSTRAINT fk_host_ID
        FOREIGN KEY (host_ID) REFERENCES Host(host_ID),
    neighbourhood_id BIGINT,
    CONSTRAINT fk_neighbourhood_id
        FOREIGN KEY (neighbourhood_id) REFERENCES Neighbourhood(neighbourhood_id),
    property_name VARCHAR(250),
    room_type VARCHAR(250), 
    price INT, 
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    minimum_nights INT,
    license VARCHAR(250),
    availability_365 INT
);

CREATE TABLE Reviewer (
    reviewer_ID BIGINT PRIMARY KEY,
    reviewer_name VARCHAR(250)
);

CREATE TABLE Review (
    review_ID BIGINT PRIMARY KEY,
    reviewer_ID BIGINT,
    CONSTRAINT fk_reviewer_ID
        FOREIGN KEY (reviewer_ID) REFERENCES Reviewer(reviewer_ID),
    listing_ID BIGINT,
    CONSTRAINT fk_review_listing_ID
        FOREIGN KEY (listing_ID) REFERENCES Listing(listing_ID),
    date DATETIME,
    comments TEXT
);
