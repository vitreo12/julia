/*
	SuperCollider real time audio synthesis system
    Copyright (c) 2002 James McCartney. All rights reserved.
	http://www.audiosynth.com

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
*/

/* Separated header file from struct World. Here it defines how World looks like
when supernova is active. Use it to cast void pointers inside jl_get_supernova_buffer_and_lock/unlock functions.*/

#pragma once

#include "SC_Types.h"
#include "SC_Rate.h"
#include "SC_SndBuf_supernova.h"

namespace nova
{
    class spin_lock;
    class padded_rw_spinlock;
}

struct World_supernova
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
	SndBuf_supernova *mSndBufs;
	SndBuf_supernova *mSndBufsNonRealTimeMirror;
	
	struct SndBufUpdates *mSndBufUpdates;

	struct Group *mTopGroup;

	Rate mFullRate, mBufRate;

	uint32 mNumRGens;
	struct RGen *mRGen;

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

	nova::padded_rw_spinlock * mAudioBusLocks;
	nova::spin_lock * mControlBusLock;
};