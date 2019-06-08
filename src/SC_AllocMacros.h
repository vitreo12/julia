/*
    JuliaCollider: Julia's JIT compilation for low-level audio synthesis and prototyping in SuperCollider.
    Copyright (C) 2019 Francesco Cameli. All rights reserved.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

//For gc.c and gc-pages.c
#define malloc(s) SC_RTMalloc(sc_julia_alloc_pool, s)
#define calloc(n, s) SC_RTCalloc(sc_julia_alloc_pool, n, s)
#define realloc(p, s) SC_RTRealloc(sc_julia_alloc_pool, p, s)
#define free(p) SC_RTFree(sc_julia_alloc_pool, p)
#define free_standard(p) free_standard(p)

//For arraylist.c
#define LLT_ALLOC(s) SC_RTMalloc(sc_julia_alloc_pool, s)
#define LLT_REALLOC(p, s) SC_RTRealloc(sc_julia_alloc_pool, p, s)
#define LLT_FREE(p) SC_RTFree(sc_julia_alloc_pool, p)