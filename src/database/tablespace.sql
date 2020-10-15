CREATE FUNCTION @extschema@.create_tablespace(_name TEXT, _location TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('CREATE TABLESPACE "%s" LOCATION ''%s'';', _name, _location));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_tablespace_owner(_name TEXT, _owner TEXT, _current_session BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER TABLESPACE "%s" OWNER TO %s;',
		_name, (CASE _current_session WHEN TRUE THEN 'CURRENT_USER' WHEN FALSE THEN 'SESSION_USER' ELSE ('"' || _owner || '"') END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_tablespace_option(_name TEXT, _key TEXT, _value TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER TABLESPACE "%s" SET (%s = %s);', _name, _key, _value));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_tablespace_option(_name TEXT, _list TEXT[][])
  RETURNS TEXT AS
$$
DECLARE
	cas 	TEXT[];
	param	TEXT[];
	query 	TEXT := '';
BEGIN
	FOREACH cas IN ARRAY _list LOOP
	  param = array_append(param, cas[1] || ' = ' || cas[2]);
	END LOOP;

	RETURN (SELECT format('ALTER TABLESPACE "%s" SET (%s);', _name, _key, string_to_array(param, ', ')));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.reset_tablespace_option(_name TEXT, _option_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT @extschema@.reset_tablespace_option(_name, ARRAY[_option_name]));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.reset_tablespace_option(_name TEXT, _option_name TEXT[])
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER TABLESPACE "%s" RESET (%s);', _name, _key, string_to_array(_option_name, ', ')));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_tablespace(_name TEXT, _exists BOOLEAN)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('DROP TABLESPACE %s"%s";', (CASE _exists WHEN TRUE THEN 'IF EXISTS ' ELSE '' END), _name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;
