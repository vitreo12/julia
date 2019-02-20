#include "SC_Julia.h"

/* INIT GLOBAL VARIABLES */
int scsynthRunning = 0;
World* SCWorld = NULL;
InterfaceTable* SCInterfaceTable = NULL;

/* RTALLOC WRAPPER FUNCTIONS */

/* Perhaps, I could remove all these printf calls (even if wrapped in ifs). 
Set them only if World* verbosity is > -2. (I could pass in the verbosity val at jl_init_with_image_SC()) */

inline void* RTCalloc(World* inWorld, size_t nitems, size_t inSize)
{
	size_t length = inSize * nitems;
	void* alloc_memory = RTAlloc(inWorld, length);
	
	if(!alloc_memory)
	{
		printf("ERROR: Julia could not allocate memory from real-time allocator. Run GC to free up memory.\n");
		return NULL;
	}

	memset(alloc_memory, 0, length);
	return alloc_memory; //It would be NULL anyway if failed to allocate
}

inline void* SC_RTMalloc(World* inWorld, size_t inSize)
{
	if(scsynthRunning)
	{
		//Check if real-time allocator actually allocated anything...
		void* alloc_memory = RTAlloc(inWorld, inSize);
		
		//This check won't ever happen, as RTAlloc would have thrown an exception already. 
		//I can't catch this exception here in C code. I need to have this file as C++ and wrap
		//this calls in try {} catch {} with std::exception. I won't be ever returning the NULL ptr that
		//I would need. ALSO: I need to change julia_internal.h to be calling these .cpp functions that would check
		//the exceptions, not the standard RT SC ones.
 		if(!alloc_memory)
			printf("ERROR: Julia could not allocate memory from real-time allocator. Run GC to free up memory.\n");
		
		return alloc_memory; //It would be NULL anyway if failed to allocate
	}
	else
		return malloc(inSize);
}

inline void* SC_RTRealloc(World* inWorld, void *inPtr, size_t inSize)
{
	if(scsynthRunning)
	{
		void* alloc_memory = RTRealloc(inWorld, inPtr, inSize);
		if(!alloc_memory)
			printf("ERROR: Julia could not allocate memory from real-time allocator. Run GC to free up memory.\n");
		return alloc_memory; //It would be NULL anyway if failed to allocate
	}
	else
		return realloc(inPtr, inSize);
}

inline void SC_RTFree(World* inWorld, void* inPtr)
{
	if(scsynthRunning)
	{
		if(inPtr) //If valid pointer, RTFree it
		{
			RTFree(inWorld, inPtr);
			return;
		}
		else //Wasn't allocated correctly. Don't free it.
		{
			printf("ERROR: Julia could not free memory from real-time allocator\n");
			return;
		}
	}
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
	
	//CHECK THIS BIT AGAIN.
	//this if is from libc. check if alignment is a power of two of size void
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