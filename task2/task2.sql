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
  UNION
    (SELECT Roads.roadtax as cost
      FROM Persons INNER JOIN Roads ON
      (Persons.locationcountry = Roads.tocountry AND Persons.locationarea = Roads.toarea) OR
      (Persons.locationcountry = Roads.fromcountry AND Persons.locationarea = Roads.fromarea) AND
      NOT ((Persons.country = Roads.ownercountry AND Persons.personnummer = Roads.ownerpersonnummer)
      OR (''= Roads.ownercountry AND '' = Roads.ownerpersonnummer))
  ORDER by personnummer
  ;

  --Roads.roadtax


CREATE FUNCTION roadChanges() RETURNS TRIGGER AS $road$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    IF (EXISTS (SELECT toarea, fromarea, ownercountry, ownerpersonnummer FROM Roads WHERE
        ((ownerpersonnummer = NEW.ownerpersonnummer) AND (ownercountry = NEW.ownercountry)
        AND (toarea = NEW.toarea OR toarea = NEW.fromarea) AND (fromarea = NEW.fromarea OR fromarea = NEW.toarea))))
        THEN RETURN NULL;
    ELSIF (EXISTS (SELECT toarea, fromarea, ownercountry, ownerpersonnummer, roadtax FROM Roads
        WHERE NEW.ownercountry != '' AND NEW.ownerpersonnummer != ''))
        THEN IF (EXISTS (SELECT locationcountry, locationarea, personnummer FROM Persons
                 WHERE (locationarea = NEW.toarea AND locationcountry = NEW.ownercountry AND personnummer = NEW.ownerpersonnummer)
                 OR (NEW.fromarea = locationarea AND locationcountry = NEW.ownercountry AND personnummer = NEW.ownerpersonnummer)))
                 THEN UPDATE Persons SET budget = budget - 33 WHERE personnummer = NEW.ownerpersonnummer AND country = NEW.ownercountry;
                 RETURN NEW;
             END IF;
             RETURN NULL;
    END IF ;
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    IF (EXISTS (SELECT toarea, fromarea FROM Roads WHERE
         toarea = OLD.fromarea AND fromarea = OLD.toarea))
         THEN DELETE FROM Roads WHERE toarea = OLD.fromarea AND fromarea = OLD.toarea;
         RETURN NULL;
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
$road$ LANGUAGE plpgsql
;
CREATE TRIGGER road
  BEFORE INSERT OR DELETE OR UPDATE ON Roads
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
      UPDATE Persons SET budget = budget - 56 WHERE
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
      UPDATE Persons SET budget = budget + 25 WHERE
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
