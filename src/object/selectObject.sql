CREATE FUNCTION @extschema@.create_select_object(_name VARCHAR, _objt JSONB)
  RETURNS VOID AS
$$
BEGIN
	INSERT INTO @extschema@.select_object(name, objt) VALUES (_name, _objt) ON CONFLICT (name) DO UPDATE SET objt = _objt;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_select_object(_name VARCHAR)
  RETURNS VOID AS
$$
	DELETE FROM @extschema@.select_object WHERE name = _name;
$$
LANGUAGE sql;


CREATE FUNCTION @extschema@.delete_select_object(_name VARCHAR[])
  RETURNS VOID AS
$$
BEGIN
	DELETE FROM @extschema@.select_object WHERE name = ANY(_name);
END;
$$
LANGUAGE plpgsql;



CREATE FUNCTION @extschema@.create_view_from_select_object(_objt_name VARCHAR, _schema TEXT, _name TEXT)
 RETURNS VOID AS
$$
DECLARE
	objt	 JSONB := (SELECT objt FROM @extschema@.select_object WHERE name = _objt_name);
	arg		 JSONB;
	query 	 TEXT;
	dep_list JSONB := @extschema@.extract_table_as(objt);
	_key	 TEXT;
	_value	 JSONB;
BEGIN
	SELECT * FROM @extschema@.create_str_select(objt, TRUE) INTO arg, query;
	
	EXECUTE format('CREATE MATERIALIZED VIEW "%I"."%I" AS %s;', _schema, _name, query);
	
	EXECUTE format('
		CREATE FUNCTION "%I"."%I_trigger_proc"()
		RETURNS TRIGGER AS
		$T1$
		BEGIN
			REFRESH MATERIALIZED VIEW CONCURRENTLY "%I"."%I";
			RETURN NULL;
		END;
		$T1$
		LANGUAGE plpgsql;
	', _schema, _name, _schema, _name);
	
	FOR _key, _value IN (SELECT * FROM jsonb_each(dep_list)) LOOP
		EXECUTE format('
			CREATE TRIGGER "%I_%I_trigger_%I_%I"
			AFTER INSERT OR UPDATE OR DELETE OR TRUNCATE
			ON "%I"."%I" FOR EACH STATEMENT 
			EXECUTE PROCEDURE "%I"."%I_trigger_proc"();
		', _schema, _name, _value->>'schema', _value->>'table', _value->>'schema', _value->>'table', _schema, _name);
	END LOOP;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.delete_view_from_select_object(_objt_name VARCHAR, _schema TEXT, _name TEXT)
 RETURNS VOID AS
$$
DECLARE
	objt 	 JSONB := (SELECT objt FROM @extschema@.select_object WHERE name = _objt_name);
	dep_list JSONB := @extschema@.extract_table_as(objt);
	_key	 TEXT;
	_value	 JSONB;
BEGIN
	FOR _key, _value IN (SELECT * FROM jsonb_each(dep_list)) LOOP
		EXECUTE format('DROP TRIGGER "%I_%I_trigger_%I_%I" ON "%I"."%I";', _schema, _name, _value->>'schema', _value->>'table', _value->>'schema', _value->>'table');
	END LOOP;
	
	EXECUTE format('DROP FUNCTION "%I"."%I_trigger_proc";', _schema, _name);
	EXECUTE format('DROP MATERIALIZED VIEW "%I"."%I";', _schema, _name);
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_function_from_select_object(_objt_name VARCHAR, _schema TEXT DEFAULT NULL, _name TEXT DEFAULT NULL)
 RETURNS VOID AS
$$
BEGIN
	EXECUTE @extschema@.create_str_select_function((SELECT objt FROM @extschema@.select_object WHERE name = _objt_name), _schema, _name);
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_select_function(objt JSONB, _schema TEXT DEFAULT NULL, _name TEXT DEFAULT NULL)
 RETURNS TEXT AS
$$
DECLARE
	str 	 	TEXT := 'CREATE FUNCTION ';
	query 	 	TEXT;
	
	arg		 	JSONB;
	arg_arr 	TEXT[] := '{}';
	
	retrn	 	JSONB;
	retrn_arr	TEXT[] := '{}';
	
	_key		TEXT;
	_value	 	TEXT;
	field	 	JSONB;
BEGIN
	IF _schema IS NULL THEN
		_schema := 'test';
	ELSE
		_schema := _schema;
	END IF;
	
	IF _name IS NULL THEN
		_name := _objt_name;
	END IF;
	
	str := str || '"' || _schema || '"."' || _name || '"(';
	
	SELECT * FROM @extschema@.create_str_select(objt, TRUE) INTO arg, query, retrn;
	
	FOR _key, _value IN (SELECT * FROM jsonb_each_text(arg)) LOOP
		arg_arr := array_append(arg_arr, '"' || _key || '" ' || _value);
	END LOOP;
	
	str := str || array_to_string(arg_arr, ',') || ') RETURNS TABLE(';
	
	FOR field IN (SELECT * FROM jsonb_array_elements(retrn)) LOOP
		retrn_arr := array_append(retrn_arr, '"' || (field->>0) || '" ' || (field->>1));
	END LOOP;
	
	str := str || array_to_string(retrn_arr, ',') || ') AS $T1$ ' || query || '; $T1$ LANGUAGE sql;';
	
	RAISE NOTICE 'Function: %', str;
	
	RETURN str;
END;
$$
LANGUAGE plpgsql;

CREATE FUNCTION @extschema@.create_str_select(objt JSONB, IN list_arg_type BOOLEAN DEFAULT FALSE, INOUT arg JSONB DEFAULT '{}', OUT str_request TEXT, OUT retrn JSONB)
 AS
$$
DECLARE
	str_join		TEXT;
	str_buffer		TEXT;
	str_buffer2		TEXT;
	str_buffer3		TEXT;
	column_list 	TEXT[] := '{}';
	column_var		TEXT[];
	as_list			JSONB := '{}';
	field 			JSONB;
BEGIN
	IF objt->'column' IS NULL THEN
		RAISE EXCEPTION 'Property "column" is required in selectObject.';
	ELSEIF jsonb_array_length(objt->'column') = 0 THEN
		RAISE EXCEPTION 'One or more column have to be specified in table description: %', objt;
	END IF;

	str_request := 'SELECT ';
	retrn := '[]'::JSONB;
	
	IF objt->'join' IS NOT NULL THEN
		FOR field IN (SELECT * FROM jsonb_array_elements(objt->'join')) LOOP
			IF field->'table' IS NOT NULL THEN
				SELECT jsonb_set(as_list, ('{' || (field->>'as') || '}')::TEXT[], ('{ "schema" : "' || (field->>'schema') || '", "table" : "' || (field->>'table') || '"}')::JSONB) INTO as_list;
			END IF;
		END LOOP;
	END IF;
	
	/* To continue
	FOR field IN (SELECT * FROM jsonb_array_elements(objt->'column')) LOOP
		IF field = '"*"' OR (field->>'type' = 'column' AND field->'name' = '"*"') THEN
			FOR str_buffer, str_buffer2 IN (SELECT name FROM @extschema@.get_table_column_list(objt->>'schema', objt->>'table')) LOOP
				SELECT jsonb_insert(objt, ('{column}')::TEXT[], ('{ "name" : "' || str_buffer || '", "varType" : "' || str_buffer2 || '"}')::JSONB) INTO objt->'column';
			END LOOP;
		END IF;
	END LOOP;*/
	
	FOR field IN (SELECT * FROM jsonb_array_elements(objt->'column')) LOOP
		IF (field->>'variable')::BOOLEAN IS TRUE THEN
			IF objt->'schema' IS NULL THEN
				RAISE EXCEPTION 'Property "schema" is required in column when property "variable" is true.';
			ELSEIF objt->'table' IS NULL THEN
				RAISE EXCEPTION 'Property "table" is required in column when property "variable" is true.';
			END IF;
			
			str_buffer := @extschema@.get_variable_schema_name(objt->>'schema', field->>'schema');
			str_buffer2 := @extschema@.get_variable_table_name(objt->>'table', field->>'table', field->>'column');
			str_buffer3 := (objt->>'schema') || '_' || (field->>'schema') || '_' || (objt->>'table') || '_' || (field->>'table') || '_' || (field->>'column');

			IF (SELECT str_buffer3 = ANY(column_var)) IS NULL THEN
				column_var := array_append(column_var, str_buffer3);

				IF objt->'join' IS NULL THEN
					SELECT jsonb_set(objt, '{join}', '[]') INTO objt;
				END IF;

				SELECT jsonb_insert(objt, '{join,0}', format('{
					"schema" : "%I",
					"table" : "%I",
					"as" : "%I",
					"condition" : {
						"type" : "AND",
						"condition" : [{
							"type" : "operator",
							"left" : "_target_",
							"operator" : "=",
							"right" : {
								"name" : "%I",
								"from" : "%I"
							}
						}, {
							"type" : "operator",
							"left" : "_variable_",
							"operator" : "=",
							"right" : {
								"type" : "variable",
								"name" : "var_%I",
								"varType" : %I
							}
						}]
					}
				}',
				str_buffer, str_buffer2, str_buffer3,
				@extschema@.get_foreign_key_target(str_buffer, str_buffer2, '_target_'),
				objt->>'as', str_buffer3,
				@extschema@.get_column_type(str_buffer, str_buffer2, '_variable_')
				)::JSONB, TRUE) INTO objt;
			END IF;

			IF objt->'system' IS NOT NULL AND objt->'system'->'variable' IS NOT NULL THEN
				IF LOWER(objt->'condition'->>'type') <> 'and' THEN
					SELECT jsonb_set(objt, '{condition}', jsonb_insert('{
						"type" : "AND",
						"condition" : []
					}', '{condition,0}', objt->'condition', TRUE)) INTO objt;
				END IF;

				IF 	(objt->'system'->'variable'->>'apply_mask')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->>'apply_mask')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->(field->>'table')->>'apply_mask')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->(field->>'table')->(field->>'column')->>'apply_mask')::BOOLEAN
				THEN
					SELECT jsonb_insert(objt, '{condition,condition,0}', @extschema@.create_mask_objt_condition(str_buffer, str_buffer2, str_buffer3)) INTO objt;
				END IF;

				IF 	(objt->'system'->'variable'->>'apply_delete')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->>'apply_delete')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->(field->>'table')->>'apply_delete')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->(field->>'table')->(field->>'column')->>'apply_delete')::BOOLEAN
				THEN
					SELECT jsonb_insert(objt, '{condition,condition,0}', @extschema@.create_delete_objt_condition(str_buffer, str_buffer2, str_buffer3)) INTO objt;
				END IF;

				IF 	(objt->'system'->'variable'->>'apply_history')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->>'apply_history')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->(field->>'table')->>'apply_history')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->(field->>'table')->(field->>'column')->>'apply_history')::BOOLEAN
				THEN
					SELECT jsonb_insert(objt, '{condition,condition,0}', @extschema@.create_history_objt_condition(str_buffer, str_buffer2, str_buffer3)) INTO objt;
				END IF;

				IF 	(objt->'system'->'variable'->>'apply_right')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->>'apply_right')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->(field->>'table')->>'apply_right')::BOOLEAN OR
					(objt->'system'->'variable'->(field->>'schema')->(field->>'table')->(field->>'column')->>'apply_right')::BOOLEAN
				THEN
					SELECT jsonb_insert(objt, '{condition,condition,0}', @extschema@.create_right_objt_condition(str_buffer, str_buffer2, str_buffer3)) INTO objt;
				END IF;
			END IF;

			SELECT jsonb_set(field, '{schema}', ('"' || str_buffer || '"')::JSONB) INTO field;
			SELECT jsonb_set(field, '{table}', ('"' || str_buffer2 || '"')::JSONB) INTO field;
			SELECT * FROM @extschema@.create_str_member(field, str_buffer3, TRUE, arg) INTO arg, str_buffer;
		ELSE
			SELECT * FROM @extschema@.create_str_member(field, objt->>'as', TRUE, arg) INTO arg, str_buffer;
		END IF;

		column_list := array_append(column_list, str_buffer);

		IF list_arg_type IS TRUE THEN
			IF jsonb_typeof(field) = 'string' THEN
				field := format('{"type" : "column", "name" : %s}', field);
			END IF;
			
			IF field->'as' IS NOT NULL THEN
				str_buffer := field->>'as';
			ELSEIF field->'type' IS NULL OR field->>'type' = 'column' OR (field->>'variable')::BOOLEAN IS TRUE THEN
				str_buffer := field->>'name';
			ELSEIF field->>'type' = 'function' THEN
				str_buffer := field->>'name';
			ELSEIF field->>'type' = 'constant' THEN
				RAISE EXCEPTION 'Property "as" is required with colum type "constant"';
			END IF;
			
			IF field->'varType' IS NOT NULL THEN
				str_buffer2 := field->>'varType';
			ELSEIF field->'cast' IS NOT NULL THEN
				str_buffer2 := field->'cast'->>-1;
			ELSEIF field->>'type' = 'selection' THEN	-- actually, varType is mandatory with "selection" type
				RAISE EXCEPTION 'Property "varType" is required with colum type "selection"';
			ELSEIF field->>'type' = 'constant' THEN
				str_buffer := jsonb_typeof(field->'value');

				IF str_buffer = 'string' THEN
					str_buffer2 := 'TEXT';
				ELSEIF str_buffer = 'boolean' OR str_buffer = 'null' THEN
					str_buffer2 := 'BOOLEAN';
				ELSEIF str_buffer = 'number' THEN
					str_buffer2 := 'NUMERIC';
				ELSE
					RAISE EXCEPTION 'Cannot determine column type and property "varType" is not defined.';
				END IF;
			ELSEIF field->>'type' = 'condition' THEN
				str_buffer2 := 'BOOLEAN';
			ELSEIF field->'type' IS NULL OR field->>'type' = 'column' OR (field->>'variable')::BOOLEAN IS TRUE THEN
				IF (field->>'variable')::BOOLEAN IS TRUE THEN
					str_buffer2 := @extschema@.get_column_type(field->>'schema', field->>'table', field->>'name');
				ELSEIF field->'from' IS NOT NULL THEN
					str_buffer2 := @extschema@.get_column_type(as_list->(field->>'from')->>'schema', as_list->(field->>'from')->>'table', field->>'name');
				ELSE
					str_buffer2 := @extschema@.get_column_type(objt->>'schema', objt->>'table', field->>'name');
				END IF;
			ELSEIF field->>'type' = 'function' THEN
				RAISE EXCEPTION 'Property "varType" is required with colum type "function"';
				--str_buffer2 := @extschema@.get_function_return_type(objt->>'schema', objt->>'name');;
			ELSEIF field->>'type' = 'variable' THEN
				RAISE EXCEPTION 'Property "varType" is required with colum type "variable"';
			END IF;

			RAISE NOTICE 'ICI % % % % %', field, objt->>'schema', objt->>'table', str_buffer, str_buffer2;
			SELECT jsonb_insert(retrn, ('{-1}')::TEXT[], ('["' || str_buffer || '","' || UPPER(str_buffer2) || '"]')::JSONB, TRUE) INTO retrn;
			RAISE NOTICE 'SUITE %', retrn;
		END IF;
	END LOOP;

	SELECT * FROM @extschema@.create_str_source(objt, arg) INTO arg, str_buffer;
	
	str_request := str_request || array_to_string(column_list, ',') || ' FROM ' || str_buffer;
	
	IF objt->'join' IS NOT NULL THEN
		FOR field IN (SELECT * FROM jsonb_array_elements(objt->'join')) LOOP
			str_join := LOWER(field->>'join');
			
			IF str_join = 'join' THEN
				str_request := str_request || ' JOIN ';
			ELSEIF str_join = 'right_join' THEN
				str_request := str_request || ' RIGHT JOIN ';
			ELSEIF str_join = 'full_join' THEN
				str_request := str_request || ' FULL JOIN ';
			ELSE --IF str_join = 'left_join' THEN
				str_request := str_request || ' LEFT JOIN ';
			END IF;
			
			SELECT * FROM @extschema@.create_str_source(field, arg) INTO arg, str_buffer;
			SELECT * FROM @extschema@.create_str_condition(field->'condition', field->>'as', arg) INTO arg, str_buffer2;
			
			str_request := str_request || ' ' || str_buffer || ' ON ' || '(' || str_buffer2 || ')';
		END LOOP;
	END IF;
	
	IF objt->'table' IS NOT NULL AND objt->'system' IS NOT NULL THEN	-- System settings are only available with table selection not with function selection
		IF objt->'condition' IS NULL THEN
			SELECT jsonb_set(objt, '{condition}', '{ "type" : "AND", "condition" : [] }') INTO objt;
		ELSEIF LOWER(objt->'condition'->>'type') <> 'and' THEN
			SELECT jsonb_set(objt, '{condition}', jsonb_insert('{ "type" : "AND", "condition" : [] }', '{condition,0}', objt->'condition', TRUE)) INTO objt;
		END IF;
		
		IF (objt->'system'->>'apply_mask')::BOOLEAN IS TRUE THEN
			SELECT jsonb_insert(objt, '{condition,condition,0}', @extschema@.create_mask_objt_condition(objt->>'schema', objt->>'table', objt->>'as'), TRUE) INTO objt;
		END IF;
		
		IF (objt->'system'->>'apply_delete')::BOOLEAN IS TRUE THEN
			SELECT jsonb_insert(objt, '{condition,condition,0}', @extschema@.create_delete_objt_condition(objt->>'schema', objt->>'table', objt->>'as'), TRUE) INTO objt;
		END IF;
		
		IF (objt->'system'->>'apply_history')::BOOLEAN IS TRUE THEN
			SELECT jsonb_insert(objt, '{condition,condition,0}', @extschema@.create_history_objt_condition(objt->>'schema', objt->>'table', objt->>'as'), TRUE) INTO objt;
		END IF;
		
		IF (objt->'system'->>'apply_right')::BOOLEAN IS TRUE THEN
			SELECT jsonb_insert(objt, '{condition,condition,0}', @extschema@.create_right_objt_condition(objt->>'schema', objt->>'table', objt->>'as'), TRUE) INTO objt;
		END IF;
	END IF;
	
	IF objt->'condition' IS NOT NULL /*AND (SELECT COUNT(TRUE) > 0 FROM jsonb_object_keys(objt->'condition'))*/ IS TRUE THEN
		SELECT * FROM @extschema@.create_str_condition(objt->'condition', objt->>'as', arg) INTO arg, str_buffer;
		
		IF LENGTH(str_buffer) > 0 THEN
			str_request := str_request || ' WHERE (' || str_buffer || ')';
		END IF;
	END IF;
	
	IF objt->>'orderBy' IS NOT NULL THEN
		str_request := str_request || ' ORDER BY "';
		
		IF objt->'orderBy'->'from' IS NOT NULL THEN
			str_request := str_request || (objt->'orderBy'->>'from') || '"."' || (objt->'orderBy'->>'name') || '"';
		ELSE
			str_request := str_request || (objt->>'as') || '"."' || (objt->>'orderBy') || '"';
		END IF;
		
		IF (objt->>'orderASC')::BOOLEAN IS TRUE THEN
			str_request := str_request || ' ASC';
		ELSE
			str_request := str_request || ' DESC';
		END IF;
	END IF;
	
	IF objt->>'limit' IS NOT NULL THEN
		str_request := str_request || ' LIMIT ' || (objt->>'limit');
	END IF;
	
	IF objt->>'offset' IS NOT NULL THEN
		str_request := str_request || ' OFFSET ' || (objt->>'offset');
	END IF;
	
	RAISE NOTICE 'Request: %', str_request;
	RAISE NOTICE 'Args: %', arg;
	RAISE NOTICE 'Return: %', retrn;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_mask_objt_condition(_schema TEXT, _table TEXT, _from TEXT)
  RETURNS JSONB AS
