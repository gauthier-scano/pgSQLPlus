DO LANGUAGE plpgsql $$
DECLARE
	request JSONB := ('[{
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : [{
				"type" : "variable",
				"target" : "key",
				"varType" : "bigint"
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
		
		SELECT * FROM extension.create_str_insert(field->'objt') INTO arg, var, str_request;
		
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

/*SELECT test.create_insert_object('my_insert_object', '{
	"schema" : "activity",
	"table" : "discount",
	"as" : "act",
	"column" : ["id", {
		"target" : "key",
		"cast" 	: ["text", "VARCHAR"]
	}, "type", "value", "expire", "unique", "condition", "state", {
		"target" : "id_currency",
		
		"type" : "selection",
		"schema" : "system",
		"table" : "currency",
		"as" : "currency",
		"column" : ["id"],
		"condition" : {
			"type" : "operator",
			"operator" : "=",
			"left" : "code",
			"right" : {
				"type" : "variable",
				"varType" : "TEXT",
				"name" : "currency"
			}
		}
	}, {
		"target" : "titi",
		
		"variable" : true,
		"schema" : "test",
		"table" : "locale",
		"column" : "id"
	}],
	"join" : [{
		"schema" : "activity",
		"table" : "discount_target",
		"as" : "act_tar",
		"column" : [
			"id_product",
			{
				"target" : "id_discount",
				"from" : "act",
				"column" : "id"
			}
		],
		"join" : [{
			"schema" : "activity",
			"table" : "discount_target",
			"as" : "table_other",
			"column" : [{
				"target" : "id_product",
				
				"type" : "constant",
				"value": 5
			}, {
				"target" : "id_discount",
				"from" : "act",
				"column" : "id"
			}],
			"where" : {}
		}]
	}],
	
	"returning" : [{
		"from" : "act",
		"column" : "id",
		"as" : "my_first_column"
	}, {
		"from" : "act",
		"column" : "key",
		"as" : "my_second_column"
	}]
}'::JSONB
);
