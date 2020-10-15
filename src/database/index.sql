CREATE FUNCTION @extschema@.get_constraint_name_index(_schema TEXT, _table TEXT, _column TEXT[])
  RETURNS TEXT AS
$$
BEGIN
	RETURN (SELECT 'ind_' || _schema || '_' || _table || '_' || array_to_string(_column, '_'));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_index(_schema TEXT, _table TEXT, _column TEXT[], _unique BOOLEAN DEFAULT FALSE, _concurrently BOOLEAN DEFAULT FALSE, _name TEXT DEFAULT NULL)
  RETURNS TEXT AS
$$
BEGIN
	IF _name IS NULL THEN
		_name := @extschema@.get_constraint_name_index(_schema, _table, _column);
	END IF;
	
	RETURN (SELECT format(
		'CREATE %sINDEX %s"%s" ON "%s"."%s"("%s");',
		(CASE _unique WHEN TRUE THEN 'UNIQUE ' WHEN FALSE THEN '' END),
		(CASE _concurrently WHEN TRUE THEN 'CONCURRENTLY ' WHEN FALSE THEN '' END),
		_name, _schema, _table, array_to_string(_column, '","')
	));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.rename_index(_schema TEXT, _table TEXT, _name TEXT, _new_name TEXT)
  RETURNS TEXT AS
$$
BEGIN
	--RETURN (SELECT format('ALTER TABLE "%s"."%s" RENAME CONSTRAINT "%s" TO "%s";', _schema, _table, _constraint_name, _constraint_new_name));
END;
$$
IMMUTABLE
PARALLEL SAFE
LANGUAGE plpgsql;
