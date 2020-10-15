CREATE FUNCTION @extschema@.get_variable_schema_name(_schema TEXT, _schema_variable TEXT)
  RETURNS TEXT AS
$$
	SELECT ('_var_' || _schema || '_' || _schema_variable || '_');
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.get_variable_table_name(_table TEXT, _table_variable TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT _table || '_' || _table_variable || '_' || _column;
$$
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
LANGUAGE sql;


CREATE FUNCTION @extschema@.get_variable_table_list(_schema TEXT, _table TEXT)
  RETURNS TABLE(
		column_from TEXT,
		schema_to 	TEXT,
		table_to 	TEXT,
		column_to 	TEXT
  ) AS
$$
	SELECT 	column_from, schema_to, table_to, column_to
	FROM 	@extschema@.variable
	WHERE	schema_from = _schema AND table_from = _table;
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.has_variable_table(_schema TEXT, _table TEXT, _schema_variable TEXT, _table_variable TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.table_exists(
		@extschema@.get_variable_schema_name(_schema, _schema_variable),
		@extschema@.get_variable_table_name(_table, _table_variable, _column)
	);
$$
PARALLEL SAFE
LANGUAGE sql;


CREATE FUNCTION @extschema@.create_variable_table(
	_schema 				TEXT,
	_table 					TEXT,
	_column 				TEXT,
--	_column_type 			TEXT,
	_schema_variable 		TEXT,
	_table_variable 		TEXT,
	_column_variable 		TEXT
--	_column_variable_type 	TEXT
)
  RETURNS TEXT AS
$$
DECLARE
	_schema_variable_name 	TEXT := @extschema@.get_variable_schema_name(_schema, _schema_variable);
	_table_variable_name 	TEXT := @extschema@.get_variable_table_name(_table, _table_variable, _column_variable);
	
	_column_type			TEXT := @extschema@.get_column_type(_schema, _table, _column);
	_column_variable_type 	TEXT := @extschema@.get_column_type(_schema_variable, _table_variable, _column_variable);
BEGIN
	RETURN (SELECT
			@extschema@.create_schema(@extschema@.get_variable_schema_name(_schema, _schema_variable), TRUE)
		||	@extschema@.create_table(_schema_variable_name, _table_variable_name)
		
		|| 	@extschema@.create_column(_schema_variable_name, _table_variable_name, '_id_', 'BIGSERIAL') -- unique
		|| 	@extschema@.set_column_not_null(_schema_variable_name, _table_variable_name, '_id_', TRUE)
		
		|| 	@extschema@.create_column(_schema_variable_name, _table_variable_name, '_target_',  _column_type)
		|| 	@extschema@.set_column_not_null(_schema_variable_name, _table_variable_name, '_target_', TRUE)
		
		|| 	@extschema@.create_column(_schema_variable_name, _table_variable_name, '_variable_', _column_variable_type)
		|| 	@extschema@.set_column_not_null(_schema_variable_name, _table_variable_name, '_variable_', TRUE)
		
		||	@extschema@.create_unique(_schema_variable_name, _table_variable_name, ARRAY['_target_', '_variable_'])
		|| 	@extschema@.create_index(_schema_variable_name, _table_variable_name, ARRAY['_target_', '_variable_'])
		
		|| 	@extschema@.create_foreign_key(_schema_variable_name, _table_variable_name, ARRAY['_target_'], _schema, _table, ARRAY[_column], TRUE, TRUE, TRUE)
		|| 	@extschema@.create_foreign_key(_schema_variable_name, _table_variable_name, ARRAY['_variable_'], _schema_variable, _table_variable, ARRAY[_column_variable], TRUE, TRUE, TRUE)
		
		|| 	@extschema@.create_index(_schema_variable_name, _table_variable_name, ARRAY['_id_'], TRUE, FALSE)
		
	--	|| 	@extschema@.create_right_function(_schema, _table, _column, _column_type)
				
		|| format(
			'INSERT INTO @extschema@.variable(schema_from, table_from, column_from, schema_to, table_to, column_to) VALUES (%L, %L, %L, %L, %L, %L);',
			_schema, _table, _column, _schema_variable, _table_variable, _column_variable
		)
	);
END;
$$
LANGUAGE plpgsql;


/*
TO RECODE
CREATE FUNCTION @extschema@.create_variable_column(
	_schema 			TEXT,
	_table 				TEXT,
	_schema_variable 	TEXT,
	_table_variable 	TEXT,
	_column				TEXT,
	
	_name 				TEXT,
	_new_name			TEXT,
	_type				TEXT,
	_not_null			BOOLEAN,
	_default			TEXT
) RETURNS VOID AS
$$
	SELECT @extschema@.create_column(
		@extschema@.get_variable_schema_name(_schema, _schema_variable),
		@extschema@.get_variable_table_name(_table, _table_variable, _column),
		_name, _new_name, _type, _not_null, _default
	);
$$
LANGUAGE sql;
*/


CREATE FUNCTION @extschema@.create_variable_function(_schema TEXT, _table TEXT, _column TEXT, _type TEXT)
  RETURNS TEXT AS
$$
DECLARE
	_schema_right TEXT := @extschema@.get_right_schema_name(_schema);
BEGIN
  	RETURN (SELECT format(
		'CREATE FUNCTION "%s"."syst_set_right_from_%s"(_user TEXT, _user_target TEXT, _value %s[], _delete BOOLEAN, _mask BOOLEAN, _history BOOLEAN, _update BOOLEAN, _read BOOLEAN, _right BOOLEAN)
		RETURNS VOID AS 
		$T2$
	  	BEGIN
			INSERT INTO "%s"."%s" (
				
			) VALUES (
				
			);
	 	END;
		$T2$
		LANGUAGE plpgsql;',
		_schema, _table, _type,
		_schema_right, _table
 	));
END;
$$
LANGUAGE plpgsql;
