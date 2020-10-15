DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test for collation =====';
	
	-- Test 1.1 --
		SELECT extension.create_collation('schema_1', 'french', 'fr-FR.utf8') INTO source;
		result = 'CREATE COLLATION "schema_1"."french" (LOCALE = ''fr-FR.utf8'');';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.1: ERROR';
		END IF;
	-- FIN Test 1.1 --
	
	-- Test 1.2 --
		SELECT extension.create_collation('schema_1', 'french', NULL, 'fr-FR', 'utf8') INTO source;
		result = 'CREATE COLLATION "schema_1"."french" (LC_COLLATE = ''fr-FR'', LC_CTYPE = ''utf8'');';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.2: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.2: ERROR';
		END IF;
	-- FIN Test 1.2 --
	
	-- Test 1.3 --
		SELECT extension.create_collation('schema_1', 'french', 'fr-FR.utf8', NULL, NULL, 'icu') INTO source;
		result = 'CREATE COLLATION "schema_1"."french" (LOCALE = ''fr-FR.utf8'', PROVIDER = icu);';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.3: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.3: ERROR';
		END IF;
	-- FIN Test 1.3 --
	
	RAISE NOTICE '===== Test for collation ALL PASSED =====';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
