-- tests personnummer,each try schould fail
INSERT INTO Countries VALUES ('Sweden');
INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Persons VALUES ('Sweden','123456781234','player1','Sweden','Gothenburg',1000);
INSERT INTO Persons VALUES ('Sweden','123456781-234','player1','Sweden','Gothenburg',1000);
INSERT INTO Persons VALUES ('Sweden','2345678-1234','player1','Sweden','Gothenburg',1000);
