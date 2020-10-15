CREATE TABLE @extschema@."table"(
	"id" 		BIGSERIAL  	NOT NULL PRIMARY KEY,
	"schema" 	TEXT 		NOT NULL,
	"table"  	TEXT 		NOT NULL,
	
	UNIQUE ("schema", "table")
);

CREATE TABLE @extschema@."variable"(
	"schema_from" 	TEXT NOT NULL,
	"table_from" 	TEXT NOT NULL,
	"column_from" 	TEXT NOT NULL,
	"schema_to" 	TEXT NOT NULL,
	"table_to" 		TEXT NOT NULL,
	"column_to" 	TEXT NOT NULL,
	
	PRIMARY KEY ("schema_from", "table_from", "column_from", "schema_to", "table_to", "column_to")
);


CREATE TABLE @extschema@."user"(
	"id"		BIGINT		NOT NULL PRIMARY KEY,
	"name" 		TEXT		NOT NULL UNIQUE,
	"index"		SMALLINT	NOT NULL,
	
	"delete"	BOOLEAN		NOT NULL,
	"mask"		BOOLEAN		NOT NULL,
	"history"	BOOLEAN		NOT NULL,
	"right"		BOOLEAN 	NOT NULL
);

CREATE TABLE @extschema@."table_user_right"(
	"id_user"	BIGINT NOT NULL,
	"id_table" 	BIGINT NOT NULL,
	
	"read" 		BOOLEAN NOT NULL,
	"insert" 	BOOLEAN NOT NULL,
	"update" 	BOOLEAN NOT NULL,
	"delete"	BOOLEAN NOT NULL,
	
	PRIMARY KEY	("id_user", "id_table"),
	FOREIGN KEY ("id_user")  REFERENCES @extschema@."user" (id),
	FOREIGN KEY ("id_table") REFERENCES @extschema@."table" (id)
);

CREATE TABLE @extschema@."insert_object"(
	"name"	TEXT 	NOT NULL PRIMARY KEY,
	"objt"	JSONB	NOT NULL UNIQUE
);

CREATE TABLE @extschema@."select_object"(
	"name"	TEXT 	NOT NULL PRIMARY KEY,
	"objt" 	JSONB	NOT NULL UNIQUE
);

/*
CREATE TABLE @extschema@.locale(
	id			BIGINT		NOT NULL PRIMARY KEY,
	countrycode VARCHAR(2)	NOT NULL UNIQUE
);
INSERT INTO @extschema@.locale(id, countrycode) VALUES (1, 'FR');
*/
