CREATE FUNCTION @extschema@.create_str_insert_function(objt JSONB, _schema TEXT DEFAULT NULL, _name TEXT DEFAULT NULL)
 RETURNS TEXT AS
$$
DECLARE
	str 	 	TEXT := 'CREATE FUNCTION ';
	query 	 	TEXT;
	
	arg		 	JSONB;
	arg_arr		TEXT[] := '{}';
	var			JSONB;
	variable	TEXT := '';
	retrn	 	JSONB;
	retrn_arr 	TEXT[] := '{}';
	
	_key		TEXT;
	_value	 	TEXT;
	field	 	JSONB;
BEGIN
	IF _schema IS NULL THEN
		_schema := '@extschema@';
	ELSE
		_schema := _schema;
	END IF;
	
	IF _name IS NULL THEN
		_name := _objt_name;
	END IF;
	
	str := str || '"' || _schema || '"."' || _name || '"(';
	
	SELECT * FROM @extschema@.create_str_insert(objt) INTO arg, var, query, retrn;
	
	RAISE NOTICE 'Arg: %', arg;
	RAISE NOTICE 'Var: %', var;
	RAISE NOTICE 'Return: %', retrn;
	
	FOR _key, _value IN (SELECT * FROM jsonb_each_text(arg)) LOOP
		IF var->_key IS NULL THEN
			arg_arr := array_append(arg_arr, _key || ' ' || _value);
		END IF;
	END LOOP;
	
	FOR _key, _value IN (SELECT * FROM jsonb_each_text(var)) LOOP
		variable := variable || _key || ' ' || _value || '; ';
	END LOOP;
	
	FOR field IN (SELECT * FROM jsonb_array_elements(retrn)) LOOP
		retrn_arr := array_append(retrn_arr, '"' || (field->>0) || '" ' || (field->>1));
	END LOOP;
	
	str := str || array_to_string(arg_arr, ', ') || ') RETURNS TABLE(' || array_to_string(retrn_arr, ', ') || ') AS $T1$ DECLARE ' || variable || ' BEGIN ' || query || ' END; $T1$ LANGUAGE plpgsql;';
	
	RAISE NOTICE 'Function: %', str;
	
	RETURN str;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.create_str_insert(objt JSONB, as_list JSONB DEFAULT NULL, INOUT arg JSONB DEFAULT '{}', INOUT var JSONB DEFAULT '{}', OUT str_request TEXT, OUT retrn JSONB)
 AS
$$
DECLARE
	str_buffer		TEXT;
	str_buffer2		TEXT;
	str_buffer3		TEXT;
	column_list 	TEXT[] := '{}';
	column_arg 		TEXT[] := '{}';
	column_var		JSONB  := '{}';
	column_index	BIGINT := 0;
	retrning_list_l	TEXT[] := '{}';
	retrning_list_r	TEXT[] := '{}';
	last_ret_list	TEXT[] := '{}';
	insert_return	JSONB;
	field 			JSONB;
	field2 			JSONB;
	_key			TEXT;
	_key2			TEXT;
	_key3			TEXT;
	_value			JSONB;
	items			RECORD;
