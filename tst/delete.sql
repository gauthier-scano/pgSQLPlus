DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test: delete =====';
	
	-- Test 1 --
		--SELECT extension.create_schema('schema_1');
		--SELECT extension.create_table('schema_1', 'table_1');
		
		SELECT extension.create_delete_table('schema_1', 'table_1', 'column_1') INTO source;
		result := 'CREATE SCHEMA "__delete_schema_1__";CREATE TABLE "__delete_schema_1__"."table_1"();ALTER TABLE "__delete_schema_1__"."table_1" ADD COLUMN "target" INTEGER;ALTER TABLE "__delete_schema_1__"."table_1" ALTER COLUMN "target" SET DATA TYPE INTEGER;ALTER TABLE "__delete_schema_1__"."table_1" ALTER COLUMN "target" SET NOT NULL;ALTER TABLE "__delete_schema_1__"."table_1" ALTER COLUMN "target" DROP DEFAULT;ALTER TABLE "__delete_schema_1__"."table_1" ADD CONSTRAINT pkey___delete_schema_1___table_1_target PRIMARY KEY ("target");ALTER TABLE "__delete_schema_1__"."table_1" ADD CONSTRAINT fk___delete_schema_1___table_1_target_schema_1_table_1_column_1 FOREIGN KEY ("target") REFERENCES "schema_1"."table_1"("column_1") ON DELETE CASCADE ON UPDATE CASCADE VALID;CREATE FUNCTION "schema_1"."syst_insert_delete_from_table_1"(_user TEXT, _value INTEGER[])
		RETURNS VOID AS 
		$T2$
		BEGIN
			INSERT INTO "__delete_schema_1__"."table_1" ("target") VALUES (unnest(_value));
		END;
		$T2$
		LANGUAGE plpgsql;CREATE FUNCTION "schema_1"."syst_delete_delete_from_table_1"(_user TEXT, _value INTEGER[])
		RETURNS VOID AS 
		$T2$
			DELETE FROM "__delete_schema_1__"."table_1" WHERE "target" = ANY(_value);
		$T2$
		LANGUAGE sql;';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1: ERROR';
		END IF;
	-- FIN Test 1 --
	
	RAISE NOTICE '========= ALL PASSED =========';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
