CREATE FUNCTION @extschema@.create_collation(
	_schema 	TEXT,
	_name 		TEXT,
	_locale 	TEXT,
	_lc_collate TEXT DEFAULT NULL,
	_lc_ctype	TEXT DEFAULT NULL,
	_provider	TEXT DEFAULT NULL,
	_version	TEXT DEFAULT NULL
) RETURNS TEXT AS
$$
DECLARE
	param TEXT[];
BEGIN
	IF _locale IS NOT NULL THEN
		param = array_append(param, 'LOCALE = ''' || _locale || '''');
	END IF;
	
	IF _lc_collate IS NOT NULL THEN
		param = array_append(param, 'LC_COLLATE = ''' || _lc_collate || '''');
	END IF;
	
	IF _lc_ctype IS NOT NULL THEN
		param = array_append(param, 'LC_CTYPE = ''' || _lc_ctype || '''');
	END IF;
	
	IF _provider IS NOT NULL THEN
		param = array_append(param, 'PROVIDER = ' || _provider);
	END IF;
	
	IF _version IS NOT NULL THEN
		param = array_append(param, 'VERSION = ''' || _version || '''');
	END IF;
	
	RETURN (SELECT format('CREATE COLLATION "%s"."%s" (%s);', _schema, _name, array_to_string(param, ', ')));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_collation_from(_schema TEXT, _name TEXT, _from TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('CREATE COLLATION "%s"."%s" FROM "%s";', _schema, _name, _from));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.refresh_collation_version(_schema TEXT, _name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER COLLATION "%s"."%s" REFRESH VERSION;', _schema, _name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.rename_collation(_schema TEXT, _name TEXT, _new_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER COLLATION "%s"."%s" RENAME TO "%";', _schema, _name, _new_name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_collation_owner(_schema TEXT, _name TEXT, _owner TEXT, _current_session BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER COLLATION "%s"."%s" OWNER TO %s;',
		_schema, _name, (CASE _current_session WHEN TRUE THEN 'CURRENT_USER' WHEN FALSE THEN 'SESSION_USER' ELSE ('"' || _owner || '"') END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_collation_schema(_schema TEXT, _name TEXT, _new_schema TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER COLLATION "%s"."%s" SET SCHEMA "%s";', _schema, _name, _new_schema));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_collation(_schema TEXT, _name TEXT, _cascade BOOLEAN DEFAULT FALSE, _exists BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP COLLATION %s"%s"."%s" %s;',
		(CASE _exists WHEN TRUE THEN 'IF EXISTS' ELSE '' END),
		_schema, _name,
		(CASE _cascade WHEN TRUE THEN 'CASCADE' ELSE 'RESTRICT' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.collation_exists(_schema TEXT, _name TEXT)
  RETURNS BOOLEAN AS
$$
BEGIN
	IF (SELECT TRUE FROM pg_collation WHERE collname = _name AND collnamespace = _schema::regnamespace) THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;
