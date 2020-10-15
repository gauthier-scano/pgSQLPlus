DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test for tablespace =====';
	
	-- Test 1.1 --
		SELECT extension.create_tablespace('name', '/path/to/tablespace') INTO source;
		result = 'CREATE TABLESPACE "name" LOCATION ''/path/to/tablespace'';';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.1: ERROR';
		END IF;
	-- FIN Test 1.1 --
	
	-- Test 1.2 --
		SELECT extension.set_tablespace_owner('name', 'owner') INTO source;
		result = 'ALTER TABLESPACE "name" OWNER TO "owner";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.2: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.2: ERROR';
		END IF;
	-- FIN Test 1.2 --
	
	-- Test 1.3 --
		SELECT extension.set_tablespace_option('name', 'key', 'value') INTO source;
		result = 'ALTER TABLESPACE "name" SET (key = value);';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.3: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.3: ERROR';
		END IF;
	-- FIN Test 1.3 --
	
	------------------
	
	-- Test 2.1 --
	/*	PERFORM extension.create_tablespace('name', '/data/dbs');
		
		IF (SELECT extension.collation_exists('schema_1', 'french')) IS TRUE THEN
			RAISE NOTICE 'Test 2.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 2.1: ERROR';
		END IF;*/
	-- FIN Test 2.1 --
	
	RAISE NOTICE '===== Test for tablespace ALL PASSED =====';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