$$
DECLARE
	buffer TEXT := @extschema@.get_mask_schema_name(_schema);
BEGIN
	RETURN format('{
		"type" : "operator",
		"left" : {
			"type" : "selection",
			"schema" : "%I",
			"table" : "%I",
			"as" : "_mask_",
			"column" : [{
				"type" : "constant",
				"value" : true
			}],
			"condition" : {
				"type" : "and",
				"condition" : [{
					"type" : "operator",
					"left" : "target",
					"operator" : "=",
					"right" : {
						"type" : "column",
						"from" : "%I",
						"name" : "%I"
					}
				}, {
					"type" : "operator",
					"left" : "id_user",
					"operator" : "=",
					"right" : {
						"type" : "selection",
						"schema" : "test",
						"table" : "user",
						"as" : "_user_id_",
						"column" : [{
							"name" : "id"
						}],
						"condition" : {
							"type" : "operator",
							"left" : "name",
							"operator" : "=",
							"right" : {
								"type" : "variable",
								"name" : "user",
								"varType" : "VARCHAR"
							}
						}
					}
				}]
			}
		},
		"operator" : "not_exists"
	}', buffer, _table, _from, @extschema@.get_foreign_key_target(buffer, _table, 'target'))::JSONB;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_delete_objt_condition(_schema TEXT, _table TEXT, _from TEXT)
  RETURNS JSONB AS
