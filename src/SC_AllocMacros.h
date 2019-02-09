#define malloc(s) SC_RTMalloc(SCWorld, s)
#define calloc(n, s) SC_RTCalloc(SCWorld, n, s)
#define realloc(p, s) SC_RTRealloc(SCWorld, p, s)
#define free(p) SC_RTFree(SCWorld, p)