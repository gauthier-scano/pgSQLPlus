DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test constraint =====';
	
	-- Test 1.1 --
		SELECT extension.create_primary_key('schema_1', 'table_1', '{column_1,column_2}') INTO source;
		result = 'ALTER TABLE "schema_1"."table_1" ADD CONSTRAINT "pk_schema_1_table_1_column_1_column_2" PRIMARY KEY ("column_1","column_2");';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.1: ERROR';
		END IF;
	-- FIN Test 1.1 --
	
	-- Test 1.2 --
		SELECT extension.create_primary_key('schema_1', 'table_1', '{column_1,column_2}', TRUE) INTO source;
		result = 'ALTER TABLE "schema_1"."table_1" ADD CONSTRAINT "pk_schema_1_table_1_column_1_column_2" PRIMARY KEY ("column_1","column_2") NOT VALID;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.2: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.2: ERROR';
		END IF;
	-- FIN Test 1.2 --
	
	-- Test 1.3 --
		SELECT extension.create_primary_key('schema_1', 'table_1', '{column_1,column_2}', TRUE, 'my_constraint_name') INTO source;
		result = 'ALTER TABLE "schema_1"."table_1" ADD CONSTRAINT "my_constraint_name" PRIMARY KEY ("column_1","column_2") NOT VALID;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.3: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.3: ERROR';
		END IF;
	-- FIN Test 1.3 --
	
	
	-- Test 1.4 --
		SELECT extension.create_foreign_key('schema_from', 'table_from', '{column_from_1,column_from_2}', 'schema_to', 'table_to', '{column_to_1,column_to_2}') INTO source;
		result = 'ALTER TABLE "schema_from"."table_from" ADD CONSTRAINT "fk_schema_from_table_from_column_from_1_column_from_2_schema_to_table_to_column_to_1_column_to_2" FOREIGN KEY ("column_from_1","column_from_2") REFERENCES "schema_to"."table_to"("column_to_1","column_to_2") ON DELETE RESTRICT ON UPDATE RESTRICT;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.4: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.4: ERROR';
		END IF;
	-- FIN Test 1.4 --
	
	-- Test 1.5 --
		SELECT extension.create_foreign_key('schema_from', 'table_from', '{column_from_1,column_from_2}', 'schema_to', 'table_to', '{column_to_1,column_to_2}', FALSE) INTO source;
		result = 'ALTER TABLE "schema_from"."table_from" ADD CONSTRAINT "fk_schema_from_table_from_column_from_1_column_from_2_schema_to_table_to_column_to_1_column_to_2" FOREIGN KEY ("column_from_1","column_from_2") REFERENCES "schema_to"."table_to"("column_to_1","column_to_2") ON DELETE RESTRICT ON UPDATE RESTRICT NOT VALID;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.5: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.5: ERROR';
		END IF;
	-- FIN Test 1.5 --
	
	-- Test 1.6 --
		SELECT extension.create_foreign_key('schema_from', 'table_from', '{column_from_1,column_from_2}', 'schema_to', 'table_to', '{column_to_1,column_to_2}', TRUE, TRUE) INTO source;
		result = 'ALTER TABLE "schema_from"."table_from" ADD CONSTRAINT "fk_schema_from_table_from_column_from_1_column_from_2_schema_to_table_to_column_to_1_column_to_2" FOREIGN KEY ("column_from_1","column_from_2") REFERENCES "schema_to"."table_to"("column_to_1","column_to_2") ON DELETE CASCADE ON UPDATE RESTRICT;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.6: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.6: ERROR';
		END IF;
	-- FIN Test 1.6 --
	
	-- Test 1.7 --
		SELECT extension.create_foreign_key('schema_from', 'table_from', '{column_from_1,column_from_2}', 'schema_to', 'table_to', '{column_to_1,column_to_2}', TRUE, TRUE, FALSE, 'my_constraint_name') INTO source;
		result = 'ALTER TABLE "schema_from"."table_from" ADD CONSTRAINT "my_constraint_name" FOREIGN KEY ("column_from_1","column_from_2") REFERENCES "schema_to"."table_to"("column_to_1","column_to_2") ON DELETE CASCADE ON UPDATE RESTRICT;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.7: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.7: ERROR';
		END IF;
	-- FIN Test 1.7 --
	
	-- Test 1.8 --
		SELECT extension.create_foreign_key('schema_from', 'table_from', '{column_from_1,column_from_2}', 'schema_to', 'table_to', '{column_to_1,column_to_2}', TRUE, TRUE, TRUE, 'my_constraint_name') INTO source;
		result = 'ALTER TABLE "schema_from"."table_from" ADD CONSTRAINT "my_constraint_name" FOREIGN KEY ("column_from_1","column_from_2") REFERENCES "schema_to"."table_to"("column_to_1","column_to_2") ON DELETE CASCADE ON UPDATE CASCADE;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.8: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.8: ERROR';
		END IF;
	-- FIN Test 1.8 --
	
	
	-- Test 1.9 --
		SELECT extension.create_unique('schema', 'table', '{column_1,column_2}') INTO source;
		result = 'ALTER TABLE "schema"."table" ADD CONSTRAINT "unique_schema_table_column_1_column_2" UNIQUE ("column_1","column_2");';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.9: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.9: ERROR';
		END IF;
	-- FIN Test 1.9 --
	
	-- Test 1.10 --
		SELECT extension.create_unique('schema', 'table', '{column_1,column_2}', TRUE) INTO source;
		result = 'ALTER TABLE "schema"."table" ADD CONSTRAINT "unique_schema_table_column_1_column_2" UNIQUE ("column_1","column_2") NOT VALID;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.10: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.10: ERROR';
		END IF;
	-- FIN Test 1.10 --
	
	-- Test 1.11 --
		SELECT extension.create_unique('schema', 'table', '{column_1,column_2}', FALSE, 'my_constraint_name') INTO source;
		result = 'ALTER TABLE "schema"."table" ADD CONSTRAINT "my_constraint_name" UNIQUE ("column_1","column_2");';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.11: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.11: ERROR';
		END IF;
	-- FIN Test 1.11 --
	
	RAISE NOTICE '===== Test for constraint ALL PASSED =====';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
