module JuliaDef

    export __JuliaDef__
    
    #Mirrored to JuliaObject in C
    struct __JuliaDef__
        evaluated_module::Base.RefValue{Module}
        ugen_ref_fun::Base.RefValue{Function}
        constructor_fun::Base.RefValue{Function}
        perform_fun::Base.RefValue{Function}
        destructor_fun::Base.RefValue{Function}
        ugen_ref_instance::Base.RefValue{Core.MethodInstance}
        constructor_instance::Base.RefValue{Core.MethodInstance}
        perform_instance::Base.RefValue{Core.MethodInstance}
        destructor_instance::Base.RefValue{Core.MethodInstance}
        
        #Should I construct it with Base.RefValue{Module}, Base.RefValue{Function} directly??
        #Module, Function and MethodInstance are just pointers, anyway...
        function __JuliaDef__(e::Module, u_f::Function, c_f::Function, p_f::Function, d_f::Function, u_i::Core.MethodInstance, c_i::Core.MethodInstance, p_i::Core.MethodInstance, d_i::Core.MethodInstance)
            e_r::Base.RefValue{Module}     = Base.RefValue{Module}(e)
            u_f_r::Base.RefValue{Function} = Base.RefValue{Function}(u_f)
            c_f_r::Base.RefValue{Function} = Base.RefValue{Function}(c_f)
            p_f_r::Base.RefValue{Function} = Base.RefValue{Function}(p_f)
            d_f_r::Base.RefValue{Function} = Base.RefValue{Function}(d_f)
            u_i_r::Base.RefValue{Core.MethodInstance} = Base.RefValue{Core.MethodInstance}(u_i)
            c_i_r::Base.RefValue{Core.MethodInstance} = Base.RefValue{Core.MethodInstance}(c_i)
            p_i_r::Base.RefValue{Core.MethodInstance} = Base.RefValue{Core.MethodInstance}(p_i)
            d_i_r::Base.RefValue{Core.MethodInstance} = Base.RefValue{Core.MethodInstance}(d_i)
            
            return new(e_r, u_f_r, c_f_r, p_f_r, d_f_r, u_i_r, c_i_r, p_i_r, d_i_r)
        end
    end
end