$$
DECLARE
	buffer TEXT := @extschema@.get_delete_schema_name(_schema);
BEGIN
	RETURN format('{
		"type" : "operator",
		"left" : {
			"type" : "selection",
			"schema" : "%I",
			"table" : "%I",
			"as" : "_delete_",
			"column" : [{
				"type" : "constant",
				"value" : true
			}],
			"condition" : {
				"type" : "operator",
				"left" : "target",
				"operator" : "=",
				"right" : {
					"type" : "column",
					"from" : "%I",
					"name" : "%I"
				}
			}
		},
		"operator" : "not_exists"
	}', buffer, _table, _from, @extschema@.get_foreign_key_target(buffer, _table, 'target'))::JSONB;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_history_objt_condition(_schema TEXT, _table TEXT, _from TEXT)
  RETURNS JSONB AS
$$
DECLARE
	fkey TEXT;
BEGIN
	_schema := @extschema@.get_history_schema_name(_schema);
	fkey = @extschema@.get_foreign_key_target(_schema, _table, 'target');
	
	RETURN format('{
		"type" : "or",
		"condition" : [{
			"type" : "operator",
			"left" : {
				"type" : "selection",
				"schema" : "%I",
				"table" : "%I",
				"as" : "_history_",
				"column" : [{
					"type" : "constant",
					"value" : true
				}],
				"condition" : {
					"type" : "operator",
					"left" : "parent",
					"operator" : "=",
					"right" : {
						"name" : "%I",
						"from" : "%I"
					}
				}
			},
			"operator" : "not_exists"
		}, {
			"type" : "operator",
			"left" : "%I",
			"operator" : "=",
			"right" : {
				"type" : "selection",
				"schema" : "test",
				"name" : "get_history",
				"as" : "_get_history_",
				"arguments" : [{
					"type" : "constant",
					"value" : "%I"
				}, {
					"type" : "constant",
					"value" : "%I"
				}, {
					"type" : "column",
					"name" : "%I",
					"from" : "%I"
				}],
				"column" : [{
					"type" : "function",
					"name" : "MAX",
					"arguments" : [{
						"name" : "_get_history_",
						"from" : false
					}]
				}]
			}
		}]
	}', _schema, _table, fkey, _from, fkey, _schema, _table, fkey, _from)::JSONB;
