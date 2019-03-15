module UGenMacros

export @inputs, @outputs, @constructor, @new, @perform, @sample, @sample_index, @destructor, @unit, @in0, @in, @out, @sampleRate, @bufSize

#All these macros need to be ran by an eval() call in the respective module
macro inputs(num_of_inputs, tuple_input_names)
    local single_string = eval(
        quote
            if($num_of_inputs > 32)
                error("@inputs: too many inputs. Max is 32")
                return false
            end
            if($num_of_inputs < 0)
                error("@inputs: Negative values aren't supported. Minimum is 0")
                return false
            end
            if(isa($tuple_input_names, String)) #if tuple_input_names is a single string, make a Tuple out of it
                if($num_of_inputs > 1)
                    error("@inputs: different number of inputs and parameter names")
                    return false
                end
                return true
            else
                if($num_of_inputs != length($tuple_input_names))
                    error("@inputs: different number of inputs and parameter names")
                    return false
                end
                if(!isa($tuple_input_names, NTuple{$num_of_inputs, String}))
                    error("@inputs: parameter names are not a tuple of strings")
                    return false
                end
            end
            return false
        end
    )

    #global macro variable to be used to check input access in @in0, @in
    global __macro_inputs_count__ = num_of_inputs;
    
    local inputs_expr = :(const __inputs__ = Int32($num_of_inputs))
    local input_names_expr = :(const __input_names__ = $tuple_input_names)
    if(single_string)
        input_names_expr = :(const __input_names__ = ($tuple_input_names, ))
    end
    
    return esc(:(Expr(:block, $inputs_expr, $input_names_expr)))
end

#Only number of inputs. input_names = "NO_NAMES"
macro inputs(num_of_inputs)
    eval(
        quote
            if($num_of_inputs > 32)
                error("@inputs: too many inputs. Max is 32")
            end
            if($num_of_inputs < 0)
                error("@inputs: Negative values aren't supported. Minimum is 0")
            end
        end
    )

    #global macro variable to be used to check input access in @in0, @in
    global __macro_inputs_count__ = num_of_inputs;

    local inputs_expr = :(const __inputs__ = Int32($num_of_inputs))
    local input_names_expr = :(const __input_names__ = "NO_NAMES") #single string "NO_NAMES".
    return esc(:(Expr(:block, $inputs_expr, $input_names_expr)))
end

macro outputs(num_of_outputs, tuple_output_names)
    local single_string = eval(
        quote
            if($num_of_outputs > 32)
                error("@outputs: too many outputs. Max is 32")
                return false
            end
            if($num_of_outputs < 1)
                error("@outputs: Minimum is 1")
                return false
            end
            if(isa($tuple_output_names, String)) #if tuple_output_names is a single string, make a Tuple out of it
                if($num_of_outputs > 1)
                    error("@outputs: different number of outputs and output names")
                    return false
                end
                return true
            else
                if($num_of_outputs != length($tuple_output_names))
                    error("@outputs: different number of outputs and output names")
                    return false
                end
                if(!isa($tuple_output_names, NTuple{$num_of_outputs, String}))
                    error("@outputs: output names are not a tuple of strings")
                    return false
                end
            end
            return false
        end
    )

    #global macro variable to be used to check output access in @out
    global __macro_outputs_count__ = num_of_outputs;
    
    local outputs_expr = :(const __outputs__ = Int32($num_of_outputs))
    local output_names_expr = :(const __output_names__ = $tuple_output_names)
    if(single_string)
        output_names_expr = :(const __output_names__ = ($tuple_output_names, ))
    end
    
    return esc(:(Expr(:block, $outputs_expr, $output_names_expr)))
end

#Only number of outputs. output_names = "NO_NAMES"
macro outputs(num_of_outputs)
    eval(
        quote
            if($num_of_outputs > 32)
                error("@outputs: too many outputs. Max is 32")
            end
            if($num_of_outputs < 1)
                error("@outputs: Minimum is 1")
            end
        end
    )

    #global macro variable to be used to check output access in @out
    global __macro_outputs_count__ = num_of_outputs;

    local outputs_expr = :(const __outputs__ = Int32($num_of_outputs))
    local output_names_expr = :(const __output_names__ = "NO_NAMES") #single string "NO_NAMES".
    return esc(:(Expr(:block, $outputs_expr, $output_names_expr)))
