#= Module for pointers to SC buffers =#
module SCBuffer

    export Buffer, __get_SC_buffer__, __get_supernova_buffer_and_lock__, __unlock_supernova_buffer__, samplerate, sampledur

    mutable struct Buffer
        SCWorld::Ptr{Cvoid}
        snd_buf::Ptr{Cvoid}
        bufnum::Float32
        input_num::Int
    end

    function Buffer(input_num::Signed)
        if(input_num > 32)
            error("Buffer: Input number out of bounds. Maximum input number is 32")
        elseif(input_num < 1)
            error("Buffer: Input number out of bounds. Minimum input number is 1")
        end
        
        SCWorld::Ptr{Cvoid} = ccall(:jl_get_SCWorld, Ptr{Cvoid}, ())
        if(SCWorld == C_NULL)
            error("Invalid SCWorld")
            return nothing
        end
        
        snd_buf::Ptr{Cvoid} = C_NULL
        
        bufnum::Float32 = Float32(-1e9)

        return Buffer(SCWorld, snd_buf, bufnum, Int(input_num))
    end

    #scsynth
    function __get_SC_buffer__(buffer::Buffer, fbufnum::Float32)
        if(fbufnum < 0.0)
            fbufnum = 0.0
        end
    
        #Update buffer pointer only with a new buffer number as input
        if(buffer.bufnum != fbufnum)
            buffer.bufnum = fbufnum
            buffer.snd_buf = ccall(:jl_get_SC_buffer, Ptr{Cvoid}, (Ptr{Cvoid}, Cfloat,), buffer.SCWorld, fbufnum)
        end
    
        return nothing
    end

    #supernova
    function __get_supernova_buffer_and_lock__(buffer::Buffer, fbufnum::Float32)
        if(fbufnum < 0.0)
            fbufnum = 0.0
        end
    
        #Update buffer pointer only with a new buffer number as input
        if(buffer.bufnum != fbufnum)
            buffer.bufnum = fbufnum
            buffer.snd_buf = ccall(:jl_get_supernova_buffer_and_lock, Ptr{Cvoid}, (Ptr{Cvoid}, Cfloat,), buffer.SCWorld, fbufnum)
        end
    
        return nothing
    end

    function __unlock_supernova_buffer__(buffer::Buffer)
        snd_buf::Ptr{Cvoid} = buffer.snd_buf

        if(snd_buf != C_NULL)
            ccall(:jl_unlock_supernova_buffer, Cvoid, (Ptr{Cvoid},), snd_buf)
        end
        
        return nothing
    end

    import Base.getindex
    import Base.setindex!
    import Base.length
    import Base.size
    import JuliaCollider.SCData.nchans
    
    #Generalized version
    function getindex(buffer::Buffer, index::Signed, channel::Signed = 1)
        return ccall(:jl_get_float_value_SC_buffer, Cfloat, (Ptr{Cvoid}, Int, Int), buffer.snd_buf, Int(index), Int(channel))
    end

    function getindex(buffer::Buffer, index::Int32, channel::Int32 = Int32(1))
        return ccall(:jl_get_float_value_SC_buffer, Cfloat, (Ptr{Cvoid}, Int, Int), buffer.snd_buf, Int(index), Int(channel))
    end

    function getindex(buffer::Buffer, index::Int32, channel::Int64 = 1)
        return ccall(:jl_get_float_value_SC_buffer, Cfloat, (Ptr{Cvoid}, Int, Int), buffer.snd_buf, Int(index), Int(channel))
    end

    function getindex(buffer::Buffer, index::Int64, channel::Int32 = Int32(1))
        return ccall(:jl_get_float_value_SC_buffer, Cfloat, (Ptr{Cvoid}, Int, Int), buffer.snd_buf, Int(index), Int(channel))
    end

    function getindex(buffer::Buffer, index::Int64, channel::Int64 = 1)
        return ccall(:jl_get_float_value_SC_buffer, Cfloat, (Ptr{Cvoid}, Int, Int), buffer.snd_buf, Int(index), Int(channel))
    end

    #Should they just return the ccall?

    #Generalized version
    function setindex!(buffer::Buffer, value::T, index::Signed, channel::Signed = 1) where T <: Union{AbstractFloat, Signed}
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end
    
    #Specialized versions
    function setindex!(buffer::Buffer, value::Float32, index::Int32, channel::Int32 = Int32(1))
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, value, Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Float64, index::Int32, channel::Int32 = Int32(1))
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Float32, index::Int32, channel::Int64 = 1)
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, value, Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Float64, index::Int32, channel::Int64 = 1)
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Float32, index::Int64, channel::Int32 = Int32(1))
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, value, Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Float64, index::Int64, channel::Int32 = Int32(1))
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Float32, index::Int64, channel::Int64 = 1)
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, value, Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Float64, index::Int64, channel::Int64 = 1)
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Int32, index::Int32, channel::Int32 = Int32(1))
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Int64, index::Int32, channel::Int32 = Int32(1))
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Int32, index::Int32, channel::Int64 = 1)
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Int64, index::Int32, channel::Int64 = 1)
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Int32, index::Int64, channel::Int32 = Int32(1))
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Int64, index::Int64, channel::Int32 = Int32(1))
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Int32, index::Int64, channel::Int64 = 1)
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    function setindex!(buffer::Buffer, value::Int64, index::Int64, channel::Int64 = 1)
        ccall(:jl_set_float_value_SC_buffer, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, Float32(value), Int(index), Int(channel))
        return nothing
    end

    #Length of each frame
    function length(buffer::Buffer)
        return ccall(:jl_get_frames_SC_buffer, Cint, (Ptr{Cvoid},), buffer.snd_buf)
    end
    
    #Returns total size (snd_buf->samples)
    function size(buffer::Buffer)
        return ccall(:jl_get_samples_SC_buffer, Cint, (Ptr{Cvoid},), buffer.snd_buf)
    end

    #Number of channels
    function nchans(buffer::Buffer)
        return ccall(:jl_get_channels_SC_buffer, Cint, (Ptr{Cvoid},), buffer.snd_buf)
    end

    #Samplerate (Float64)
    function samplerate(buffer::Buffer)
        return ccall(:jl_get_samplerate_SC_buffer, Cdouble, (Ptr{Cvoid},), buffer.snd_buf)
    end

    #Sampledur (Float64)
    function sampledur(buffer::Buffer)
        return ccall(:jl_get_sampledur_SC_buffer, Cdouble, (Ptr{Cvoid},), buffer.snd_buf)
    end

end