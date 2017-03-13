-- tests that budget can't be negative
INSERT INTO Countries VALUES ('Sweden');
INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Persons VALUES ('Sweden','12345678-1234','player1','Sweden','Gothenburg',-1000);