BEGIN
	IF objt->'as' IS NULL THEN
		RAISE EXCEPTION 'Property "as" is required in selectObject.';
	ELSEIF objt->'column' IS NULL THEN
		RAISE EXCEPTION 'Property "column" is required in selectObject.';
	END IF;
	
	IF as_list IS NULL THEN
		as_list := (SELECT @extschema@.extract_table_as(objt));
	END IF;
	
	IF objt->'condition' IS NOT NULL THEN
		str_request := 'UPDATE ';
	ELSE
		str_request := 'INSERT INTO ';
	END IF;
	
	str_request := str_request || '"' || (objt->>'schema') || '"."' || (objt->>'table') || '" AS "' || (objt->>'as') || '" ';
	retrn := '[]'::JSONB;
	
	FOR field IN (SELECT * FROM jsonb_array_elements(objt->'column')) LOOP
		IF jsonb_typeof(field) = 'string' THEN
			field := format('{"target" : %s, "type" : "variable"}', field);
		ELSEIF field->>'type' = 'column' THEN
			RAISE EXCEPTION 'Column type "column" is not allowed.';
		ELSEIF field->>'target' IS NULL THEN
			RAISE EXCEPTION 'Property "target" is required in insert column: %', field;
		ELSEIF field->>'type' IS NULL /*OR field->>'type' = 'column'*/ THEN
			SELECT jsonb_set(field, '{type}', '"variable"') INTO field;
		END IF;
		
		IF field->'name' IS NOT NULL THEN
			IF field->'from' IS NOT NULL THEN
				SELECT jsonb_set(field, '{name}', ('"ret_val_' || (field->>'name') || '"')::JSONB) INTO field;
			END IF;
		ELSE
			IF field->'from' IS NOT NULL THEN
				str_buffer2 := 'ret_val_' || (as_list->(field->>'from')->>'schema') || '_' || (as_list->(field->>'from')->>'table') || '_' || (field->>'column');
			ELSE
				str_buffer2 := (objt->>'schema') || '_' || (objt->>'table') || '_' ||  (field->>'target');
			END IF;

			SELECT jsonb_set(field, '{name}', ('"' || str_buffer2 || '"')::JSONB) INTO field;
		END IF;
		
		IF field->'varType' IS NULL THEN
			str_buffer2 := '_' || str_buffer2;

			IF field->'cast' IS NOT NULL THEN
				str_buffer3 := field->'cast'->>-1;
			ELSEIF field->'from' IS NOT NULL THEN
				str_buffer3 := @extschema@.get_column_type(
					(as_list->(field->>'from')->>'schema'),
					(as_list->(field->>'from')->>'table'),
					field->>'column'
				);
			ELSEIF (field->>'variable')::BOOLEAN IS TRUE THEN
				str_buffer3 := @extschema@.get_column_type(
					@extschema@.get_variable_schema_name(objt->>'schema', field->>'schema'),
					@extschema@.get_variable_table_name(objt->>'table', field->>'table', field->>'column'),
					field->>'target'
				);
			ELSE
				str_buffer3 := @extschema@.get_column_type(objt->>'schema', objt->>'table', field->>'target');
			END IF;

			SELECT jsonb_set(field, '{varType}', ('"' || str_buffer3 || '"')::JSONB) INTO field;
		END IF;
		
		IF (field->'variable' IS NULL OR (field->>'variable')::BOOLEAN IS FALSE) THEN
			IF field->'from' IS NOT NULL THEN
				SELECT jsonb_set(var, ('{"' || str_buffer2 || '"}')::TEXT[], ('"' || (field->>'varType') || '"')::JSONB) INTO var;
			END IF;
			
			SELECT * FROM @extschema@.create_str_member(field, NULL, FALSE, arg) INTO arg, str_buffer;

			column_list := array_append(column_list, '"' || (field->>'target') || '"');
			column_arg := array_append(column_arg, str_buffer);
		ELSE
			IF column_var->(field->>'schema') IS NULL THEN
				SELECT jsonb_set(column_var, ('{' || (field->>'schema') || '}')::TEXT[], '{}', TRUE) INTO column_var;
			END IF;
			
			IF column_var->(field->>'schema')->(field->>'table') IS NULL THEN
				SELECT jsonb_set(column_var, ('{' || (field->>'schema') || ',' || (field->>'table') || '}')::TEXT[], '{}', TRUE) INTO column_var;
			END IF;
			
			IF column_var->(field->>'schema')->(field->>'table')->(field->>'column') IS NULL THEN
				SELECT jsonb_set(column_var, ('{' || (field->>'schema') || ',' || (field->>'table') || ',' || (field->>'column') || '}')::TEXT[], '[]', TRUE) INTO column_var;
			END IF;
			
			SELECT jsonb_insert(column_var,	('{' || (field->>'schema') || ',' || (field->>'table') || ',' || (field->>'column') || ',-1}')::TEXT[], field->'target') INTO column_var;
		END IF;
		
		SELECT jsonb_set(objt, ('{"column",' || column_index || '}')::TEXT[], field) INTO objt;
		column_index := column_index + 1;
	END LOOP;
	
	FOR _key, field IN (SELECT * FROM jsonb_each(column_var)) LOOP
		IF objt->'join' IS NULL THEN
			SELECT jsonb_set(objt, '{join}', '[]') INTO objt;
		END IF;

		FOR _key2, field2 IN (SELECT * FROM jsonb_each(field)) LOOP
			FOR _key3, _value IN (SELECT * FROM jsonb_each(field2)) LOOP
				str_buffer := @extschema@.get_variable_schema_name(objt->>'schema', _key);
				str_buffer2 := @extschema@.get_variable_table_name(objt->>'table', _key2, _key3);
				
				SELECT jsonb_insert(objt, '{join, -1}', format('{
					"schema" : "%I",
					"table" : "%I",
					"as" : "%I",
					"column" : %s
				}',
				str_buffer, str_buffer2, (objt->>'schema') || '_' || _key || '_' || _key2 || '_' || _key3,
				_value || format('[{
						"target" : "__target__",
						"from" : "%I",
						"column" : "%I"
					}, {
						"target" : "__variable__"
					}]', 
					objt->>'as', @extschema@.get_foreign_key_target(str_buffer, str_buffer2, '__target__'))::JSONB
				)::JSONB
				, TRUE) INTO objt;
			END LOOP;
		END LOOP;
	END LOOP;
	
	SELECT @extschema@.extract_column_req(objt, TRUE) INTO insert_return;
	
	RAISE NOTICE 'Join: %', objt->'join';
	RAISE NOTICE 'As list: %', as_list;
	RAISE NOTICE 'Returning: %', insert_return;
	RAISE NOTICE 'Column list: %', column_list;
	RAISE NOTICE 'Column arg: %', column_arg;
	
	IF objt->'condition' IS NOT NULL THEN
		str_request := str_request || ' SET ';	-- SET only when UPDATE not INSERT
	END IF;
	
	IF objt->'condition' IS NULL OR COUNT(column_list) >= 2 THEN
		str_request := str_request || '(' || array_to_string(column_list, ',') || ')';
	ELSE
		str_request := str_request || column_list[1];
	END IF;
	
	IF objt->'condition' IS NOT NULL THEN
		str_request := str_request || ' = ';
	ELSE
		str_request := str_request || ' VALUES ';
	END IF;
	
	IF objt->'condition' IS NULL OR COUNT(column_arg) >= 2 THEN
		str_request := str_request || '(' || array_to_string(column_arg, ',') || ')';
	ELSE
		str_request := str_request || column_arg[1];
	END IF;
	
	IF objt->'condition' IS NOT NULL THEN
		SELECT * FROM @extschema@.create_str_condition(objt->'condition', objt->>'as', arg) INTO arg, str_buffer;
		
		str_request := str_request || ' WHERE (' || str_buffer || ')';
	END IF;
	
	IF insert_return->(objt->>'as') IS NOT NULL THEN
		str_request := str_request || ' RETURNING ';
		
		FOR str_buffer IN (SELECT * FROM jsonb_array_elements_text(insert_return->(objt->>'as'))) LOOP
			retrning_list_l := array_append(retrning_list_l, '"' || str_buffer || '"');
			retrning_list_r := array_append(retrning_list_r, '_ret_val_' || (objt->>'schema') || '_' || (objt->>'table') || '_' || str_buffer);
			
			SELECT jsonb_set(var, ('{_ret_val_' || ((objt->>'schema') || '_' || (objt->>'table') || '_' || str_buffer) || '}')::TEXT[], ('"' || @extschema@.get_column_type(objt->>'schema', objt->>'table', str_buffer) || '"')::JSONB, TRUE) INTO var;
		END LOOP;
		
		str_request := str_request || array_to_string(retrning_list_l, ', ') || ' INTO ' || array_to_string(retrning_list_r, ', ');
	END IF;
	
	str_request := str_request || ';';
	
	IF objt->'join' IS NOT NULL THEN
		FOR field IN (SELECT * FROM jsonb_array_elements(objt->'join')) LOOP
			SELECT * FROM @extschema@.create_str_insert(field, as_list, arg, var) INTO arg, var, str_buffer;
			
			str_request := str_request || ' ' || str_buffer;
		END LOOP;
	END IF;
	
	-- Ajouter IF _first THEN pour ne pas pouvoir faire de returning dans un join
	IF objt->'returning' IS NOT NULL AND jsonb_array_length(objt->'returning') > 0 THEN
		FOR field IN (SELECT * FROM jsonb_array_elements(objt->'returning')) LOOP
			IF field->'as' IS NOT NULL THEN
				str_buffer := field->>'as';
			ELSE
				str_buffer := field->>'column';
			END IF;
			
			last_ret_list := array_append(last_ret_list, '_ret_val_' || (as_list->(field->>'from')->>'schema') || '_' || (as_list->(field->>'from')->>'table') || '_' || (field->>'column'));
			SELECT jsonb_insert(retrn, '{-1}', ('["' || str_buffer || '","'|| @extschema@.get_column_type(as_list->(field->>'from')->>'schema', as_list->(field->>'from')->>'table', field->>'column') || '"]')::JSONB, true) INTO retrn;
		END LOOP;
		
		str_request := str_request || ' RETURN QUERY SELECT ' || array_to_string(last_ret_list, ', ') || ';';
	END IF;
	
	-- If "system" property exists, check if "history", "mask", "delete", "right" exists with user bigint id or boolean
	-- If history => insert history id with value given as parent id
	-- If mask => nothing, only on select requests
	-- If delete => nothing, only on select request
	-- If rights => check if user can insert data before process selection
	
	RAISE NOTICE 'Request: %', str_request;
	RAISE NOTICE 'Arguments: %', arg;
	RAISE NOTICE 'Return type: %', retrn;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.extract_table_as(objt JSONB)
 RETURNS JSONB AS
