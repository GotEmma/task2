--Tests pop_positive constraint by trying to add negative population
INSERT INTO Countries VALUES ('Sweden');
INSERT INTO Areas VALUES ('Sweden','Gothenburg',-10);
