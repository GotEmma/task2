
INSERT INTO Countries VALUES ('Sweden');
INSERT INTO Countries VALUES ('Denmark');

INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Areas VALUES ('Sweden','Stockholm',1100000);
INSERT INTO Areas VALUES ('Sweden','Malmo',200000);
INSERT INTO Areas VALUES ('Denmark','Copenhagen',1100000);

INSERT INTO Persons VALUES ('Sweden','11111111-1111','Player1','Sweden','Gothenburg',1000);

INSERT INTO Roads VALUES ('Sweden','Gothenburg','Sweden','Stockholm','Sweden','11111111-1111',getval('roadtax'));

--tests that the same person can't own a road (a -> b) AND a road (b -> a)
INSERT INTO Roads VALUES ('Sweden','Stockholm','Sweden','Gothenburg','Sweden','11111111-1111',getval('roadtax'));

--tests that a person can't buy a road (a -> b) if they're not located in a or b
INSERT INTO Roads VALUES ('Sweden','Stockholm','Sweden','Malmo','Sweden','11111111-1111',getval('roadtax'));

--buy another road to use up the budget
INSERT INTO Roads VALUES ('Sweden','Gothenburg','Sweden','Malmo','Sweden','11111111-1111',getval('roadtax'));

--tests that a person cannot buy a road if they don't have enough money
INSERT INTO Roads VALUES ('Sweden','Gothenburg','Denmark','Copenhagen','Sweden','11111111-1111',getval('roadtax'));

INSERT INTO Persons VALUES ('Sweden','22222222-2222','Player2','Sweden','Stockholm',1000);

--tests updating other values than roadtax
UPDATE Roads SET ownerpersonnummer = '22222222-2222' WHERE fromcountry = 'Sweden' AND fromarea = 'Gothenburg' AND
  tocountry = 'Sweden' AND toarea = 'Stockholm' AND ownercountry = 'Sweden' AND ownerpersonnummer = '11111111-1111';

UPDATE Roads SET roadtax = 22, toarea = 'Malmo' WHERE fromcountry = 'Sweden' AND fromarea = 'Gothenburg' AND
  tocountry = 'Sweden' AND toarea = 'Stockholm' AND ownercountry = 'Sweden' AND ownerpersonnummer = '11111111-1111';
