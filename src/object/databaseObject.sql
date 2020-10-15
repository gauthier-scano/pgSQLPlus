CREATE FUNCTION @extschema@.create_database_from_object(objt JSONB)
 RETURNS VOID AS
$$
BEGIN
	EXECUTE @extschema@.create_str_create_database_from_object(objt);
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_create_database_from_object(objt JSONB)
 RETURNS TEXT AS
$$
DECLARE
	query		TEXT	= '';
	queryOut	TEXT	= '';
	schema_list	JSONB 	= '{}';
	table_list 	JSONB 	= '{}';
	
	role		JSONB;
	roleParam	JSONB;
	tablespac	JSONB;
	tablespacPa	JSONB;
	schem 		JSONB;
	schemaName	TEXT;
	iter		JSONB;
	tab			JSONB;
	tabVar		JSONB;
	colum 		JSONB;
	constrt		JSONB;
BEGIN
	IF objt->'schema' IS NULL THEN
		RAISE EXCEPTION 'Property "schema" is required in database object: %', tab;
	ELSEIF objt->'role' IS NULL THEN
		RAISE EXCEPTION 'Property "role" is required in database object: %', tab;
	ELSEIF objt->'extension' IS NULL THEN
		RAISE EXCEPTION 'Property "extension" is required in database object: %', tab;
	END IF;
	
	-- Creating roles
	FOR role IN (SELECT * FROM jsonb_array_elements(objt->'role')) LOOP
		query = query || @extschema@.create_role(
			role->>'name',
			ARRAY(SELECT jsonb_array_elements_text(role->'inRole')),
			ARRAY(SELECT jsonb_array_elements_text(role->'role')),
			ARRAY(SELECT jsonb_array_elements_text(role->'admin'))
		);
		
		query = query 	|| @extschema@.set_role_superuser(		role->>'name', (role->>'superUser')::BOOLEAN)
						|| @extschema@.set_role_createdb(		role->>'name', (role->>'createDb')::BOOLEAN)
						|| @extschema@.set_role_createrole(		role->>'name', (role->>'createRole')::BOOLEAN)
						|| @extschema@.set_role_inherit(			role->>'name', (role->>'inherit')::BOOLEAN)
						|| @extschema@.set_role_login(			role->>'name', (role->>'login')::BOOLEAN)
						|| @extschema@.set_role_connection_limit(role->>'name', (role->>'connectionLimit')::BIGINT)
						|| @extschema@.set_role_password(		role->>'name', (role->>'password')::TEXT)
						|| @extschema@.set_role_valid_until(		role->>'name', (role->>'validUntil')::TIMESTAMP);
		
		FOR roleParam IN (SELECT * FROM jsonb_array_elements(tab->'parameter')) LOOP
			query = query || @extschema@.set_role_parameter(roleParam->>'key', roleParam->>'value', roleParam->>'database', (roleParam->>'current')::BOOLEAN);
		END LOOP;
	END LOOP;
	
	-- Creating tablespace
	FOR tablespac IN (SELECT * FROM jsonb_array_elements(objt->'tablespace')) LOOP
		query = query || @extschema@.create_tablespace(tablespac->>'name', tablespac->>'location');
		
		IF tablespac->'owner' IS NOT NULL THEN
			query = query || @extschema@.set_tablespace_owner(tablespac->>'name', tablespac->>'owner');
		END IF;
		
		FOR tablespacPa IN (SELECT * FROM jsonb_array_elements(tab->'option')) LOOP
			query = query || @extschema@.set_tablespace_option(tablespac->>'name', tablespacPa->>'key', tablespacPa->>'value');
		END LOOP;
	END LOOP;
	
	-- Creating schema, table and column
	FOR schem IN (SELECT * FROM jsonb_array_elements(objt->'schema')) LOOP
		IF schem->'name' IS NULL THEN
			RAISE EXCEPTION 'Property "name" is required in schema object: %', tab;
		ELSEIF schem->'table' IS NULL THEN
			RAISE EXCEPTION 'Property "table" is required in schema object: %', schem;
		END IF;
		
		IF schema_list->(schem->>'name') IS NULL THEN
			query = query || @extschema@.create_schema(schem->>'name', TRUE);
			
			SELECT jsonb_set(schema_list, ('{' || (schem->>'name') || '}')::TEXT[], ('true')::JSONB) INTO schema_list;
		END IF;
		
		FOR iter IN (SELECT * FROM jsonb_array_elements(schem->'extension')) LOOP
			query = query || @extschema@.create_extension(ext->>'name', schem->>'name', iter->>'version', (iter->>'cascade')::BOOLEAN);
		END LOOP;
		
		FOR iter IN (SELECT * FROM jsonb_array_elements(schem->'domain')) LOOP
			query = query 	|| @extschema@.create_domain(schem->>'name', iter->>'name', iter->>'type', iter->>'collate')
							|| @extschema@.set_domain_not_null(schem->>'name', iter->>'name', (iter->>'notNull')::BOOLEAN);
			
			IF iter->>'default' IS NOT NULL THEN
				query = query || @extschema@.set_domain_default(schem->>'name', iter->>'name', iter->>'default');
			END IF;
			
			IF iter->'check' IS NOT NULL THEN
				query = query || @extschema@.add_domain_constraint(schem->>'name', iter->>'name', iter->>'check', FALSE);
			END IF;
		END LOOP;
		
		FOR tab IN (SELECT * FROM jsonb_array_elements(schem->'table')) LOOP
			IF tab->'name' IS NULL THEN
				RAISE EXCEPTION 'Property "name" is required in table object: %', tab;
			ELSEIF tab->'column' IS NULL THEN
				RAISE EXCEPTION 'Property "column" is required in table object: %', tab;
			END IF;
			
			IF table_list->((schem->>'name') || '.' || (tab->>'name')) IS NULL THEN
				query = query || @extschema@.create_table(schem->>'name', tab->>'name');
				
				SELECT jsonb_set(table_list, ('{' || ((schem->>'name') || '.' || (tab->>'name')) || '}')::TEXT[], ('true')::JSONB) INTO table_list;
			END IF;
			
			FOR colum IN (SELECT * FROM jsonb_array_elements(tab->'column')) LOOP
				IF colum->'name' IS NULL OR colum->'type' IS NULL OR colum->'notNull' IS NULL OR colum->'default' IS NULL THEN
					RAISE EXCEPTION 'Property "name", "type", "notNull" and "default" are required in column object: %', colum;
				END IF;
				
				query = query 	|| @extschema@.create_column(schem->>'name', tab->>'name', colum->>'name', colum->>'type', (colum->>'typeArray')::BOOLEAN)
								|| @extschema@.set_column_not_null(schem->>'name', tab->>'name', colum->>'name', (colum->>'notNull')::BOOLEAN)
								|| @extschema@.set_column_default(schem->>'name', tab->>'name', colum->>'name',  colum->>'default');
			END LOOP;
		END LOOP;
	END LOOP;
	
	-- Processing primary and unique first to prevent error from missing unique constraint
	FOR schem IN (SELECT * FROM jsonb_array_elements(objt->'schema')) LOOP
		FOR tab IN (SELECT * FROM jsonb_array_elements(schem->'table')) LOOP
			IF tab->'constraint' IS NOT NULL THEN
				query = query || @extschema@.create_str_process_pk_unique_from_constraint_object_list(schem->>'name', tab->>'name', tab->'constraint');
			END IF;
		END LOOP;
	END LOOP;
	
	-- Processing foreign and check constraint + indexes
	FOR schem IN (SELECT * FROM jsonb_array_elements(objt->'schema')) LOOP
		FOR tab IN (SELECT * FROM jsonb_array_elements(schem->'table')) LOOP
			query = query || @extschema@.create_str_process_fkey_check_index_from_table_object(schem->>'name', tab);
		END LOOP;
	END LOOP;
	
	-- Processing system functionnalities when every constraint are created
	FOR schem IN (SELECT * FROM jsonb_array_elements(objt->'schema')) LOOP
		FOR tab IN (SELECT * FROM jsonb_array_elements(schem->'table')) LOOP
			SELECT result.schema_list, result.query FROM @extschema@.create_str_process_system_from_object(schem->>'name', tab->>'name', tab, schema_list, query) AS result INTO schema_list, query;
			
			FOR tabVar IN (SELECT * FROM jsonb_array_elements(tab->'variable')) LOOP
				schemaName = @extschema@.get_variable_schema_name(schem->>'name', tabVar->>'schema');
				
				IF schema_list->(schemaName) IS NULL THEN
					query = query || @extschema@.create_schema(schemaName, TRUE);
					
					SELECT jsonb_set(schema_list, ARRAY[schemaName], ('true')::JSONB) INTO schema_list;
				END IF;
				
				query = query || @extschema@.create_table_variable_from_object(schem->>'name', tab->>'name', objt, tabVar, schema_list);
			END LOOP;
		END LOOP;
	END LOOP;
	
	RETURN (SELECT query);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_process_pk_unique_from_constraint_object_list(schem TEXT, tab TEXT, constraint_list JSONB)
 RETURNS TEXT AS
