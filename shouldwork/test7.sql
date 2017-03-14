--tests persontriggers
INSERT INTO Countries VALUES ('');
INSERT INTO Countries VALUES ('Sweden');
INSERT INTO Countries VALUES ('Denmark');

INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Areas VALUES ('Sweden','Stockholm',1100000);
INSERT INTO Areas VALUES ('Sweden','Malmo',200000);
INSERT INTO Areas VALUES ('Denmark','Copenhagen',1100000);

INSERT INTO Cities VALUES ('Sweden','Stockholm',1000);
INSERT INTO Cities VALUES ('Sweden','Gothenburg',2000);
INSERT INTO Cities VALUES ('Denmark','Copenhagen',0);

INSERT INTO Persons VALUES ('','','The_government','Sweden','Gothenburg',1000000000000);
INSERT INTO Persons VALUES ('Sweden','11111111-1111','Player1','Sweden','Gothenburg',10000);
INSERT INTO Persons VALUES ('Sweden','22222222-2222','Player2','Sweden','Gothenburg',10000);
INSERT INTO Persons VALUES ('Denmark','33333333-3333','Player3','Sweden','Gothenburg',10000);
INSERT INTO Persons VALUES ('Denmark','44444444-4444','Player4','Sweden','Malmo',10000);

INSERT INTO Hotels VALUES ('firstHotel', 'Sweden', 'Gothenburg', 'Sweden','11111111-1111');
INSERT INTO Hotels VALUES ('secondHotel', 'Denmark', 'Copenhagen', 'Sweden','22222222-2222');
INSERT INTO Hotels VALUES ('thirdHotel','Denmark', 'Copenhagen','Denmark','33333333-3333');

INSERT INTO Roads VALUES ('Sweden','Gothenburg','Sweden','Malmo','','',getval('roadtax'));
INSERT INTO Roads VALUES ('Sweden','Gothenburg','Sweden','Stockholm','Sweden','22222222-2222',getval('roadtax'));
INSERT INTO Roads VALUES ('Sweden','Malmo','Denmark','Copenhagen','','',getval('roadtax'));

UPDATE Persons SET budget = 1000000 WHERE personnummer != '';

UPDATE Persons SET locationarea = 'Malmo' WHERE personnummer='11111111-1111';
--Travel on government owned road
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '11111111-1111'), 1000000);

UPDATE Persons SET locationarea = 'Stockholm' WHERE personnummer='22222222-2222';
--Travel on own road, got visitbonus
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '22222222-2222'), 1001000);

UPDATE Persons SET locationarea = 'Stockholm' WHERE personnummer='33333333-3333';
--Check that roadtax is deducted
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '33333333-3333'), 999986.5);
--Check that roadtax is added to roadowner
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '22222222-2222'), 1001013.5);

UPDATE Persons SET locationarea = 'Gothenburg' WHERE personnummer='44444444-4444';
--Check that cityvisit is deducted and visitbonus is added
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '44444444-4444'), 899969.7);
--Check that hotelowner got cityvisit
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '11111111-1111'), 1102030.3);

UPDATE Persons SET locationarea = 'Copenhagen', locationcountry = 'Denmark' WHERE personnummer='11111111-1111';
--Check that cityvisit is deducted
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '11111111-1111'), 1000000);
--Check that hotelowners got cityvisit
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '22222222-2222'), 1052028.65);
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '33333333-3333'), 1051001.65);
