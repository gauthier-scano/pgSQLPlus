CREATE FUNCTION @extschema@.get_mask_schema_name(_schema TEXT)
  RETURNS TEXT AS
$$
	SELECT '_mask_' || _schema || '_';
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.has_mask_table(_schema TEXT, _table TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.table_exists(@extschema@.get_mask_schema_name(_schema), _table);
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.create_mask_table(_schema TEXT, _table TEXT, _column TEXT, _column_type_def TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
DECLARE
	_schema_mask TEXT := @extschema@.get_mask_schema_name(_schema);
	_column_type	TEXT;
BEGIN
	IF _column_type_def IS NULL THEN
		_column_type := @extschema@.get_column_type(_schema, _table, _column);
	ELSE
		_column_type := _column_type_def;
	END IF;
	
	RETURN (SELECT
			@extschema@.create_schema(_schema_mask, TRUE)
		||	@extschema@.create_table(_schema_mask, _table, TRUE, FALSE)
						
		|| 	@extschema@.create_column(_schema_mask, _table, 'target', _column_type)
		|| 	@extschema@.set_column_not_null(_schema_mask, _table, 'target', TRUE)
		
		|| 	@extschema@.create_column(_schema_mask, _table, 'id_user', 'BIGINT')
		|| 	@extschema@.set_column_not_null(_schema_mask, _table, 'id_user', TRUE)
		
		|| 	@extschema@.create_primary_key(_schema_mask, _table, ARRAY['target', 'id_user'])
		
		|| 	@extschema@.create_foreign_key(_schema_mask, _table, ARRAY['target'], _schema, _table, ARRAY[_column], TRUE, TRUE, TRUE)
		|| 	@extschema@.create_foreign_key(_schema_mask, _table, ARRAY['id_user'], '@extschema@', 'user', ARRAY['id'], TRUE, TRUE, TRUE)
		|| 	@extschema@.create_mask_function(_schema, _table, _column, _column_type)
	);
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_mask_table(_schema TEXT, _table TEXT, _column TEXT, _column_type_def TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
DECLARE
	_schema_mask TEXT := @extschema@.get_mask_schema_name(_schema);
	_column_type 	TEXT;
BEGIN
	IF _column_type_def IS NULL THEN
		_column_type := @extschema@.get_column_type(_schema, _table, _column);
	ELSE
		_column_type := _column_type_def;
	END IF;
	
	RETURN (SELECT
			@extschema@.drop_table(_schema_mask, _table, TRUE)
		||	@extschema@.drop_schema_if_empty(_schema_mask)
		|| 	@extschema@.delete_mask_function(_schema, _table, _column_type)
	);
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_mask_function(_schema TEXT, _table TEXT, _column TEXT, _type TEXT)
  RETURNS TEXT AS
$$
DECLARE
	_schema_mask TEXT := @extschema@.get_mask_schema_name(_schema);
BEGIN
	IF UPPER(_type) = 'BIGSERIAL' THEN
		_type = 'BIGINT';
	ELSEIF UPPER(_type) = 'SERIAL' THEN
		_type = 'INTEGER';
	ELSEIF UPPER(_type) = 'SMALLSERIAL' THEN
		_type = 'SMALLINT';
	END IF;
	
  	RETURN (SELECT format(
		'CREATE FUNCTION "%s"."syst_insert_mask_from_%s"(_user BIGINT, _value %s[])
		RETURNS VOID AS 
		$T2$
			INSERT INTO "%s"."%s" ("target", "id_user") VALUES (UNNEST(_value), (SELECT id FROM @extschema@.user WHERE name = _user));
		$T2$
		LANGUAGE sql;',
		_schema, _table, _type,
		_schema_mask, _table
 	) || format(
		'CREATE FUNCTION "%s"."syst_delete_mask_from_%s"(_user BIGINT, _value %s[])
		RETURNS VOID AS 
		$T2$
			DELETE FROM "%s"."%s" WHERE "target" = ANY(_value) AND "id_user" = (SELECT id FROM @extschema@.user WHERE name = _user);
		$T2$
		LANGUAGE sql;',
		_schema, _table, _type,
		_schema_mask, _table
	));
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_mask_function(_schema TEXT, _table TEXT, _type TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP FUNCTION "%s"."syst_insert_mask_from_%s"(BIGINT, %s[]) CASCADE;',
		_schema, _table, _type
	) || format(
		'DROP FUNCTION "%s"."syst_delete_mask_from_%s"(BIGINT, %s[]) CASCADE;',
		_schema, _table, _type
	));
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;
