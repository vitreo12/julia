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

/* Separated header file for struct SndBuf representation in supernova. buffer_lock functions for
   SndBuf_supernova are defined in SC_Unit.h. Modifications are needed in order to compile 
   both scsynth and supernova buffer functions directly with julia, and just switch the calls with macros inside
   juliaProbably going to implement my own locks anyway. */

#pragma once
 
#include <atomic>
#include <cassert>

#ifdef __SSE2__
#include <emmintrin.h>
#endif

class rw_spinlock
{
	static const uint32_t unlocked_state = 0;
	static const uint32_t locked_state   = 0x80000000;
	static const uint32_t reader_mask    = 0x7fffffff;

#ifdef __SSE2__
	static inline void pause() { _mm_pause(); }
#else
	static inline void pause() { }
#endif

public:
	struct unique_lock
	{
		explicit unique_lock(rw_spinlock & sl) : sl_(sl) { sl_.lock();   }
		~unique_lock()                                   { sl_.unlock(); }

	private:
		rw_spinlock & sl_;
	};

	typedef unique_lock unique_lock;

	struct shared_lock
	{
		explicit shared_lock(rw_spinlock & sl): sl_(sl) { sl_.lock_shared();   }
		~shared_lock()                                  { sl_.unlock_shared(); }

	private:
		rw_spinlock & sl_;
	};

	rw_spinlock()                                    = default;
	rw_spinlock(rw_spinlock const & rhs)             = delete;
	rw_spinlock & operator=(rw_spinlock const & rhs) = delete;
	rw_spinlock(rw_spinlock && rhs)                  = delete;

	~rw_spinlock() { assert(state == unlocked_state); }

	void lock()
	{
		for (;;) {
			while( state.load(std::memory_order_relaxed) != unlocked_state )
				pause();

			uint32_t expected = unlocked_state;
			if( state.compare_exchange_weak(expected, locked_state, std::memory_order_acquire) )
				break;
		}
	}

	bool try_lock()
	{
		uint32_t expected = unlocked_state;
		if( state.compare_exchange_strong(expected, locked_state, std::memory_order_acquire) )
			return true;
		else
			return false;
	}

	void unlock()
	{
		assert( state.load(std::memory_order_relaxed) == locked_state) ;
		state.store( unlocked_state, std::memory_order_release );
	}

	void lock_shared()
	{
		for(;;) {
			/* with the mask, the cas will fail, locked exclusively */
			uint32_t current_state    = state.load( std::memory_order_acquire ) & reader_mask;
			const uint32_t next_state = current_state + 1;

			if( state.compare_exchange_weak(current_state, next_state, std::memory_order_acquire) )
				break;
			pause();
		}
	}

	bool try_lock_shared()
	{
		/* with the mask, the cas will fail, locked exclusively */
		uint32_t current_state    = state.load(std::memory_order_acquire) & reader_mask;
		const uint32_t next_state = current_state + 1;

		if( state.compare_exchange_strong(current_state, next_state, std::memory_order_acquire) )
			return true;
		else
			return false;
	}

	void unlock_shared()
	{
		for(;;) {
			uint32_t current_state    = state.load(std::memory_order_relaxed); /* we don't need the reader_mask */
			const uint32_t next_state = current_state - 1;

			if( state.compare_exchange_weak(current_state, uint32_t(next_state)) )
				break;
			pause();
		}
	}

private:
	std::atomic<uint32_t> state {unlocked_state};
};

typedef struct SNDFILE_tag SNDFILE;

struct SndBuf_supernova
{
	double samplerate;
	double sampledur; // = 1/ samplerate
	float *data;
	int channels;
	int samples;
	int frames;
	int mask;	// for delay lines
	int mask1;	// for interpolating oscillators.
	int coord;	// used by fft ugens
	SNDFILE *sndfile; // used by disk i/o
	// SF_INFO fileinfo; // used by disk i/o
	bool isLocal;
	mutable rw_spinlock lock;
};
typedef struct SndBuf_supernova SndBuf_supernova;