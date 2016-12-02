--
-- Clears the PG Unit functions
--
--
drop function test_run_suite(TEXT);
drop function test_run_all();
drop function test_run_condition(proc_name text);
drop function test_build_procname(parts text[], p_from integer, p_to integer);
drop function test_get_procname(test_case_name text, expected_name_count integer, result_prefix text);
drop function test_terminate(db VARCHAR);
drop function test_autonomous(p_statement VARCHAR);
drop function test_dblink_connect(text, text);
drop function test_dblink_disconnect(text);
drop function test_dblink_exec(text, text);
drop function test_detect_dblink_schema();
drop function test_assertTrue(message VARCHAR, condition BOOLEAN);
drop function test_assertTrue(condition BOOLEAN);
drop function test_assertNotNull(VARCHAR, ANYELEMENT);
drop function test_assertNull(VARCHAR, ANYELEMENT);
drop function test_fail(VARCHAR);
drop type test_results cascade;
