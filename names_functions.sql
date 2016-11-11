

--------------------------------------------------------------------------------------------------------------------------------------
--                                                             Function 1                                                           --
--                        Match record using surname on surname only; take origin with the highest score                            --
--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION function1()
RETURNS TABLE(surname text, country_ono text, country_clustering text) AS $$
   DECLARE 
      sname text;
      country_ono text;
   BEGIN
   FOR sname, country_ono IN
   SELECT DISTINCT ON (onomap_test.surname) onomap_test.surname, onomap_test.type2 FROM onomap_test
   LOOP
   BEGIN RETURN QUERY
      WITH 
      surnames_clustering AS
      (SELECT group_surnames.surname AS surname, group_surnames.country AS country, group_surnames.score AS score
         FROM group_surnames WHERE group_surnames.surname = sname),
      country_top_score AS 
      (SELECT
         (CASE 
            WHEN (SELECT count(*) AS rows_nr FROM surnames_clustering) = 0 THEN
               'UNCLASSIFIED'::text
            ELSE
               (SELECT surnames_clustering.country AS country
                  FROM surnames_clustering ORDER BY surnames_clustering.score DESC LIMIT 1)
            END) country_cl)
      SELECT sname, country_ono, country_top_score.country_cl FROM country_top_score;
   END;
   END LOOP;
   END $$
LANGUAGE plpgsql;


--------------------------------------------------------------------------------------------------------------------------------------
--                                                             Function 2                                                           --
--                        Match record using forename on forename only; take origin with the highest score                          --
--------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION function2()
RETURNS TABLE(forename text, country_ono text, country_clustering text) AS $$
   DECLARE 
      fname text;
      country_ono text;
   BEGIN
   FOR fname, country_ono IN
   SELECT DISTINCT ON (onomap_test.forename) onomap_test.forename, onomap_test.type2 FROM onomap_test
   LOOP
   BEGIN RETURN QUERY
      WITH 
      forenames_clustering AS
      (SELECT group_forenames.forename AS forename, group_forenames.country AS country, group_forenames.score AS score
         FROM group_forenames WHERE group_forenames.forename = fname),
      country_top_score AS 
      (SELECT
         (CASE 
            WHEN (SELECT count(*) AS rows_nr FROM forenames_clustering) = 0 THEN
               'UNCLASSIFIED'::text
            ELSE
               (SELECT forenames_clustering.country AS country
                  FROM forenames_clustering ORDER BY forenames_clustering.score DESC LIMIT 1)
            END) country_cl)
      SELECT fname, country_ono, country_top_score.country_cl FROM country_top_score;
   END;
   END LOOP;
   END $$
LANGUAGE plpgsql;


--------------------------------------------------------------------------------------------------------------------------------------
--                                                             Function 3                                                           --
--                                               Match record using surname on surname only - if:                                   --
--  a) Single match, assign origin                                                                                                  --
--  b) Multiple match, check forename                                                                                               --
--  i. If forename origin match surname origin, assign origin                                                                       --
--  ii. If forename origin different from surname origin, assign origin based on highest score from either forename or surname      --
--------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION function3()
RETURNS TABLE(forename text, surname text, country_ono text, country_clustering text) AS $$
   DECLARE 
      fname text;
      sname text;
      country_ono text;
   BEGIN
   FOR fname, sname, country_ono IN
   SELECT onomap_test.forename, onomap_test.surname, onomap_test.type2 FROM onomap_test
   LOOP
   BEGIN RETURN QUERY
      WITH 
      forenames_clustering AS
      (SELECT group_forenames.forename AS forename, group_forenames.country AS country, group_forenames.score AS score
         FROM group_forenames WHERE group_forenames.forename = fname),
      country_top_score AS 
      (SELECT
         (CASE 
            WHEN (SELECT count(*) AS rows_nr FROM forenames_clustering) = 0 THEN
               'UNCLASSIFIED'::text
            WHEN (SELECT count(*) AS rows_nr FROM forenames_clustering) = 1 THEN
               (SELECT forenames_clustering.country FROM forenames_clustering)
            ELSE
               (WITH surnames_top_clustering AS
               (SELECT group_surnames.country AS country, group_surnames.score AS score
                  FROM group_surnames WHERE group_surnames.surname = sname ORDER BY group_surnames.score DESC LIMIT 1),
               forenames_top_clustering AS
               (SELECT forenames_clustering.country AS country, forenames_clustering.score AS score
                  FROM forenames_clustering ORDER BY forenames_clustering.score DESC LIMIT 1)
               SELECT
               (CASE
                  WHEN (SELECT count(*) FROM surnames_top_clustering) = 0 THEN
                     (SELECT forenames_top_clustering.country FROM forenames_top_clustering)
                  WHEN (SELECT surnames_top_clustering.score FROM surnames_top_clustering) > (SELECT forenames_top_clustering.score FROM forenames_top_clustering) THEN
                     (SELECT surnames_top_clustering.country FROM surnames_top_clustering)
                  ELSE
                     (SELECT forenames_top_clustering.country FROM forenames_top_clustering)
                  END) score_compare_country)
            END) country_cl)
      SELECT fname, sname, country_ono, country_top_score.country_cl FROM country_top_score;
   END;
   END LOOP;
   END $$
LANGUAGE plpgsql;


