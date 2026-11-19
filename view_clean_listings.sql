USE group_project;

CREATE OR REPLACE VIEW Clean_Listings AS
SELECT 
    l.listing_ID,
    l.host_ID,
    c.city_ID,
    c.city_name,
    n.neighbourhood_id,
    n.neighbourhood_name,
    n.neighbourhood_group,
    l.property_name,
    l.room_type,
    l.price,
    l.minimum_nights,
    l.license,
    l.availability_365
FROM Listing l
JOIN Neighbourhood n ON l.neighbourhood_id = n.neighbourhood_id
JOIN City c ON n.city_ID = c.city_ID
WHERE l.price BETWEEN 20 AND 5000;