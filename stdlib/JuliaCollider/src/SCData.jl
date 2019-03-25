#= Module for memory allocation using SC's RTAlloc/RTFree callbacks =#
    module SCData

    export Data, __DataFree__, nchans

    #Have specialized Data for Float32, Float64 ???

    #It needs to be mutable to set data.ptr = C_NULL.
    #I could actually maybe remove that line if no finalizers are ran anyway...
    struct Data{T, N}
        ptr::Ptr{T}
        vec::Array{T, N}
        length::Signed
        num_chans::Signed
    end

    #RTFree() called in destructor.
    #I could have a global id dict with Data objects that might need to be freed, instead
    #of using finalizers...
    function __DataFree__(data::Data) 
        #If valid memory
        if(data.ptr != C_NULL)
            println("*** RTFree data ***")
            
            #RTFree call
            ccall(:jl_rtfree_sc, Cvoid, (Ptr{Cvoid},), data.ptr)
            
            #data.ptr would now be pointing at a wrong memory location, since it's been freed. 
            #Set ptr to NULL
            #data.ptr = C_NULL
        end
    end

    #= 
    The code for finalizers could be lead to errors:
        size_t last_age = jl_get_ptls_states()->world_age;
        jl_get_ptls_states()->world_age = jl_world_counter;
        jl_apply(args, 2);
        jl_get_ptls_states()->world_age = last_age;
    =#

    function Data(type::DataType, length::Signed, num_chans::Signed = 1)
        if(!(type <: Signed) && !(type <: AbstractFloat))
            error("Data: only Signed and AbstractFloat subtypes are supported")
            return nothing
        end

        if(!(isconcretetype(type)))
            error("Data: only concrete types are supported")
            return nothing
        end
        
        if(length <= 0)
            error("Data: length must be a positive non-zero value")
            return nothing
        end

        if(num_chans <= 0)
            error("Data: number of channels must be a positive non-zero value")
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
            
            #Construct a Data object
            data_1d::Data{type, 1} = Data{type, 1}(ptr, vec_1d, length, num_chans)

            #Register finalizer
            #finalizer(__DataFinalizer__, data_1d)

            return data_1d
        else
            #Wrap ptr in a 2d array
            vec_2d::Array{type, 2} = unsafe_wrap(Array{type, 2}, ptr, (num_chans, length))

            #Construct a Data object
            data_2d::Data{type, 2} = Data{type, 2}(ptr, vec_2d, length, num_chans)

            #Register finalizer
            #finalizer(__DataFinalizer__, data_2d)

            return data_2d
        end
    end

    #Expand Base functions for Data
    import Base.getindex
    import Base.setindex!
    import Base.size
    import Base.length

    #= Add bounds checking in here too??? =#
    
    ##############
    #= GETINDEX =#
    ##############

    #1d
    function getindex(data::Data{T, 1}, index::Int32) where T <: Union{AbstractFloat, Signed}
        return Base.getindex(data.vec, index)
    end

    function getindex(data::Data{T, 1}, index::Int64) where T <: Union{AbstractFloat, Signed}
        return Base.getindex(data.vec, index)
    end

    #2d
    function getindex(data::Data{T, 2}, index1::Int32, index2::Int32) where T <: Union{AbstractFloat, Signed}
        return Base.getindex(data.vec, index1, index2)
    end

    function getindex(data::Data{T, 2}, index1::Int32, index2::Int64) where T <: Union{AbstractFloat, Signed}
        return Base.getindex(data.vec, index1, index2)
    end

    function getindex(data::Data{T, 2}, index1::Int64, index2::Int32) where T <: Union{AbstractFloat, Signed}
        return Base.getindex(data.vec, index1, index2)
    end

    function getindex(data::Data{T, 2}, index1::Int64, index2::Int64) where T <: Union{AbstractFloat, Signed}
        return Base.getindex(data.vec, index1, index2)
    end

    ##############
    #= SETINDEX =#
    ##############

    #1d, AbstractFloat
    function setindex!(data::Data{T, 1}, value::Z, index::Int32) where {T <: AbstractFloat, Z <: AbstractFloat}
        return Base.setindex!(data.vec, value, index)
    end

    function setindex!(data::Data{T, 1}, value::Z, index::Int64) where {T <: AbstractFloat, Z <: AbstractFloat}
        return Base.setindex!(data.vec, value, index)
    end

    #1d, Signed
    function setindex!(data::Data{T, 1}, value::Z, index::Int32) where {T <: Signed, Z <: Signed}
        return Base.setindex!(data.vec, value, index)
    end

    function setindex!(data::Data{T, 1}, value::Z, index::Int64) where {T <: Signed, Z <: Signed}
        return Base.setindex!(data.vec, value, index)
    end

    #2d, Same type
    function setindex!(data::Data{T, 2}, value::T, index1::Int32, index2::Int32) where T <: Union{AbstractFloat, Signed}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::T, index1::Int32, index2::Int64) where T <: Union{AbstractFloat, Signed}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::T, index1::Int64, index2::Int32) where T <: Union{AbstractFloat, Signed}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::T, index1::Int64, index2::Int64) where T <: Union{AbstractFloat, Signed}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    #2d, AbstractFloat
    function setindex!(data::Data{T, 2}, value::Z, index1::Int32, index2::Int32) where {T <: AbstractFloat, Z <: AbstractFloat}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::Z, index1::Int32, index2::Int64) where {T <: AbstractFloat, Z <: AbstractFloat}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::Z, index1::Int64, index2::Int32) where {T <: AbstractFloat, Z <: AbstractFloat}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::Z, index1::Int64, index2::Int64) where {T <: AbstractFloat, Z <: AbstractFloat}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    #2d, Signed
    function setindex!(data::Data{T, 2}, value::Z, index1::Int32, index2::Int32) where {T <: Signed, Z <: Signed}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::Z, index1::Int32, index2::Int64) where {T <: Signed, Z <: Signed}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::Z, index1::Int64, index2::Int32) where {T <: Signed, Z <: Signed}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    function setindex!(data::Data{T, 2}, value::Z, index1::Int64, index2::Int64) where {T <: Signed, Z <: Signed}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    #General versions
    function setindex!(data::Data{T, 1}, value::Z, index::Signed) where {T <: Union{AbstractFloat, Signed}, Z <: Union{AbstractFloat, Signed}}
        return Base.setindex!(data.vec, value, index)
    end

    function setindex!(data::Data{T, 2}, value::Z, index1::Signed, index2::Signed) where {T <: Union{AbstractFloat, Signed}, Z <: Union{AbstractFloat, Signed}}
        return Base.setindex!(data.vec, value, index1, index2)
    end

    ##############
    #=  OTHERS  =#
    ##############

    function length(data::Data{T, 1}) where T <: Union{AbstractFloat, Signed}
        return data.length
    end

    function length(data::Data{T, 2}) where T <: Union{AbstractFloat, Signed}
        return data.length
    end

    function nchans(data::Data{T, 1}) where T <: Union{AbstractFloat, Signed}
        return data.num_chans
    end

    function nchans(data::Data{T, 2}) where T <: Union{AbstractFloat, Signed}
        return data.num_chans
    end

    #1d == length(size)
    function size(data::Data{T, 1}) where T <: Union{AbstractFloat, Signed}
        return data.length
    end

    #2d == length * nchans
    function size(data::Data{T, 2}) where T <: Union{AbstractFloat, Signed}
        return data.length * data.num_chans
    end
end