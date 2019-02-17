using Test
using JuliaCollider

#=
#=To be called at Julia initialization to access __SCSynth__ and @object.
When doing tests outside of the Julia build, below should be "using Main.JuliaCollider..." =#
using JuliaCollider.SCSynth
using JuliaCollider.UGenObjectMacro

@object Sine begin
    @inputs 1 ("frequency")
    @outputs 2

    #Declaration of structs (possibly, include() calls aswell)
    mutable struct Phasor
        p::Float64
        function Phasor()
            return new(0.0)
        end
    end

    #initialization of variables
    @constructor begin
        phasor::Phasor = Phasor()
        counter::Float64 = 1.0

        #Must always be last.
        @new(phasor, counter)
    end

    @perform begin
        sampleRate::Float64 = @sampleRate()

        frequency_kr::Float64 = @in0(1)

        @sample begin
            phase::Float64 = @unit(phasor.p) #equivalent to __unit__.phasor.p
            
            frequency::Float64 = @in(1)
            
            if(phase >= 1.0)
                phase = 0.0
            end
            
            out_value::Float64 = cos(phase * 2pi)
            
            @out(1) = out_value
            
            phase += frequency / (sampleRate - 1)
            
            @unit(phasor.p) = phase
        end
    end

    #used to RTFree buffers
    @destructor begin end
end

ins = 440 * ones(Float32, 1, 512) #frequency = 440hz
outs = zeros(Float32, 1, 512)
obj = Sine.__constructor__()
scsynth = __SCSynth__(44100.0, Int32(512))

using BenchmarkTools

#They should have same speed... even with the test on @unit.
@benchmark Sine.__perform__(obj, ins, outs, scsynth)
=#