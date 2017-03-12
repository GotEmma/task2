INSERT INTO Countries VALUES ('');
INSERT INTO Countries VALUES ('Sweden');
INSERT INTO Countries VALUES ('Denmark');
INSERT INTO Countries VALUES ('Germany');
INSERT INTO Countries VALUES ('Austria');

INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Areas VALUES ('Sweden','Stockholm',1100000);
INSERT INTO Areas VALUES ('Sweden','Malmo',200000);
INSERT INTO Areas VALUES ('Denmark','Copenhagen',1100000);
INSERT INTO Areas VALUES ('Germany','Berlin',6000000);
INSERT INTO Areas VALUES ('Germany','Hamburg',2000000);
INSERT INTO Areas VALUES ('Germany','Munich',2000000);
INSERT INTO Areas VALUES ('Austria','Vienna',2000000);

INSERT INTO Persons VALUES ('','','The_government','Sweden','Gothenburg',1000000000000);
INSERT INTO Persons VALUES ('Sweden','11111111-1111','Player1','Sweden','Gothenburg',10000);
INSERT INTO Persons VALUES ('Sweden','22222222-2222','Player2','Sweden','Stockholm',10000);
INSERT INTO Persons VALUES ('Denmark','33333333-3333','Player3','Denmark','Copenhagen',10000);
INSERT INTO Persons VALUES ('Denmark','44444444-4444','Player4','Germany','Munich',10000);

INSERT INTO Roads VALUES ('Sweden','Gothenburg','Sweden','Stockholm','','',getval('roadtax'));
INSERT INTO Roads VALUES ('Sweden','Gothenburg','Sweden','Stockholm','Sweden','11111111-1111',getval('roadtax'));

INSERT INTO Roads VALUES ('Sweden','Malmö','Denmark','Copenhagen','Sweden','22222222-2222',getval('roadtax'));
INSERT INTO Roads VALUES ('Denmark','Copenhagen','Germany','Berlin','Sweden','22222222-2222',getval('roadtax'));

INSERT INTO Roads VALUES ('Germany','Hamburg','Germany','Munich','','',getval('roadtax'));
INSERT INTO Roads VALUES ('Germany','Munich','Sweden','Stockholm','Denmark','44444444-4444',getval('roadtax'));
INSERT INTO Roads VALUES ('Germany','Munich','Austria','Vienna','Sweden','11111111-1111',getval('roadtax'));
