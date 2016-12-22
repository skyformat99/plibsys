/*
 * Copyright (C) 2016 Alexander Saprykin <xelfium@gmail.com>
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

#include "perror.h"
#include "pfile.h"
#include "plibraryloader.h"
#include "pmem.h"

#include <be/kernel/image.h>

typedef image_id plibrary_handle;

struct PLibraryLoader_ {
	plibrary_handle	handle;
};

static void pp_library_loader_clean_handle (plibrary_handle handle);

static void
pp_library_loader_clean_handle (plibrary_handle handle)
{
	if (P_UNLIKELY (unload_add_on (handle) != B_OK))
		P_ERROR ("PLibraryLoader::pp_library_loader_clean_handle: unload_add_on() failed");
}

P_LIB_API PLibraryLoader *
p_library_loader_new (const pchar *path)
{
	PLibraryLoader	*loader = NULL;
	plibrary_handle	handle;

	if (!p_file_is_exists (path))
		return NULL;

	if (P_UNLIKELY ((handle = load_add_on (path)) == B_ERROR)) {
		P_ERROR ("PLibraryLoader::p_library_loader_new: load_add_on() failed");
		return NULL;
	}

	if (P_UNLIKELY ((loader = p_malloc0 (sizeof (PLibraryLoader))) == NULL)) {
		P_ERROR ("PLibraryLoader::p_library_loader_new: failed to allocate memory");
		pp_library_loader_clean_handle (handle);
		return NULL;
	}

	loader->handle = handle;

	return loader;
}

P_LIB_API PFuncAddr
p_library_loader_get_symbol (PLibraryLoader *loader, const pchar *sym)
{
	ppointer location = NULL;

	if (P_UNLIKELY (loader == NULL || sym == NULL))
		return NULL;

	if (P_UNLIKELY (get_image_symbol (loader->handle,
					  (pchar *) sym,
					  B_SYMBOL_TYPE_ANY,
					  &location) != B_OK)) {
		P_ERROR ("PLibraryLoader::p_library_loader_get_symbol: get_image_symbol() failed");
		return NULL;
	}

	return (PFuncAddr) location;
}

P_LIB_API void
p_library_loader_free (PLibraryLoader *loader)
{
	if (P_UNLIKELY (loader == NULL))
		return;

	pp_library_loader_clean_handle (loader->handle);

	p_free (loader);
}

P_LIB_API pchar *
p_library_loader_get_last_error (void)
{
	return NULL;
}
