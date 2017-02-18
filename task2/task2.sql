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


CREATE VIEW NextMoves(personcountry, personnummer, country, area, destcountry, destarea, cost) AS
  SELECT Persons.country personcountry, personnummer personnummer, Areas.country country, Areas.name area, Areas.country destcountry, Areas.name destarea,
  CASE WHEN (personnummer = Roads.ownerpersonnummer AND Persons.country = Roads.ownercountry) THEN 0
  ELSE MIN(Roads.roadtax)
  END
  FROM Persons, Areas, Roads
  WHERE (destcountry = Roads.fromcountry AND destarea = Roads.fromarea) OR (destcountry = Roads.tocountry AND destarea = Roads.toarea)
;
CREATE FUNCTION when_road_added() RETURNS TRIGGER AS $addRoad$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF (EXISTS (SELECT toarea, fromarea, ownercountry, ownerpersonnummer FROM Roads WHERE
        ((ownerpersonnummer = NEW.ownerpersonnummer) AND (ownercountry = NEW.ownercountry)
        AND (toarea = NEW.toarea OR toarea = NEW.fromarea) AND (fromarea = NEW.fromarea OR fromarea = NEW.toarea))))
        THEN RETURN NULL;
    END IF ;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (EXISTS (SELECT toarea, fromarea FROM Roads WHERE
    toarea LIKE OLD.fromarea AND fromarea LIKE OLD.toarea))
      THEN DELETE FROM Roads WHERE toarea LIKE OLD.fromarea AND fromarea LIKE OLD.toarea;
    END IF;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$addRoad$ LANGUAGE plpgsql
;
CREATE TRIGGER addRoad
  BEFORE INSERT OR DELETE ON Roads
  FOR EACH ROW
  EXECUTE PROCEDURE when_road_added()
;
