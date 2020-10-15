CREATE FUNCTION @extschema@.get_constraint_name_pkey(_schema TEXT, _table TEXT, _column TEXT[])
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT 'pk_' || _schema || '_' || _table || '_' || array_to_string(_column, '_'));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_primary_key(_schema TEXT, _table TEXT, _column TEXT[], _valid BOOLEAN DEFAULT FALSE, _name TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	IF _name IS NULL THEN
		_name := @extschema@.get_constraint_name_pkey(_schema, _table, _column);
	END IF;
	
	RETURN (SELECT format(
		'ALTER TABLE "%s"."%s" ADD CONSTRAINT "%s" PRIMARY KEY ("%s")' || (CASE _valid WHEN TRUE THEN ' NOT VALID' WHEN FALSE THEN '' END) || ';',
		_schema, _table, _name, array_to_string(_column, '","')
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_constraint_name_fkey(_schema_from TEXT, _table_from TEXT, _column_from TEXT[], _schema_to TEXT, _table_to TEXT, _column_to TEXT[])
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT 'fk_' || _schema_from || '_' || _table_from || '_' || array_to_string(_column_from, '_') || '_' || _schema_to || '_' || _table_to || '_' || array_to_string(_column_to, '_'));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_foreign_key(
	_schema_from 	TEXT,
	_table_from 	TEXT,
	_column_from 	TEXT[],
	_schema_to 		TEXT,
	_table_to 		TEXT,
	_column_to 		TEXT[],
	_valid 			BOOLEAN DEFAULT TRUE,
	_delete_cascade BOOLEAN DEFAULT FALSE,
	_update_cascade BOOLEAN DEFAULT FALSE,
	_name 			TEXT DEFAULT NULL
) RETURNS TEXT AS
$$
BEGIN
	IF _name IS NULL THEN
		_name := @extschema@.get_constraint_name_fkey(_schema_from, _table_from, _column_from, _schema_to, _table_to, _column_to);
	END IF;
	
	RETURN (SELECT format(
		'ALTER TABLE "%s"."%s" ADD CONSTRAINT "%s" FOREIGN KEY ("%s") REFERENCES "%s"."%s"("%s") ON DELETE %s ON UPDATE %s%s;',
		_schema_from, _table_from, _name, array_to_string(_column_from, '","'),
		_schema_to, _table_to, array_to_string(_column_to, '","'),
		(CASE _delete_cascade 	WHEN TRUE THEN 'CASCADE' WHEN FALSE THEN 'RESTRICT' END),
		(CASE _update_cascade 	WHEN TRUE THEN 'CASCADE' WHEN FALSE THEN 'RESTRICT' END),
		(CASE _valid 			WHEN TRUE THEN '' 	 	 WHEN FALSE THEN ' NOT VALID' END)
	));
	-- ON DELETE CASCADE ON UPDATE CASCADE
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_constraint_name_unique(_schema TEXT, _table TEXT, _column TEXT[])
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT 'unique_' || _schema || '_' || _table || '_' || array_to_string(_column, '_'));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_unique(_schema TEXT, _table TEXT, _column TEXT[], _valid BOOLEAN DEFAULT FALSE, _name TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	IF _name IS NULL THEN
		_name := @extschema@.get_constraint_name_unique(_schema, _table, _column);
	END IF;
	
	RETURN (SELECT format(
		'ALTER TABLE "%s"."%s" ADD CONSTRAINT "%s" UNIQUE ("%s")' || (CASE _valid WHEN TRUE THEN ' NOT VALID' WHEN FALSE THEN '' END) || ';',
		_schema, _table, _name, array_to_string(_column, '","')
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.rename_constraint(_schema TEXT, _table TEXT, _name TEXT, _new_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER TABLE "%s"."%s" RENAME CONSTRAINT "%s" TO "%s";', _schema, _table, _name, _new_name));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;
