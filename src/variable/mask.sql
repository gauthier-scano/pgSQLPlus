CREATE FUNCTION @extschema@.create_variable_mask_table(_schema TEXT, _table TEXT, _schema_variable TEXT, _table_variable TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.create_mask_table(
		@extschema@.get_variable_schema_name(_schema, _schema_variable),
		@extschema@.get_variable_table_name(_table, _table_variable, _column),
		'_id_'
	--	@extschema@.get_column_type(_schema, _table, _column)
	);
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.delete_variable_mask_table(_schema TEXT, _table TEXT, _schema_variable TEXT, _table_variable TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.delete_mask_table(
		@extschema@.get_variable_schema_name(_schema, _schema_variable),
		@extschema@.get_variable_table_name(_table, _table_variable, _column),
		'_id_'
	--	@extschema@.get_column_type(_schema, _table, _column)
	);
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.has_variable_mask_table(_schema TEXT, _table TEXT, _schema_variable TEXT, _table_variable TEXT, _column TEXT)
  RETURNS TEXT AS
$$
	SELECT @extschema@.has_mask_table(
		@extschema@.get_variable_schema_name(_schema, _schema_variable),
		@extschema@.get_variable_table_name(_table, _table_variable, _column)
	);
$$
LANGUAGE sql;
