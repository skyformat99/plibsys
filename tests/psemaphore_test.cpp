/*
 * Copyright (C) 2013-2017 Alexander Saprykin <xelfium@gmail.com>
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library; if not, see <http://www.gnu.org/licenses/>.
 */

#include "plibsys.h"
#include "ptestmacros.h"

P_TEST_MODULE_INIT ();

#define PSEMAPHORE_MAX_VAL 10

static pint semaphore_test_val = 0;
static pint is_thread_exit     = 0;

static void clean_error (PError **error)
{
	if (error == NULL || *error == NULL)
		return;

	p_error_free (*error);
	*error = NULL;
}

static void * semaphore_test_thread (void *)
{
	PSemaphore	*sem;
	pint		i;

	sem = p_semaphore_new ("p_semaphore_test_object", 1, P_SEM_ACCESS_OPEN, NULL);

	if (sem == NULL)
		p_uthread_exit (1);

	for (i = 0; i < 1000; ++i) {
		if (!p_semaphore_acquire (sem, NULL)) {
			if (is_thread_exit > 0) {
				semaphore_test_val = PSEMAPHORE_MAX_VAL;
				break;
			}

			p_uthread_exit (1);
		}

		if (semaphore_test_val == PSEMAPHORE_MAX_VAL)
			--semaphore_test_val;
		else {
			p_uthread_sleep (1);
			++semaphore_test_val;
		}

		if (!p_semaphore_release (sem, NULL)) {
			if (is_thread_exit > 0) {
				semaphore_test_val = PSEMAPHORE_MAX_VAL;
				break;
			}

			p_uthread_exit (1);
		}
	}

	++is_thread_exit;

	p_semaphore_free (sem);
	p_uthread_exit (0);

	return NULL;
}

extern "C" ppointer pmem_alloc (psize nbytes)
{
	P_UNUSED (nbytes);
	return (ppointer) NULL;
}

extern "C" ppointer pmem_realloc (ppointer block, psize nbytes)
{
	P_UNUSED (block);
	P_UNUSED (nbytes);
	return (ppointer) NULL;
}

extern "C" void pmem_free (ppointer block)
{
	P_UNUSED (block);
}

P_TEST_CASE_BEGIN (psemaphore_nomem_test)
{
	p_libsys_init ();

	PMemVTable vtable;

	vtable.free    = pmem_free;
	vtable.malloc  = pmem_alloc;
	vtable.realloc = pmem_realloc;

	P_TEST_CHECK (p_mem_set_vtable (&vtable) == TRUE);

	P_TEST_CHECK (p_semaphore_new ("p_semaphore_test_object", 1, P_SEM_ACCESS_CREATE, NULL) == NULL);

	p_mem_restore_vtable ();

	p_libsys_shutdown ();
}
P_TEST_CASE_END ()

P_TEST_CASE_BEGIN (psemaphore_general_test)
{
	PSemaphore	*sem = NULL;
	PError		*error = NULL;
	pint		i;

	p_libsys_init ();

	P_TEST_CHECK (p_semaphore_new (NULL, 0, P_SEM_ACCESS_CREATE, &error) == NULL);
	P_TEST_CHECK (error != NULL);
	clean_error (&error);

	P_TEST_REQUIRE (p_semaphore_acquire (sem, &error) == FALSE);
	P_TEST_CHECK (error != NULL);
	clean_error (&error);

	P_TEST_REQUIRE (p_semaphore_release (sem, &error) == FALSE);
	P_TEST_CHECK (error != NULL);
	clean_error (&error);

	p_semaphore_take_ownership (sem);
	p_semaphore_free (NULL);

	sem = p_semaphore_new ("p_semaphore_test_object", 10, P_SEM_ACCESS_CREATE, NULL);
	P_TEST_REQUIRE (sem != NULL);
	p_semaphore_take_ownership (sem);
	p_semaphore_free (sem);

	sem = p_semaphore_new ("p_semaphore_test_object", 10, P_SEM_ACCESS_CREATE, NULL);
	P_TEST_REQUIRE (sem != NULL);

	for (i = 0; i < 10; ++i)
		P_TEST_CHECK (p_semaphore_acquire (sem, NULL));

	for (i = 0; i < 10; ++i)
		P_TEST_CHECK (p_semaphore_release (sem, NULL));

	for (i = 0; i < 1000; ++i) {
		P_TEST_CHECK (p_semaphore_acquire (sem, NULL));
		P_TEST_CHECK (p_semaphore_release (sem, NULL));
	}

	p_semaphore_free (sem);

	p_libsys_shutdown ();
}
P_TEST_CASE_END ()

P_TEST_CASE_BEGIN (psemaphore_thread_test)
{
	PUThread	*thr1, *thr2;
	PSemaphore	*sem = NULL;

	p_libsys_init ();

	sem = p_semaphore_new ("p_semaphore_test_object", 10, P_SEM_ACCESS_CREATE, NULL);
	P_TEST_REQUIRE (sem != NULL);
	p_semaphore_take_ownership (sem);
	p_semaphore_free (sem);

	sem                = NULL;
	is_thread_exit     = 0;
	semaphore_test_val = PSEMAPHORE_MAX_VAL;

	thr1 = p_uthread_create ((PUThreadFunc) semaphore_test_thread, NULL, true);
	P_TEST_REQUIRE (thr1 != NULL);

	thr2 = p_uthread_create ((PUThreadFunc) semaphore_test_thread, NULL, true);
	P_TEST_REQUIRE (thr2 != NULL);

	P_TEST_CHECK (p_uthread_join (thr1) == 0);
	P_TEST_CHECK (p_uthread_join (thr2) == 0);

	P_TEST_REQUIRE (semaphore_test_val == PSEMAPHORE_MAX_VAL);

	P_TEST_REQUIRE (p_semaphore_acquire (sem, NULL) == FALSE);
	P_TEST_REQUIRE (p_semaphore_release (sem, NULL) == FALSE);
	p_semaphore_free (sem);
	p_semaphore_take_ownership (sem);

	sem = p_semaphore_new ("p_semaphore_test_object", 1, P_SEM_ACCESS_OPEN, NULL);
	P_TEST_REQUIRE (sem != NULL);
	p_semaphore_take_ownership (sem);
	p_semaphore_free (sem);

	p_uthread_unref (thr1);
	p_uthread_unref (thr2);

	p_libsys_shutdown ();
}
P_TEST_CASE_END ()

P_TEST_SUITE_BEGIN()
{
	P_TEST_SUITE_RUN_CASE (psemaphore_nomem_test);
	P_TEST_SUITE_RUN_CASE (psemaphore_general_test);
	P_TEST_SUITE_RUN_CASE (psemaphore_thread_test);
}
P_TEST_SUITE_END()