END;
$$
LANGUAGE plpgsql;
				  

CREATE FUNCTION @extschema@.create_right_objt_condition(_schema TEXT, _table TEXT, _from TEXT)
  RETURNS JSONB AS
$$
BEGIN
	RETURN format('{
			"type" : "operator",
			"left" : {
				"type" : "selection",
				"schema" : "%I",
				"name" : "syst_get_user_right_from_%I",
				"as" : "_right_",
				"column" : ["read"],
				"arguments" : [{
					"type" : "variable",
					"name" : "user",
					"varType" : "VARCHAR"
				}, {
					"name" : "%I",
					"from" : "%I"
				}]
			},
			"operator" : "is_true"
		}',
		_schema, _table,
		@extschema@.get_foreign_key_target(@extschema@.get_right_schema_name(_schema), _table, 'target'),
		_from
	)::JSONB;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_condition(objt JSONB, table_from TEXT, INOUT arg JSONB, OUT str TEXT)
  AS
$$
DECLARE
	type			TEXT := '';
	operator 		TEXT := '';
	buffer			TEXT;
	process_right 	BOOLEAN := TRUE;
	cond_list		TEXT[] := '{}';
	field 			JSONB;
BEGIN
	RAISE NOTICE 'Starting new condition from %.', table_from;
	str := '';
	
	IF objt->'type' IS NULL THEN
		RAISE EXCEPTION 'Property "type" is required in condition: %', objt;
	ELSE
		type := LOWER(objt->>'type');
		
		IF type = 'and' THEN
			IF objt->'condition' IS NULL THEN
				RAISE EXCEPTION 'Property "condition" is required in condition using type "AND".';
			ELSEIF jsonb_array_length(objt->'condition') > 0 THEN
				FOR field IN (SELECT * FROM jsonb_array_elements(objt->'condition')) LOOP
					SELECT * FROM @extschema@.create_str_condition(field, table_from, arg) INTO arg, buffer;

					cond_list := array_append(cond_list, buffer);
				END LOOP;

				str := str || '(' || array_to_string(cond_list, ' AND ') || ')';
			END IF;
		ELSEIF type = 'or' THEN
			IF objt->'condition' IS NULL THEN
				RAISE EXCEPTION 'Property "condition" is required in condition using type "OR".';
			ELSEIF jsonb_array_length(objt->'condition') > 0 THEN
				FOR field IN (SELECT * FROM jsonb_array_elements(objt->'condition')) LOOP
					SELECT * FROM @extschema@.create_str_condition(field, table_from, arg) INTO arg, buffer;

					cond_list := array_append(cond_list, buffer);
				END LOOP;

				str := str || '(' || array_to_string(cond_list, ' OR ') || ')';
			END IF;
		ELSEIF type = 'operator' THEN
			IF (objt->>'negate')::BOOLEAN IS TRUE THEN
				str := 'NOT(';
			END IF;
			
			IF objt->'left' IS NULL THEN
				RAISE EXCEPTION 'Property "left" is required in condition.';
			ELSE
				SELECT * FROM @extschema@.create_str_member(objt->'left', table_from, FALSE, arg) INTO arg, buffer;
				
				str := str || buffer;
			END IF;

			IF objt->'operator' IS NULL THEN
				RAISE EXCEPTION 'Property "operator" is required in condition using type "operator".';
			ELSE
				operator := LOWER(objt->>'operator');
			END IF;

			IF operator = 'null' THEN
				str := str || ' IS NULL';
			ELSEIF operator = 'not_null' THEN
				str := str || ' IS NOT NULL';
			ELSEIF operator = 'is_true' THEN
				str := str || ' IS TRUE';
			ELSEIF operator = 'is_false' THEN
				str := str || ' IS FALSE';
			ELSEIF operator = '>' THEN
				str := str || ' > ';
			ELSEIF operator = '>=' THEN
				str := str || ' >= ';
			ELSEIF operator = '<' THEN
				str := str || ' < ';
			ELSEIF operator = '<=' THEN
				str := str || ' <= ';
			ELSEIF operator = '=' THEN
				str := str || ' = ';
			ELSEIF operator = '<>' OR operator = '!=' THEN
				str := str || ' <> ';
			ELSE
				process_right := FALSE;
				
				IF operator = 'exists' THEN
					str := 'EXISTS ' || str;
				ELSEIF operator = 'not_exists' THEN
					str := 'NOT EXISTS ' || str;
				ELSE
					RAISE EXCEPTION 'Operator "%" is not supported: %', operator, objt;
				END IF;
			END IF;
			
			IF process_right IS TRUE AND objt->'right' IS NOT NULL THEN
				SELECT * FROM @extschema@.create_str_member(objt->'right', table_from, FALSE, arg) INTO arg, buffer;

				str := str || buffer;
			END IF;
			
			IF (objt->>'negate')::BOOLEAN IS TRUE THEN
				str := str || ')';
			END IF;
		ELSE
			RAISE EXCEPTION 'Unsupported type "%" in condition: %', objt->type, objt;
		END IF;
	END IF;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_source(objt JSONB, INOUT arg JSONB, OUT str TEXT)
  AS
