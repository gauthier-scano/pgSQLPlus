CREATE FUNCTION @extschema@.create_column(_schema TEXT, _table TEXT, _name TEXT, _type TEXT[], _type_is_array BOOLEAN DEFAULT FALSE, _precision TEXT DEFAULT NULL, _scale TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	IF _precision IS NOT NULL AND _precision ~* '(NaN|Infinity)' THEN
		_precision = '"' || _precision || '"';
	END IF;
	
	IF _scale IS NOT NULL AND _scale ~* '(NaN|Infinity)' THEN
		_scale = '"' || _scale || '"';
	END IF;
	
	RETURN (SELECT format(
		'ALTER TABLE "%s"."%s" ADD COLUMN "%s" %s%s%s;',
		_schema, _table, _name,
		(CASE array_length(_type, 1) = 1 WHEN TRUE THEN _type[1] ELSE ('"' || array_to_string(_type, '"."') || '"') END),
		(CASE _type_is_array WHEN TRUE THEN '[]' ELSE '' END),
		(CASE _precision IS NOT NULL
			WHEN TRUE THEN
				(CASE _scale IS NOT NULL
					WHEN TRUE THEN ('(' || _precision || ', ' || _scale || ')')
					ELSE ''
				END)
			ELSE ''
		END)
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_column(_schema TEXT, _table TEXT, _name TEXT, _type TEXT, _type_is_array BOOLEAN DEFAULT FALSE, _precision TEXT DEFAULT NULL, _scale TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT @extschema@.create_column(_schema, _table, _name, ARRAY[_type], _type_is_array, _precision, _scale));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.rename_column(_schema TEXT, _table TEXT, _name TEXT, _new_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER TABLE "%s"."%s" RENAME COLUMN "%s" TO "%s";', _schema, _table, _name, _new_name));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_column_type(_schema TEXT, _table TEXT, _name TEXT, _type TEXT[], _type_is_array BOOLEAN DEFAULT FALSE, _precision TEXT DEFAULT NULL, _scale TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	IF _precision IS NOT NULL AND _precision ~* '(NaN|Infinity)' THEN
		_precision = '"' || _precision || '"';
	END IF;
	
	IF _scale IS NOT NULL AND _scale ~* '(NaN|Infinity)' THEN
		_scale = '"' || _scale || '"';
	END IF;
	
	RETURN (SELECT format(
		'ALTER TABLE "%s"."%s" ALTER COLUMN "%s" SET DATA TYPE %s%s;',
		_schema, _table, _name,
		(CASE array_length(_type, 1) = 1 WHEN TRUE THEN _type[1] ELSE ('"' || array_to_string(_type, '"."') || '"') END),
		(CASE _type_is_array WHEN TRUE THEN '[]' ELSE '' END),
		(CASE _precision IS NOT NULL
			WHEN TRUE THEN
				(CASE _scale IS NOT NULL
					WHEN TRUE THEN ('(' || _precision || ', ' || _scale || ')')
					ELSE ''
				END)
			ELSE ''
		END)
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_column_type(_schema TEXT, _table TEXT, _name TEXT, _type TEXT, _type_is_array BOOLEAN DEFAULT FALSE, _precision TEXT DEFAULT NULL, _scale TEXT DEFAULT NULL)
  RETURNS VOID AS
$$
BEGIN
	EXECUTE @extschema@.set_column_type(_schema, _table, _name, ARRAY[_type], _type_is_array, _precision, _scale);
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_column_type(_schema TEXT, _table TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT UPPER(data_type) FROM information_schema.columns WHERE table_schema = _schema AND table_name = _table AND column_name = _column;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE sql;


CREATE FUNCTION @extschema@.set_column_not_null(_schema TEXT, _table TEXT, _name TEXT, _not_null BOOLEAN)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER TABLE "%s"."%s" ALTER COLUMN "%s" %s NOT NULL;',
		_schema, _table, _name,
		(CASE _not_null WHEN TRUE THEN 'SET' ELSE 'DROP' END)
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_column_default(_schema TEXT, _table TEXT, _name TEXT, _default TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER TABLE "%s"."%s" ALTER COLUMN "%s" %s;',
		_schema, _table, _name,
		(CASE _default IS NULL WHEN TRUE THEN 'DROP DEFAULT' ELSE ('SET DEFAULT ' || _default) END)
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;

/*
CREATE FUNCTION @extschema@.set_column_datatype(
	_schema 	TEXT,
	_table 		TEXT,
	_name 		TEXT,
	_type 		TEXT,
	_precision 	SMALLINT DEFAULT NULL,
	_scale		SMALLINT DEFAULT NULL
)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER TABLE "%s"."%s" ALTER COLUMN "%s" SET DATA TYPE %s%s%s;',
		_schema, _table, _name, _type,
		(CASE _precision IS NOT NULL AND _scale IS NOT NULL WHEN TRUE THEN ('(' || _precision || ', ' || _scale || ')') ELSE '' END),
		(CASE _precision IS NOT NULL WHEN TRUE THEN ('(' || _precision || ')') ELSE '' END)
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_column_datatype(_schema TEXT, _table TEXT, _name TEXT, _type TEXT[])
  RETURNS TEXT AS
$$
BEGIN
	SELECT @extschema@.set_column_datatype(_schema, _table, _name, ('"' || array_to_string(_type, '"."') || '"'), NULL, NULL);
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;
*/


CREATE FUNCTION @extschema@.get_table_column_list(_schema TEXT, _table TEXT)
RETURNS TABLE(
	name 		TEXT,
	type 		TEXT,
	length 		INTEGER,
	nullable 	BOOLEAN
) AS
$$
	SELECT column_name, data_type, character_octet_length, is_nullable = 'yes'
	FROM information_schema.columns
	WHERE table_schema = _schema
	  AND table_name   = _table;
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.get_column_desc(_schema TEXT, _table TEXT, _column TEXT)
RETURNS TABLE(
	name 		TEXT,
	type 		TEXT,
	length 		INTEGER,
	nullable 	BOOLEAN
) AS
$$
	SELECT name, type, length, nullable FROM @extschema@.get_table_column_list(_schema, _table) WHERE name = _column;
$$
ROWS 1
LANGUAGE sql;


CREATE FUNCTION @extschema@.column_exists(_schema TEXT, _table TEXT, _column TEXT)
  RETURNS BOOLEAN AS
$$
	SELECT COUNT(TRUE) > 0 FROM information_schema.columns WHERE table_schema = _schema AND table_name = _table AND column_name = _column;
$$
LANGUAGE sql;