$$
DECLARE
	query 	TEXT = '';
	constrt JSONB;
BEGIN
	FOR constrt IN (SELECT * FROM jsonb_array_elements(constraint_list)) LOOP
		IF constrt->'type' IS NULL THEN
			RAISE EXCEPTION 'Property "type" est required in constraint object: %', constrt;
		ELSE
			CASE constrt->>'type'
				WHEN 'primary' THEN
					query = query || @extschema@.create_primary_key(schem, tab, ARRAY(SELECT jsonb_array_elements_text(constrt->'target')));
				WHEN 'unique' THEN
					query = query || @extschema@.create_unique(schem, tab, ARRAY(SELECT jsonb_array_elements_text(constrt->'target')));
				WHEN 'foreign' THEN
				WHEN 'check' THEN
				ELSE
					RAISE EXCEPTION 'Unsupported constraint type "%" in constraint: %', constrt->>'type', constrt;
			END CASE;
		END IF;
	END LOOP;
	
	RETURN (SELECT query);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_process_fkey_check_index_from_table_object(schem TEXT, tab JSONB)
 RETURNS TEXT AS
$$
DECLARE
	query 	TEXT = '';
	constrt JSONB;
	inde	JSONB;
BEGIN
	IF tab->'constraint' IS NOT NULL THEN
		FOR constrt IN (SELECT * FROM jsonb_array_elements(tab->'constraint')) LOOP
			IF constrt->'type' IS NULL THEN
				RAISE EXCEPTION 'Property "type" est required in constraint object: %', constrt;
			ELSE
				CASE constrt->>'type'
					WHEN 'foreign' THEN
						query = query || @extschema@.create_foreign_key(schem, tab->>'name', ARRAY(SELECT jsonb_array_elements_text(constrt->'from')), constrt->>'schema', constrt->>'table', ARRAY(SELECT jsonb_array_elements_text(constrt->'column')));
					WHEN 'check' THEN
					--	query = query || @extschema@.create_check(schem, tab->>'name', (colum->'from')::TEXT[], '{}'::JSONB); TODO
					ELSE -- required
				END CASE;
			END IF;
		END LOOP;
	END IF;
	
	IF tab->'index' IS NOT NULL THEN
		FOR inde IN (SELECT * FROM jsonb_array_elements(tab->'index')) LOOP
			query = query || @extschema@.create_index(schem, tab->>'name', ARRAY(SELECT jsonb_array_elements_text(inde->'column')));
		END LOOP;
	END IF;
	
	RETURN (SELECT query);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_process_system_from_object(schem TEXT, tab_name TEXT, tab JSONB, INOUT schema_list JSONB, INOUT query TEXT)
 AS
