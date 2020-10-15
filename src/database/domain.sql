CREATE FUNCTION @extschema@.create_domain(_schema TEXT, _name TEXT, _data_type TEXT, _collate TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'CREATE DOMAIN "%s"."%s" AS %s%s;',
		_schema, _name, _data_type,
		(CASE _collate IS NOT NULL WHEN TRUE THEN (' COLLATE ' || _collate) ELSE '' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_domain_default(_schema TEXT, _name TEXT, _default TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER DOMAIN "%s"."%s" SET DEFAULT %s;', _schema, _name, _default));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_domain_default(_schema TEXT, _name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER DOMAIN "%s"."%s" DROP DEFAULT;', _schema, _name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_domain_not_null(_schema TEXT, _name TEXT, _not_null BOOLEAN)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER DOMAIN "%s"."%s" %s NOT NULL;',
		_schema, _name, (CASE _not_null WHEN TRUE THEN 'SET' ELSE 'DROP' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.add_domain_constraint(_schema TEXT, _name TEXT, _constraint TEXT, _valid BOOLEAN DEFAULT FALSE)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER DOMAIN "%s"."%s" ADD %s%s;',
		_schema, _name,
		(CASE _if_exists WHEN TRUE THEN ' NOT VALID' ELSE '' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_domain_constraint(_schema TEXT, _name TEXT, _constraint_name TEXT, _if_exists BOOLEAN DEFAULT NULL, _restrict_cascade BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'ALTER DOMAIN "%s"."%s" DROP CONSTRAINT %s"%s"%s;',
		_schema, _name,
		(CASE _if_exists WHEN TRUE THEN 'IF EXISTS ' ELSE '' END),
		_constraint_name,
		(CASE _restrict_cascade WHEN TRUE THEN ' RESTRICT' WHEN FALSE THEN ' CASCADE' ELSE '' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.rename_domain_constraint(_schema TEXT, _name TEXT, _constraint_name TEXT, _new_constraint_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER DOMAIN "%s"."%s" RENAME CONSTRAINT "%s" TO "%s";', _schema, _name, _constraint_name, _new_constraint_name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.validate_domain_constraint(_schema TEXT, _name TEXT, _constraint_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER DOMAIN "%s"."%s" VALIDATE CONSTRAINT "%s";', _schema, _name, _constraint_name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_domain_owner(_schema TEXT, _name TEXT, _owner TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER DOMAIN "%s"."%s" OWNER TO "%s";', _schema, _name, _owner));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.rename_domain(_schema TEXT, _name TEXT, _new_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER DOMAIN "%s"."%s" RENAME TO "%s";', _schema, _name, _new_name));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.set_domain_schema(_schema TEXT, _name TEXT, _new_schema TEXT)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format('ALTER DOMAIN "%s"."%s" SET SCHEMA "%s";', _schema, _name, _new_schema));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_domain(_schema TEXT, _name TEXT, _cascade_restrict BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN @extschema@.drop_domain(_schema, ARRAY[_name], _cascade_restrict);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.drop_domain(_schema TEXT, _name TEXT[], _cascade_restrict BOOLEAN DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT format(
		'DROP DOMAIN "%s"."%s"%s;',
		_schema, array_to_string(_name, '", "' || _schema || '"."'),
		(CASE _cascade_restrict WHEN TRUE THEN ' CASCADE' ELSE ' RESTRICT' END)
	));
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.domain_exists(_schema TEXT, _name TEXT)
  RETURNS BOOLEAN AS
$$
BEGIN
	IF (SELECT TRUE FROM pg_type WHERE typname = _name AND typnamespace = _schema::regnamespace) THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;
