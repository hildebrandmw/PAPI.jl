@testset "Testing Highlevel API" begin
    @test PAPI.HighLevel.num_counters() > 0
    @test PAPI.HighLevel.num_components() > 0
end