$$
DECLARE
	reslt JSONB := '{}';
	field JSONB;
BEGIN
	IF objt->'as' IS NOT NULL THEN
		SELECT jsonb_set(reslt, ('{' || (objt->>'as') || '}')::TEXT[], ('{ "schema" : "' || (objt->>'schema') || '", "table" : "' || (objt->>'table') || '"}')::JSONB) INTO reslt;
	END IF;
	
	IF objt->'join' IS NOT NULL THEN
		FOR field IN (SELECT * FROM jsonb_array_elements(objt->'join')) LOOP
			SELECT reslt || @extschema@.extract_table_as(field) INTO reslt;
		END LOOP;
	END IF;
	
	RETURN reslt;
END;
$$
LANGUAGE plpgsql;


CREATE FUNCTION @extschema@.extract_column_req(objt JSONB, _first BOOLEAN)
 RETURNS JSONB AS
$$
DECLARE
	reslt JSONB := '{}';
	field JSONB;
BEGIN
	-- Searching for all other join which need a column from the current objt
	-- Columns found have to be added using the "RETURNING" keyword
	-- Variable _first defines if actual objt column has to be checked (TRUE) or not (FALSE) (needed for the main table that can't need own inserted value)
	
	IF _first IS FALSE THEN
		FOR field IN (SELECT * FROM jsonb_array_elements(objt->'column')) LOOP
			IF field->>'from' IS NOT NULL THEN
				IF reslt->(field->>'from') IS NULL THEN
					SELECT jsonb_insert(reslt, ('{' || (field->>'from') || '}')::TEXT[], ('[]')::JSONB) INTO reslt;
				END IF;
				
				SELECT jsonb_insert(reslt, ('{' || (field->>'from') || ',-1}')::TEXT[], ('"' || (field->>'column') || '"')::JSONB) INTO reslt;
			END IF;
		END LOOP;
	ELSEIF objt->'returning' IS NOT NULL AND jsonb_array_length(objt->'returning') > 0 THEN
		FOR field IN (SELECT * FROM jsonb_array_elements(objt->'returning')) LOOP
			IF field->'from' IS NULL THEN
				RAISE EXCEPTION 'Property "from" is required in returning column: %', field;
			ELSEIF field->'column' IS NULL THEN
				RAISE EXCEPTION 'Property "column" is required in returning column: %', field;
			END IF;

			IF reslt->(field->>'from') IS NULL THEN
				SELECT jsonb_insert(reslt, ('{' || (field->>'from') || '}')::TEXT[], ('[]')::JSONB) INTO reslt;
			END IF;

			SELECT jsonb_insert(reslt, ('{' || (field->>'from') || ',-1}')::TEXT[], ('"' || (field->>'column') || '"')::JSONB) INTO reslt;
		END LOOP;
	END IF;
	
	IF objt->'join' IS NOT NULL THEN
		FOR field IN (SELECT * FROM jsonb_array_elements(objt->'join')) LOOP
			SELECT (@extschema@.extract_column_req(field, FALSE) || reslt) INTO reslt;
		END LOOP;
	END IF;
	
	RETURN reslt;
END;
$$
LANGUAGE plpgsql;
