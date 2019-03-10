module SCSynth

export __SCSynth__, set_index_audio_vector

struct __SCSynth__
    sampleRate::Float64
    bufferSize::Int32
end

function set_index_audio_vector(vec::Vector{Vector{Float32}}, vec1d::Vector{Float32}, index::Int32)
    setindex!(vec, vec1d, index)
end

end