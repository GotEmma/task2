-- tests the two valid formats of the personal number
INSERT INTO Countries VALUES ('');
INSERT INTO Countries VALUES ('Sweden');
INSERT INTO Countries VALUES ('Denmark');
INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Areas VALUES ('Denmark','Copenhagen',1200000);
INSERT INTO Persons VALUES ('','','The_government','Sweden','Gothenburg',1000000000000);
INSERT INTO Persons VALUES ('Sweden','12345678-1234','player1','Sweden','Gothenburg',1000);
INSERT INTO Persons VALUES ('Denmark','00000000-0000','player2','Sweden','Gothenburg',0);
