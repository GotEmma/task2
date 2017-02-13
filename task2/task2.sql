CREATE TABLE Countries (name TEXT,
  PRIMARY KEY (name)
);
CREATE TABLE Areas (country TEXT,
  name TEXT,
  population INT,
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
  name TEXT,
  locationcountry TEXT,
  locationarea TEXT,
  budget NUMERIC,
  PRIMARY KEY(country, personnummer),
  FOREIGN KEY(country) REFERENCES Countries(name),
  FOREIGN KEY(locationcountry, locationarea) REFERENCES Areas(country, name),
  CONSTRAINT format_personnummer CHECK
  (personnummer LIKE '[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]' ),
  CONSTRAINT budget_positive CHECK (budget >= 0)
);
CREATE TABLE Hotels (name TEXT,
  locationcountry TEXT,
  locationname TEXT,
  ownercountry TEXT,
  ownerpersonnummer VARCHAR(13),
  PRIMARY KEY(locationcountry, locationname, ownercountry, ownerpersonnummer),
  FOREIGN KEY(locationcountry, locationname) REFERENCES Cities(country, name),
  FOREIGN KEY(ownercountry, ownerpersonnummer) REFERENCES Persons(country, personnummer)
);
