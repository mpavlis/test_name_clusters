-- Creating the schema from the data

-- create database names
create database names;

-- create table onomap_test
create table onomap_test (forename text, surname text, type2 text);

-- copy csv file to onomap_test (modify path as appropriate)
\copy onomap_test from '~/names/onomap_test.csv' CSV DELIMITER ',' HEADER;

-- create indexes
create index on onomap_test(forename);
create index on onomap_test(surname);

-- create table group_forenames 
create table group_forenames (forename text, score double precision, country text);

-- copy csv file to group_forenames (modify path as appropriate)
\copy group_forenames from '~/names/names_scores.csv' CSV DELIMITER ',' HEADER;

-- change forenames to Camel case
UPDATE group_forenames SET forename=initcap(lower(forename));

-- change country names to upper
UPDATE group_forenames SET country=upper(country);

-- create table group_surnames 
create table group_surnames (surname text, score double precision, country text);

-- copy csv file to group_surnames (modify path as appropriate)
\copy group_surnames from '~/names/surnames_scores.csv' CSV DELIMITER ',' HEADER;

-- change surnames to Camel case
UPDATE group_surnames SET surname=initcap(lower(surname));

-- change country names to upper
UPDATE group_surnames SET country=upper(country);



