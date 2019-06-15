module JuliaDef

    export __JuliaDef__
    
    #Mirrored to JuliaObject in C
    struct __JuliaDef__
        #= Module contains the functions aswell. No need to include those too =#
        evaluated_module::Base.RefValue{Module}
        
        #= MethodInstance table for this JuliaDef =#
        ugen_ref_instance::Base.RefValue{Core.MethodInstance}
        constructor_instance::Base.RefValue{Core.MethodInstance}
        perform_instance::Base.RefValue{Core.MethodInstance}
        destructor_instance::Base.RefValue{Core.MethodInstance}
        set_index_ugen_ref_instance::Base.RefValue{Core.MethodInstance}
        delete_index_ugen_ref_instance::Base.RefValue{Core.MethodInstance}
        
        #Should I construct it with Base.RefValue{Module}, Base.RefValue{Function} directly??
        #Module, Function and MethodInstance are just pointers, anyway...
        function __JuliaDef__(e::Module, u_i::Core.MethodInstance, c_i::Core.MethodInstance, p_i::Core.MethodInstance, d_i::Core.MethodInstance, s_i_i::Core.MethodInstance, d_i_i::Core.MethodInstance)
            e_r::Base.RefValue{Module}                    = Base.RefValue{Module}(e)
            u_i_r::Base.RefValue{Core.MethodInstance}     = Base.RefValue{Core.MethodInstance}(u_i)
            c_i_r::Base.RefValue{Core.MethodInstance}     = Base.RefValue{Core.MethodInstance}(c_i)
            p_i_r::Base.RefValue{Core.MethodInstance}     = Base.RefValue{Core.MethodInstance}(p_i)
            d_i_r::Base.RefValue{Core.MethodInstance}     = Base.RefValue{Core.MethodInstance}(d_i)
            s_i_i_r::Base.RefValue{Core.MethodInstance}   = Base.RefValue{Core.MethodInstance}(s_i_i)
            d_i_i_r::Base.RefValue{Core.MethodInstance}   = Base.RefValue{Core.MethodInstance}(d_i_i)

            return new(e_r, u_i_r, c_i_r, p_i_r, d_i_r, s_i_i_r, d_i_i_r)
        end
    end
end