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

typedef struct AllocPool AllocPool;

typedef struct JuliaAllocPool
{
	AllocPool* alloc_pool;
} JuliaAllocPool;

typedef struct JuliaAllocFuncs
{
	void* (*fRTAlloc)(JuliaAllocPool* inPool, size_t inSize);
	void* (*fRTRealloc)(JuliaAllocPool* inPool, void *inPtr, size_t inSize);
	void  (*fRTFree)(JuliaAllocPool* inPool, void *inPtr);
	size_t(*fRTTotalFreeMemory)(JuliaAllocPool* inPool);
} JuliaAllocFuncs;


/* GLOBAL VARIABLES */
extern World* SCWorld;
extern JuliaAllocPool* julia_alloc_pool;
extern JuliaAllocFuncs* julia_alloc_funcs;
extern int scsynthRunning;

/* RT ALLOCATOR INFORMATIONS */
extern void* RT_memory_start;
extern size_t RT_memory_size;
extern uintptr_t RT_memory_start_uint;
extern uintptr_t RT_memory_size_uint;

/* FUNCTIONS */
#define RTAlloc (*julia_alloc_funcs->fRTAlloc)
#define RTRealloc (*julia_alloc_funcs->fRTRealloc)
#define RTFree (*julia_alloc_funcs->fRTFree)
#define RTTotalFreeMemory (*julia_alloc_funcs->fRTTotalFreeMemory)
extern void* RTCalloc(JuliaAllocPool* inPool, size_t nitems, size_t inSize);

extern void* SC_RTMalloc(JuliaAllocPool* inPool, size_t inSize);
extern void* SC_RTRealloc(JuliaAllocPool* inPool, void *inPtr, size_t inSize);
extern void  SC_RTFree(JuliaAllocPool* inPool, void* inPtr);
extern void* SC_RTCalloc(JuliaAllocPool* inPool, size_t nitems, size_t inSize);

//ADD CREDITS: https://github.com/chneukirchen/musl-chris2/blob/master/src/malloc/posix_memalign.c
extern int RTPosix_memalign(JuliaAllocPool* inPool, void **res, size_t align, size_t len);
extern int SC_RTPosix_memalign(JuliaAllocPool* inPool, void **res, size_t align, size_t len);

//Standard free() call. Explanation in jl_gc_free_array in gc.c
extern void free_standard(void* inPtr);

#ifdef __cplusplus
}
#endif

#endif