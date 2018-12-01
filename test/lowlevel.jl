@testset "Testing Low Level API" begin
    # For convenience sake
    LowLevel = PAPI.LowLevel
    PAPIError = PAPI.PAPIBase.PAPIError

    # Initialization should have been performed through the low level API at application
    # startup
    @test LowLevel.is_initialized() == PAPI.PAPIBase.LOW_LEVEL_INITED

    #####
    ##### Test 1 - Event Codes
    #####

    # Make sure all the event codes are correct
    for event in instances(PAPI.Event)
        # Skip the "END" event - not entirely sure what's going on here but apparently
        # it belongs but is actually not an event ...

        event == PAPI.END && continue
        code = LowLevel.event_name_to_code("PAPI_$event")
        @test code == Int(event)
    end

    #####
    ##### Test 2 - Query current process
    #####

    let
        # Parameters
        nevents = 1
        nfloats = 1000000

        # Create an eventset
        eventset = LowLevel.create_eventset()

        # Perform some queries on the state of the eventset
        state = LowLevel.state(eventset)
        @test LowLevel.stopped(state) == true
        @test LowLevel.cpu_attached(state) == false
        @test LowLevel.running(state) == false

        # Make the the "TOT_INS" instruction exists and add it to the eventset
        @test LowLevel.query_event(Int32(PAPI.TOT_INS)) == PAPI.PAPIBase.OK
        LowLevel.add_event(eventset, Int32(PAPI.TOT_INS))

        # Precompile the "sum" function
        arr = rand(Float64, nfloats)
        y = sum(arr)

        values = zeros(Int64, nevents)
        LowLevel.start(eventset)
        y = sum(arr)
        LowLevel.stop(eventset, values)

        # Number of executed instructions should be greater than the number of floats
        @show values
        @test first(values) > nfloats

        # Since the profiling is stopped, if we read again, we should get the same
        # results
        oldvalues = copy(values)
        LowLevel.read(eventset, values)
        @test values == oldvalues

        # Reset and verify that counters start again
        LowLevel.reset(eventset)
        y = sum(arr)
        LowLevel.read(eventset, values)
        @show values
        @test first(values) > nfloats

        # Make sure that if we try to destroy the eventset without stopping it, we get
        # an error
        @test_throws PAPIError LowLevel.destroy_eventset(eventset)
        LowLevel.stop(eventset, values)

        # Should still through because we haven't cleaned up the eventset
        @test_throws PAPIError LowLevel.destroy_eventset(eventset)
        LowLevel.cleanup_eventset(eventset)
        LowLevel.destroy_eventset(eventset)
    end

    #####
    ##### Test 3 - Attach to another PID for third party monitoring
    #####

    let
        # Test parameters
        sleeptime = 1 # seconds
        iterations = 5
        nevents = 1

        # Create a new eventset
        eventset = LowLevel.create_eventset()

        # Attach the eventset to the CPU
        LowLevel.assign_eventset_component(eventset, Int32(0))

        # Launch an external process
        pid, process, _ = launch("sleep $(iterations * sleeptime)")
        LowLevel.attach(eventset, pid)
        LowLevel.add_event(eventset, PAPI.TOT_INS)
        LowLevel.start(eventset)

        # Run some queries
        state = LowLevel.state(eventset)
        @test LowLevel.running(state) == true
        @test LowLevel.attached(state) == true

        values = zeros(Int64, nevents)
        for i in 1:iterations
            sleep(sleeptime)

            LowLevel.read(eventset, values)
            LowLevel.reset(eventset)
            # Number of instruction executed should be pretty small
            @show values
            @test first(values) < 10000 
        end

        LowLevel.stop(eventset, values)

        LowLevel.cleanup_eventset(eventset)
        LowLevel.destroy_eventset(eventset)
    end
end
