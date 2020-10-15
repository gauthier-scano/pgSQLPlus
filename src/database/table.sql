CREATE FUNCTION @extschema@.create_table(_schema TEXT, _name TEXT, _not_exists BOOLEAN DEFAULT FALSE, _system BOOLEAN DEFAULT TRUE)
  RETURNS TEXT AS
$$
DECLARE
	_query TEXT;
BEGIN
	_query := format('CREATE TABLE %s"%s"."%s"();', (CASE _not_exists WHEN TRUE THEN 'IF NOT EXISTS ' ELSE '' END), _schema, _name);
	
	IF _system THEN
		_query := _query || format('INSERT INTO @extschema@.table("schema", "table") VALUES (%L, %L);', _schema, _name);
	END IF;
	
	RETURN (SELECT _query);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_table(_schema TEXT, _name TEXT, _exists BOOLEAN DEFAULT FALSE, _cascade BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN @extschema@.drop_table(_schema, ARRAY[_name], _exists, _cascade);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_table(_schema TEXT, _name TEXT[], _exists BOOLEAN DEFAULT FALSE, _cascade BOOLEAN DEFAULT FALSE, _system BOOLEAN DEFAULT TRUE)
  RETURNS TEXT AS
$$
DECLARE
	_query TEXT;
BEGIN
	_query := format(
		'DROP TABLE %s"%s"."%s" %s;',
		(CASE _exists WHEN TRUE THEN 'IF EXISTS ' WHEN FALSE THEN '' END),
		_schema, array_to_string(_name, '", "' || _schema || '"."')
	);
	
	IF _system THEN
		_query := _query || format(
			'DELETE FROM @extschema@."table" WHERE "schema" = %L AND "table" IN (''%s'');',
			(CASE _cascade WHEN TRUE THEN 'CASCADE' WHEN FALSE THEN 'RESTRICT' ELSE '' END),
			_schema, array_to_string(_name, ''',''')
		);
	END IF;
	
	RETURN (SELECT _query);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.rename_table(_schema TEXT, _name TEXT, _new_name TEXT DEFAULT NULL, _basic BOOLEAN DEFAULT TRUE, _system BOOLEAN DEFAULT TRUE)
  RETURNS TEXT AS
$$
DECLARE
	_query TEXT;
BEGIN
	_query := format('ALTER TABLE "%s"."%s" RENAME TO "%s";', _schema, _name, _new_name);
	
	IF _system THEN
		_query := _query || format('UPDATE @extschema@."table" SET "table" = ''%s'' WHERE "schema" = %L AND "table" = %L;', _new_name, _schema, _name);
	END IF;
	
	IF _basic THEN
		_query := _query || 'IF (' || @extschema@.has_history_table(_schema, _name) || ') IS TRUE THEN ' || @extschema@.rename_table(@extschema@.get_history_schema_name(_schema), _name, _new_name, FALSE) || ' END IF;';
		_query := _query || 'IF (' || @extschema@.has_mask_table(_schema, _name) 	|| ') IS TRUE THEN ' || @extschema@.rename_table(@extschema@.get_mask_schema_name(_schema), _name, _new_name, FALSE) 	|| ' END IF;';
		_query := _query || 'IF (' || @extschema@.has_delete_table(_schema, _name) 	|| ') IS TRUE THEN ' || @extschema@.rename_table(@extschema@.get_delete_schema_name(_schema), _name, _new_name, FALSE)  || ' END IF;';
		_query := _query || 'IF (' || @extschema@.has_right_table(_schema, _name) 	|| ') IS TRUE THEN ' || @extschema@.rename_table(@extschema@.get_right_schema_name(_schema), _name, _new_name, FALSE) 	|| ' END IF;';
	END IF;
	
	/*IF (SELECT COUNT(TRUE) FROM @extschema@.get_variable_table_list(_schema, _name)) > 0 THEN
		_schema_variable_name	:= @extschema@.get_variable_schema_name(_schema, _schema_variable);
		_table_variable_name	:= @extschema@.get_variable_table_name(_table, _table_variable, _column_variable);
		
		EXECUTE format('ALTER TABLE "%s"."%s" RENAME TO "%s";',
			SELECT @extschema@.get_variable_schema_name(_schema, _name),
		   _name, _new_name
		);
	END IF;*/
	
	RETURN (SELECT _query);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_table_schema(_schema TEXT, _name TEXT, _new_schema TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER TABLE "%s"."%s" SET SCHEMA "%s";', _schema, _name, _new_schema));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_table_owner(_schema TEXT, _name TEXT, _owner TEXT, current_session BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER TABLE "%s"."%s" OWNER TO %s;',
		_schema,
		_name,
		(CASE 
			WHEN _owner IS NOT NULL THEN ('"' || _owner || '"')
			WHEN current_session IS TRUE THEN 'CURRENT_USER'
			ELSE 'SESSION_USER'
		END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.table_exists(_schema TEXT, _table TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('COALESCE((SELECT TRUE FROM information_schema.tables WHERE table_schema = %L AND table_name = %L), FALSE)', _schema, _table));
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_table_length(_schema TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('SELECT COUNT(TRUE) FROM information_schema.tables WHERE table_schema = "%s";', _schema));
END
$$
LANGUAGE plpgsql;
