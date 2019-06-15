module IORef
    export __IORef__, set_index_io_ref, delete_index_io_ref

    #Executed once per UGen. It will keep alive the ins/outs of the UGen.
    struct __IORef__
        input_vector::Base.RefValue{Vector{Vector{Float32}}}
        output_vector::Base.RefValue{Vector{Vector{Float32}}}

        function __IORef__(i_v::Vector{Vector{Float32}}, o_v::Vector{Vector{Float32}})
            i_v_r::Base.RefValue{Vector{Vector{Float32}}} = Base.RefValue{Vector{Vector{Float32}}}(i_v)
            o_v_r::Base.RefValue{Vector{Vector{Float32}}} = Base.RefValue{Vector{Vector{Float32}}}(o_v)

            return new(i_v_r, o_v_r)
        end
    end

    function set_index_io_ref(id_dict::IdDict{Any, Any}, io_ref::__IORef__)
        setindex!(id_dict, io_ref, io_ref)
    end

    function delete_index_io_ref(id_dict::IdDict{Any, Any}, io_ref::__IORef__)
        delete!(id_dict, io_ref)
    end
end