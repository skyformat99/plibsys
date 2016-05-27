/*
 * Copyright (C) 2013-2016 Alexander Saprykin <xelfium@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 */

#include "pmem.h"
#include "ptimeprofiler.h"

#include <mach/mach_time.h>

struct PTimeProfiler_ {
	puint64		counter;
	double		mach_timebase;
};

static puint64 pp_time_profiler_current_ticks (const PTimeProfiler *profiler);

static puint64
pp_time_profiler_current_ticks (const PTimeProfiler *profiler)
{
	return (puint64) (mach_absolute_time () * profiler->mach_timebase);
}

P_LIB_API PTimeProfiler *
p_time_profiler_new ()
{
	PTimeProfiler			*ret;
	mach_timebase_info_data_t	tb;

	if (P_UNLIKELY ((ret = p_malloc0 (sizeof (PTimeProfiler))) == NULL))
		return NULL;

	if (P_UNLIKELY (mach_timebase_info (&tb) != KERN_SUCCESS || tb.denom == 0)) {
		P_ERROR ("PTimeProfiler: Failed to get clock frequency using mach_timebase_info()");
		ret->mach_timebase = 0.0;
	} else
		ret->mach_timebase = (double) tb.numer / (double) tb.denom / 1000.0;

	ret->counter = pp_time_profiler_current_ticks (ret);

	return ret;
}

P_LIB_API void
p_time_profiler_reset (PTimeProfiler *profiler)
{
	if (P_UNLIKELY (profiler == NULL))
		return;

	profiler->counter = pp_time_profiler_current_ticks (profiler);
}

P_LIB_API puint64
p_time_profiler_elapsed_usecs (const PTimeProfiler *profiler)
{
	if (P_UNLIKELY (profiler == NULL))
		return 0;

	return pp_time_profiler_current_ticks (profiler) - profiler->counter;
}

P_LIB_API void
p_time_profiler_free (PTimeProfiler *profiler)
{
	if (P_UNLIKELY (profiler == NULL))
		return;

	p_free (profiler);
}
