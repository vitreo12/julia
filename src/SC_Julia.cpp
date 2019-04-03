#include "SC_Julia.h"
#include <cstdio>

extern "C" 
{
	/* INIT GLOBAL VARIABLES */
	int scsynthRunning = 0;
	World* SCWorld = NULL;
	JuliaAllocPool* sc_julia_alloc_pool = NULL;
	JuliaAllocFuncs* sc_julia_alloc_funcs = NULL;

	void* RT_memory_start = NULL;
	size_t RT_memory_size = 0;
	uintptr_t RT_memory_start_uintptr = 0;
	uintptr_t RT_memory_size_uintptr = 0;

	/* RTALLOC WRAPPER FUNCTIONS */
	void* SC_RTMalloc(JuliaAllocPool* inPool, size_t inSize)
	{
		if(scsynthRunning)
		{
			if(inPool != sc_julia_alloc_pool)
				printf("ERROR: Different pools \n");
			
			void* alloc_memory = RTAlloc(inPool, inSize);
			
			//AllocPoolSafe will return NULL if it can't allocate RT memory.
			if(!alloc_memory)
			{
				printf("WARNING: Julia could not allocate RT memory. Using normal allocator. Run the GC. \n");

				alloc_memory = malloc(inSize);
			}

			return alloc_memory;
		}
		else
			return malloc(inSize);
	}

	/* Previous area might have been allocated with RTAlloc, so results would be undefined for normal realloc.
	There is the need to RTFree previous memory and allocate new one. */
	void* manual_realloc(JuliaAllocPool* inPool, void* inPtr, size_t inSize)
	{
		uintptr_t inPtr_uintptr = (uintptr_t)inPtr;

		/* If memory has been RT allocated, it is between the RT pointer beginning block and its end.
		This also means that the memory has been normally allocated with malloc/calloc/realloc when there was 
		no RT memory to alloc to. */
		bool is_memory_RT = (inPtr_uintptr >= RT_memory_start_uintptr && inPtr_uintptr < (RT_memory_start_uintptr + RT_memory_size_uintptr));

		//if it was normal malloced memory, just realloc it
		if(!is_memory_RT)
			return realloc(inPtr, inSize);
		
		/* OTHERWISE IT'S RT MEMORY */
		
		//if size is 0, RTFree the memory and return NULL
		if(inSize == 0)
		{
			RTFree(inPool, inPtr);
			return NULL;
		}

		//Allocate new chunk
		void* mem = malloc(inSize);

		//If previous pointer was invalid, just return the new malloced ptr
		if(!inPtr)
			return mem;

		/* This is not how realloc() works, as it internally it knows the previous size of malloc to just copy
		that chunk of memory to the new one. But since realloc()'s extra memory is undefined anyway, I might just copy
		junk memory past the previous memory, and let Julia initialize it as it would do with a normal realloc() call */
		memcpy(mem, inPtr, inSize);

		//Free old pointer
		RTFree(inPool, inPtr);
		
		//Return new allocated memory.
		return mem;
	}

	void* SC_RTRealloc(JuliaAllocPool* inPool, void *inPtr, size_t inSize)
	{
		if(scsynthRunning)
		{
			if(inPool != sc_julia_alloc_pool)
				printf("ERROR: Different pools \n");

			void* alloc_memory = RTRealloc(inPool, inPtr, inSize);

			//AllocPoolSafe will return NULL if it can't allocate RT memory.
			if(!alloc_memory)
			{
				printf("WARNING: Julia could not allocate RT memory. Using normal allocator. Run the GC. \n");

				alloc_memory = manual_realloc(inPool, inPtr, inSize);
			}

			return alloc_memory;
		}
		else
			return realloc(inPtr, inSize);
	}

	void SC_RTFree(JuliaAllocPool* inPool, void* inPtr)
	{
		if(!inPtr)
			return;
		
		if(inPool != sc_julia_alloc_pool)
			printf("ERROR: Different pools \n");

		uintptr_t inPtr_uintptr = (uintptr_t)inPtr;

		/* If memory has been RT allocated, it is between the RT pointer beginning block and its end.
		This also means that the memory has been normally allocated with malloc/calloc/realloc when there was 
		no RT memory to alloc to. */
		bool is_memory_RT = (inPtr_uintptr >= RT_memory_start_uintptr && inPtr_uintptr < (RT_memory_start_uintptr + RT_memory_size_uintptr));

		/* printf("*** Is memory RT? %d\n", is_memory_RT);
		printf("inPtr: %zu\n", inPtr_uintptr);
		printf("RT_memory_start: %zu\n", RT_memory_start_uintptr);
		printf("RT_memory_siz: %zu\n", RT_memory_size_uintptr); */

		if(scsynthRunning && is_memory_RT)
			RTFree(inPool, inPtr);
		else
			free(inPtr);
	}

	void* RTCalloc(JuliaAllocPool* inPool, size_t nitems, size_t inSize)
	{
		if(inPool != sc_julia_alloc_pool)
			printf("ERROR: Different pools \n");
				
		size_t length = inSize * nitems;
		void* alloc_memory = RTAlloc(inPool, length);

		//AllocPoolSafe will return NULL if it can't allocate RT memory.
		if(!alloc_memory)
		{
			printf("WARNING: Julia could not allocate RT memory. Using normal allocator. Run the GC. \n");

			alloc_memory = calloc(nitems, inSize);
		}

		memset(alloc_memory, 0, length);

		return alloc_memory; 
	}

	void* SC_RTCalloc(JuliaAllocPool* inPool, size_t nitems, size_t inSize)
	{
		if(scsynthRunning)
			return RTCalloc(inPool, nitems, inSize);
		else
			return calloc(nitems, inSize);
	}

	//Code adapted from:
	//https://github.com/chneukirchen/musl-chris2/blob/master/src/malloc/posix_memalign.c
	int RTPosix_memalign(JuliaAllocPool* inPool, void **res, size_t align, size_t len)
	{
		if(inPool != sc_julia_alloc_pool)
			printf("ERROR: Different pools \n");

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
			mem = (unsigned char*)RTAlloc(inPool, len);
			
			//AllocPoolSafe will return NULL if it can't allocate RT memory.
			if(!mem)
			{
				printf("WARNING: Julia could not allocate RT memory. Using normal allocator. Run the GC. \n");
				return posix_memalign(res, align, len);
			}

			/* RT MEMORY */
			
			if (!mem)
				return ENOMEM;

			*res = mem;
			return 0;
		}
		
		mem = (unsigned char*)RTAlloc(inPool, len + align-1);
		
		//AllocPoolSafe will return NULL if it can't allocate RT memory.
		if(!mem)
		{
			printf("WARNING: Julia could not allocate RT memory. Using normal allocator. Run the GC. \n");
			return posix_memalign(res, align, len);
		}

		/* RT MEMORY */
		
		if (!mem)
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
			SC_RTFree(inPool, mem);

		*res = newAlloc;
		return 0;
	}

	int SC_RTPosix_memalign(JuliaAllocPool* inPool, void **res, size_t align, size_t len)
	{
		if(scsynthRunning)
			return RTPosix_memalign(inPool, res, align, len);
		else
			return posix_memalign(res, align, len);
	}

	/* STANDARD free() FUNCTION. NEEDED FOR jl_gc_free_array() in gc.c. See comment there. */
	void free_standard(void* inPtr)
	{
		free(inPtr);
	}
}