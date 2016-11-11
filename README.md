# test_name_clusters

Tests that were created to verify the clustering output of surnames and forenames against the onomap.

The SQL functions in names_functions assume that there are three tables in postgres:

 - Table 1: onomap_test with fields forename(text), surname(text), type2(text)

 - Table 2: group_forenames with fields forename(text), score(double precision), country(text)

 - Table 3: group_surnames with fields surname(text), score(double precision), country(text)

### function1

 - Objective: Match record using surname on surname only; take origin with the highest score

 - Algorithm: Iterates over unique surnames in the onomap table and finds matches in the group_surnames table

 - Returns: table with 3 columns: surname text, country_ono text, country_clustering text

### function2

 - Objective: Match record using forename on forename only; take origin with the highest score

 - Algorithm: Iterates over unique forenames in the onomap table and finds matches in the group_forenames table

 - Returns: table with 3 columns: forename text, country_ono text, country_clustering text

### function3

 - Objective: Match record using surname on surname only - if:
    - Single match, assign origin
    - Multiple match, check forename
       - If forename origin match surname origin, assign origin
       - If forename origin different from surname origin, assign origin based on highest score from either forename or surname
 
 - Algorithm: Iterates over every row in the onomap table and finds matches in the group_surnames table, if multiple matches finds matches in the group_forenames table and picks the country with the highest score

 - Returns: table with 4 columns: forename text, surname text, country_ono text, country_clustering text

### function4

 - Objective: Match record using surname and forename; select origin based on highest score assigned to either the surname or forename

 - Algorithm: Iterates over every row in the onomap table and finds matches in the group_surnames table and group_forenames table selects the country with the highest score

 - Returns: table with 4 columns: forename text, surname text, country_ono text, country_clustering text

### function5

 - Arguments: forename_weight double precision default 1, surname_weight double precision default 1

 - Objective: Match record using surname and forename; select origin based on:
   - Sum of origin scores (forename + surname), select origin based on the highest score
   - Optionally allows weighting forename and surname scores

 - Algorithm: Iterates over every row in the onomap table and finds matches in the group_surnames table and group_forenames table
   Then takes the weighted sum of the countries from both surnames and forenames tables and selects the highest

 - Returns: table with 4 columns: forename text, surname text, country_ono text, country_clustering text


### Testing the functions

CREATE TABLE test1 AS (SELECT * FROM function1());

CREATE TABLE test2 AS (SELECT * FROM function2());

CREATE TABLE test3 AS (SELECT * FROM function3());

CREATE TABLE test4 AS (SELECT * FROM function4());

CREATE TABLE test5 AS (SELECT * FROM function5(surname_weight:=1.5));

CREATE TABLE test5b AS (SELECT * FROM function5(forename_weight:=2, surname_weight:=3));
