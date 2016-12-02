# PGUnit - unit test framework for Postgresql

This suite of stored procedures purpose is to allow an user to run unit tests as stored procedures.

The testing is based on specific naming convention that allows automatic grouping of tests, setup, tear-downs, pre and post conditions.

Each unit test procedure name should have "test_case_" prefix in order to be identified as an unit test. Here is the comprehensive list of prefixes for all types:
- "test_case_": identifies an unit test procedure
- "test_precondition_": identifies a test precondition function
- "test_postcondition_": identifies a test postcondition  function
- "test_setup_": identifies a test setup procedure
- "test_teardown_": identifies a test tear down procedure.

For each test case the following 3 transactions are executed:
1. setup transaction: the setup procedure is searched based on the test name. If one is found it is executed in an autonomous transaction
2. unit test transaction: the pre and post condition functions are searched based on the test name; if they are found the autonomous transaction will be: if the precondition is true (default if one is not found) the unit test is ran, then the postcondition function is evaluated (true if one is not found). If any condition returns false the test is failed
3. tear down transaction: if a tear down procedure is found it is executed in an autonomous transaction indepedent of the unit test result.

An unit test execution can have 3 results: successful if the condition functions are true and the unit test procedure doesn't throw an exception, failed if there is an action exception triggered by a condition function or an assertion, and finally erronous if any other exeception is triggered by any of the code above.

## Tests logical grouping

The tests can be grouped based on their name structure. The underscore character is used to delimit the test name into an hierarhical structure and as such be able to share the setup, tear down, or the precondtions across several unit tests. For instance the tests 'test_case_finance_audit_x' and 'test_case_finance_accounting_y' can share the setup procedure called 'test_setup_finance', the teardown procedure 'test_teardown_finance' as well as the precondition 'test_precondition_finance' function as they share a common prefix.

If, lets say, the audit tests have a specific precondition function one can define a new 'test_precondition_finance_audit' function and that will be shared accross all unit test procedures with prefix 'test_case_finance_audit_' and override the common 'test_precondition_finance' one.

Using the built in grouping mechanism one can re-use the supporting code accross unit tests such as the data setup and tear down. There is little if any gain if the save data setup is shared across multiple tests and they will have to be present in test-specific setup function while having the exact same content.

## Running one or more tests

To run the entire test suite the 'test_run_all' stored procedure needs to be used:
```sql
select * from test_run_all();
```
One can pick one or an entire group of tests based on their prefix using 'test_run_suite' stored procedure:
```sql
select * from test_run_suite('finance');
```

The statement above will pick up all unit tests starting with 'test_case_finance' prefix together with the associated support functions and procedures.

The select statement returns the type 'test_results' which is:
```sql
create type test_results as (
  test_name varchar, 
  successful boolean, 
  failed boolean, 
  errorneous boolean, 
  error_message varchar,
  duration interval);
```

## Setting up PGUnit
The plpgsql code dependens on the dblink extension being present in the server so you may want to issue the statement below before loading the test code:
```sql
CREATE EXTENSION DBLINK;
```

One should run `PGUnit.sql` code using either `psql` command line tool or any other tool and have it deployed in the pubic schema of the selected database.

## Removal
The `PGUnitDrop.sql` has the code one can use to remove all `PGUnit` code from the database.

## Assertion procedures
| Procedure | Description |
| --- | --- |
|`test_assertTrue(message VARCHAR, condition BOOLEAN) returns void`|If condition is false it throws an exception with the given message|
| `test_assertTrue(condition BOOLEAN) returns void` |Similar to `assertTrue` above but with no user message|
|`test_assertNotNull(message VARCHAR, data ANYELEMENT) returns void`|If the data is null an exception is thrown with the message provided|
|`test_assertNull(message VARCHAR, data ANYELEMENT) returns void`|If the data is not null an exception is thrown with the message provided|
|`test_fail(message VARCHAR) returns void`|If reached, the test fails witht the message provided|

## Examples

Test case that checks if the an application user is created by a stored procedure
- the user id is returned if user id 1 is a parent
- the id is larger than a thresold
```sql
create or replace function test_case_user_create_1() returns void as $$
declare
  id BIGINT;
begin
  SELECT customer.createUser(1, 100) INTO id;
  perform test_assertNotNull('user not created', id);
  perform test_assertTrue('user id range improper', id >= 10000);
end;
$$ language plpgsql;
```
A precondition function for this test may be one checking for user id 1 being present into the database
```sql
create or replace function test_precondition_user() returns boolean as $$
declare
   id BIGINT;
begin
  SELECT user_id INTO id FROM customer.user WHERE user_id=1;
  RETURN id IS NOT NULL AND (id = 1);
end;
$$ language plpgsql;
```
The precondition above will be shared on all 'user' tests unless one with a more specific name is created.

## Troubleshooting

### Lock issues
Although the unit tests are run in autonoumous transactions it is possible to run into lock issues and have the select statements above hanging. In this case have a new connection on the same database and issue the statement below to stop all locking sessions:
select * from test_terminate('my_db_name');

In order to find out which test is at issue you should run the suite one test at the time. The procedure above it is not specific to PGUnit and can be used in general as well; it will terminate all locking sessions.

### Install the code in public schema and switching to a different schema

You can add 'public' schema in the search path using the statement below:
```sql
SELECT set_config(
    'search_path',
    current_setting('search_path') || ',public',
    false
) WHERE current_setting('search_path') !~ '(^|,)public(,|$)';
```

### Installing the code in dedicated schema

The framework can be installed in a dedicated schema, event not present in the search_path, for example `pgunit`. In that case all calls to pgunit functions should be qualified with its installation schema name:
```sql
create or replace function test_case_user_create_1() returns void as $$
declare
  id BIGINT;
begin
  SELECT customer.createUser(1, 100) INTO id;
  perform pgunit.test_assertNotNull('user not created', id);
  perform pgunit.test_assertTrue('user id range improper', id >= 10000);
end;
$$ language plpgsql;
```

---

# Copyright and License

Copyright (c) 2016 Adrian Andrei. Some rights reserved.

Permission to use, copy, modify, and distribute this software and its documentation for any purpose, without fee, and without a written agreement is hereby granted, provided that the above copyright notice and this paragraph and the following two paragraphs appear in all copies.

IN NO EVENT SHALL ADRIAN ANDREI BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF ADRIAN ANDREI HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

ADRIAN ANDREI SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND ADRIAN ANDREI HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
