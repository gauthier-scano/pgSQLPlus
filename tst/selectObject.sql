DO LANGUAGE plpgsql $$
DECLARE
	request JSONB := ('[{
		"objt" : ' ||  '{
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id"]
		},
		"result" : "' || REPLACE('SELECT "my_name"."id" FROM "my_schema"."my_table" AS "my_name"', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : [{
				"type" : "column",
				"name" : "id"
			}]
		},
		"result" : "' || REPLACE('SELECT "my_name"."id" FROM "my_schema"."my_table" AS "my_name"', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : [{
				"type" : "column",
				"name" : "id",
				"as" : "id_test"
			}]
		},
		"result" : "' || REPLACE('SELECT "my_name"."id" AS "id_test" FROM "my_schema"."my_table" AS "my_name"', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : [{
				"type" : "column",
				"name" : "id",
				"as" : "id_test",
				"cast" : ["varchar", "TEXT"]
			}]
		},
		"result" : "' || REPLACE('SELECT "my_name"."id"::VARCHAR::TEXT AS "id_test" FROM "my_schema"."my_table" AS "my_name"', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"]
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name"', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"limit" : 1
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" LIMIT 1', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"limit" : 1,
			"offset" : 5
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" LIMIT 1 OFFSET 5', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"limit" : 1,
			"offset" : 5,
			"orderBy" : "id"
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" ORDER BY "my_name"."id" DESC LIMIT 1 OFFSET 5', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"limit" : 1,
			"offset" : 5,
			"orderBy" : {
				"from" : "test",
				"name" : "id"
			}
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" ORDER BY "test"."id" DESC LIMIT 1 OFFSET 5', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"limit" : 1,
			"offset" : 5,
			"orderBy" : "id",
			"orderASC" : true
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" ORDER BY "my_name"."id" ASC LIMIT 1 OFFSET 5', '"', '\"') || '"
	},
	
	{
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", {
				"type" : "column",
				"name" : "name"
			}, {
				"type" : "selection",
				"schema" : "my_schema",
				"table" : "my_table2",
				"as" : "sub",
				"column" : ["reference"],
				"condition" : {
					"type" : "operator",
					"left" : "id",
					"operator" : "=",
					"right" : {
						"type" : "column",
						"from" : "my_name",
						"name" : "id"
					}
				},
				"cast" : ["boolean"]
			}]
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name",(SELECT "sub"."reference" FROM "my_schema"."my_table2" AS "sub" WHERE ("sub"."id" = "my_name"."id"))::BOOLEAN AS "sub" FROM "my_schema"."my_table" AS "my_name"', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"condition" : {
				"type" : "operator",
				"left" : "id",
				"operator" : "=",
				"right" : {
					"type" : "constant",
					"value" : true
				}
			}
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" WHERE ("my_name"."id" = true)', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"condition" : {
				"type" : "operator",
				"left" : {
					"type" : "column",
					"from" : "my_name",
					"name" : "id"
				},
				"operator" : "=",
				"right" : {
					"type" : "constant",
					"value" : true,
					"cast" : ["VARCHAR", "TEXT"]
				}
			}
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" WHERE ("my_name"."id" = true::VARCHAR::TEXT)', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"condition" : {
				"type" : "and",
				"condition" : [{
					"type" : "operator",
					"left" : "id",
					"operator" : "=",
					"right" : {
						"type" : "constant",
						"value" : 1
					}
				}, {
					"type" : "operator",
					"left" : "id",
					"operator" : "not_null"
				}]
			}
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" WHERE (("my_name"."id" = 1 AND "my_name"."id" IS NOT NULL))', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"condition" : {
				"type" : "or",
				"condition" : [{
					"type" : "operator",
					"left" : "id",
					"operator" : "is_true",
					"negate" : true
				}, {
					"type" : "operator",
					"left" : "id",
					"operator" : "null"
				}]
			}
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" WHERE ((NOT("my_name"."id" IS TRUE) OR "my_name"."id" IS NULL))', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["id", "name", "key"],
			"condition" : {
				"type" : "or",
				"condition" : [{
					"type" : "operator",
					"left" : "id",
					"operator" : "is_true",
					"negate" : true
				}, {
					"type" : "and",
					"condition" : [{
						"type" : "operator",
						"left" : "id",
						"operator" : "null"
					}, {
						"type" : "operator",
						"left" : "name",
						"operator" : "=",
						"right" : {
							"type" : "constant",
							"value" : "test"
						}
					}]
				}]
			}
		},
		"result" : "' || REPLACE('SELECT "my_name"."id","my_name"."name","my_name"."key" FROM "my_schema"."my_table" AS "my_name" WHERE ((NOT("my_name"."id" IS TRUE) OR ("my_name"."id" IS NULL AND "my_name"."name" = ''test'')))', '"', '\"') || '"
	}, {
		"objt" : {
			"schema" : "my_schema",
			"table" : "my_table",
			"as" : "my_name",
			"column" : ["name"],
			"condition" : {
				"type" : "or",
				"condition" : [{
					"type" : "operator",
					"left" : "id",
					"operator" : "null",
					"negate" : true
				}, {
					"type" : "operator",
					"left" : {
						"type" : "selection",
						"schema" : "my_schema2",
						"table" : "my_table2",
						"as" : "sub_request",
						"column" : [{
							"type" : "constant",
							"value" : true
						}],
						"condition" : {
							"type" : "operator",
							"left" : {
								"type" : "column",
								"from" : "sub_request",
								"name" : "id"
							},
							"operator" : "=",
							"right" : {
								"from" : "my_name",
								"name" : "id"
							}
						}
					},
					"operator" : "is_true"
				}]
			}
		},
		"result" : "' || REPLACE('SELECT "my_name"."name" FROM "my_schema"."my_table" AS "my_name" WHERE ((NOT("my_name"."id" IS NULL) OR (SELECT true FROM "my_schema2"."my_table2" AS "sub_request" WHERE ("sub_request"."id" = "my_name"."id")) IS TRUE))', '"', '\"') || '"
	}]')::JSONB;
	
	field		JSONB;
	arg			JSONB 	:= '{}';
	str_request TEXT 	:= '';
	i			INTEGER := 1;
BEGIN
	RAISE NOTICE '===== Starting test: selectObject =====';
	
	FOR field IN (SELECT * FROM jsonb_array_elements(request)) LOOP
		IF field->'objt' IS NULL OR field->'result' IS NULL THEN
			RAISE EXCEPTION 'Missing property "objt" or "result" in object: %', field;
		END IF;
		
		SELECT * FROM extension.create_str_select(field->'objt') INTO arg, str_request;
		
		IF str_request = REPLACE(field->>'result', '\"', '"') THEN
			RAISE NOTICE 'Test %: OK', i;
			i := i + 1;
		ELSE
			RAISE NOTICE 'Test %: %', i, str_request;
			RAISE NOTICE 'Test %: %', i, REPLACE(field->>'result', '\"', '"');
			RAISE EXCEPTION 'Test %: ERROR', i;
		END IF;
	END LOOP;
	
	RAISE NOTICE '========= ALL PASSED =========';
END $$;
