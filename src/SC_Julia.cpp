#include "SC_Julia.h"
#include <cstdio>
#include <exception>

//For jl_nothing
//#include <julia.h>

extern "C" 
{
	/* INIT GLOBAL VARIABLES */
	int scsynthRunning = 0;
	World* SCWorld = NULL;
	InterfaceTable* SCInterfaceTable = NULL;

	/* RTALLOC WRAPPER FUNCTIONS */
	void* SC_RTMalloc(World* inWorld, size_t inSize)
	{
		if(scsynthRunning)
		{
			void* alloc_memory = NULL;
			try
			{
				alloc_memory = RTAlloc(inWorld, inSize);
			}
			catch (...) //If RTAlloc gives exception, go here. Reassign null and return it
			{
				printf("WARNING: Julia could not allocate memory. Run the GC. \n");

				/* PERHAPS HERE I NEED TO RETURN A ptr to jl_nothing, as it is the void* counterpart of Julia
				Julia would know how to treat the value, if it is used in functions. Consider:
				a = zeros(10000) -> memory error
				println(a) -> wouldn't know how to print a NULL, but it would for a jl_nothing */
				alloc_memory = NULL;
				//alloc_memory = (void*)jl_nothing;
			}

			return alloc_memory;
		}
		else
			return malloc(inSize);
	}

	void* SC_RTRealloc(World* inWorld, void *inPtr, size_t inSize)
	{
		if(scsynthRunning)
		{
			void* alloc_memory = NULL;
			try
			{
				alloc_memory = RTRealloc(inWorld, inPtr, inSize);
			}
			catch (...) //If RTAlloc gives exception, go here. Reassign null and return it
			{
				printf("WARNING: Julia could not allocate memory. Run the GC. \n");

				/* PERHAPS HERE I NEED TO RETURN A ptr to jl_nothing, as it is the void* counterpart of Julia
				Julia would know how to treat the value, if it is used in functions. Consider:
				a = zeros(10000) -> memory error
				println(a) -> wouldn't know how to print a NULL, but it would for a jl_nothing */
				alloc_memory = NULL;
				//alloc_memory = (void*)jl_nothing;
			}

			return alloc_memory;
		}
		else
			return realloc(inPtr, inSize);
	}

	void SC_RTFree(World* inWorld, void* inPtr)
	{
		if(!inPtr)
			return;
			
		if(scsynthRunning)
			RTFree(inWorld, inPtr);
		else
			free(inPtr);
	}

	void* RTCalloc(World* inWorld, size_t nitems, size_t inSize)
	{
		void* alloc_memory = NULL;
		try
		{
			size_t length = inSize * nitems;
			alloc_memory = RTAlloc(inWorld, length);
			memset(alloc_memory, 0, length);
		}
		catch (...) //If RTAlloc gives exception, go here. Reassign null and return it
		{
			printf("WARNING: Julia could not allocate memory. Run the GC. \n");

			/* PERHAPS HERE I NEED TO RETURN A ptr to jl_nothing, as it is the void* counterpart of Julia
				Julia would know how to treat the value, if it is used in functions. Consider:
				a = zeros(10000) -> memory error
				println(a) -> wouldn't know how to print a NULL, but it would for a jl_nothing */
			alloc_memory = NULL;
			//alloc_memory = (void*)jl_nothing;
		}

		return alloc_memory; 
	}

	void* SC_RTCalloc(World* inWorld, size_t nitems, size_t inSize)
	{
		if(scsynthRunning)
			return RTCalloc(inWorld, nitems, inSize);
		else
			return calloc(nitems, inSize);
	}

	//ADD CREDITS: https://github.com/chneukirchen/musl-chris2/blob/master/src/malloc/posix_memalign.c
	int RTPosix_memalign(World* inWorld, void **res, size_t align, size_t len)
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
			try
			{
				mem = (unsigned char*)RTAlloc(inWorld, len);
			}
			catch (...)
			{
				printf("WARNING: Julia could not allocate memory. Run the GC. \n");

				/* PERHAPS HERE I NEED TO RETURN A ptr to jl_nothing, as it is the void* counterpart of Julia
				Julia would know how to treat the value, if it is used in functions. Consider:
				a = zeros(10000) -> memory error
				println(a) -> wouldn't know how to print a NULL, but it would for a jl_nothing */
				mem = NULL;
				//mem = (void*)jl_nothing;
			}
			if (!mem)
				return ENOMEM;

			*res = mem;
			return 0;
		}
		
		try
		{
			mem = (unsigned char*)RTAlloc(inWorld, len + align-1);
		}
		catch (...)
		{
			printf("WARNING: Julia could not allocate memory. Run the GC. \n");

			/* PERHAPS HERE I NEED TO RETURN A ptr to jl_nothing, as it is the void* counterpart of Julia
				Julia would know how to treat the value, if it is used in functions. Consider:
				a = zeros(10000) -> memory error
				println(a) -> wouldn't know how to print a NULL, but it would for a jl_nothing */
			mem = NULL;
			//mem = (void*)jl_nothing;
		}
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
			RTFree(inWorld, mem);

		*res = newAlloc;
		return 0;
	}

	int SC_RTPosix_memalign(World* inWorld, void **res, size_t align, size_t len)
	{
		if(scsynthRunning)
			return RTPosix_memalign(inWorld, res, align, len);
		else
			return posix_memalign(res, align, len);
	}

	/* STANDARD free() FUNCTION. NEEDED FOR jl_gc_free_array() in gc.c */
	void free_standard(void* inPtr)
	{
		free(inPtr);
	}
}