--tests hoteltriggers
INSERT INTO Countries VALUES ('Sweden');

INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Areas VALUES ('Sweden','Stockholm',1100000);

INSERT INTO Cities VALUES ('Sweden','Gothenburg',0);
INSERT INTO Cities VALUES ('Sweden', 'Stockholm', 0);

INSERT INTO Persons VALUES ('Sweden','11111111-1111','Player1','Sweden','Gothenburg',2000);
INSERT INTO Persons VALUES ('Sweden','22222222-2222','Player2','Sweden','Gothenburg',1000);

INSERT INTO Hotels VALUES ('firstHotel', 'Sweden', 'Stockholm', 'Sweden','11111111-1111');
-- check that Player1 has 1210.8 in budget
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '11111111-1111'), 1210.8);

INSERT INTO Hotels VALUES ('secondHotel', 'Sweden', 'Gothenburg', 'Sweden','11111111-1111');
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '11111111-1111'), 421.6);

--Change owner (no money is transfered)
UPDATE Hotels SET ownerpersonnummer ='22222222-2222' WHERE locationname = 'Stockholm';
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '11111111-1111'), 421.6);
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '22222222-2222'), 1000);

--Delete hotel and owner gets refund
DELETE FROM Hotels WHERE ownerpersonnummer = '22222222-2222';
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '22222222-2222'), 1394.6);
