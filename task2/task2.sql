CREATE TABLE Constants(
    name TEXT PRIMARY KEY,
    value NUMERIC NOT NULL
);

INSERT INTO Constants VALUES('roadprice', 456.9);
INSERT INTO Constants VALUES('hotelprice', 789.2);
INSERT INTO Constants VALUES('roadtax', 13.5);
INSERT INTO Constants VALUES('hotelrefund', 0.50);
INSERT INTO Constants VALUES('cityvisit', 102030.3);

CREATE OR REPLACE FUNCTION getval(qname TEXT) RETURNS NUMERIC AS $$
DECLARE
    xxx NUMERIC;
BEGIN
    xxx := (SELECT value FROM Constants WHERE name = qname);
    RETURN xxx;
END
$$ LANGUAGE 'plpgsql' ;
CREATE OR REPLACE FUNCTION assert(x numeric, y numeric) RETURNS void AS $$
BEGIN
    IF NOT (SELECT trunc(x, 2) = trunc(y, 2))
    THEN
        RAISE 'assert(%=%) failed (up to 2 decimal places, checked with trunc())!', x, y;
    END IF;
    RETURN;
END
$$ LANGUAGE 'plpgsql' ;

CREATE OR REPLACE FUNCTION assert(x text, y text) RETURNS void AS $$
BEGIN
    IF NOT (SELECT x = y)
    THEN
        RAISE 'assert(%=%) failed!', x, y;
    END IF;
    RETURN;
END
$$ LANGUAGE 'plpgsql' ;
CREATE TABLE Countries (name TEXT,
  PRIMARY KEY (name)
);
CREATE TABLE Areas (country TEXT,
  name TEXT,
  population INT NOT NULL,
  PRIMARY KEY(country, name),
  FOREIGN KEY (country) REFERENCES Countries (name),
  CONSTRAINT pop_positive CHECK (population >= 0)
);
CREATE TABLE Towns(country TEXT,
  name TEXT,
  PRIMARY KEY(country, name),
  FOREIGN KEY(country, name) REFERENCES Areas (country, name)
);
CREATE TABLE Cities (country TEXT,
  name TEXT,
  visitbonus INT,
  PRIMARY KEY(country, name),
  FOREIGN KEY(country, name) REFERENCES Areas(country, name),
  CONSTRAINT bonus_positive CHECK (visitbonus >= 0)
);
CREATE TABLE Persons(country TEXT,
  personnummer VARCHAR(13),
  name TEXT NOT NULL,
  locationcountry TEXT NOT NULL,
  locationarea TEXT NOT NULL,
  budget NUMERIC,
  PRIMARY KEY(country, personnummer),
  FOREIGN KEY(country) REFERENCES Countries(name),
  FOREIGN KEY(locationcountry, locationarea) REFERENCES Areas(country, name),
  CONSTRAINT format_personnummer CHECK
  (personnummer ~ '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'
    OR personnummer LIKE '' ),
  CONSTRAINT budget_positive CHECK (budget >= 0)
);
CREATE TABLE Hotels (name TEXT NOT NULL,
  locationcountry TEXT,
  locationname TEXT,
  ownercountry TEXT,
  ownerpersonnummer VARCHAR(13),
  PRIMARY KEY(locationcountry, locationname, ownercountry, ownerpersonnummer),
  FOREIGN KEY(locationcountry, locationname) REFERENCES Cities(country, name),
  FOREIGN KEY(ownercountry, ownerpersonnummer) REFERENCES Persons(country, personnummer)
);
CREATE TABLE Roads (fromcountry TEXT,
  fromarea TEXT,
  tocountry TEXT,
  toarea TEXT,
  ownercountry TEXT,
  ownerpersonnummer VARCHAR(13),
  roadtax NUMERIC NOT NULL,
  PRIMARY KEY (fromcountry, fromarea, tocountry, toarea, ownercountry, ownerpersonnummer),
  FOREIGN KEY (fromcountry, fromarea) REFERENCES Areas(country, name),
  FOREIGN KEY (tocountry,toarea) REFERENCES Areas (country, name),
  FOREIGN KEY (ownercountry, ownerpersonnummer) REFERENCES Persons (country, personnummer),
  CONSTRAINT roadtax_positive CHECK (roadtax >= 0),
  CONSTRAINT distinct_from_and_to CHECK(fromarea != toarea)
);

