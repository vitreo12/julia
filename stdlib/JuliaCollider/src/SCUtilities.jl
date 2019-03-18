module SCUtilities
    export __find_data_type__

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

    #Maybe get rid of this?
    const UnionAllDataType = Union{UnionAll, DataType}
    
    #Given a var_type::DataType, recursively find if it contains any data_type_to_find::DataType or data_type_to_find::UnionAll (for parametric types)
    function __find_data_type__(data_type_to_find::UnionAllDataType, var_name::Symbol, var_type::UnionAllDataType)

        final_array_symbols::Vector{Symbol} = Vector{Symbol}()

        function __find_field_recursive__(var_type::UnionAllDataType, recursive_string::String)
            count::Int32 = 1

            #Abstract types don't have fieldnames
            if(isabstracttype(var_type) || Base.argument_datatype(var_type) === nothing)
                return
            end
            
            #Field names for this DataType/UnionAll
            field_names::Tuple = fieldnames(var_type)
            
            #DataType
            if(isa(var_type, DataType))
                for this_type = var_type.types
                    #String path for this inner iteration
                    inner_string::String = recursive_string
                    
                    #Found it!
                    if(this_type <: data_type_to_find)
                        inner_string = inner_string * "." * String(field_names[count])
                        
                        #Final result. Found the type we were looking for. Push it to the list.
                        push!(final_array_symbols, Symbol(inner_string))

                        #break 
                    end
                    
                    inner_string = inner_string * "." * String(field_names[count])
                    count += 1
                    __find_field_recursive__(this_type, inner_string)
                end
            else #else, it's a UnionAll. UnionAll has no .types. Need to get them with fieldtype(UnionAll, index)
                for i = 1 : fieldcount(var_type)
                    this_type = fieldtype(var_type, i)
                    
                    #String path for this inner iteration
                    inner_string::String = recursive_string

                    #Found it!
                    if(this_type <: data_type_to_find)
                        inner_string = inner_string * "." * String(field_names[count])
                        
                        #Final result. Found the type we were looking for. Push it to the list.
                        push!(final_array_symbols, Symbol(inner_string))

                        #break
                    end
                    
                    inner_string = inner_string * "." * String(field_names[count])
                    count += 1
                    __find_field_recursive__(this_type, inner_string)
                end
            end
        end

        __find_field_recursive__(var_type, String(var_name))

        return final_array_symbols
    end
end