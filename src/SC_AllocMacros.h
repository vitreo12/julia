//For gc.c and gc-pages.c
#define malloc(s) SC_RTMalloc(SCWorld, s)
#define calloc(n, s) SC_RTCalloc(SCWorld, n, s)
#define realloc(p, s) SC_RTRealloc(SCWorld, p, s)
#define free(p) SC_RTFree(SCWorld, p)
#define free_standard(p) free_standard(p)

//For arraylist.c
#define LLT_ALLOC(s) SC_RTMalloc(SCWorld, s)
#define LLT_REALLOC(p, s) SC_RTRealloc(SCWorld, p, s)
#define LLT_FREE(p) SC_RTFree(SCWorld, p)