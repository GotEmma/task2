-- tests to change a players location
INSERT INTO Countries VALUES ('Sweden');

INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Areas VALUES ('Sweden','Stockholm',1100000);
INSERT INTO Areas VALUES ('Sweden','Malmo',200000);

INSERT INTO Persons VALUES ('Sweden','11111111-1111','Player1','Sweden','Gothenburg',10000);
INSERT INTO Persons VALUES ('Sweden','22222222-2222','Player2','Sweden','Stockholm',1);
INSERT INTO Persons VALUES ('Sweden','33333333-3333','Player3','Sweden','Stockholm',100000);


INSERT INTO Roads VALUES ('Sweden','Gothenburg','Sweden','Stockholm','Sweden','11111111-1111',getval('roadtax'));

-- Try to move person to a location to which there is no road
UPDATE Persons SET locationarea = 'Malmo' WHERE personnummer = '22222222-2222' AND country = 'Sweden';
-- Try to travel on a road without money for the tax
UPDATE Persons SET locationarea = 'Gothenburg' WHERE personnummer = '22222222-2222' AND country = 'Sweden';

INSERT INTO Cities VALUES ('Sweden', 'Stockholm', 0);

INSERT INTO Hotels VALUES ('grandHotel', 'Sweden', 'Stockholm', 'Sweden','33333333-3333');

--Try to travel to city with hotel without money for cityvisit
UPDATE Persons SET locationarea = 'Stockholm' WHERE personnummer = '11111111-1111' AND country = 'Sweden';
