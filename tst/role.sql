DO LANGUAGE plpgsql $$
DECLARE
	error  TEXT;
	source TEXT;
	result TEXT;
BEGIN
	RAISE NOTICE '===== Starting test for role =====';
	
	-- Test 1.1 --
		SELECT extension.create_role('root') INTO source;
		result := 'CREATE ROLE "root";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.1: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.1: ERROR';
		END IF;
	-- FIN Test 1.1 --
	
	-- Test 1.2 --
		SELECT extension.create_role('root', '{"role_1", "role_2"}') INTO source;
		result := 'CREATE ROLE "root" IN ROLE "role_1", "role_2";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.2: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.2: ERROR';
		END IF;
	-- FIN Test 1.2 --
	
	-- Test 1.3 --
		SELECT extension.create_role('root', NULL, '{"group_1", "group_2"}') INTO source;
		result := 'CREATE ROLE "root" ROLE "group_1", "group_2";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.3: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.3: ERROR';
		END IF;
	-- FIN Test 1.3 --
	
	-- Test 1.4 --
		SELECT extension.create_role('root', NULL, NULL, '{"admin_1", "admin_2"}') INTO source;
		result := 'CREATE ROLE "root" ADMIN "admin_1", "admin_2";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.4: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.4: ERROR';
		END IF;
	-- FIN Test 1.4 --
	
	-- Test 1.5 --
		SELECT extension.create_role('root', '{"group_1", "group_2"}', '{"role_1", "role_2"}', '{"admin_1", "admin_2"}') INTO source;
		result := 'CREATE ROLE "root" IN ROLE "group_1", "group_2" ROLE "role_1", "role_2" ADMIN "admin_1", "admin_2";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.5: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.5: ERROR';
		END IF;
	-- FIN Test 1.5 --
	
	-- Test 1.6 --
		SELECT extension.drop_role('root') INTO source;
		result := 'DROP ROLE "root";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.6: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.6: ERROR';
		END IF;
	-- FIN Test 1.6 --
	
	-- Test 1.7 --
		SELECT extension.drop_role('root', TRUE) INTO source;
		result := 'DROP ROLE IF EXISTS "root";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.7: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.7: ERROR';
		END IF;
	-- FIN Test 1.7 --
	
	-- Test 1.8 --
		SELECT extension.drop_role('{"root", "role"}'::TEXT[], TRUE) INTO source;
		result := 'DROP ROLE IF EXISTS "root", "role";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.8: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.8: ERROR';
		END IF;
	-- FIN Test 1.8 --
	
	-- Test 1.9 --
		SELECT extension.add_role_to_group('role_group', '{"root", "role"}'::TEXT[]) INTO source;
		result := 'ALTER GROUP "role_group" ADD USER "root", "role";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.9: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.9: ERROR';
		END IF;
	-- FIN Test 1.9 --
	
	-- Test 1.10 --
		SELECT extension.delete_role_from_group('role_group', '{"root", "role"}'::TEXT[]) INTO source;
		result := 'ALTER GROUP "role_group" DROP USER "root", "role";';
		
		IF source = result THEN
			RAISE NOTICE 'Test 1.10: OK';
		ELSE
			RAISE EXCEPTION USING MESSAGE = 'Test 1.10: ERROR';
		END IF;
	-- FIN Test 1.10 --
	
	------------------
	
	-- Test 2.1 --
		PERFORM extension.create_role('role_1');
		PERFORM extension.create_role('role_2');
		PERFORM extension.create_role('group_1');
		
		PERFORM extension.create_role('role_3', '{"group_1"}', '{"role_1"}', '{"role_2"}');
		
		PERFORM extension.drop_role('role_1', TRUE);
		PERFORM extension.drop_role('role_2', TRUE);
		PERFORM extension.drop_role('group_1', TRUE);
		PERFORM extension.drop_role('role_3', TRUE);
		
		RAISE NOTICE 'Test 2.1: OK';
	-- FIN Test 2.1 --
	
	
	RAISE NOTICE '===== Test for role ALL PASSED =====';
EXCEPTION WHEN others THEN
	GET STACKED DIAGNOSTICS error = MESSAGE_TEXT;
	
	RAISE NOTICE '%', error;
	RAISE NOTICE 'Source: %', source;
	RAISE NOTICE 'Result: %', result;
END $$;