CREATE OR REPLACE VIEW NextMoves AS --(personcountry, personnummer, country, area, destcountry, destarea, cost)
  WITH NextMovesSub AS (
    SELECT Persons.country as personcountry, personnummer, Persons.locationcountry as country,
    Persons.locationarea as area,
    Roads.tocountry as destcountry, Roads.toarea as destarea, Roads.roadtax as cost
    FROM Persons INNER JOIN Roads ON
      Persons.locationcountry = Roads.fromcountry AND Persons.locationarea = Roads.fromarea
    UNION
    SELECT Persons.country as personcountry, personnummer, Persons.locationcountry as country,
    Persons.locationarea as area,
    Roads.fromcountry as destcountry, Roads.fromarea as destarea, Roads.roadtax as cost
    FROM Persons INNER JOIN Roads ON
      Persons.locationcountry = Roads.tocountry AND Persons.locationarea = Roads.toarea
    UNION
    SELECT Persons.country as personcountry, personnummer, Persons.locationcountry as country,
      Persons.locationarea as area,
      Roads.fromcountry as destcountry, Roads.fromarea as destarea, 0 as cost
      FROM Persons INNER JOIN Roads ON
      (Persons.locationcountry = Roads.tocountry AND Persons.locationarea = Roads.toarea) AND
      ((Persons.country = Roads.ownercountry AND Persons.personnummer = Roads.ownerpersonnummer)
      OR (''= Roads.ownercountry AND '' = Roads.ownerpersonnummer))
    UNION
    SELECT Persons.country as personcountry, personnummer, Persons.locationcountry as country,
          Persons.locationarea as area,
          Roads.tocountry as destcountry, Roads.toarea as destarea, 0 as cost
            FROM Persons INNER JOIN Roads ON
            (Persons.locationcountry = Roads.fromcountry AND Persons.locationarea = Roads.fromarea) AND
            ((Persons.country = Roads.ownercountry AND Persons.personnummer = Roads.ownerpersonnummer)
            OR (''= Roads.ownercountry AND '' = Roads.ownerpersonnummer))
    )
    SELECT
    *
    FROM NextMovesSub
    WHERE personnummer != '' AND personcountry != ''
    --GROUP BY personcountry, personnummer, country, area, destcountry, destarea
    ORDER by personnummer, personcountry, destarea, cost ASC
  --ta översta raden per sträcka person
  ;

  CREATE VIEW AssetSummary AS

    SELECT Persons.country as country, Persons.personnummer as personnummer, Persons.budget as budget,
      (SELECT (count(*) * getval('roadprice'))
        FROM Roads
        WHERE Persons.country = ownercountry AND Persons.personnummer = ownerpersonnummer) +
      (SELECT (count(*)*getval('hotelprice'))
        FROM Hotels
        WHERE Persons.country = ownercountry AND Persons.personnummer = ownerpersonnummer) as assets,
      (SELECT ((count(*)*getval('hotelprice'))*getval('hotelrefund'))
        FROM Hotels
        WHERE Persons.country = ownercountry AND Persons.personnummer = ownerpersonnummer)
      as reclaimable
    FROM Persons
    GROUP by country, personnummer
    ORDER by personnummer
    ;


    CREATE OR REPLACE FUNCTION roadChanges() RETURNS TRIGGER AS $road$
    BEGIN
      IF (TG_OP = 'INSERT') THEN
        IF (EXISTS (SELECT toarea, fromarea, ownercountry, ownerpersonnummer FROM Roads WHERE
            ((ownerpersonnummer = NEW.ownerpersonnummer) AND (ownercountry = NEW.ownercountry)
            AND (toarea = NEW.toarea OR toarea = NEW.fromarea) AND (fromarea = NEW.fromarea OR fromarea = NEW.toarea))))
            THEN
            RAISE NOTICE 'Road already exists for that owner';
            RETURN NULL;
        ELSIF (NEW.ownercountry != '' AND NEW.ownerpersonnummer != '')
              THEN IF ((SELECT budget FROM Persons
              WHERE country = NEW.ownercountry AND personnummer = NEW.ownerpersonnummer) > getval('roadprice'))

                THEN IF (EXISTS (SELECT * FROM Persons
                     WHERE ((locationarea = NEW.toarea AND locationcountry = NEW.tocountry
                       AND personnummer = NEW.ownerpersonnummer AND country = NEW.ownercountry)
                     OR (NEW.fromarea = locationarea AND locationcountry = NEW.fromcountry
                       AND personnummer = NEW.ownerpersonnummer AND country = NEW.ownercountry))))
                     THEN UPDATE Persons SET budget = budget - getval('roadprice') WHERE personnummer = NEW.ownerpersonnummer AND country = NEW.ownercountry;
                     RETURN NEW;
                 END IF;
                 RAISE NOTICE 'Person have to be located where the road begin/end';
                 RETURN NULL;
              END IF;
              RAISE NOTICE 'Player does not have enough money to buy a road';
              RETURN NULL;
        END IF ;
        RETURN NEW;

      ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.fromcountry != NEW.fromcountry OR OLD.fromarea != NEW.fromarea OR OLD.tocountry != NEW.tocountry 
            OR OLD.toarea != NEW.toarea OR OLD.ownercountry != NEW.ownercountry OR OLD.ownerpersonnummer != NEW.ownerpersonnummer
            THEN
            RAISE NOTICE 'You can only change the roadtax';
            RETURN NULL;
        END IF;
        RETURN NEW;
      END IF;
      RETURN NULL;
    END;
    $road$ LANGUAGE plpgsql
    ;