$$
DECLARE
	schemaName 	TEXT;
	colum 		JSONB;
BEGIN
	IF tab->'system' IS NOT NULL THEN
		FOR colum IN (SELECT * FROM jsonb_array_elements(tab->'column')) LOOP
			IF tab->'system'->'history' IS NOT NULL AND tab->'system'->>'history' = colum->>'name' THEN
				schemaName = @extschema@.get_history_schema_name(schem);
				
				IF schema_list->(schemaName) IS NULL THEN
					query = query || @extschema@.create_schema(schemaName, TRUE);
					
					SELECT jsonb_set(schema_list, ARRAY[schemaName], ('true')::JSONB) INTO schema_list;
				END IF;
				
				query = query || @extschema@.create_history_table(schem, tab_name, colum->>'name', colum->>'type');
			END IF;

			IF tab->'system'->'mask' IS NOT NULL AND tab->'system'->>'mask' = colum->>'name' THEN
				schemaName = @extschema@.get_mask_schema_name(schem);
				
				IF schema_list->(schemaName) IS NULL THEN
					query = query || @extschema@.create_schema(schemaName, TRUE);
					
					SELECT jsonb_set(schema_list, ARRAY[schemaName], ('true')::JSONB) INTO schema_list;
				END IF;
				
				query = query || @extschema@.create_mask_table(schem, tab_name, colum->>'name', colum->>'type');
			END IF;
			
			IF tab->'system'->'delete' IS NOT NULL AND tab->'system'->>'delete' = colum->>'name' THEN
				schemaName = @extschema@.get_delete_schema_name(schem);
				
				IF schema_list->(schemaName) IS NULL THEN
					query = query || @extschema@.create_schema(schemaName, TRUE);
					
					SELECT jsonb_set(schema_list, ARRAY[schemaName], ('true')::JSONB) INTO schema_list;
				END IF;
				
				query = query || @extschema@.create_delete_table(schem, tab_name, colum->>'name', colum->>'type');
			END IF;

			IF tab->'system'->'right' IS NOT NULL AND tab->'system'->>'right' = colum->>'name' THEN
				schemaName = @extschema@.get_right_schema_name(schem);
				
				IF schema_list->(schemaName) IS NULL THEN
					query = query || @extschema@.create_schema(schemaName, TRUE);
					
					SELECT jsonb_set(schema_list, ARRAY[schemaName], ('true')::JSONB) INTO schema_list;
				END IF;
				
				query = query || @extschema@.create_right_table(schem, tab_name, colum->>'name', colum->>'type');
			END IF;
		END LOOP;
	END IF;
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_table_variable_from_object(parent_schema TEXT, parent_table TEXT, databaseObjt JSONB, objt JSONB, schema_list JSONB)
 RETURNS TEXT AS