--------------------------------------------------------------------------------------------------------------------------------------
--                                                             Function 4                                                           --
--                                                Match record using surname and forename;                                          --
--                             select origin based on highest score assigned to either the surname or forename                      --
--------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION function4()
RETURNS TABLE(forename text, surname text, country_ono text, country_clustering text) AS $$
   DECLARE 
      fname text;
      sname text;
      country_ono text;
   BEGIN
   FOR fname, sname, country_ono IN
   SELECT onomap_test.forename, onomap_test.surname, onomap_test.type2 FROM onomap_test
   LOOP
   BEGIN RETURN QUERY
      WITH 
      forenames_clustering AS
      (SELECT group_forenames.forename AS forename, group_forenames.country AS country, group_forenames.score AS score
         FROM group_forenames WHERE group_forenames.forename = fname),
      surnames_clustering AS
      (SELECT group_surnames.surname AS surname, group_surnames.country AS country, group_surnames.score AS score
         FROM group_surnames WHERE group_surnames.surname = sname),
      country_top_score AS 
      (SELECT
         (CASE 
            WHEN (SELECT count(*) FROM forenames_clustering) = 0 AND (SELECT count(*) FROM surnames_clustering) = 0 THEN
               'UNCLASSIFIED'::text
            WHEN (SELECT count(*) FROM forenames_clustering) = 0 AND (SELECT count(*) FROM surnames_clustering) != 0 THEN
               (SELECT surnames_clustering.country FROM surnames_clustering ORDER BY surnames_clustering.score DESC LIMIT 1)
            WHEN (SELECT count(*) FROM forenames_clustering) != 0 AND (SELECT count(*) FROM surnames_clustering) = 0 THEN
               (SELECT forenames_clustering.country FROM forenames_clustering ORDER BY forenames_clustering.score DESC LIMIT 1)
            ELSE
               (WITH 
               forenames_top_clustering AS
               (SELECT forenames_clustering.country AS country, forenames_clustering.score AS score
                  FROM forenames_clustering ORDER BY forenames_clustering.score DESC LIMIT 1),
               surnames_top_clustering AS
               (SELECT surnames_clustering.country AS country, surnames_clustering.score AS score
                  FROM surnames_clustering ORDER BY surnames_clustering.score DESC LIMIT 1)
               SELECT
               (CASE
                  WHEN (SELECT surnames_top_clustering.score FROM surnames_top_clustering) > (SELECT forenames_top_clustering.score FROM forenames_top_clustering) THEN
                     (SELECT surnames_top_clustering.country FROM surnames_top_clustering)
                  ELSE
                     (SELECT forenames_top_clustering.country FROM forenames_top_clustering)
                  END) score_compare_country)
            END) country_cl)
      SELECT fname, sname, country_ono, country_top_score.country_cl FROM country_top_score;
   END;
   END LOOP;
   END $$
LANGUAGE plpgsql;


--------------------------------------------------------------------------------------------------------------------------------------
--                                                             Function 5                                                           --
--                                     Match record using surname and forename; select origin based on:                             --
--                                             Sum of origin scores (forename + surname)                                            --
--                                           Optionally weight forename and surname scores                                          --
--------------------------------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION function5(forename_weight double precision default 1, surname_weight double precision default 1)
RETURNS TABLE(forename text, surname text, country_ono text, country_clustering text) AS $$
   DECLARE 
      fname text;
      sname text;
      country_ono text;
   BEGIN
   FOR fname, sname, country_ono IN
   SELECT onomap_test.forename, onomap_test.surname, onomap_test.type2 FROM onomap_test
   LOOP
   BEGIN RETURN QUERY
      WITH 
      forenames_clustering AS
      (SELECT group_forenames.forename AS forename, group_forenames.country AS country, group_forenames.score AS score
         FROM group_forenames WHERE group_forenames.forename = fname),
      surnames_clustering AS
      (SELECT group_surnames.surname AS surname, group_surnames.country AS country, group_surnames.score AS score
         FROM group_surnames WHERE group_surnames.surname = sname),
      country_top_score AS 
      (SELECT
         (CASE 
            WHEN (SELECT count(*) FROM forenames_clustering) = 0 AND (SELECT count(*) FROM surnames_clustering) = 0 THEN
               'UNCLASSIFIED'::text
            WHEN (SELECT count(*) FROM forenames_clustering) = 0 AND (SELECT count(*) FROM surnames_clustering) != 0 THEN
               (SELECT surnames_clustering.country FROM surnames_clustering ORDER BY surnames_clustering.score DESC LIMIT 1)
            WHEN (SELECT count(*) FROM forenames_clustering) != 0 AND (SELECT count(*) FROM surnames_clustering) = 0 THEN
               (SELECT forenames_clustering.country FROM forenames_clustering ORDER BY forenames_clustering.score DESC LIMIT 1)
            ELSE
               (WITH 
               collect_data AS
               (SELECT s.score AS s_score, s.country AS s_country, f.score AS f_score, f.country AS f_country
               FROM surnames_clustering s FULL JOIN forenames_clustering f ON s.country = f.country),
               sum_scores AS
               (SELECT surname_weight * coalesce(s_score, 0) + forename_weight * coalesce(f_score, 0) AS sum_score, coalesce(s_country, f_country) AS country
               FROM collect_data GROUP BY s_score, f_score, s_country, f_country ORDER BY sum_score DESC LIMIT 1)
               (SELECT sum_scores.country FROM sum_scores))
            END) country_cl)
      SELECT fname, sname, country_ono, country_top_score.country_cl FROM country_top_score;
   END;
   END LOOP;
   END $$
LANGUAGE plpgsql;