CREATE TRIGGER road
  BEFORE INSERT OR UPDATE ON Roads
  FOR EACH ROW
  EXECUTE PROCEDURE roadChanges()
;
CREATE FUNCTION hotel() RETURNS TRIGGER AS $hotelChanges$
  BEGIN
    IF (TG_OP = 'INSERT') THEN
      IF (EXISTS (SELECT ownercountry, ownerpersonnummer, locationcountry, locationname FROM Hotels
          WHERE ownercountry = NEW.ownercountry AND ownerpersonnummer = NEW.ownerpersonnummer
          AND locationname = NEW.locationname AND locationcountry = NEW.locationcountry))
          THEN RETURN NULL;
      END IF;
      UPDATE Persons SET budget = budget - getval(’hotelprice’) WHERE
      NEW.ownercountry = country AND NEW.ownerpersonnummer = personnummer;
      RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
      IF (EXISTS (SELECT locationcountry, locationname FROM Hotels
          WHERE locationname != NEW.locationname OR NEW.locationname = NULL OR
          locationcountry != NEW.locationcountry OR NEW.locationcountry = NULL))
          THEN RETURN NULL;
      ELSIF (EXISTS (SELECT ownercountry, ownerpersonnummer, locationcountry, locationname FROM Hotels
             WHERE ownercountry = NEW.ownercountry AND ownerpersonnummer = NEW.ownerpersonnummer
             AND locationname = OLD.locationname AND locationcountry = OLD.locationcountry))
             THEN RETURN NULL;
      END IF;
      RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
      UPDATE Persons SET budget = budget + getval(’hotelrefund’) WHERE
      personnummer = OLD.ownerpersonnummer AND country = OLD.ownercountry;
      RETURN OLD;
    END IF;
  END;
$hotelChanges$ LANGUAGE plpgsql
;
 CREATE TRIGGER hotelChanges
   BEFORE INSERT OR UPDATE OR DELETE ON Hotels
   FOR EACH ROW
   EXECUTE PROCEDURE hotel()
;
CREATE FUNCTION person() RETURNS TRIGGER AS $personChanges$
  BEGIN
    IF(TG_OP = 'UPDATE') THEN
      IF (EXISTS (SELECT fromarea, fromcountry, toarea, tocountry, locationarea,
      locationcountry, personnummer, country FROM Roads, Persons
      WHERE (fromarea = NEW.locationarea AND fromcountry = NEW.locationcountry
      AND locationarea = toarea AND locationcountry = tocountry) OR
      (toarea = NEW.locationarea AND tocountry = NEW.locationcountry
      AND locationarea = fromarea AND locationcountry = fromcountry)))
          THEN UPDATE Persons SET budget = budget - (SELECT MIN(cost) FROM NextMoves
          WHERE NextMoves.personnummer = personnummer AND NextMoves.personcountry = country)
          WHERE Persons.personnummer = personnummer AND Persons.country = country;
          IF (EXISTS (SELECT Cities.name, country, Hotels.locationcountry, Hotels.locationname FROM Cities, Hotels
          WHERE name = NEW.locationname AND country = NEW.locationcountry AND
          Hotels.locationcountry = NEW.locationcountry AND Hotels.locationname = NEW.locationname))
              THEN UPDATE Persons SET budget = budget - getval(’cityvisit’) +
              (SELECT visitbonus FROM Cities WHERE Persons.personnummer = personnummer AND Persons.country = country)
              WHERE Persons.personnummer = personnummer;
          END IF;
          RETURN NEW;
      END IF;
      RETURN NULL;
    END IF;
  END;