end

#The @new macro, actually calls another macro.
macro new(variables...)
    local get_args_with_types = quote
            @__get_types__($(variables...))
    end
    
    #println(variables)
    return esc(:($get_args_with_types))
end

macro constructor(body)
    local body_julia_code = body.args

    #everything else needed in initialization
    local variables_up_to_new = body_julia_code[1 : end - 1]

    #last entry in the @constructor must be a @new call
    local new_macro = body_julia_code[end]

    if (!occursin("@new", String("$new_macro")))
        error("@constructor: body does not end with a call to @new")
    end
    
    local constructor_definition = quote
        #Declare function that would return me the type of the variables in @new
        function __get_args_with_types__()
            $(variables_up_to_new...)
            $new_macro
        end

        #= 
        None of the following functions has arguments, as they act on the two global variables __args_with_types__ and __constructor_body__
        1) __args_with_types__ is defined in @new, which calls @__get_types__
        2) __constructor_body__ is defined in @__get_constructor_body__
        =#

        #execute the function to get the types under the @constructor and @new scopes
        __get_args_with_types__()

        #define __UGen__ struct
        eval(__define_struct__())

        #Pass the julia code to the @__get_constructor_body__ macro that will transform it in an array of symbols stored in the global variable __constructor_body__
        @__get_constructor_body__($(variables_up_to_new...))

        #Parse __constructor_body__ to turn it from Expr to symbols 
        __parse_constructor_body__()

        #define outer constructor according to __constructor_body__
        eval(__define_constructor__())
    end

    #println(constructor_definition)

    return esc(:($constructor_definition))
end

macro perform(arguments)
    local body = arguments.args

    local perform_and_destructor_definitions = quote
        @__get_perform_body__($(body...))

        __parse_perform_body__()

        #Define __perform__ function
        eval(__define_perform__())
        
        #Define __destructor__ function to free Data allocations
        eval(__define_destructor__())
    end

    return esc(:($perform_and_destructor_definitions))
end

#Should @inbounds be here or at every array access? I can't be sure that the user will be accessing his own buffers
macro sample(arguments)
    local body = arguments.args

    local sample_loop = quote
        __unit_range_loop__::UnitRange{Int32} = Int32(1) : __buffer_size__
        @inbounds for __sample_index__ = __unit_range_loop__
            $(body...)
        end
    end
    
    return esc(:($sample_loop))
end

macro sample_index()
    return esc(:(__sample_index__))
end

macro in0(input_number)
    if(input_number > __macro_inputs_count__)
        error("@in0: Input number $input_number out of bounds. Maximum is $__macro_inputs_count__")
    end
    if(input_number < 1)
        error("@in0: Input number $input_number out of bounds. Counting starts from 1")
    end
    
    return esc(:(__ins__[$input_number][1]))
end

macro in(input_number)
    if(input_number > __macro_inputs_count__)
        error("@in: Input number $input_number out of bounds. Maximum is $__macro_inputs_count__")
    end
    if(input_number < 1)
        error("@in: Input number $input_number out of bounds. Counting starts from 1")
    end

    return esc(:(__ins__[$input_number][__sample_index__]))
end

macro out(output_number)
    if(output_number > __macro_outputs_count__)
        error("@out: Output number $output_number out of bounds. Maximum is $__macro_outputs_count__")
    end
    if(output_number < 1)
        error("@out: Output number $output_number out of bounds. Counting starts from 1")
    end

    return esc(:(__outs__[$output_number][__sample_index__]))
end

#=
Quick tip: macros can also be used as standard text replacement with the Base.parse_input_line function.
Simply turn the aruments to strings, do you processing on the string, and just get another Expr out of the string
with Base.parse_input_line.
=#
macro unit(var_name) 
    local get_property = Base.parse_input_line(String("__unit__.$var_name"))
    #Base.parse_input_line already returns an Expr. No need to wrap it in :()
    return esc(get_property) 
end

macro sampleRate()
    return esc(:(__server__.sampleRate))
end

macro bufSize()
    return esc(:(__server__.bufferSize))
end

#= macro destructor(arguments)
    local body = arguments.args

    local destructor_definition = :(
        function __destructor__(__unit__::__UGen__)
            $(body...)
        end
    )

    return esc(:($destructor_definition))
end =#

end