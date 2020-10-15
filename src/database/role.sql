CREATE FUNCTION @extschema@.create_role(
	name 	TEXT,
	in_role TEXT[] 	DEFAULT NULL,
	role 	TEXT[] 	DEFAULT NULL,
	admin 	TEXT[] 	DEFAULT NULL
) RETURNS TEXT AS
$$
DECLARE
	_query TEXT := '';
BEGIN
	RETURN (SELECT format(
		'CREATE ROLE "%s"%s%s%s;',
		name,
		(CASE (in_role  IS NOT NULL AND array_length(in_role, 1) > 0) 	WHEN TRUE THEN (' IN ROLE "' || array_to_string(in_role, '", "')) || '"' ELSE '' END),
		(CASE (role 	IS NOT NULL AND array_length(role, 1) > 0) 		WHEN TRUE THEN (' ROLE "' 	 || array_to_string(role, '", "')) 	  || '"' ELSE '' END),
		(CASE (admin 	IS NOT NULL AND array_length(admin, 1) > 0) 	WHEN TRUE THEN (' ADMIN "' 	 || array_to_string(admin, '", "'))   || '"' ELSE '' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_name(_name TEXT, _new_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER ROLE "%s" RENAME TO "%s";', _name, _new_name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_superuser(_name TEXT, _superuser BOOLEAN)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s" WITH %sSUPERUSER;',
		_name,
		(CASE _superuser WHEN TRUE THEN '' ELSE 'NO' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_createdb(_name TEXT, _createdb BOOLEAN)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s" WITH %sCREATEDB;',
		_name,
		(CASE _createdb WHEN TRUE THEN '' ELSE 'NO' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_createrole(_name TEXT, _createrole BOOLEAN)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s" WITH %sCREATEROLE;',
		_name,
		(CASE _createrole WHEN TRUE THEN '' ELSE 'NO' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_inherit(_name TEXT, _inherit BOOLEAN)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s" WITH %sINHERIT;',
		_name,
		(CASE _inherit WHEN TRUE THEN '' ELSE 'NO' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_login(_name TEXT, _login BOOLEAN)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s" WITH %sLOGIN;',
		_name,
		(CASE _login WHEN TRUE THEN '' ELSE 'NO' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_connection_limit(_name TEXT, _limit BIGINT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s" WITH CONNECTION LIMIT %s;',
		_name,
		(CASE _limit WHEN NULL THEN '-1' ELSE _limit END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_password(_name TEXT, _password TEXT, _encrypted BOOLEAN DEFAULT TRUE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s" WITH %sENCRYPTED PASSWORD %s;',
		_name,
		(CASE _encrypted WHEN TRUE THEN '' 		ELSE 'UN' END),
		(CASE _password  WHEN NULL THEN 'NULL' 	ELSE ('''' || _password || '''') END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_valid_until(_name TEXT, _time TIMESTAMP)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s" WITH VALID UNTIL ''%s'';',
		_name,
		(CASE _time WHEN NULL THEN 'infinity' ELSE _time END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_role_parameter(_name TEXT, _param TEXT, _value TEXT, _database TEXT DEFAULT NULL, _current BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE %s%s SET %s%s;',
		(CASE _name 	WHEN NULL THEN 'ALL' ELSE ('"' || _name || '"') END),
		(CASE _database WHEN NULL THEN '' ELSE (' IN DATABASE "' || _database || '"') END),
		_param,
		(CASE _current 	WHEN TRUE THEN ' FROM CURRENT' ELSE (' = ' || _value) END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.reset_role_parameter(_name TEXT, _param TEXT, _database TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER ROLE "%s"%s RESET %s;',
		(CASE _name 	WHEN NULL THEN 'ALL' ELSE ('"' || _name || '"') END),
		(CASE _database WHEN NULL THEN '' ELSE (' IN DATABASE "' || _database || '"') END),
		(CASE _param 	WHEN NULL THEN 'ALL' ELSE _value END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_role(_name TEXT, _exists BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN @extschema@.drop_role(ARRAY[_name], _exists);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_role(_name TEXT[], _exists BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP ROLE %s"%s";',
		(CASE _exists WHEN TRUE THEN 'IF EXISTS ' ELSE '' END),
		array_to_string(_name, '", "')
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.add_role_to_group(_group_name TEXT, _user TEXT[], _current_session BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER GROUP "%s" ADD USER "%s";',
		(CASE _group_name IS NOT NULL
			WHEN TRUE THEN _group_name
			ELSE
				(CASE _current_session
					WHEN TRUE THEN 'CURRENT_USER'
					ELSE 'SESSION_USER'
				END)
		END),
		array_to_string(_user, '", "')
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_role_from_group(_group_name TEXT, _user TEXT[], _current_session BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER GROUP "%s" DROP USER "%s";',
		(CASE _group_name IS NOT NULL
			WHEN TRUE THEN _group_name
			ELSE
				(CASE _current_session
					WHEN TRUE THEN 'CURRENT_USER'
					ELSE 'SESSION_USER'
				END)
		END),
		array_to_string(_user, '", "')
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.role_exists(_name TEXT)
  RETURNS BOOLEAN AS
$$
BEGIN
	IF (SELECT TRUE FROM pg_roles WHERE rolname = _name) THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$
LANGUAGE plpgsql;