$$
DECLARE
	query 		TEXT = '';
	colum 		JSONB;
	varia 		JSONB;
	_schema_var TEXT;
	_table_var 	TEXT;
BEGIN
	IF objt->'schema' IS NULL THEN
		RAISE EXCEPTION 'Property "schema" is required in variable table object: %', tab;
	ELSEIF objt->'table' IS NULL THEN
		RAISE EXCEPTION 'Property "table" is required in variable table object: %', tab;
	ELSEIF objt->'target' IS NULL THEN
		RAISE EXCEPTION 'Property "target" is required in variable table object: %', tab;
	ELSEIF objt->'targetVar' IS NULL THEN
		RAISE EXCEPTION 'Property "targetVar" is required in variable table object: %', tab;
	ELSEIF objt->'column' IS NULL THEN
		RAISE EXCEPTION 'Property "column" is required in variable table object: %', tab;
	ELSEIF objt->'constraint' IS NULL THEN
		RAISE EXCEPTION 'Property "constraint" is required in variable table object: %', tab;
	ELSEIF objt->'index' IS NULL THEN
		RAISE EXCEPTION 'Property "index" is required in variable table object: %', tab;
	ELSEIF objt->'variable' IS NULL THEN
		RAISE EXCEPTION 'Property "variable" is required in variable table object: %', tab;
	END IF;
	
	_schema_var = @extschema@.get_variable_schema_name(parent_schema, objt->>'schema');
	_table_var 	= @extschema@.get_variable_table_name(parent_table, objt->>'table', objt->>'target');
	
	query = query || @extschema@.create_variable_table(
		parent_schema,
		parent_table,
		objt->>'targetVar',
	--	(@extschema@.get_column_by_name_from_database_object(parent_schema, parent_table, objt->>'targetVar', databaseObjt))->>'type',
		objt->>'schema',
		objt->>'table',
		objt->>'target'
	--	(@extschema@.get_column_by_name_from_database_object(objt->>'schema', objt->>'table', objt->>'target', databaseObjt))->>'type'
	);
	
	FOR colum IN (SELECT * FROM jsonb_array_elements(objt->'column')) LOOP
		IF colum->'name' IS NULL OR colum->'type' IS NULL OR colum->'notNull' IS NULL OR colum->'default' IS NULL THEN
			RAISE EXCEPTION 'Property "name", "type", "notNull" and "default" are required in column object: %', colum;
		END IF;
		
		query = query   || @extschema@.create_column(_schema_var, _table_var, colum->>'name', colum->>'type', (colum->>'typeArray')::BOOLEAN)
						|| @extschema@.set_column_not_null(_schema_var, _table_var, colum->>'name', (colum->>'notNull')::BOOLEAN)
						|| @extschema@.set_column_default(_schema_var, _table_var, colum->>'name',  colum->>'default');
	END LOOP;
	
	query = query || @extschema@.create_str_process_pk_unique_from_constraint_object_list(_schema_var, _table_var, objt->'constraint');
	query = query || @extschema@.create_str_process_fkey_check_index_from_table_object(_schema_var, objt);
	
	SELECT result.schema_list, result.query FROM @extschema@.create_str_process_system_from_object(_schema_var, _table_var, objt, schema_list, query) AS result INTO schema_list, query;
	
	FOR varia IN (SELECT * FROM jsonb_array_elements(objt->'variable')) LOOP
		query = query || @extschema@.create_table_variable_from_object(objt->>'schema', objt->>'table', databaseObjt, varia, schema_list);
	END LOOP;
	
	RETURN (SELECT query);
END;
$$
PARALLEL SAFE
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.get_column_by_name_from_database_object(schema_name TEXT, table_name TEXT, column_name TEXT, objt JSONB)
 RETURNS JSONB AS
$$
DECLARE
	schem 	JSONB;
	tab 	JSONB;
	colum 	JSONB;
BEGIN
	FOR schem IN (SELECT * FROM jsonb_array_elements(objt->'schema')) LOOP
		IF schem->>'name' = schema_name THEN
			FOR tab IN (SELECT * FROM jsonb_array_elements(schem->'table')) LOOP
				IF tab->>'name' = table_name THEN
					FOR colum IN (SELECT * FROM jsonb_array_elements(tab->'column')) LOOP
						IF colum->>'name' = column_name THEN
							RETURN (SELECT colum);
						END IF;
					END LOOP;
				END IF;
			END LOOP;
		END IF;
	END LOOP;
	
	RETURN NULL;
END;
$$
LANGUAGE plpgsql;
