CREATE FUNCTION @extschema@.create_variable_delete_table(_schema TEXT, _table TEXT, _schema_variable TEXT, _table_variable TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.create_delete_table(
		@extschema@.get_variable_schema_name(_schema, _schema_variable),
		@extschema@.get_variable_table_name(_table, _table_variable, _column),
		'_id_'
	--	@extschema@.get_column_type(_schema, _table, _column)
	);
$$
PARALLEL SAFE
LANGUAGE sql;


CREATE FUNCTION @extschema@.delete_variable_delete_table(_schema TEXT, _table TEXT, _schema_variable TEXT, _table_variable TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.delete_delete_table(
		@extschema@.get_variable_schema_name(_schema, _schema_variable),
		@extschema@.get_variable_table_name(_table, _table_variable, _column),
		'_id_'
	--	@extschema@.get_column_type(_schema, _table, _column)
	);
$$
PARALLEL SAFE
LANGUAGE sql;


CREATE FUNCTION @extschema@.has_variable_delete_table(_schema TEXT, _table TEXT, _schema_variable TEXT, _table_variable TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.has_delete_table(
		@extschema@.get_variable_schema_name(_schema, _schema_variable),
		@extschema@.get_variable_table_name(_table, _table_variable, _column)
	);
$$
LANGUAGE sql;
