#ifndef SC_JULIA_INCLUDE_H
#define SC_JULIA_INCLUDE_H

#include <stddef.h>
#include <stdint.h>
#include <string.h>

#if !defined(__cplusplus)
# include <stdbool.h>
#endif // __cplusplus

typedef  int64_t  int64;
typedef uint64_t uint64;

typedef  int32_t  int32;
typedef uint32_t uint32;

typedef  int16_t  int16;
typedef uint16_t uint16;

typedef  int8_t  int8;
typedef uint8_t uint8;

typedef float float32;
typedef double float64;

typedef struct World World;
typedef struct Unit Unit;
typedef struct sc_msg_iter sc_msg_iter;
typedef struct SndBuf SndBuf;
typedef struct Node Node;
typedef struct FifoMsg FifoMsg;
typedef struct SCFFT_Allocator SCFFT_Allocator;
typedef struct ScopeBufferHnd ScopeBufferHnd;

typedef void (*UnitCtorFunc)(Unit* inUnit);
typedef void (*UnitDtorFunc)(Unit* inUnit);
typedef void (*PlugInCmdFunc)(World *inWorld, void* inUserData, sc_msg_iter *args, void *replyAddr);
typedef void (*UnitCmdFunc)(Unit *unit, sc_msg_iter *args);
typedef void (*BufGenFunc)(World *world, SndBuf *buf, sc_msg_iter *msg);
typedef bool (*AsyncStageFn)(World *inWorld, void* cmdData);
typedef void (*AsyncFreeFn)(World *inWorld, void* cmdData);

enum SCFFT_Direction
{
	kForward = 1,
	kBackward = 0
};

enum SCFFT_WindowFunction
{
	kRectWindow = -1,
	kSineWindow = 0,
	kHannWindow = 1
};

typedef enum SCFFT_Direction SCFFT_Direction;
typedef enum SCFFT_WindowFunction SCFFT_WindowFunction;

struct InterfaceTable
{
	unsigned int mSineSize;
	float32 *mSineWavetable;
	float32 *mSine;
	float32 *mCosecant;

	// call printf for debugging. should not use in finished code.
	int (*fPrint)(const char *fmt, ...);

	// get a seed for a random number generator
	int32 (*fRanSeed)();

	// define a unit def
	bool (*fDefineUnit)(const char *inUnitClassName, size_t inAllocSize,
			UnitCtorFunc inCtor, UnitDtorFunc inDtor, uint32 inFlags);

	// define a command  /cmd
	bool (*fDefinePlugInCmd)(const char *inCmdName, PlugInCmdFunc inFunc, void* inUserData);

	// define a command for a unit generator  /u_cmd
	bool (*fDefineUnitCmd)(const char *inUnitClassName, const char *inCmdName, UnitCmdFunc inFunc);

	// define a buf gen
	bool (*fDefineBufGen)(const char *inName, BufGenFunc inFunc);

	// clear all of the unit's outputs.
	void (*fClearUnitOutputs)(Unit *inUnit, int inNumSamples);

	// non real time memory allocation
	void* (*fNRTAlloc)(size_t inSize);
	void* (*fNRTRealloc)(void *inPtr, size_t inSize);
	void  (*fNRTFree)(void *inPtr);

	// real time memory allocation
	void* (*fRTAlloc)(World *inWorld, size_t inSize);
	void* (*fRTRealloc)(World *inWorld, void *inPtr, size_t inSize);
	void  (*fRTFree)(World *inWorld, void *inPtr);

	// call to set a Node to run or not.
	void (*fNodeRun)(Node* node, int run);

	// call to stop a Graph after the next buffer.
	void (*fNodeEnd)(Node* graph);

	// send a trigger from a Node to clients
	void (*fSendTrigger)(Node* inNode, int triggerID, float value);

	// send a reply message from a Node to clients
	void (*fSendNodeReply)(Node* inNode, int replyID, const char* cmdName, int numArgs, const float* values);

	// sending messages between real time and non real time levels.
	bool (*fSendMsgFromRT)(World *inWorld, FifoMsg* inMsg);
	bool (*fSendMsgToRT)(World *inWorld, FifoMsg* inMsg);

	// libsndfile support
	int (*fSndFileFormatInfoFromStrings)(struct SF_INFO *info,
		const char *headerFormatString, const char *sampleFormatString);

	// get nodes by id
	Node* (*fGetNode)(World *inWorld, int inID);
	struct Graph* (*fGetGraph)(World *inWorld, int inID);

	void (*fNRTLock)(World *inWorld);
	void (*fNRTUnlock)(World *inWorld);

	bool mUnused0;

	void (*fGroup_DeleteAll)(struct Group* group);
	void (*fDoneAction)(int doneAction, Unit *unit);

	int (*fDoAsynchronousCommand)
		(
			World *inWorld,
			void* replyAddr,
			const char* cmdName,
			void *cmdData,
			AsyncStageFn stage2, // stage2 is non real time
			AsyncStageFn stage3, // stage3 is real time - completion msg performed if stage3 returns true
			AsyncStageFn stage4, // stage4 is non real time - sends done if stage4 returns true
			AsyncFreeFn cleanup,
			int completionMsgSize,
			void* completionMsgData
		);


	// fBufAlloc should only be called within a BufGenFunc
	int (*fBufAlloc)(SndBuf *inBuf, int inChannels, int inFrames, double inSampleRate);
	
	struct scfft * (*fSCfftCreate)(size_t fullsize, size_t winsize, SCFFT_WindowFunction wintype,
					 float *indata, float *outdata, SCFFT_Direction forward, SCFFT_Allocator* alloc);

	void (*fSCfftDoFFT)(struct scfft *f);
	void (*fSCfftDoIFFT)(struct scfft *f);

	// destroy any resources held internally.
	void (*fSCfftDestroy)(struct scfft *f, SCFFT_Allocator* alloc);

	// Get scope buffer. Returns the maximum number of possile frames.
	bool (*fGetScopeBuffer)(World *inWorld, int index, int channels, int maxFrames, ScopeBufferHnd* bufHand);
	void (*fPushScopeBuffer)(World *inWorld, ScopeBufferHnd* bufHand, int frames);
	void (*fReleaseScopeBuffer)(World *inWorld, ScopeBufferHnd* bufHand);
};

typedef struct InterfaceTable InterfaceTable;

//They will be pointing to server's ones at Julia boot.
//static will assure just one global state.
static World* SCWorld;
static InterfaceTable* SCInterfaceTable;

#define SC_RTAlloc (*SCInterfaceTable->fRTAlloc)
#define SC_RTRealloc (*SCInterfaceTable->fRTRealloc)
#define SC_RTFree (*SCInterfaceTable->fRTFree)

static inline void* SC_RTCalloc(World* inWorld, size_t nitems, size_t inSize)
{
	size_t length = inSize * nitems;
	void* alloc_memory = SC_RTAlloc(inWorld, length);
	if(alloc_memory)
		memset(alloc_memory, 0, length);
	return alloc_memory;
}

#endif