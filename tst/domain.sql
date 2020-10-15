DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test for domain =====';
	
	-- Test 1.1 --
		SELECT extension.create_domain('schema_1', 'domain_1', 'BigInt') INTO source;
		result = 'CREATE DOMAIN "schema_1"."domain_1" AS BigInt;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.1: ERROR';
		END IF;
	-- FIN Test 1.1 --
	
	-- Test 1.2 --
		SELECT extension.set_domain_default('schema_1', 'domain_1', '10') INTO source;
		result = 'ALTER DOMAIN "schema_1"."domain_1" SET DEFAULT 10;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.2: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.2: ERROR';
		END IF;
	-- FIN Test 1.2 --
	
	-- Test 1.3 --
		SELECT extension.drop_domain_default('schema_1', 'domain_1') INTO source;
		result = 'ALTER DOMAIN "schema_1"."domain_1" DROP DEFAULT;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.3: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.3: ERROR';
		END IF;
	-- FIN Test 1.3 --
	
	-- Test 1.4 --
		SELECT extension.set_domain_not_null('schema_1', 'domain_1', TRUE) INTO source;
		result = 'ALTER DOMAIN "schema_1"."domain_1" SET NOT NULL;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.4: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.4: ERROR';
		END IF;
	-- FIN Test 1.4 --
	
	-- Test 1.5 --
		SELECT extension.set_domain_not_null('schema_1', 'domain_1', FALSE) INTO source;
		result = 'ALTER DOMAIN "schema_1"."domain_1" DROP NOT NULL;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.5: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.5: ERROR';
		END IF;
	-- FIN Test 1.5 --
	
	-- Test 1.6 --
		SELECT extension.rename_domain('schema_1', 'domain_1', 'domain_2') INTO source;
		result = 'ALTER DOMAIN "schema_1"."domain_1" RENAME TO "domain_2";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.6: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.6: ERROR';
		END IF;
	-- FIN Test 1.6 --
	
	-- Test 1.7 --
		SELECT extension.set_domain_owner('schema_1', 'domain_1', 'user') INTO source;
		result = 'ALTER DOMAIN "schema_1"."domain_1" OWNER TO "user";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.7: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.7: ERROR';
		END IF;
	-- FIN Test 1.7 --
	
	-- Test 1.8 --
		SELECT extension.set_domain_schema('schema_1', 'domain_1', 'schema_2') INTO source;
		result = 'ALTER DOMAIN "schema_1"."domain_1" SET SCHEMA "schema_2";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.8: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.8: ERROR';
		END IF;
	-- FIN Test 1.8 --
	
	-- Test 1.9 --
		SELECT extension.drop_domain('schema_1', 'domain_1') INTO source;
		result = 'DROP DOMAIN "schema_1"."domain_1" RESTRICT;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.9: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.9: ERROR';
		END IF;
	-- FIN Test 1.9 --
	
	-- Test 1.10 --
		SELECT extension.drop_domain('schema_1', 'domain_1', TRUE) INTO source;
		result = 'DROP DOMAIN "schema_1"."domain_1" CASCADE;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.10: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.10: ERROR';
		END IF;
	-- FIN Test 1.10 --
	
	------------------
	
	RAISE NOTICE '===== Test for column ALL PASSED =====';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