$$
DECLARE
	buffer	 TEXT;
	arg_list TEXT[] := '{}';
	field	 JSONB;
BEGIN
	IF objt->'as' IS NULL THEN
		RAISE EXCEPTION 'Property "as" is required in source. %', objt;
	END IF;
	
	IF objt->'schema' IS NOT NULL THEN
		str := '"' || (objt->>'schema') || '".';
	ELSE
		str := '';
	END IF;
	
	IF objt->'table' IS NOT NULL THEN
		IF objt->'schema' IS NULL THEN
			RAISE EXCEPTION 'Property "schema" is required in selectObject using "table" property.';
		END IF;
		
		str := str || '"' || (objt->>'table') || '"';
	ELSEIF objt->'name' IS NOT NULL THEN
		str := str || '"' || (objt->>'name') || '"(';
		
		IF objt->'arguments' IS NOT NULL THEN
			FOR field IN (SELECT * FROM jsonb_array_elements(objt->'arguments')) LOOP
				SELECT * FROM @extschema@.create_str_member(field, objt->>'as', FALSE, arg) INTO arg, buffer;
				
				arg_list := array_append(arg_list, buffer);
			END LOOP;
			
			str := str || array_to_string(arg_list, ',');
		END IF;
		
		str := str || ')';
	ELSE
		RAISE EXCEPTION 'Property "table" or "name" is required for source. %', objt;
	END IF;
	
	str := str || ' AS "' || (objt->>'as') || '"';
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_member(objt JSONB, table_from TEXT, enable_as BOOLEAN, INOUT arg JSONB, OUT str TEXT)
  AS