$personChanges$ LANGUAGE plpgsql
;
CREATE TRIGGER personChanges
  BEFORE UPDATE ON Persons
  FOR EACH ROW
  EXECUTE PROCEDURE person()
;
CREATE OR REPLACE FUNCTION changeLocation() RETURNS TRIGGER AS $$
  BEGIN
    -- See if there is a road to the new location
    IF (NOT EXISTS (SELECT * FROM NextMoves WHERE personnummer = NEW.personnummer AND personcountry = NEW.country
      AND destcountry = NEW.locationcountry AND destarea = NEW.locationarea))
    THEN
    RAISE NOTICE 'There is no road to the new location';
    RETURN NULL;
      -- Check if Person have enough  money to roadtax
    ELSIF ((SELECT DISTINCT ON (personnummer, personcountry, destarea, destcountry) cost FROM NextMoves WHERE personnummer = NEW.personnummer AND personcountry = NEW.country
        AND destcountry = NEW.locationcountry AND destarea = NEW.locationarea)
        > NEW.budget)
      THEN
      RAISE NOTICE 'Person cannot afford to travel on that road';
      RETURN NULL;
    -- Check if there is a cityvisit
    ELSIF (EXISTS (SELECT * FROM Hotels
      WHERE locationcountry = NEW.locationcountry AND locationname = NEW.locationarea))
      -- Check if we have enough money to visit city
      THEN IF ((SELECT DISTINCT ON (personnummer, personcountry, destarea, destcountry) cost FROM NextMoves WHERE personnummer = NEW.personnummer AND personcountry = NEW.country
          AND destcountry = NEW.locationcountry AND destarea = NEW.locationarea) + getval('cityvisit')
            < NEW.budget)
            THEN
            RETURN NEW;
      END IF;
      RAISE NOTICE 'Person cannot afford cityvisit';
      RETURN NULL;
    END IF;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql ;
CREATE TRIGGER changeLocation
  BEFORE UPDATE OF locationarea ON Persons
  FOR EACH ROW
  EXECUTE PROCEDURE changeLocation()
;
CREATE OR REPLACE FUNCTION afterChangeLocation() RETURNS TRIGGER AS $$
  BEGIN
  IF(EXISTS (SELECT * FROM Hotels
    WHERE locationcountry = NEW.locationcountry AND locationname = NEW.locationarea))
  --update budget, deduct roadtax and cityvisit

  THEN UPDATE Persons SET budget = budget - ((SELECT DISTINCT ON (personnummer, personcountry, destarea, destcountry) cost FROM NextMoves WHERE personnummer = NEW.personnummer AND personcountry = NEW.country
      AND destcountry = OLD.locationcountry AND destarea = OLD.locationarea) + getval('cityvisit'))
      WHERE personnummer = NEW.personnummer AND country = NEW.country;
      RETURN NEW;
    ELSE
    -- Deduct money for road tax
      UPDATE Persons SET budget = budget - (SELECT DISTINCT ON (personnummer, personcountry, destarea, destcountry) cost FROM NextMoves WHERE personnummer = NEW.personnummer AND personcountry = NEW.country
          AND destcountry = OLD.locationcountry AND destarea = OLD.locationarea)
      WHERE personnummer = NEW.personnummer AND country = NEW.country;
      RETURN NEW;
    END IF;
  END;
$$ LANGUAGE plpgsql ;
CREATE TRIGGER afterChangeLocation
  AFTER UPDATE OF locationarea ON Persons
  FOR EACH ROW
  EXECUTE PROCEDURE afterChangeLocation()
;
