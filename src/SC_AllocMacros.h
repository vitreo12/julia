//For gc.c and gc-pages.c
#define malloc(s) SC_RTMalloc(julia_alloc_pool, s)
#define calloc(n, s) SC_RTCalloc(julia_alloc_pool, n, s)
#define realloc(p, s) SC_RTRealloc(julia_alloc_pool, p, s)
#define free(p) SC_RTFree(julia_alloc_pool, p)
#define free_standard(p) free_standard(p)

//For arraylist.c
#define LLT_ALLOC(s) SC_RTMalloc(julia_alloc_pool, s)
#define LLT_REALLOC(p, s) SC_RTRealloc(julia_alloc_pool, p, s)
#define LLT_FREE(p) SC_RTFree(julia_alloc_pool, p)