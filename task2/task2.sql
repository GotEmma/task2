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
  visitbonus NUMERIC NOT NULL,
  PRIMARY KEY(country, name),
  FOREIGN KEY(country, name) REFERENCES Areas(country, name),
  CONSTRAINT bonus_positive CHECK (visitbonus >= 0)
);
CREATE TABLE Persons(country TEXT,
  personnummer VARCHAR(13),
  name TEXT NOT NULL,
  locationcountry TEXT NOT NULL,
  locationarea TEXT NOT NULL,
  budget NUMERIC NOT NULL,
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

CREATE OR REPLACE VIEW NextMoves AS
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
    SELECT DISTINCT ON (personcountry, personnummer, country, area, destcountry, destarea)
    *
    FROM NextMovesSub
    WHERE personnummer != '' AND personcountry != ''
    ORDER by personnummer, personcountry, country, area, destcountry, destarea, cost ASC
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
    FROM Persons WHERE Persons.personnummer != '' AND Persons.country != ''
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
            RAISE EXCEPTION 'Road already exists for that owner';
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
                 RAISE EXCEPTION 'Person have to be located where the road begin/end';
                 RETURN NULL;
              END IF;
              RAISE EXCEPTION 'Player does not have enough money to buy a road';
              RETURN NULL;
        END IF ;
        RETURN NEW;

      ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.fromcountry != NEW.fromcountry OR OLD.fromarea != NEW.fromarea OR OLD.tocountry != NEW.tocountry
            OR OLD.toarea != NEW.toarea OR OLD.ownercountry != NEW.ownercountry OR OLD.ownerpersonnummer != NEW.ownerpersonnummer
            THEN
            RAISE EXCEPTION 'You can only change the roadtax';
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
CREATE OR REPLACE FUNCTION hotel() RETURNS TRIGGER AS $hotelChanges$
  BEGIN
    IF (TG_OP = 'INSERT') THEN
      IF (EXISTS (SELECT * FROM Hotels
          WHERE ownercountry = NEW.ownercountry AND ownerpersonnummer = NEW.ownerpersonnummer
          AND locationname = NEW.locationname AND locationcountry = NEW.locationcountry))
          THEN
          RAISE EXCEPTION 'Person already owns hotel in this city';
          RETURN NULL;
      END IF;
      IF ((SELECT budget FROM Persons WHERE country = NEW.ownercountry AND personnummer = NEW.ownerpersonnummer)
          < getval('hotelprice'))
        THEN
        RAISE EXCEPTION 'Persons cannot afford to buy this hotel';
        RETURN NULL;
      END IF;
      RETURN NEW;
    ELSIF (TG_OP = 'UPDATE') THEN
      IF OLD.locationname != NEW.locationname OR OLD.locationcountry != NEW.locationcountry
        THEN
        RAISE EXCEPTION 'You cannot change location of a hotel';
        RETURN NULL;
      END IF;
      IF (EXISTS (SELECT * FROM Hotels WHERE OLD.locationcountry = locationcountry AND OLD.locationname = locationname
        AND ownercountry = NEW.ownercountry AND ownerpersonnummer = NEW.ownerpersonnummer))
        THEN
        RAISE EXCEPTION 'The new owner already has a hotel in this city';
        RETURN NULL;
      END IF;
      RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
      UPDATE Persons SET budget = budget + (getval('hotelrefund')*getval('hotelprice')) WHERE
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
CREATE FUNCTION payHotel() RETURNS TRIGGER AS $$
  BEGIN
    UPDATE Persons SET budget = budget - getval('hotelprice') WHERE
    NEW.ownercountry = country AND NEW.ownerpersonnummer = personnummer;
    RETURN NEW;
  END;
$$ LANGUAGE plpgsql
;
  CREATE TRIGGER payHotel
    AFTER INSERT ON Hotels
    FOR EACH ROW
    EXECUTE PROCEDURE payHotel()
  ;
CREATE OR REPLACE FUNCTION changeLocation() RETURNS TRIGGER AS $$
  BEGIN
    -- See if there is a road to the new location
    IF (NOT EXISTS (SELECT * FROM NextMoves WHERE personnummer = NEW.personnummer AND personcountry = NEW.country
      AND destcountry = NEW.locationcountry AND destarea = NEW.locationarea))
    THEN
    RAISE EXCEPTION 'There is no road to the new location';
    RETURN NULL;
      -- Check if Person have enough  money to roadtax
    ELSIF ((SELECT DISTINCT ON (personnummer, personcountry, destarea, destcountry) cost FROM NextMoves WHERE personnummer = NEW.personnummer AND personcountry = NEW.country
        AND destcountry = NEW.locationcountry AND destarea = NEW.locationarea)
        > NEW.budget)
      THEN
      RAISE EXCEPTION 'Person cannot afford to travel on that road';
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
      RAISE EXCEPTION 'Person cannot afford cityvisit';
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
  DECLARE
    tax NUMERIC;
  BEGIN
    tax := (SELECT DISTINCT ON (personnummer, personcountry, destarea, destcountry) cost FROM NextMoves WHERE personnummer = NEW.personnummer AND personcountry = NEW.country
        AND destcountry = OLD.locationcountry AND destarea = OLD.locationarea);

  --deduct money for roadtax
  UPDATE Persons SET budget = budget - tax WHERE personnummer = NEW.personnummer AND country = NEW.country;
  IF tax != 0
  THEN
    --add roadtax money to road owner
    UPDATE Persons SET budget = budget + Roads.roadtax
    FROM Roads
    WHERE ((Roads.tocountry = NEW.locationcountry AND Roads.toarea = NEW.locationarea AND Roads.fromcountry = OLD.locationcountry
    AND Roads.fromarea = OLD.locationarea) OR (Roads.tocountry = OLD.locationcountry AND Roads.toarea = OLD.locationarea AND Roads.fromcountry = NEW.locationcountry
    AND Roads.fromarea = NEW.locationarea)) AND Roads.ownerpersonnummer = Persons.personnummer AND Roads.ownercountry = Persons.country;
  END IF;
  -- check if it is a city
  IF(EXISTS (SELECT * FROM Cities
    WHERE NEW.locationarea = name AND NEW.locationcountry = country))
    --Check if there are hotels in the city
    THEN IF(EXISTS (SELECT * FROM Hotels
      WHERE locationcountry = NEW.locationcountry AND locationname = NEW.locationarea))
      --update budget, deduct cityvisit
      THEN UPDATE Persons SET budget = budget - getval('cityvisit')
        WHERE personnummer = NEW.personnummer AND country = NEW.country;
      --update hotelowners' budget(s)
      UPDATE Persons SET budget = budget + (getval('cityvisit')/
        (SELECT count(*) FROM Hotels WHERE locationcountry = NEW.locationcountry AND locationname = NEW.locationarea))
        FROM Hotels
        WHERE Hotels.locationcountry = NEW.locationcountry AND Hotels.locationname = NEW.locationarea
        AND Hotels.ownercountry = Persons.country AND Hotels.ownerpersonnummer = Persons.personnummer;
    END IF;
    -- check if there is a visitbonus
    IF((SELECT visitbonus FROM Cities
      WHERE NEW.locationarea = name AND NEW.locationcountry = country) != 0)
      --add visitbonus
      THEN UPDATE Persons SET budget = budget + (SELECT visitbonus FROM Cities
        WHERE NEW.locationarea = name AND NEW.locationcountry = country)
      WHERE personnummer = NEW.personnummer AND country = NEW.country;
      --set visitbonus to 0
      UPDATE Cities SET visitbonus = 0
      WHERE NEW.locationarea = name AND NEW.locationcountry = country;
    END IF;
    RETURN NEW;
  ELSE
    RETURN NEW;
  END IF;
  END;
$$ LANGUAGE plpgsql ;
CREATE TRIGGER afterChangeLocation
  AFTER UPDATE OF locationarea ON Persons
  FOR EACH ROW
  EXECUTE PROCEDURE afterChangeLocation()
;
