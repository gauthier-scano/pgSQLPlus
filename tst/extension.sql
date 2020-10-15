DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test for extension =====';
	
	-- Test 1.1 --
		SELECT extension.create_extension('extension') INTO source;
		result = 'CREATE EXTENSION IF NOT EXISTS "extension";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.1: ERROR';
		END IF;
	-- FIN Test 1.1 --
	
	-- Test 1.2 --
		SELECT extension.create_extension('extension', 'schema_1') INTO source;
		result = 'CREATE EXTENSION IF NOT EXISTS "extension" SCHEMA "schema_1";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.2: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.2: ERROR';
		END IF;
	-- FIN Test 1.2 --
	
	-- Test 1.3 --
		SELECT extension.create_extension('extension', NULL, '1.1') INTO source;
		result = 'CREATE EXTENSION IF NOT EXISTS "extension" VERSION "1.1";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.3: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.3: ERROR';
		END IF;
	-- FIN Test 1.3 --
	
	-- Test 1.4 --
	/*	SELECT extension.create_extension('extension', NULL, NULL, '1.1') INTO source;
		result = 'CREATE EXTENSION IF NOT EXISTS "extension" FROM "1.1";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.4: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.4: ERROR';
		END IF;*/
	-- FIN Test 1.4 --
	
	-- Test 1.5 --
		SELECT extension.create_extension('extension', NULL, NULL, TRUE) INTO source;
		result = 'CREATE EXTENSION IF NOT EXISTS "extension" CASCADE;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.5: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.5: ERROR';
		END IF;
	-- FIN Test 1.5 --
	
	-- Test 1.6 --
		SELECT extension.create_extension('extension', 'schema_1', '1.1', TRUE) INTO source;
		result = 'CREATE EXTENSION IF NOT EXISTS "extension" SCHEMA "schema_1" VERSION "1.1" CASCADE;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.6: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.6: ERROR';
		END IF;
	-- FIN Test 1.6 --
	
	-- Test 1.7 --
		SELECT extension.drop_extension('extension') INTO source;
		result = 'DROP EXTENSION IF EXISTS "extension";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.7: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.7: ERROR';
		END IF;
	-- FIN Test 1.7 --
	
	-- Test 1.8 --
		SELECT extension.drop_extension('extension', TRUE) INTO source;
		result = 'DROP EXTENSION IF EXISTS "extension" CASCADE;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.8: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.8: ERROR';
		END IF;
	-- FIN Test 1.8 --
	
	-- Test 1.9 --
		SELECT extension.drop_extension('extension', FALSE, TRUE) INTO source;
		result = 'DROP EXTENSION IF EXISTS "extension" RESTRICT;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.9: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.9: ERROR';
		END IF;
	-- FIN Test 1.9 --
	
	-- Test 1.10 --
		SELECT extension.drop_extension('extension', TRUE, TRUE) INTO source;
		result = 'DROP EXTENSION IF EXISTS "extension" CASCADE RESTRICT;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.10: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.10: ERROR';
		END IF;
	-- FIN Test 1.10 --
	
	-- Test 1.11 --
		SELECT extension.set_extension_schema('extension', 'schema_1') INTO source;
		result = 'ALTER EXTENSION "extension" SET SCHEMA "schema_1";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.11: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.11: ERROR';
		END IF;
	-- FIN Test 1.11 --
	
	-- Test 1.12 --
		SELECT extension.update_extension_to('extension', '1.1') INTO source;
		result = 'ALTER EXTENSION "extension" UPDATE TO "1.1";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.12: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.12: ERROR';
		END IF;
	-- FIN Test 1.12 --
	
	------------------
	
	RAISE NOTICE '===== Test for extension ALL PASSED =====';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
