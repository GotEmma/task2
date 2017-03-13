--tests roadtrigger
INSERT INTO Countries VALUES ('Sweden');

INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Areas VALUES ('Sweden','Stockholm',1100000);
INSERT INTO Areas VALUES ('Sweden','Malmo',200000);

INSERT INTO Persons VALUES ('Sweden','11111111-1111','Player1','Sweden','Gothenburg',2000);

INSERT INTO Roads VALUES ('Sweden','Gothenburg','Sweden','Stockholm','Sweden','11111111-1111',getval('roadtax'));

-- check that Player1 has 1543,1 in budget
SELECT assert((SELECT budget FROM Persons WHERE personnummer = '11111111-1111'), 1543.1);

--Insert a road to locationarea
INSERT INTO Roads VALUES ('Sweden', 'Malmo', 'Sweden','Gothenburg','Sweden','11111111-1111',getval('roadtax'));

--change road tax
UPDATE Roads SET roadtax = 55 WHERE toarea = 'Stockholm';
