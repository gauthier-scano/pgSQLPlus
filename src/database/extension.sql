CREATE FUNCTION @extschema@.create_extension(
	name 		TEXT,
	schema 		TEXT 	DEFAULT NULL,
	version 	TEXT 	DEFAULT NULL,
	cascade		BOOLEAN	DEFAULT FALSE
) RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'CREATE EXTENSION IF NOT EXISTS "%s"%s%s%s;',
		name,
		(CASE schema 		IS NOT NULL WHEN TRUE THEN (' SCHEMA "'  || schema 		|| '"') ELSE '' END),
		(CASE version 		IS NOT NULL WHEN TRUE THEN (' VERSION "' || version 	|| '"') ELSE '' END),
		(CASE cascade 		WHEN TRUE THEN ' CASCADE' ELSE '' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_extension(
	name 		TEXT,
	cascade		BOOLEAN	DEFAULT FALSE,
	restrict	BOOLEAN	DEFAULT FALSE
) RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP EXTENSION IF EXISTS "%s"%s%s;',
		name,
		(CASE cascade  WHEN TRUE THEN ' CASCADE' ELSE '' END),
		(CASE restrict WHEN TRUE THEN ' RESTRICT' ELSE '' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_extension_schema(
	name 		TEXT,
	schema 		TEXT
) RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER EXTENSION "%s" SET SCHEMA "%s";', name, schema));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.update_extension_to(
	name 	TEXT,
	version TEXT
) RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER EXTENSION "%s" UPDATE TO "%s";', name, version));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;
