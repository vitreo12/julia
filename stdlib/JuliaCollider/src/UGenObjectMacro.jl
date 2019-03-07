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
    
    #Need to parse the array of Symbols...
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
                function __constructor__()
                    $(__constructor_body__...)
                    return __UGen__($(args_names...))
                end
            )
            
            #println(constructor_definition)
            #to be evaluated...
            return constructor_definition
        end
    )

    #struct that will hold num of inputs, outputs, name, to be sent to sclang
    local ugen_graph_definition = :(
        struct __UGenGraph__
            name::Symbol
            inputs::Int32
            input_names
            outputs::Int32
            output_names
        end
    )
    
    #inputs and outputs will already be declared at this point...
    local create_ugen_graph = :(__ugen_graph__ = __UGenGraph__(nameof($name), __inputs__, __input_names__, __outputs__, __output_names__))

    #unique_id used when retrieving a JuliaDef by name
    local unique_id_def_and_setter = quote
        global __unique_id__ = -1
        
        function __set_unique_id__(val::Int64)
            global __unique_id__ = val
        end
    end

    #Actual module definition
    local module_name = name
    local module_definition = :(
        module $module_name
            #= The "JuliaCollider" module is in the Main namespace as it is precompiled inside the sysimg.
            When testing outside of the Julia build, below macros should be "using Main.JuliaCollider..." =#
            
            #@inputs, @outputs, etc...
            using JuliaCollider.UGenMacros
            #using Main.JuliaCollider.UGenMacros
            
            #__SCSynth__
            import JuliaCollider.SCSynth.__SCSynth__
            #import Main.JuliaCollider.SCSynth.__SCSynth__
            
            #inner macros definitions
            $macro_to_get_names_and_types
            $macro_to_get_constructor_body
            
            #inner function definitions for creating __UGen__ struct and its constructor
            $function_to_define_struct
            $function_to_create_outer_constructor
            $function_to_parse_constructor_body
            
            #__UGenGraph__ definition
            $ugen_graph_definition
            
            #Actual body of @object
            $quoted_julia_code
            
            #Create __UGenGraph__
            $create_ugen_graph
            
            #Unique_id
            $unique_id_def_and_setter
        end
    )
    
    #The actual module creation Expr. Evaluate at toplevel (Main)
    local create_module = Expr(:toplevel, module_definition)

    return esc(:($create_module))
end

end