CREATE FUNCTION @extschema@.get_right_schema_name(_schema TEXT)
  RETURNS TEXT AS
$$
	SELECT '_right_' || _schema || '_';
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.has_right_table(_schema TEXT, _table TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.table_exists(@extschema@.get_right_schema_name(_schema), _table);
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.create_right_table(_schema TEXT, _table TEXT, _column TEXT, _column_type_def TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
DECLARE
	_schema_right 	TEXT := @extschema@.get_right_schema_name(_schema);
	_column_type	TEXT;
BEGIN
	IF _column_type_def IS NULL THEN
		_column_type := @extschema@.get_column_type(_schema, _table, _column);
	ELSE
		_column_type := _column_type_def;
	END IF;
	
	RETURN (SELECT
			@extschema@.create_schema(_schema_right, TRUE)
		|| 	@extschema@.create_table(_schema_right, _table, TRUE, FALSE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'target', _column_type)
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'target', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'id_user', 'BIGINT')
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'id_user', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'id_user_set','BIGINT')
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'id_user_set', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'delete', 'BOOLEAN')
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'delete', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'mask', 'BOOLEAN')
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'mask', TRUE)
		
		||	@extschema@.create_column(_schema_right, _table, 'history', 'BOOLEAN')
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'history', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'update', 'BOOLEAN')
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'update', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'read', 'BOOLEAN')
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'read', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'right', 'BOOLEAN')
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'right', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'from', _column_type)
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'from', TRUE)
		
		|| 	@extschema@.create_column(_schema_right, _table, 'to', _column_type)
		|| 	@extschema@.set_column_not_null(_schema_right, _table, 'to', TRUE)
		
		|| 	@extschema@.create_primary_key(_schema_right, _table, ARRAY['target', 'id_user', 'id_user_set'])
		
		|| 	@extschema@.create_index(_schema_right, _table, ARRAY['from', 'to'], TRUE, FALSE)
		
		|| 	@extschema@.create_foreign_key(_schema_right, _table, ARRAY['target'], _schema, _table, ARRAY[_column], TRUE, TRUE, TRUE)
		|| 	@extschema@.create_foreign_key(_schema_right, _table, ARRAY['from'], _schema, _table, ARRAY[_column], TRUE, TRUE, TRUE)
		|| 	@extschema@.create_foreign_key(_schema_right, _table, ARRAY['to'], _schema, _table, ARRAY[_column], TRUE, TRUE, TRUE)
		
		|| 	@extschema@.create_foreign_key(_schema_right, _table, ARRAY['id_user'], '@extschema@', 'user', ARRAY['id'], TRUE, TRUE, TRUE)
		|| 	@extschema@.create_foreign_key(_schema_right, _table, ARRAY['id_user_set'], '@extschema@', 'user', ARRAY['id'], TRUE, TRUE, TRUE)
		|| 	@extschema@.create_right_function(_schema, _table, _column, _column_type)
	);
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_right_table(_schema TEXT, _table TEXT, _column TEXT, _column_type_def TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
DECLARE
	_schema_right 	TEXT := @extschema@.get_right_schema_name(_schema);
	_column_type 	TEXT;
BEGIN
	IF _column_type_def IS NULL THEN
		_column_type := @extschema@.get_column_type(_schema, _table, _column);
	ELSE
		_column_type := _column_type_def;
	END IF;
	
	RETURN (SELECT
			@extschema@.drop_table(_schema_right, _table, TRUE)
		||	@extschema@.drop_schema_if_empty(_schema_right)
		|| 	@extschema@.delete_right_function(_schema, _table, _column_type)
	);	
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_right_function(_schema TEXT, _table TEXT, _column TEXT, _type TEXT)
  RETURNS TEXT AS
$$
DECLARE
	_schema_right TEXT := @extschema@.get_right_schema_name(_schema);
BEGIN
	IF UPPER(_type) = 'BIGSERIAL' THEN
		_type = 'BIGINT';
	ELSEIF UPPER(_type) = 'SERIAL' THEN
		_type = 'INTEGER';
	ELSEIF UPPER(_type) = 'SMALLSERIAL' THEN
		_type = 'SMALLINT';
	END IF;
	
  	RETURN (SELECT format(
		'CREATE FUNCTION "%s"."syst_set_right_from_%s"(_user TEXT, _user_target TEXT, _value %s[], _delete BOOLEAN, _mask BOOLEAN, _history BOOLEAN, _update BOOLEAN, _read BOOLEAN, _right BOOLEAN)
		RETURNS VOID AS 
		$T2$
			INSERT INTO "%s"."%s" (
				"target",
				"id_user",
				"id_user_set",
				"delete",
				"mask",
				"history",
				"update",
				"read",
				"right"
			) VALUES (
				UNNEST(_value),
				(SELECT id FROM @extschema@.user WHERE name = _user),
				(SELECT id FROM @extschema@.user WHERE name = _user_target),
				_delete,
				_mask,
				_history,
				_update,
				_read,
				_right
			);
		$T2$
		LANGUAGE sql;',
		_schema, _table, _type,
		_schema_right, _table
 	) || format(
		'CREATE FUNCTION "%s"."syst_delete_right_from_%s"(_user TEXT, _user_target TEXT, _value %s[])
		RETURNS VOID AS 
		$T2$
			DELETE FROM "%s"."%s"
			WHERE
				"target" = ANY(_value) AND
				"id_user" = (SELECT id FROM @extschema@.user WHERE name = _user_target) AND
				"id_user_set" = (SELECT id FROM @extschema@.user WHERE name = _user);
		$T2$
		LANGUAGE sql;',
		_schema, _table, _type,
		_schema_right, _table
  	) || format(
		'CREATE FUNCTION "%s"."syst_get_user_right_from_%s"(_user TEXT, _value %s)
		RETURNS TABLE(
			delete 	BOOLEAN,
			mask	BOOLEAN,
			history BOOLEAN,
			update	BOOLEAN,
			read	BOOLEAN,
			"right"	BOOLEAN
		) AS 
		$T2$
		DECLARE
			_id_user 	BIGINT 		:= (SELECT "id" 	FROM @extschema@.user WHERE name = _user);
			_index_user	SMALLINT 	:= (SELECT "index" 	FROM @extschema@.user WHERE name = _user);
		BEGIN
			RETURN QUERY (
				SELECT
					COALESCE(bool_and("t1"."delete"), TRUE),
					COALESCE(bool_and("t1"."mask"), TRUE),
					COALESCE(bool_and("t1"."history"), TRUE),
					COALESCE(bool_and("t1"."update"), TRUE),
					COALESCE(bool_and("t1"."read"), TRUE),
					COALESCE(bool_and("t1"."right"), TRUE)
				FROM "%s"."%s" AS "t1"
				WHERE
					"id_user" = _id_user AND
					"id_user_set" = ANY(SELECT "id" FROM @extschema@.user WHERE "index" > _index_user AND "id" <> _id_user) AND
					"target" = _value
			);
		END;
		$T2$
		ROWS 1
		LANGUAGE plpgsql;',
		_schema, _table, _type,
		_schema_right, _table
  	));
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_right_function(_schema TEXT, _table TEXT, _type TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP FUNCTION "%s"."syst_set_right_from_%s"(TEXT, TEXT, %s[], BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;',
		_schema, _table, _type
	) || format(
		'DROP FUNCTION "%s"."syst_delete_right_from_%s"(TEXT, TEXT, %s[]) CASCADE;',
		_schema, _table, _type
	) || format(
		'DROP FUNCTION "%s"."syst_get_user_right_from_%s"(TEXT, %s) CASCADE;',
		_schema, _table, _type
	));
END;
$$
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE plpgsql;
