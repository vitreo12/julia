module UGenObjectMacro

export @object

macro object(name, body)
    
    #A quoted block expression for all the body of @object
    local julia_code = Expr(:quote, :($body))
    local quoted_julia_code = julia_code.args[1]
    #println(quoted_julia_code)

    #=
    This macro must be defined in the newly created module for global __args_with_types__ to be seen in that module.
    Gotta find a way to have it on another module and just execute the global variable in the calling one.
    I could make it local by simply evaluating __args_with_types__ in the function, instead of global
    =#
    local macro_to_get_names_and_types = :(
        macro __get_types__(exs...)
            blk = Expr(:block)
            push!(blk.args, :(global __args_with_types__ = []))
            for ex in exs
                push!(blk.args, :((push!(__args_with_types__, ((Symbol($(string(ex))), typeof($(esc(ex))), ))))))
            end
            return blk
        end
    )

    local macro_to_get_constructor_body = :(
        macro __get_constructor_body__(exs...)
            blk = Expr(:block)
            push!(blk.args, :(global __constructor_body__ = []))
            for ex in exs
                push!(blk.args, :((push!(__constructor_body__, ((Symbol($(string(ex)))))))))
            end
            return blk
        end
    )

    #Expects the global variable args_with_types as the one generated by the @get_types. It's an array of tuples
    local function_to_define_struct = :(
        function __define_struct__()
            extended_args = Any[]
            for arg in __args_with_types__
                var_name = arg[1]
                var_type = arg[2]
                push!(extended_args, :($(var_name)::$(var_type)))
            end

            function_definition = :(
                struct __UGen__
                    $(extended_args...)
                end
            )

            #println(function_definition)
            #to be evaluated...
            return function_definition
        end
    )
    
    #Need to parse the array of Symbols into a Julia list of valid Exprs, replacing values in the same __constructor_body__ global array.
    local function_to_parse_constructor_body = :(
        function __parse_constructor_body__()
            for i = 1 : length(__constructor_body__)
                this_line = __constructor_body__[i]
                __constructor_body__[i] = Base.parse_input_line(String(this_line))
            end
        end
    )

    local function_to_create_outer_constructor = :(
        function __define_constructor__()
            #Get only the names of the arguments out of the __args_with_types__ variable
            args_names = Any[]  
            for arg in __args_with_types__
                var_name = arg[1]
                push!(args_names, :($(var_name)))
            end           
            
            #Return a constructor definition. When calling __constructor__(), a __UGen__() with valid fields would be returned.
            #__constructor_body__ is a global variable in the newly created @object module
            constructor_definition = :(
                function __constructor__(__ins__::Vector{Vector{Float32}}, __server__::__SCSynth__)
                    $(__constructor_body__...)
                    return __UGen__($(args_names...))
                end
            )
            
            #to be evaluated...
            return constructor_definition
        end
    )

    local macro_to_get_perform_body = :(
        macro __get_perform_body__(exs...)
            blk = Expr(:block)
            push!(blk.args, :(global __perform_body__ = []))
            for ex in exs
                push!(blk.args, :((push!(__perform_body__, ((Symbol($(string(ex)))))))))
            end
            return blk
        end
    )

    #Need to parse the array of Symbols into a Julia list of valid Exprs, replacing values in the same __perform_body__ global array.
    local function_to_parse_perform_body = :(
        function __parse_perform_body__()
            for i = 1 : length(__perform_body__)
                this_line = __perform_body__[i]
                __perform_body__[i] = Base.parse_input_line(String(this_line))
            end
        end
    )

    local function_to_create_perform = :(
        function __define_perform__()
            
            unroll_constructor_variables_perform = Any[]  
            
            for arg in __args_with_types__
                var_name = arg[1]
                var_type = arg[2]
                push!(unroll_constructor_variables_perform, :($(var_name)::$(var_type) = __unit__.$(var_name)))

                #################################
                #SPECIAL CASE: recursive search:#
                #################################

                #================================================#
                #================================================#
                #= IT WORKS, BUT IT SLOWS THINGS QUITE A BIT... =# 
                #================================================#
                #================================================#

                #================================================#
                #================================================#
                #= ALSO, IT ALLOCATES A LOT OF MEMORY!!!!!!!... =# 
                #================================================#
                #================================================#

                #Recursively find Buffer for this var_name/var_type. It expects that the full
                #var_type is defined, up until Buffer.
                final_path_buffer::Vector{Symbol} = __find_data_type__(SCBuffer.Buffer, var_name, var_type)

                #If not empty, push it to unroll_constructor_variables_destructor
                if(!isempty(final_path_buffer))
                    for this_final_path in final_path_buffer
                        #Since the Vector{Symbol} returned is not parsed, I need to parse it in here to create a valid Expr
                        if(Main.__SUPERNOVA__ == 0) #scsynth
                            push!(unroll_constructor_variables_perform, Base.parse_input_line("__get_SC_buffer__(__unit__.$(this_final_path), __ins__[__unit__.$(this_final_path).input_num][1])"))
                        else                        #supernova
                            push!(unroll_constructor_variables_perform, Base.parse_input_line("__get_supernova_buffer_and_lock__(__unit__.$(this_final_path), __ins__[__unit__.$(this_final_path).input_num][1])"))
                        end
                    end
                end

                #######################################################################
                #NORAML CASE: no recursive search (the var_name directly is a Buffer):#
                #######################################################################
                
                #= If it's a Buffer, also run the __get_SC_buffer__ command for the specific input that's been set in Buffer constructor (Buffer.input_num)
                There is no need to do input checking, as it's outside the @sample macro (where access is @inbounds), and, thus, it's boundschecked =#
                if(var_type <: Buffer)
                    if(Main.__SUPERNOVA__ == 0) #scsynth
                        push!(unroll_constructor_variables_perform, :(__get_SC_buffer__($(var_name), __ins__[$(var_name).input_num][1])))
                    else                        #supernova
                        push!(unroll_constructor_variables_perform, :(__get_supernova_buffer_and_lock__($(var_name), __ins__[$(var_name).input_num][1])))
                    end
                end
            end   

            #User can now access __unit__ elements by simply calling them. They have been unrolled in the unroll_constructor_variables array
            perform_definition = :(
                function __perform__(__unit__::__UGen__, __ins__::Vector{Vector{Float32}}, __outs__::Vector{Vector{Float32}}, __buffer_size__::Int32, __server__::__SCSynth__)
                    $(unroll_constructor_variables_perform...)
                    $(__perform_body__...) #it is a global variable in this module
                    return nothing
                end
            )

            return perform_definition
        end
    )

    local function_to_create_destructor = :(
        function __define_destructor__()
            
            unroll_constructor_variables_destructor = Any[]  
            
            for arg in __args_with_types__
                var_name = arg[1]
                var_type = arg[2]

                #################################
                #SPECIAL CASE: recursive search:#
                #################################

                #================================================#
                #================================================#
                #= IT WORKS, BUT IT SLOWS THINGS QUITE A BIT... =# 
                #================================================#
                #================================================#

                #================================================#
                #================================================#
                #= ALSO, IT ALLOCATES A LOT OF MEMORY!!!!!!!... =# 
                #================================================#
                #================================================#
                
                #Recursively find Data for this var_name/var_type. It expects that the full
                #var_type is defined, up until Data.
                final_path_data::Vector{Symbol} = __find_data_type__(SCData.Data, var_name, var_type)

                #If not empty, push it to unroll_constructor_variables_destructor. 
                if(!isempty(final_path_data))
                    for this_final_path in final_path_data
                        #Since the Symbol returned is not parsed, I need to parse it in here to create a valid Expr
                        push!(unroll_constructor_variables_destructor, Base.parse_input_line("__DataFree__(__unit__.$(this_final_path))")) 
                    end
                end

                #####################################################################
                #NORAML CASE: no recursive search (the var_name directly is a Data):#
                #####################################################################

                #Insert the __DataFree__ to free all allocated Data when calling destructor
                if(var_type <: Data)
                    push!(unroll_constructor_variables_destructor, :(__DataFree__(__unit__.$(var_name))))
                end

                #supernova, unlock the locked buffer. Perhaps, it's kind of memory expensive to run a second __find_data_type__ functions here ...
                if(Main.__SUPERNOVA__ == 1)

                    #################################
                    #SPECIAL CASE: recursive search:#
                    #################################

                    final_path_buffer::Vector{Symbol} = __find_data_type__(SCBuffer.Buffer, var_name, var_type)

                    if(!isempty(final_path_buffer))
                        for this_final_path in final_path_buffer
                            #Since the Vector{Symbol} returned is not parsed, I need to parse it in here to create a valid Expr
                            push!(unroll_constructor_variables_perform, Base.parse_input_line("__unlock_supernova_buffer__(__unit__.$(this_final_path))"))
                        end
                    end

                    #######################################################################
                    #NORAML CASE: no recursive search (the var_name directly is a Buffer):#
                    #######################################################################

                    if(var_type <: Buffer)
                        push!(unroll_constructor_variables_perform, :(__unlock_supernova_buffer__(__unit__.$(var_name))))
                    end
                end
                
            end 

            destructor_definition = :(
                function __destructor__(__unit__::__UGen__)
                    $(unroll_constructor_variables_destructor...)
                    return nothing
                end
            )
            
            return destructor_definition
        end
    )

    #unique_id used when retrieving a JuliaDef by name
    local unique_id_def_and_setter = quote
        global __unique_id__ = -1
        
        function __set_unique_id__(val::Int32)
            global __unique_id__ = val
        end
    end

    #Used in global_object_id_dict for each object to be added to global_object_id_dict table
    local ugen_ref_definition = :(
        struct __UGenRef__
            object::Base.RefValue{__UGen__}
            
            ins::Base.RefValue{Vector{Vector{Float32}}}
            outs::Base.RefValue{Vector{Vector{Float32}}}

            #= Should I also keep the module itself alive?? =#
            destructor_fun::Base.RefValue{Function}
            destructor_instance::Base.RefValue{Core.MethodInstance}

            function __UGenRef__(o::__UGen__, i_v::Vector{Vector{Float32}}, o_v::Vector{Vector{Float32}}, d_f::Function, d_i::Core.MethodInstance)
                o_r::Base.RefValue{__UGen__} = Base.RefValue{__UGen__}(o)
                
                i_v_r::Base.RefValue{Vector{Vector{Float32}}} = Base.RefValue{Vector{Vector{Float32}}}(i_v)
                o_v_r::Base.RefValue{Vector{Vector{Float32}}} = Base.RefValue{Vector{Vector{Float32}}}(o_v)
                
                d_f_r::Base.RefValue{Function} = Base.RefValue{Function}(d_f)
                d_i_r::Base.RefValue{Core.MethodInstance} = Base.RefValue{Core.MethodInstance}(d_i)

                return new(o_r, i_v_r, o_v_r, d_f_r, d_i_r)
            end
        end
    )
    
    local set_index_ugen_ref = :(
        function set_index_ugen_ref(id_dict::IdDict{Any, Any}, ugen_ref::__UGenRef__)
            setindex!(id_dict, ugen_ref, ugen_ref)
        end
    )

    local delete_index_ugen_ref = :(
        function delete_index_ugen_ref(id_dict::IdDict{Any, Any}, ugen_ref::__UGenRef__)
            delete!(id_dict, ugen_ref)
        end
    )

    #Actual module definition
    local module_name = name
    local module_definition = :(
        module $module_name
            #= The "JuliaCollider" module is in the Main namespace as it is precompiled inside the sysimg.
            When testing outside of the Julia build, below macros should be "using Main.JuliaCollider..." =#
            
            #@inputs, @outputs, etc...
            using JuliaCollider.UGenMacros
            #using Main.JuliaCollider.UGenMacros

            #SCUtilities
            using JuliaCollider.SCUtilities
            #using Main.JuliaCollider.SCUtilities
            
            #__SCSynth__
            import JuliaCollider.SCSynth.__SCSynth__
            #import Main.JuliaCollider.SCSynth.__SCSynth__

            #Data
            using JuliaCollider.SCData
            import JuliaCollider.SCData.Data
            #using Main.JuliaCollider.SCData
            #import Main.JuliaCollider.SCData.Data

            #Buffer
            using JuliaCollider.SCBuffer
            import JuliaCollider.SCBuffer.Buffer
            #using Main.JuliaCollider.SCBuffer
            #import Main.JuliaCollider.SCBuffer.Buffer
            
            #Inner macros definitions
            $macro_to_get_names_and_types
            $macro_to_get_constructor_body
            
            #Inner function definitions for creating __UGen__ struct and its constructor
            $function_to_define_struct
            $function_to_parse_constructor_body
            $function_to_create_outer_constructor
            
            #__perform__
            $macro_to_get_perform_body
            $function_to_parse_perform_body
            $function_to_create_perform

            #__destructor__
            $function_to_create_destructor
            
            #Actual body of @object
            $quoted_julia_code
            
            #Unique_id
            $unique_id_def_and_setter

            #__UGenRef__ definition
            $ugen_ref_definition

            #setindex! and delete! for __UGenRef__
            $set_index_ugen_ref
            $delete_index_ugen_ref
        end
    )
    
    #The actual module creation Expr. Evaluate at toplevel (Main)
    local create_module = Expr(:toplevel, module_definition)

    return esc(:($create_module))
end

end