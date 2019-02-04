#ifndef SC_JULIA_INCLUDE_H
#define SC_JULIA_INCLUDE_H

#include <stddef.h>
#include <stdint.h>

#if !defined(__cplusplus)
# include <stdbool.h>
#endif // __cplusplus

typedef int SCErr;

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

typedef union {
	uint32 u;
	int32 i;
	float32 f;
} elem32;

typedef union {
	uint64 u;
	int64 i;
	float64 f;
} elem64;

#ifdef __GXX_EXPERIMENTAL_CXX0X__
#define sc_typeof_cast(x) (decltype(x))
#elif defined(__GNUC__)
#define sc_typeof_cast(x) (__typeof__(x))
#else
#define sc_typeof_cast(x) /* (typeof(x)) */
#endif

enum { calc_ScalarRate, calc_BufRate, calc_FullRate, calc_DemandRate };

struct Rate
{
	double mSampleRate; // samples per second
	double mSampleDur;  // seconds per sample
	double mBufDuration; // seconds per buffer
	double mBufRate;	// buffers per second
	double mSlopeFactor;  // 1. / NumSamples
	double mRadiansPerSample; // 2pi / SampleRate
	int mBufLength;	// length of the buffer
	// second order filter loops are often unrolled by 3
	int mFilterLoops, mFilterRemain;
	double mFilterSlope;
};

typedef struct Rate Rate;

struct World
{
	// a pointer to private implementation, not available to plug-ins.
	struct HiddenWorld *hw;

	// a pointer to the table of function pointers that implement the plug-ins'
	// interface to the server.
	struct InterfaceTable *ft;

	// data accessible to plug-ins :
	double mSampleRate;
	int mBufLength;
	int mBufCounter;

	uint32 mNumAudioBusChannels;
	uint32 mNumControlBusChannels;
	uint32 mNumInputs;
	uint32 mNumOutputs;

	// vector of samples for all audio busses
	float *mAudioBus;

	// vector of samples for all control busses
	float *mControlBus;

	// these tell if a bus has been written to during a control period
	// if the value is equal to mBufCounter then the buss has been touched
	// this control period.
	int32 *mAudioBusTouched;
	int32 *mControlBusTouched;

	uint32 mNumSndBufs;
	struct SndBuf *mSndBufs;
	struct SndBuf *mSndBufsNonRealTimeMirror;
	struct SndBufUpdates *mSndBufUpdates;

	struct Group *mTopGroup;

	Rate mFullRate, mBufRate;

	uint32 mNumRGens;
	struct RGen* mRGen;

	uint32 mNumUnits, mNumGraphs, mNumGroups;
	int mSampleOffset; // offset in the buffer of current event time.

	void * mNRTLock;

	uint32 mNumSharedControls;
	float *mSharedControls;

	bool mRealTime;
	bool mRunning;
	int mDumpOSC;

	void* mDriverLock;

	float mSubsampleOffset; // subsample accurate offset in the buffer of current event time.

	int mVerbosity;
	int mErrorNotification;
	int mLocalErrorNotification;

	bool mRendezvous; // Allow user to disable Rendezvous

	const char* mRestrictedPath; // OSC commands to read/write data can only do it within this path, if specified
};

typedef struct World World;

typedef void (*UnitCtorFunc)(struct Unit* inUnit);
typedef void (*UnitDtorFunc)(struct Unit* inUnit);
typedef void (*PlugInCmdFunc)(World *inWorld, void* inUserData, struct sc_msg_iter *args, void *replyAddr);
typedef void (*UnitCmdFunc)(struct Unit *unit, struct sc_msg_iter *args);
typedef void (*BufGenFunc)(World *world, struct SndBuf *buf, struct sc_msg_iter *msg);
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
	void (*fClearUnitOutputs)(struct Unit *inUnit, int inNumSamples);

	// non real time memory allocation
	void* (*fNRTAlloc)(size_t inSize);
	void* (*fNRTRealloc)(void *inPtr, size_t inSize);
	void  (*fNRTFree)(void *inPtr);

	// real time memory allocation
	void* (*fRTAlloc)(World *inWorld, size_t inSize);
	void* (*fRTRealloc)(World *inWorld, void *inPtr, size_t inSize);
	void  (*fRTFree)(World *inWorld, void *inPtr);

	// call to set a Node to run or not.
	void (*fNodeRun)(struct Node* node, int run);

	// call to stop a Graph after the next buffer.
	void (*fNodeEnd)(struct Node* graph);

	// send a trigger from a Node to clients
	void (*fSendTrigger)(struct Node* inNode, int triggerID, float value);

	// send a reply message from a Node to clients
	void (*fSendNodeReply)(struct Node* inNode, int replyID, const char* cmdName, int numArgs, const float* values);

	// sending messages between real time and non real time levels.
	bool (*fSendMsgFromRT)(World *inWorld, struct FifoMsg* inMsg);
	bool (*fSendMsgToRT)(World *inWorld, struct FifoMsg* inMsg);

	// libsndfile support
	int (*fSndFileFormatInfoFromStrings)(struct SF_INFO *info,
		const char *headerFormatString, const char *sampleFormatString);

	// get nodes by id
	struct Node* (*fGetNode)(World *inWorld, int inID);
	struct Graph* (*fGetGraph)(World *inWorld, int inID);

	void (*fNRTLock)(World *inWorld);
	void (*fNRTUnlock)(World *inWorld);

	bool mUnused0;

	void (*fGroup_DeleteAll)(struct Group* group);
	void (*fDoneAction)(int doneAction, struct Unit *unit);

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
	int (*fBufAlloc)(struct SndBuf *inBuf, int inChannels, int inFrames, double inSampleRate);
	
	struct scfft * (*fSCfftCreate)(size_t fullsize, size_t winsize, enum SCFFT_WindowFunction wintype,
					 float *indata, float *outdata, enum SCFFT_Direction forward, struct SCFFT_Allocator* alloc);

	void (*fSCfftDoFFT)(struct scfft *f);
	void (*fSCfftDoIFFT)(struct scfft *f);

	// destroy any resources held internally.
	void (*fSCfftDestroy)(struct scfft *f, struct SCFFT_Allocator* alloc);

	// Get scope buffer. Returns the maximum number of possile frames.
	bool (*fGetScopeBuffer)(World *inWorld, int index, int channels, int maxFrames, struct ScopeBufferHnd* bufHand);
	void (*fPushScopeBuffer)(World *inWorld, struct ScopeBufferHnd* bufHand, int frames);
	void (*fReleaseScopeBuffer)(World *inWorld, struct ScopeBufferHnd* bufHand);
};

typedef struct InterfaceTable InterfaceTable;

//They will be pointing to server's ones at Julia boot.
//static will assure just one global state.
static World* SCWorld;
static InterfaceTable* ft;

#define SC_NRTAlloc (*ft->fNRTAlloc)
#define SC_NRTRealloc (*ft->fNRTRealloc)
#define SC_NRTFree (*ft->fNRTFree)

#define SC_RTAlloc (*ft->fRTAlloc)
#define SC_RTRealloc (*ft->fRTRealloc)
#define SC_RTFree (*ft->fRTFree)

static inline void* SC_RTCalloc(World* inWorld, size_t nitems, size_t inSize)
{
	size_t length = inSize * nitems;
	void* alloc_memory = SC_RTAlloc(inWorld, length);
	if(alloc_memory)
		memset(alloc_memory, 0, length);
	return alloc_memory;
}

#endif