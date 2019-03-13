#= Module for memory allocation using SC's RTAlloc/RTFree callbacks =#
module Data
    export __Data__, __DataFree__, nchans

    #Have specialized __Data__ for Float32, Float64 ???

    #Mutable struct because finalizers only work on mutable structs
    mutable struct __Data__{T, N}
        ptr::Ptr{T}
        vec::Array{T, N}
        length::Signed
        num_chans::Signed
    end

    #RTFree()
    function __DataFree__(data::__Data__) 
        #If valid memory (hasn't been finalized yet)
        if(data.ptr != C_NULL)
            #RTFree call
            ccall(:jl_rtfree_sc, Cvoid, (Ptr{Cvoid},), data.ptr)
            
            #data.ptr would now be pointing at a wrong memory location, since it's been freed. 
            #Set ptr to NULL
            data.ptr = C_NULL
        end
    end

    #In case user forgets to delete data, finalizer will be executed at next GC if UGen has been released.
    function __DataFinalizer__(data::__Data__)
        println("*** FINALIZING data ***")
        
        __DataFree__(data)
    end

    function __Data__(type::DataType, length::Signed, num_chans::Signed = 1)
        if(type.mutable)
            error("__Data__: only immutable types supported")
            return nothing
        end
        
        if(length <= 0)
            error("__Data__: length must be a positive non-zero value")
            return nothing
        end

        if(num_chans <= 0)
            error("__Data__: number of channels must be a positive non-zero value")
            return nothing
        end
        
        alloc_size::Csize_t = (sizeof(type) * length) * num_chans

        #RTAlloc call. jl_rtalloc_sc already initializes memory to 0
        ptr::Ptr{type} = ccall(:jl_rtalloc_sc, Ptr{Cvoid}, (Csize_t,), alloc_size)

        #Return if invalid memory address
        if(ptr == C_NULL) 
            error("Invalid pointer address")
            return nothing
        end

        #1d
        if(num_chans == 1)
            #Wrap ptr in a 1d Array
            vec_1d::Vector{type} = unsafe_wrap(Vector{type}, ptr, length)
            
            #Construct a __Data__ object
            data_1d::__Data__{type, 1} = __Data__{type, 1}(ptr, vec_1d, length, num_chans)

            #Register finalizer
            finalizer(__DataFinalizer__, data_1d)

            return data_1d
        else
            #Wrap ptr in a 2d array
            vec_2d::Array{type, 2} = unsafe_wrap(Array{type, 2}, ptr, (num_chans, length))

            #Construct a __Data__ object
            data_2d::__Data__{type, 2} = __Data__{type, 2}(ptr, vec_2d, length, num_chans)

            #Register finalizer
            finalizer(__DataFinalizer__, data_2d)

            return data_2d
        end
    end

    #Expand Base functions for __Data__
    import Base.getindex
    import Base.setindex!
    import Base.size
    import Base.length

    #= Should I remove boundschecking? =#

    #1d
    function getindex(data::__Data__{T, 1}, index::Signed) where T
        return @boundscheck Base.getindex(data.vec, index)
    end

    #2d
    function getindex(data::__Data__{T, 2}, index1::Signed, index2::Signed) where T
        return @boundscheck Base.getindex(data.vec, index1, index2)
    end

    #1d
    function setindex!(data::__Data__{T, 1}, value::T, index::Signed) where T
        return @boundscheck Base.setindex!(data.vec, value, index)
    end

    #2d
    function setindex!(data::__Data__{T, 2}, value::T, index1::Signed, index2::Signed) where T
        return @boundscheck Base.setindex!(data.vec, value, index1, index2)
    end

    #length(__Data__) == size(__Data__)
    function length(data::__Data__)
        return data.length
    end

    function nchans(data::__Data__)
        return data.num_chans
    end

    #1d == length(size)
    function size(data::__Data__{T, 1}) where T
        return data.length
    end

    #2d == length * nchans
    function size(data::__Data__{T, 2}) where T
        return data.length * nchans
    end

    #macro data() end

    #macro free() end
end