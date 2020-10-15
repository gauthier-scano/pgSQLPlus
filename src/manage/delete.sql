CREATE FUNCTION @extschema@.get_delete_schema_name(_schema TEXT)
  RETURNS TEXT AS
$$
	SELECT '_delete_'  || _schema || '_';
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.has_delete_table(_schema TEXT, _table TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.table_exists(@extschema@.get_delete_schema_name(_schema), _table);
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.create_delete_table(_schema TEXT, _table TEXT, _column TEXT, _column_type_def TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
DECLARE
	_schema_delete 	TEXT := @extschema@.get_delete_schema_name(_schema);
	_column_type	TEXT;
BEGIN
	IF _column_type_def IS NULL THEN
		_column_type := @extschema@.get_column_type(_schema, _table, _column);
	ELSE
		_column_type := _column_type_def;
	END IF;
	
	RETURN (SELECT
			@extschema@.create_schema(_schema_delete, TRUE)
			
		||	@extschema@.create_table(_schema_delete, _table, TRUE, FALSE)
		|| 	@extschema@.create_column(_schema_delete, _table, 'target', ARRAY[_column_type])
		
		|| 	@extschema@.create_primary_key(_schema_delete, _table, ARRAY['target'])
		|| 	@extschema@.create_foreign_key(_schema_delete, _table, ARRAY['target'], _schema, _table, ARRAY[_column], TRUE, TRUE, TRUE)
		
		|| 	@extschema@.create_delete_function(_schema, _table, _column, _column_type)
	);
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_delete_table(_schema TEXT, _table TEXT, _column TEXT, _column_type_def TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
DECLARE
	_schema_delete 	TEXT := @extschema@.get_delete_schema_name(_schema);
	_column_type 	TEXT;
BEGIN
	IF _column_type_def IS NULL THEN
		_column_type := @extschema@.get_column_type(_schema, _table, _column);
	ELSE
		_column_type := _column_type_def;
	END IF;
	
	RETURN (SELECT
			@extschema@.drop_table(_schema_delete, _table, TRUE)
		||	@extschema@.drop_schema_if_empty(_schema_delete)
		|| 	@extschema@.delete_delete_function(_schema, _table, _column_type)
	);
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_delete_function(_schema TEXT, _table TEXT, _column TEXT, _type TEXT)
  RETURNS TEXT AS
$$
DECLARE
	_schema_delete TEXT := @extschema@.get_delete_schema_name(_schema);
BEGIN
	IF UPPER(_type) = 'BIGSERIAL' THEN
		_type = 'BIGINT';
	ELSEIF UPPER(_type) = 'SERIAL' THEN
		_type = 'INTEGER';
	ELSEIF UPPER(_type) = 'SMALLSERIAL' THEN
		_type = 'SMALLINT';
	END IF;
	
	RETURN (SELECT format(
		'CREATE FUNCTION "%s"."syst_insert_delete_from_%s"(_value %s[])
		RETURNS VOID AS 
		$T2$
			INSERT INTO "%s"."%s" ("target") VALUES (UNNEST(_value));
		$T2$
		LANGUAGE sql;',
		_schema, _table, _type,
		_schema_delete, _table
	) || format(
		'CREATE FUNCTION "%s"."syst_drop_delete_from_%s"(_value %s[])
		RETURNS VOID AS 
		$T2$
			DELETE FROM "%s"."%s" WHERE "target" = ANY(_value);
		$T2$
		LANGUAGE sql;',
		_schema, _table, _type,
		_schema_delete, _table
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_delete_function(_schema TEXT, _table TEXT, _type TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP FUNCTION "%s"."syst_insert_delete_from_%s"(%s[]) CASCADE;',
		_schema, _table, _type
	) || format(
		'DROP FUNCTION "%s"."syst_drop_delete_from_%s"(%s[]) CASCADE;',
		_schema, _table, _type
	));
END;
$$
IMMUTABLE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;
