#include "julia.h"
#include <cstdio>

#include "SC_Utilities/SC_World.h"
#include "SC_Utilities/SC_World_supernova.h"
#include "SC_Utilities/SC_Unit.h"

extern "C" 
{
    //Called at start of @perform
    JL_DLLEXPORT void* jl_get_SC_buffer(void* buffer_SCWorld, float fbufnum)
    {
        //printf("*** NEW BUFFER!!! ***\n");
        World* SCWorld = (World*)buffer_SCWorld;

        uint32 bufnum = (int)fbufnum; 

        //If bufnum is not more that maximum number of buffers in World* it means bufnum doesn't point to a LocalBuf
        if(!(bufnum >= SCWorld->mNumSndBufs))
        {
            SndBuf* buf = SCWorld->mSndBufs + bufnum; 

            if(!buf->data)
            {
                printf("WARNING: Julia: Invalid buffer: %d\n", bufnum);
                return nullptr;
            }

            return (void*)buf;
        }
        else
        {
            printf("WARNING: Julia: local buffers are not yet supported \n");
            return nullptr;
        
            /* int localBufNum = bufnum - SCWorld->mNumSndBufs; 
            
            Graph *parent = unit->mParent; 
            
            if(localBufNum <= parent->localBufNum)
                unit->m_buf = parent->mLocalSndBufs + localBufNum; 
            else 
            { 
                bufnum = 0; 
                unit->m_buf = SCWorld->mSndBufs + bufnum; 
            } 

            return (void*)buf;
            */
        }
    }

    //Called at start of @perform
    JL_DLLEXPORT void* jl_get_supernova_buffer_and_lock(void* buffer_SCWorld, float fbufnum)
    {
        World_supernova* SCWorld = (World_supernova*)buffer_SCWorld;

        uint32 bufnum = (int)fbufnum; 

        //If bufnum is not more that maximum number of buffers in World* it means bufnum doesn't point to a LocalBuf
        if(!(bufnum >= SCWorld->mNumSndBufs))
        {
            SndBuf_supernova* buf = SCWorld->mSndBufs + bufnum; 

            if(!buf->data)
            {
                printf("WARNING: Julia: Invalid buffer: %d\n", bufnum);
                return nullptr;
            }

            /* LOCK THE BUFFER HERE... */
            LOCK_SNDBUF_SHARED(buf);  //It should be another custom function, work it out when doing supernova support.

            return (void*)buf;
        }
        else
        {
            printf("WARNING: Julia: local buffers are not yet supported \n");
            return nullptr;
        }
    }

    JL_DLLEXPORT void* jl_unlock_supernova_buffer(void* buf)
    {
        /* UNLOCK THE BUFFER HERE... To be called at the end of @perform function.*/

        return nullptr;
    }

    JL_DLLEXPORT float jl_get_float_value_SC_buffer(void* buf, size_t index, size_t channel)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;

            //Supernova should lock here
            
            size_t c_index = index - 1; //Julia counts from 1, that's why index - 1
            
            size_t actual_index = (c_index * snd_buf->channels) + channel; //Interleaved data
            
            if(index && (actual_index < snd_buf->samples))
                return snd_buf->data[actual_index];
        }
        
        return 0.f;
    }

    JL_DLLEXPORT void jl_set_float_value_SC_buffer(void* buf, float value, size_t index, size_t channel)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;

            //Supernova should lock here

            size_t c_index = index - 1; //Julia counts from 1, that's why index - 1
            
            size_t actual_index = (c_index * snd_buf->channels) + channel; //Interleaved data
            
            if(index && (actual_index < snd_buf->samples))
            {
                snd_buf->data[actual_index] = value;
                return;
            }
        }
    }

    //Length of each channel
    JL_DLLEXPORT int jl_get_frames_SC_buffer(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->frames;
        }
            
        return 0;
    }

    //Total allocated length
    JL_DLLEXPORT int jl_get_samples_SC_buffer(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->samples;
        }

        return 0;
    }

    //Number of channels
    JL_DLLEXPORT int jl_get_channels_SC_buffer(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->channels;
        }
            
        return 0;
    }

    //Samplerate
    JL_DLLEXPORT double jl_get_samplerate_SC_buffer(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->samplerate;
        }
            
        return 0;
    }

    //Sampledur
    JL_DLLEXPORT double jl_get_sampledur_SC_buffer(void* buf)
    {
        if(buf)
        {
            SndBuf* snd_buf = (SndBuf*)buf;
            return snd_buf->sampledur;
        }
            
        return 0;
    }
}