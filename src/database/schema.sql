CREATE FUNCTION @extschema@.create_schema(_name TEXT, _not_exists BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'CREATE SCHEMA %s"%s";',
		CASE _not_exists WHEN TRUE THEN 'IF NOT EXISTS ' ELSE '' END,
		_name
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_schema(_name TEXT, _exists BOOLEAN DEFAULT FALSE, _cascade BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT @extschema@.drop_schema(ARRAY[_name], _exists, _cascade));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_schema(_name TEXT[], _exists BOOLEAN DEFAULT FALSE, _cascade BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP SCHEMA %s"%s" %s;',
		(CASE _exists WHEN TRUE THEN 'IF EXISTS ' WHEN FALSE THEN '' END),
		array_to_string(_name, '", "'),
		(CASE _cascade WHEN TRUE THEN 'CASCADE' WHEN FALSE THEN 'RESTRICT' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_schema_if_empty(_schema TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT 'IF (SELECT (' || @extschema@.get_table_length(_schema) || ') = 0) THEN ' ||  @extschema@.drop_schema(_schema) || ' END IF;');
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.rename_schema(_name TEXT, _new_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER SCHEMA "%s" RENAME TO "%s";', _name, _new_name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_schema_owner(name TEXT, owner TEXT, current_session BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER SCHEMA "%s" OWNER TO %s;',
		name,
		(CASE 
			WHEN owner IS NOT NULL THEN ('"' || owner || '"')
			WHEN current_session IS TRUE THEN 'CURRENT_USER'
			ELSE 'SESSION_USER'
		END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.schema_exists(_schema TEXT)
  RETURNS BOOLEAN AS
$$
BEGIN
	IF (SELECT TRUE FROM pg_catalog.pg_namespace WHERE nspname = _schema) THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_system_schema_list(_schema TEXT)
  RETURNS SETOF TEXT AS
$$
BEGIN
	SELECT * FROM pg_catalog.pg_namespace
	WHERE  		nspname NOT IN ('information_schema', 'pg_catalog')
			AND nspname NOT LIKE 'pg_toast%'
			AND nspname NOT LIKE 'pg_temp%'
			AND nspname NOT LIKE '\_\_%';
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_user_schema_list(_schema TEXT)
  RETURNS SETOF TEXT AS
$$
BEGIN
	SELECT * FROM pg_catalog.pg_namespace
	WHERE  		nspname NOT IN ('information_schema', 'pg_catalog')
			AND nspname NOT LIKE 'pg_toast%'
			AND nspname NOT LIKE 'pg_temp%'
			AND nspname LIKE '\_\_%';
END;
$$
LANGUAGE plpgsql;
