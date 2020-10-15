CREATE FUNCTION @extschema@.get_history_schema_name(_schema TEXT)
  RETURNS TEXT AS
$$
	SELECT '_history_' || _schema || '_';
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.has_history_table(_schema TEXT, _table TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.table_exists(@extschema@.get_history_schema_name(_schema), _table);
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.create_history_table(_schema TEXT, _table TEXT, _column TEXT, _column_type_def TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
DECLARE
	_schema_history TEXT := @extschema@.get_history_schema_name(_schema);
	_column_type	TEXT;
BEGIN
	IF _column_type_def IS NULL THEN
		_column_type := @extschema@.get_column_type(_schema, _table, _column);
	ELSE
		_column_type := _column_type_def;
	END IF;
	
	RETURN (SELECT 
			@extschema@.create_schema(_schema_history, TRUE)
		||	@extschema@.create_table(_schema_history, _table, TRUE, FALSE)
		
		|| 	@extschema@.create_column(_schema_history, _table, 'target', _column_type)
		|| 	@extschema@.set_column_not_null(_schema_history, _table, 'target', TRUE)
		
		|| 	@extschema@.create_column(_schema_history, _table, 'parent', _column_type)
		|| 	@extschema@.set_column_not_null(_schema_history, _table, 'parent', TRUE)
		
		|| 	@extschema@.create_primary_key(_schema_history, _table, ARRAY['target', 'parent'])
		
		|| 	@extschema@.create_foreign_key(_schema_history, _table, ARRAY['target'], _schema, _table, ARRAY[_column], TRUE, TRUE, TRUE)
		|| 	@extschema@.create_foreign_key(_schema_history, _table, ARRAY['parent'], _schema, _table, ARRAY[_column], TRUE, TRUE, TRUE)
		
		|| 	@extschema@.create_history_function(_schema, _table, _column, _column_type)
	-- TODO add trigger to disable update (?)
	);
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_history_table(_schema TEXT, _table TEXT, _column TEXT, _column_type_def TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
DECLARE
	_schema_history TEXT := @extschema@.get_history_schema_name(_schema);
	_column_type 	TEXT;
BEGIN
	IF _column_type_def IS NULL THEN
		_column_type := @extschema@.get_column_type(_schema, _table, _column);
	ELSE
		_column_type := _column_type_def;
	END IF;
	
	RETURN (SELECT
			@extschema@.drop_table(_schema_history, _table, TRUE)
		||	@extschema@.drop_schema_if_empty(_schema_history)
		|| 	@extschema@.delete_history_function(_schema, _table, _column_type)
	);
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_history_function(_schema TEXT, _table TEXT, _column TEXT, _type TEXT)
  RETURNS TEXT AS
$$
DECLARE
	_schema_history TEXT := @extschema@.get_history_schema_name(_schema);
BEGIN
	IF UPPER(_type) = 'BIGSERIAL' THEN
		_type = 'BIGINT';
	ELSEIF UPPER(_type) = 'SERIAL' THEN
		_type = 'INTEGER';
	ELSEIF UPPER(_type) = 'SMALLSERIAL' THEN
		_type = 'SMALLINT';
	END IF;
	
  	RETURN (SELECT format(
		'CREATE FUNCTION "%s"."syst_insert_history_from_%s"(_value %s[], _parent %s)
		RETURNS VOID AS 
		$T2$
			INSERT INTO "%s"."%s" ("target", "parent") VALUES (UNNEST(_value), _parent);
		$T2$
		LANGUAGE sql;',
		_schema, _table, _type, _type,
		_schema_history, _table
 	) || format(
		'CREATE FUNCTION "%s"."syst_delete_history_from_%s"(_value %s[])
		RETURNS VOID AS 
		$T2$
			DELETE FROM "%s"."%s" WHERE "target" = ANY(_value);
		$T2$
		LANGUAGE sql;',
		_schema, _table, _type,
		_schema_history, _table
  	));
END;
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_history_function(_schema TEXT, _table TEXT, _type TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP FUNCTION "%s"."syst_insert_history_from_%s"(%s[], %s[]) CASCADE;',
		_schema, _table, _type, _type
	) || format(
		'DROP FUNCTION "%s"."syst_delete_history_from_%s"(%s[]) CASCADE;',
		_schema, _table, _type
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_history(_schema TEXT, _table TEXT, _id BIGINT)
  RETURNS SETOF BIGINT AS
$$
BEGIN
	RETURN QUERY
	EXECUTE format('
		WITH RECURSIVE getChild(parent, target) AS (
			SELECT t0.parent, t0.target FROM "%s"."%s" AS "t0" WHERE t0.parent = %s OR t0.target = %s
			UNION
			SELECT t1.parent, t1.target FROM "%s"."%s" AS "t1" JOIN getChild AS "t2" ON t2.target = t1.parent
		),
		getParent(parent, target) AS (
			SELECT t0.parent, t0.target FROM "%s"."%s" AS "t0" WHERE t0.parent = %s OR t0.target = %s
			UNION
			SELECT t1.parent, t1.target FROM "%s"."%s" AS "t1" JOIN getParent AS "t2" ON t2.parent = t1.target
		)

		SELECT parent FROM getParent UNION SELECT target FROM getChild UNION SELECT MAX(target) FROM getChild;',
	   	_schema, _table, _id, _id,
		_schema, _table,
		_schema, _table, _id, _id,
		_schema, _table
	);
END;
$$
LANGUAGE plpgsql;
