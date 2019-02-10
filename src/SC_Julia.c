#include "SC_Julia.h"

/* INIT GLOBAL VARIABLES */
int scsynthRunning = 0;
World* SCWorld = NULL;
InterfaceTable* SCInterfaceTable = NULL;

/* RTALLOC WRAPPER FUNCTIONS */

inline void* RTCalloc(World* inWorld, size_t nitems, size_t inSize)
{
	size_t length = inSize * nitems;
	void* alloc_memory = RTAlloc(inWorld, length);
	
	if(alloc_memory)
		memset(alloc_memory, 0, length);
	if(!alloc_memory)
		return NULL;

	return alloc_memory;
}

inline void* SC_RTMalloc(World* inWorld, size_t inSize)
{
	if(scsynthRunning)
		return RTAlloc(inWorld, inSize);
	else
		return malloc(inSize);
}

inline void* SC_RTRealloc(World* inWorld, void *inPtr, size_t inSize)
{
	if(scsynthRunning)
		return RTRealloc(inWorld, inPtr, inSize);
	else
		return realloc(inPtr, inSize);
}

inline void SC_RTFree(World* inWorld, void* inPtr)
{
	if(scsynthRunning)
		RTFree(inWorld, inPtr);
	else
		free(inPtr);
}

inline void* SC_RTCalloc(World* inWorld, size_t nitems, size_t inSize)
{
	if(scsynthRunning)
		return RTCalloc(inWorld, nitems, inSize);
	else
		return calloc(nitems, inSize);
}

//ADD CREDITS: https://github.com/chneukirchen/musl-chris2/blob/master/src/malloc/posix_memalign.c
inline int SC_posix_memalign(World* inWorld, void **res, size_t align, size_t len)
{
	unsigned char *mem, *newAlloc, *end;
	size_t header, footer;
	
	//this if is from libc. check if it is a power of two of size void
	if (align % sizeof (void *) != 0 || !pow(align / sizeof (void *), 2) || align == 0)
    	return EINVAL;

	if ((align & -align) != align) 
		return EINVAL;
	
	if (len > SIZE_MAX - align) 
		return ENOMEM;

	if (align <= SIZE_ALIGN) 
	{
		if (!(mem = (unsigned char*)RTAlloc(inWorld, len)))
			return ENOMEM;
		*res = mem;
		return 0;
	}

	if (!(mem = (unsigned char*)RTAlloc(inWorld, len + align-1)))
		return ENOMEM;

	header = ((size_t *)mem)[-1];
	end = mem + (header & -8);
	footer = ((size_t *)end)[-2];
	newAlloc = (unsigned char*)(void *)((uintptr_t)mem + align-1 & -align);

	if (!(header & 7)) 
	{
		((size_t *)newAlloc)[-2] = ((size_t *)mem)[-2] + (newAlloc-mem);
		((size_t *)newAlloc)[-1] = ((size_t *)mem)[-1] - (newAlloc-mem);
		*res = newAlloc;
		return 0;
	}

	((size_t *)mem)[-1] = header&7 | newAlloc-mem;
	((size_t *)newAlloc)[-2] = footer&7 | newAlloc-mem;
	((size_t *)newAlloc)[-1] = header&7 | end-newAlloc;
	((size_t *)end)[-2] = footer&7 | end-newAlloc;

	if (newAlloc != mem) 
		RTFree(inWorld, mem);

	*res = newAlloc;
	return 0;
}

extern inline void free_standard(void* inPtr)
{
	free(inPtr);
}