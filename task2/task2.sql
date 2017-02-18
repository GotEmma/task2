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

CREATE VIEW NextMoves --(personcountry, personnummer, country, area, destcounry, destarea, cost)
  AS
  SELECT Persons.country as personcountry, personnummer, Persons.locationcountry as country,
  Persons.locationarea as area,
  Roads.tocountry as destcounry, Roads.toarea as destarea
  FROM Persons INNER JOIN Roads ON
    Persons.locationcountry = Roads.fromcountry AND Persons.locationarea = Roads.fromarea
  UNION
  SELECT Persons.country as personcountry, personnummer, Persons.locationcountry as country,
  Persons.locationarea as area,
  Roads.fromcountry as destcounry, Roads.fromarea as destarea
  FROM Persons INNER JOIN Roads ON
    Persons.locationcountry = Roads.tocountry AND Persons.locationarea = Roads.toarea
  ORDER by personnummer
  ;

  --Roads.roadtax



CREATE FUNCTION when_road_added() RETURNS TRIGGER AS $addRoad$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF (EXISTS (SELECT toarea, fromarea, ownercountry, ownerpersonnummer FROM Roads WHERE
        ((ownerpersonnummer = NEW.ownerpersonnummer) AND (ownercountry = NEW.ownercountry)
        AND (toarea = NEW.toarea OR toarea = NEW.fromarea) AND (fromarea = NEW.fromarea OR fromarea = NEW.toarea))))
        THEN RETURN NULL;
    ELSIF (EXISTS (SELECT toarea, fromarea, ownercountry, ownerpersonnummer, roadtax FROM Roads
        WHERE NEW.ownercountry != NULL AND NEW.ownerpersonnummer != NULL))
        THEN IF (EXISTS (SELECT locationcountry, locationarea FROM Persons
                WHERE (locationarea = NEW.toarea AND locationcountry = NEW.ownercountry)
                OR (NEW.fromarea = locationarea AND locationcountry = NEW.ownercountry)))
                THEN UPDATE Persons SET budget = budget - 23 WHERE personnummer = NEW.ownerpersonnummer AND country = NEW.ownercountry;
                RETURN NEW;
            END IF;
            RETURN NULL;
    END IF ;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (EXISTS (SELECT toarea, fromarea FROM Roads WHERE
        toarea = OLD.fromarea AND fromarea = OLD.toarea))
        THEN DELETE FROM Roads WHERE toarea = OLD.fromarea AND fromarea = OLD.toarea;
    END IF;
    RETURN OLD;
  ELSIF (TG_OP = 'UPDATE') THEN
    IF (EXISTS (SELECT roadtax FROM Roads
        WHERE roadtax != NEW.roadtax))
        THEN RETURN NEW;
    END IF;
    RETURN NULL;
  END IF;
  RETURN NULL;
END;
$addRoad$ LANGUAGE plpgsql
;

CREATE TRIGGER addRoad
  BEFORE INSERT OR DELETE OR UPDATE ON Roads
  FOR EACH ROW
  EXECUTE PROCEDURE when_road_added()
;


CREATE FUNCTION hotel() RETURNS TRIGGER AS $hotelChanges$
BEGIN
  IF (TG_OP = 'INSERT') THEN
  UPDATE Persons SET budget = budget - getval(’hotelprice’) WHERE NEW.ownercountry = Persons.country AND NEW.ownerpersonnummer = Persons.personnummer;
  RETURN NEW;
  END IF;
END;
$hotelChanges$ LANGUAGE plpgsql
;
CREATE TRIGGER hotelChanges
  BEFORE INSERT OR UPDATE ON Hotels
  FOR EACH ROW
  EXECUTE PROCEDURE hotel()
;
