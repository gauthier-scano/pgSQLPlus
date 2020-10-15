DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test for column =====';
	
	-- Test 1.1 --
		SELECT extension.create_column('schema_1', 'table_1', 'column_1', 'BigInt') INTO source;
		result = 'ALTER TABLE "schema_1"."table_1" ADD COLUMN "column_1" BigInt;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.1: ERROR';
		END IF;
	-- FIN Test 1.1 --
	
	-- Test 1.2 --
		SELECT extension.rename_column('schema_1', 'table_1', 'column_1', 'column_2') INTO source;
		result = 'ALTER TABLE "schema_1"."table_1" RENAME COLUMN "column_1" TO "column_2";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.2: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.2: ERROR';
		END IF;
	-- FIN Test 1.2 --
	
	RAISE NOTICE '===== Test for column ALL PASSED =====';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
