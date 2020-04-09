DROP DATABASE IF EXISTS   grocerydata;
CREATE DATABASE           grocerydata;
USE                       grocerydata;

DROP TABLE IF EXISTS raw_data_households;
DROP TABLE IF EXISTS raw_data_products;
DROP TABLE IF EXISTS raw_data_trips;
DROP TABLE IF EXISTS raw_data_purchases;

-- SHOW GLOBAL VARIABLES LIKE 'local_infile';
-- SET GLOBAL local_infile = 'ON';

CREATE TABLE raw_data_households (
    hh_id                            INT UNSIGNED PRIMARY KEY NOT NULL,
    hh_race                          INT UNSIGNED,
    hh_is_latinx                     TINYINT(1) UNSIGNED,
    hh_zip_code                      INT UNSIGNED,
    hh_income                        TINYINT(1) UNSIGNED,
    hh_state                         VARCHAR(10),
    hh_size                          TINYINT(1) UNSIGNED,
    hh_residence_type                TINYINT(1) UNSIGNED
    );

CREATE TABLE raw_data_products (
    brand_at_prod_id                 VARCHAR(50),
    department_at_prod_id            VARCHAR(50),
    prod_id                          BIGINT UNSIGNED PRIMARY KEY NOT NULL,
    group_at_prod_id                 VARCHAR(50),
    module_at_prod_id                VARCHAR(100),
    amount_at_prod_id                DOUBLE,
    units_at_prod_id                 VARCHAR(50)
);

CREATE TABLE raw_data_trips (
    hh_id                            INT UNSIGNED NOT NULL, 
    TC_date                          DATE,
    TC_retailer_code                 SMALLINT UNSIGNED,
    TC_retailer_code_store_code      INT UNSIGNED,
    TC_retailer_code_store_zip3      DOUBLE,
    TC_total_spent                   FLOAT,
    TC_id                            INT UNSIGNED PRIMARY KEY NOT NULL
);


CREATE TABLE raw_data_purchases (
    TC_id                            INT UNSIGNED NOT NULL, CONSTRAINT raw_data_trips_TC_id_fk FOREIGN KEY(TC_id) REFERENCES raw_data_trips(TC_id),
    quantity_at_TC_prod_id           INT UNSIGNED,
    total_price_paid_at_TC_prod_id   FLOAT,
    coupon_value_at_TC_prod_id       FLOAT,
    deal_flag_at_TC_prod_id          INT UNSIGNED,
    prod_id                          BIGINT UNSIGNED NOT NULL, CONSTRAINT raw_data_products_prod_id_fk FOREIGN KEY(prod_id) REFERENCES raw_data_products(prod_id)
);

DROP TABLE IF EXISTS purchases;
DROP TABLE IF EXISTS trips;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS households;

CREATE TABLE household AS
    SELECT 
        hh_id,
        hh_race,
        hh_is_latinx,
        hh_income,
        hh_size,
        hh_zip_code,
        hh_state,
        hh_residence_type
    FROM raw_data_households;
    



ALTER TABLE raw_data_households RENAME TO household;
ALTER TABLE raw_data_products RENAME TO product;
ALTER TABLE raw_data_trips RENAME TO trip;
ALTER TABLE raw_data_purchases RENAME TO purchase;
ALTER TABLE trip ADD CONSTRAINT raw_data_households_hh_id_fk FOREIGN KEY (hh_id) REFERENCES raw_data_households(hh_id);







