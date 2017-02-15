--Tests that the visit bouns can't be negative
INSERT INTO Countries VALUES ('Sweden');
INSERT INTO Areas VALUES ('Sweden','Gothenburg',491630);
INSERT INTO Cities VALUES ('Sweden', 'Gothenburg',-1000);
