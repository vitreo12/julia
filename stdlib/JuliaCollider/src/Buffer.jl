#= Module for pointers to SC buffers =#
module Buffer

    export __Buffer__, get_shared_buf, nchans

    #= I COULD JUST HAVE THE snd_buf* pointer =#
    mutable struct __Buffer__
        SCWorld::Ptr{Cvoid}
        snd_buf::Ptr{Cvoid}
        bufnum::Float32
    end

    function __Buffer__()
        SCWorld::Ptr{Cvoid} = ccall(:jl_get_SCWorld, Ptr{Cvoid}, ())
        if(SCWorld == C_NULL)
            error("Invalid SCWorld")
            return nothing
        end
        
        snd_buf::Ptr{Cvoid} = C_NULL

        bufnum::Float32 = Float32(-1e9)

        return __Buffer__(SCWorld, snd_buf, bufnum)
    end

    #= THESE FUNCTIONS ARE ALL DEFINED IN Julia.cpp =#

    #Returns Nothing
    function get_shared_buf(buffer::__Buffer__, bufnum::Float32)
        ccall(:jl_get_buf_shared_SC, Cvoid, (Any, Cfloat), buffer, bufnum)
    end

    import Base.getindex
    import Base.setindex!
    import Base.length
    import Base.size
    
    #Returns Float32
    function getindex(buffer::__Buffer__, index::Signed, channel::Signed = 1)
        return ccall(:jl_get_float_value_buf_SC, Cfloat, (Ptr{Cvoid}, Int, Int), buffer.snd_buf, index, channel)
    end

    #Returns Nothing
    function setindex!(buffer::__Buffer__, value::AbstractFloat, index::Signed, channel::Signed = 1)
        ccall(:jl_set_float_value_buf_SC, Cvoid, (Ptr{Cvoid}, Cfloat, Int, Int), buffer.snd_buf, value, index, channel)
        return nothing
    end

    #Length of each frame
    function length(buffer::__Buffer__)
        return ccall(:jl_get_frames_buf_SC, Cint, (Ptr{Cvoid},), buffer.snd_buf)
    end
    
    #Returns total size (snd_buf->samples)
    function size(buffer::__Buffer__)
        return ccall(:jl_get_samples_buf_SC, Cint, (Ptr{Cvoid},), buffer.snd_buf)
    end

    #Number of channels
    function nchans(buffer::__Buffer__)
        return ccall(:jl_get_channels_buf_SC, Cint, (Ptr{Cvoid},), buffer.snd_buf)
    end

end