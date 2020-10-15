CREATE FUNCTION @extschema@.create_insert_object(_name VARCHAR, _objt JSONB)
  RETURNS VOID AS
$$
	INSERT INTO @extschema@.insert_object(name, objt) VALUES (_name, _objt) ON CONFLICT (name) DO UPDATE SET objt = _objt;
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.delete_insert_object(_name VARCHAR)
  RETURNS VOID AS
$$
	DELETE FROM @extschema@.insert_object WHERE name = _name;
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.delete_insert_object(_name VARCHAR[])
  RETURNS VOID AS
$$
	DELETE FROM @extschema@.insert_object WHERE name = ANY(_name);
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.create_function_from_insert_object(_objt_name VARCHAR, _schema TEXT DEFAULT NULL, _name TEXT DEFAULT NULL)
 RETURNS VOID AS
$$
BEGIN
	EXECUTE @extschema@.create_str_insert_function((SELECT objt FROM @extschema@.insert_object WHERE name = _objt_name), _schema, _name);
END;
$$
LANGUAGE plpgsql;
