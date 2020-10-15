DO LANGUAGE plpgsql $$
DECLARE
	request JSONB := ('[{
		"objt" : {
			"schema" : [{
				"name" : "my_schema",
				"table" : [{
					"schema" : "activity",
					"table" : "product",
					"column" : [{
						"name" : "id",
						"type" : "bigserial",
						"notNull" : true,
						"default" : null
					}],
					"variable" : [{
						"schema" : {
							"table" : {
								"column" : [{
									"name" : "column",
									"type" : "int",
									"notNull" : true,
									"default" : null
								}]
							}
						}
					}],
					"constraint" : [{
						"type" : "unique",
						"target" : ["column_1"]
					}, {
						"type" : "primary",
						"target" : ["column_1"]
					}, {
						"type" : "foreign",
						"from" : ["column_1"],
						
						"schema" : "schema_test",
						"table" : "table_1",
						"column" : ["column_1"]
					}],
					"system" : {
						
					}
				}]
			}]
		},
		"result" : "' || REPLACE('INSERT INTO "my_schema"."my_table" AS "my_name" ("key") VALUES (_my_schema_my_table_key)', '"', '\"') || '"
	}]');
	
	field		JSONB;
	arg			JSONB 	:= '{}';
	var			JSONB	:= '{}';
	str_request TEXT 	:= '';
	i			INTEGER := 1;
BEGIN
	RAISE NOTICE '===== Starting test: insertObject =====';
	
	FOR field IN (SELECT * FROM jsonb_array_elements(request)) LOOP
		IF field->'objt' IS NULL OR field->'result' IS NULL THEN
			RAISE EXCEPTION 'Missing property "objt" or "result" in object: %', field;
		END IF;
		
		SELECT * FROM test.create_database_from_object(field->'objt');
		
		IF str_request = (REPLACE(field->>'result', '\"', '"') || ';') THEN
			RAISE NOTICE 'Test %: OK', i;
			i := i + 1;
		ELSE
			RAISE NOTICE 'Test %: %', i, str_request;
			RAISE NOTICE 'Test %: %', i, (REPLACE(field->>'result', '\"', '"') || ';');
			RAISE EXCEPTION 'Test %: ERROR', i;
		END IF;
	END LOOP;
	
	RAISE NOTICE '========= ALL PASSED =========';
END $$;
