module SCUtilities
    export __find_data_type__

    #================================================#
    #================================================#
    #= IT WORKS, BUT IT SLOWS THINGS QUITE A BIT... =#
    #================================================#
    #================================================#

    #Given a var_type::DataType, recursively find if it contains any data_type_to_find::DataType or data_type_to_find::UnionAll (for parametric types)
    function __find_data_type__(data_type_to_find::T, var_name::Symbol, var_type::TV) where {T <: Union{UnionAll, DataType}, TV <: Union{UnionAll, DataType}}
        
        final_array_symbols::Vector{Symbol} = Vector{Symbol}()
        
        found_at_least_one::Bool = false

        function __find_field_recursive__(var_type::T, recursive_string::String) where T <: Union{UnionAll, DataType}
            field_names = nothing
            count::Int32 = 1
            
            #Can I get rid of this try/catch here????
            #Some DataTypes have no set fieldnames (like, Signed)
            try
                field_names = fieldnames(var_type)
            catch
                field_names = nothing
            end
            
            #IS try/catch block safer here???? Instead of if/else
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

            #println(final_array_symbols)
            #Not found. Reset String
            #final_array_symbols = String(var_name)
        end

        __find_field_recursive__(var_type, String(var_name))

        return final_array_symbols
    end
end