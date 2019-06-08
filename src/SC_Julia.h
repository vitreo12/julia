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

#ifndef SC_JULIA_INCLUDE_H
#define SC_JULIA_INCLUDE_H

#include <stdlib.h>
#include <errno.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <math.h>

#if !defined(__cplusplus)
# include <stdbool.h>
#endif // __cplusplus

#define SIZE_ALIGN (4*sizeof(size_t))

#ifdef __cplusplus
extern "C" {
#endif

typedef struct World World;

typedef struct JuliaAllocPool JuliaAllocPool;

typedef struct JuliaAllocFuncs
{
	void* (*fRTAlloc)(JuliaAllocPool* inPool, size_t inSize);
	void* (*fRTRealloc)(JuliaAllocPool* inPool, void *inPtr, size_t inSize);
	void  (*fRTFree)(JuliaAllocPool* inPool, void *inPtr);
	size_t(*fRTTotalFreeMemory)(JuliaAllocPool* inPool);
} JuliaAllocFuncs;

/* GLOBAL VARIABLES */
extern World* SCWorld;
extern JuliaAllocPool* sc_julia_alloc_pool;
extern JuliaAllocFuncs* sc_julia_alloc_funcs;
extern int scsynthRunning;

/* RT ALLOCATOR INFORMATIONS */
extern void* RT_memory_start;
extern size_t RT_memory_size;
extern uintptr_t RT_memory_start_uintptr;
extern uintptr_t RT_memory_size_uintptr;

/* FUNCTIONS */
#define RTAlloc (*sc_julia_alloc_funcs->fRTAlloc)
#define RTRealloc (*sc_julia_alloc_funcs->fRTRealloc)
#define RTFree (*sc_julia_alloc_funcs->fRTFree)
#define RTTotalFreeMemory (*sc_julia_alloc_funcs->fRTTotalFreeMemory)
extern void* RTCalloc(JuliaAllocPool* inPool, size_t nitems, size_t inSize);

extern void* SC_RTMalloc(JuliaAllocPool* inPool, size_t inSize);
extern void* SC_RTRealloc(JuliaAllocPool* inPool, void *inPtr, size_t inSize);
extern void  SC_RTFree(JuliaAllocPool* inPool, void* inPtr);
extern void* SC_RTCalloc(JuliaAllocPool* inPool, size_t nitems, size_t inSize);

extern int RTPosix_memalign(JuliaAllocPool* inPool, void **res, size_t align, size_t len);
extern int SC_RTPosix_memalign(JuliaAllocPool* inPool, void **res, size_t align, size_t len);

//Standard free() call. Explanation in jl_gc_free_array in gc.c
extern void free_standard(void* inPtr);

#ifdef __cplusplus
}
#endif

#endif