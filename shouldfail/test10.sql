-- test insert hotel
INSERT INTO Countries VALUES ('Sweden');

INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Areas VALUES ('Sweden','Stockholm',1100000);

INSERT INTO Cities VALUES ('Sweden','Gothenburg',0);
INSERT INTO Cities VALUES ('Sweden', 'Stockholm', 0);

INSERT INTO Persons VALUES ('Sweden','11111111-1111','Player1','Sweden','Gothenburg',1000);
INSERT INTO Persons VALUES ('Sweden','22222222-2222','Player2','Sweden','Gothenburg',1000);

--try to own two hotels in same city
INSERT INTO Hotels VALUES ('firstHotel', 'Sweden', 'Stockholm', 'Sweden','11111111-1111');
INSERT INTO Hotels VALUES ('secondHotel', 'Sweden', 'Stockholm', 'Sweden','11111111-1111');

--try to build hotel when budget is too small
INSERT INTO Hotels VALUES ('secondHotel', 'Sweden', 'Gothenburg', 'Sweden','11111111-1111');

INSERT INTO Hotels VALUES ('secondHotel', 'Sweden', 'Stockholm', 'Sweden','22222222-2222');
--try to change city of hotel
UPDATE Hotels SET locationname = 'Gothenburg' WHERE name = 'secondHotel';
--try to change owner when new owner already have a hotel in the city
UPDATE Hotels SET ownerpersonnummer = '11111111-1111' WHERE name = 'secondHotel';
