DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test for schema =====';
	
	-- Test 1.1 --
		SELECT extension.create_schema('schema_1') INTO source;
		result := 'CREATE SCHEMA "schema_1";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.1: ERROR';
		END IF;
	-- FIN Test 1.1 --
	
	-- Test 1.2 --
		SELECT extension.rename_schema('schema_1', 'schema_2') INTO source;
		result := 'ALTER SCHEMA "schema_1" RENAME TO "schema_2";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.2: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.2: ERROR';
		END IF;
	-- FIN Test 1.2 --
	
	-- Test 1.3 --
		SELECT extension.set_schema_owner('schema_1', 'owner') INTO source;
		result := 'ALTER SCHEMA "schema_1" OWNER TO "owner";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.3: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.3: ERROR';
		END IF;
	-- FIN Test 1.3 --
	
	-- Test 1.4 --
		SELECT extension.set_schema_owner('schema_1', NULL, TRUE) INTO source;
		result := 'ALTER SCHEMA "schema_1" OWNER TO CURRENT_USER;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.4: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.4: ERROR';
		END IF;
	-- FIN Test 1.4 --
	
	-- Test 1.5 --
		SELECT extension.set_schema_owner('schema_1', NULL, FALSE) INTO source;
		result := 'ALTER SCHEMA "schema_1" OWNER TO SESSION_USER;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.5: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.5: ERROR';
		END IF;
	-- FIN Test 1.5 --
	
	-- Test 1.6 --
		SELECT extension.create_schema('schema_1', TRUE) INTO source;
		result := 'CREATE SCHEMA IF NOT EXISTS "schema_1";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.6: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.6: ERROR';
		END IF;
	-- FIN Test 1.6 --
	
	------------------
	
	RAISE NOTICE '===== Test for schema ALL PASSED =====';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