$$
DECLARE
	type 		TEXT := jsonb_typeof(objt);
	buffer		TEXT;
	arg_list	TEXT[] := '{}';
	field		JSONB;
	column_cast	JSONB;
BEGIN
	RAISE NOTICE 'Starting new member from %.', table_from;
	
	IF type = 'string' THEN
		str := '"' || table_from || '".' || objt;
	ELSEIF type = 'object' THEN
		str := '';	-- Init var is required

		IF objt->'type' IS NULL THEN
			type := 'column';	-- Default type is column
		ELSE
			type := LOWER(objt->>'type');
		END IF;

		IF objt->'from' IS NOT NULL THEN
			IF (jsonb_typeof(objt->'from') <> 'boolean') OR ((objt->>'from')::BOOLEAN IS NOT FALSE) THEN
				-- Check if objt->>'from' exists in table_as array ?
				table_from := objt->>'from';
			ELSE
				table_from := NULL;
			END IF;
		END IF;

		IF type = 'column' THEN
			IF objt->'name' IS NULL THEN
				RAISE EXCEPTION 'Property "name" is required in member using type "column". %', jsonb_typeof(objt);
			END IF;

			IF table_from IS NOT NULL THEN
				str := '"' || table_from || '".';
			END IF;

			str := str || '"' || (objt->>'name') || '"';
		ELSEIF type = 'constant' THEN
			IF objt->'value' IS NULL THEN
				RAISE EXCEPTION 'Property "value" is required in member using type "constant".';
			END IF;
			
			IF jsonb_typeof(objt->'value') = 'string' THEN
				str := '''' || (objt->>'value') || '''';	-- String has to be under single quote, double is for schema/table/column
			ELSE
				str := (objt->'value');
			END IF;
		ELSEIF type = 'variable' THEN
			IF objt->'name' IS NULL THEN
				RAISE EXCEPTION 'Property "name" is required in member using type "variable": %', objt;
			ELSEIF objt->'varType' IS NULL THEN
				RAISE EXCEPTION 'Property "varType" is required in member using type "variable": %', objt;
			END IF;

			SELECT jsonb_set(arg, ('{_' || (objt->>'name') || '}')::TEXT[], ('"' || UPPER(objt->>'varType') || '"')::JSONB, TRUE) INTO arg;
			
			str := CONCAT('_', (objt->>'name'));
		ELSEIF type = 'selection' THEN
			SELECT * FROM @extschema@.create_str_select(objt, FALSE, arg) INTO arg, buffer;

			str := '(' || buffer || ')';
		ELSEIF type = 'function' THEN
			IF objt->'name' IS NULL THEN
				RAISE EXCEPTION 'Property "name" is required in member using type "function".';
			END IF;

			IF objt->'schema' IS NOT NULL THEN
				str := '"' || (objt->>'schema') || '".';
			END IF;

			IF objt->'arguments' IS NOT NULL THEN
				FOR field IN (SELECT * FROM jsonb_array_elements(objt->'arguments')) LOOP
					SELECT * FROM @extschema@.create_str_member(field, table_from, FALSE, arg) INTO arg, buffer;

					arg_list = array_append(arg_list, buffer);
				END LOOP;
			END IF;

			IF objt->'schema' IS NOT NULL THEN
				str := str || '"' || (objt->>'name') || '"(';
			ELSE
				str := str || (objt->>'name') || '(';
			END IF;

			str := str || array_to_string(arg_list, ',') || ')';
		ELSEIF type = 'condition' THEN
			SELECT * FROM @extschema@.create_str_condition(objt, table_from, arg) INTO arg, buffer;

			str := buffer;
			enable_as := FALSE;
		ELSE
			RAISE EXCEPTION 'Unsupported member type "%"', objt->'type';
		END IF;

		IF objt->'cast' IS NOT NULL THEN
			FOR column_cast IN (SELECT * FROM jsonb_array_elements(objt->'cast')) LOOP
				str := str || '::' || UPPER(TRIM('"' FROM column_cast::TEXT));
			END LOOP;
		END IF;

		IF enable_as IS TRUE AND objt->'as' IS NOT NULL THEN
			str := str || ' AS "' || (objt->>'as') || '"';
		END IF;
	ELSE
		RAISE EXCEPTION 'Type % is not supported for member (only string or object).', type;
	END IF;
END;
$$
LANGUAGE plpgsql;
