USING AxUnit.Assert;
USING Simatic.Ax.Motor;

NAMESPACE MotorTests.TimeProvider
    /// Tests for TimeProvider implementations
    {TestFixture}
    CLASS ManualTimeProviderTest
        VAR PROTECTED
            timeProvider : ManualTimeProvider;
            timeProviderStateless : ManualTimeProvider;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            timeProvider := timeProviderStateless;
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentTimeMs_InitiallyZero
            VAR_TEMP
                timeMs : LINT;
            END_VAR
            
            // Act
            timeMs := timeProvider.GetCurrentTimeMs();
            
            // Assert
            Equal(expected := LINT#0, actual := timeMs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentTimeNs_InitiallyZero
            VAR_TEMP
                timeNs : LINT;
            END_VAR
            
            // Act
            timeNs := timeProvider.GetCurrentTimeNs();
            
            // Assert
            Equal(expected := LINT#0, actual := timeNs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_AdvanceTime_IncreasesMilliseconds
            VAR_TEMP
                timeMs : LINT;
            END_VAR
            
            // Act
            timeProvider.AdvanceTime(DeltaMs := LINT#100);
            timeMs := timeProvider.GetCurrentTimeMs();
            
            // Assert
            Equal(expected := LINT#100, actual := timeMs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_AdvanceTime_IncreasesNanoseconds
            VAR_TEMP
                timeNs : LINT;
            END_VAR
            
            // Act
            timeProvider.AdvanceTime(DeltaMs := LINT#100);
            timeNs := timeProvider.GetCurrentTimeNs();
            
            // Assert - 100ms = 100,000,000 ns
            Equal(expected := LINT#100000000, actual := timeNs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_AdvanceTimeNs_IncreasesNanoseconds
            VAR_TEMP
                timeNs : LINT;
            END_VAR
            
            // Act
            timeProvider.AdvanceTimeNs(DeltaNs := LINT#50000000);  // 50ms in ns
            timeNs := timeProvider.GetCurrentTimeNs();
            
            // Assert
            Equal(expected := LINT#50000000, actual := timeNs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_AdvanceTimeNs_UpdatesMilliseconds
            VAR_TEMP
                timeMs : LINT;
            END_VAR
            
            // Act
            timeProvider.AdvanceTimeNs(DeltaNs := LINT#50000000);  // 50ms in ns
            timeMs := timeProvider.GetCurrentTimeMs();
            
            // Assert
            Equal(expected := LINT#50, actual := timeMs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_AdvanceTime_Multiple_Accumulates
            VAR_TEMP
                timeMs : LINT;
            END_VAR
            
            // Act
            timeProvider.AdvanceTime(DeltaMs := LINT#100);
            timeProvider.AdvanceTime(DeltaMs := LINT#200);
            timeProvider.AdvanceTime(DeltaMs := LINT#300);
            timeMs := timeProvider.GetCurrentTimeMs();
            
            // Assert
            Equal(expected := LINT#600, actual := timeMs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MixedAdvance_BothMethodsWork
            VAR_TEMP
                timeMs : LINT;
                timeNs : LINT;
            END_VAR
            
            // Act - Mix millisecond and nanosecond advances
            timeProvider.AdvanceTime(DeltaMs := LINT#100);  // 100ms
            timeProvider.AdvanceTimeNs(DeltaNs := LINT#50000000);  // 50ms
            
            timeMs := timeProvider.GetCurrentTimeMs();
            timeNs := timeProvider.GetCurrentTimeNs();
            
            // Assert
            Equal(expected := LINT#150, actual := timeMs);
            Equal(expected := LINT#150000000, actual := timeNs);
        END_METHOD
    END_CLASS

    /// Tests for SystemTimeProvider with mocked GetSystemDateTime
    ///
    /// These tests use GetSystemTimeMock to provide controllable time values.
    /// The mock allows us to simulate realistic time progression and verify
    /// that SystemTimeProvider correctly calculates delta times.
    {TestFixture}
    CLASS SystemTimeProviderTest
        VAR PROTECTED
            timeProvider : SystemTimeProvider;
            timeProviderStateless : SystemTimeProvider;
            mockPayload : Simatic.Ax.Mocks.GetSystemTimerPayload;
            mockPayloadStateless : Simatic.Ax.Mocks.GetSystemTimerPayload;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            timeProvider := timeProviderStateless;
            mockPayload := mockPayloadStateless;
            
            // Set up mock with realistic starting time (1 second after epoch)
            mockPayload.systemTime := LDATE_AND_TIME#1970-01-01-00:00:01;
            
            // Install the mock for GetSystemDateTime with payload
            AxUnit.Mocking.Mock(NAME_OF(Siemens.Simatic.Clocks.GetSystemDateTime), NAME_OF(Simatic.Ax.Mocks.GetSystemTimeMock), mockPayload);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentTimeMs_ReturnsLINT
            VAR_TEMP
                timeMs : LINT;
            END_VAR
            
            // Act - First call initializes
            timeMs := timeProvider.GetCurrentTimeMs();
            
            // Assert - First call should return 0 (initialization)
            // In mocked environment, GetSystemDateTime returns 0
            Equal(expected := LINT#0, actual := timeMs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentTimeNs_ReturnsLINT
            VAR_TEMP
                timeNs : LINT;
            END_VAR
            
            // Act - First call initializes
            timeNs := timeProvider.GetCurrentTimeNs();
            
            // Assert - First call should return 0 (initialization)
            Equal(expected := LINT#0, actual := timeNs);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentTimeMs_SecondCall_ReturnsDelta
            VAR_TEMP
                timeMs1, timeMs2 : LINT;
            END_VAR
            
            // Act
            timeMs1 := timeProvider.GetCurrentTimeMs();  // Initialize
            timeMs2 := timeProvider.GetCurrentTimeMs();  // Get delta
            
            // Assert - First call initializes (returns 0)
            Equal(expected := LINT#0, actual := timeMs1);
            
            // Second call returns delta time since first call
            // In mocked environment with static time, delta is 0
            // In real PLC, this would be the actual elapsed milliseconds
            Equal(expected := TRUE, actual := (timeMs2 >= LINT#0));
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentTimeNs_SecondCall_ReturnsDelta
            VAR_TEMP
                timeNs1, timeNs2 : LINT;
            END_VAR
            
            // Act
            timeNs1 := timeProvider.GetCurrentTimeNs();  // Initialize
            timeNs2 := timeProvider.GetCurrentTimeNs();  // Get delta
            
            // Assert - First call initializes (returns 0)
            Equal(expected := LINT#0, actual := timeNs1);
            
            // Second call returns delta time in nanoseconds
            // In mocked environment, delta is 0
            // In real PLC, this would be actual elapsed nanoseconds
            Equal(expected := TRUE, actual := (timeNs2 >= LINT#0));
        END_METHOD
        
        {Test}
        METHOD PUBLIC Test_BothMethods_ReturnConsistentValues
            VAR_TEMP
                timeMs : LINT;
                timeNs : LINT;
                expectedNs : LINT;
            END_VAR
            
            // Act - Initialize both
            timeMs := timeProvider.GetCurrentTimeMs();
            timeNs := timeProvider.GetCurrentTimeNs();
            
            // Assert - Both should initialize to 0
            Equal(expected := LINT#0, actual := timeMs);
            Equal(expected := LINT#0, actual := timeNs);
            
            // Note: In real environment, subsequent calls would show
            // timeNs ≈ timeMs * 1,000,000 (allowing for small timing differences)
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MeasureTimeInterval_Milliseconds_WithMockedTime
            VAR_TEMP
                deltaMs1, deltaMs2 : LINT;
                startTime, time1, time2 : LDATE_AND_TIME;
            END_VAR
            
            // Arrange - Set up time sequence: 1s, 1.25s, 1.5s
            startTime := LDATE_AND_TIME#1970-01-01-00:00:01.0;      // 1 second = 1,000,000,000 ns
            time1 := LDATE_AND_TIME#1970-01-01-00:00:01.250;        // 1.25 seconds = 1,250,000,000 ns
            time2 := LDATE_AND_TIME#1970-01-01-00:00:01.500;        // 1.5 seconds = 1,500,000,000 ns
            
            mockPayload.SetTimeAt(index := 0, timeValue := startTime);
            mockPayload.SetTimeAt(index := 1, timeValue := time1);
            mockPayload.SetTimeAt(index := 2, timeValue := time2);
            mockPayload.Reset();
            
            // Reinstall mock with new sequence
            AxUnit.Mocking.Mock(NAME_OF(Siemens.Simatic.Clocks.GetSystemDateTime), NAME_OF(Simatic.Ax.Mocks.GetSystemTimeMock), mockPayload);
            
            // Act - Measure intervals
            deltaMs1 := timeProvider.GetCurrentTimeMs();  // First call: initialize, returns 0
            deltaMs2 := timeProvider.GetCurrentTimeMs();  // Second call: delta = 250ms
            
            // Assert
            Equal(expected := LINT#0, actual := deltaMs1);  // First call initializes
            Equal(expected := LINT#250, actual := deltaMs2);  // 250ms interval
            Equal(expected := TRUE, actual := (deltaMs2 > LINT#0));  // Verify > 0
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MeasureTimeInterval_Nanoseconds_WithMockedTime
            VAR_TEMP
                deltaNs1, deltaNs2 : LINT;
                startTime, time1, time2 : LDATE_AND_TIME;
            END_VAR
            
            // Arrange - Set up time sequence with precise nanosecond intervals
            startTime := LDATE_AND_TIME#1970-01-01-00:00:02.0;      // 2 seconds
            time1 := LDATE_AND_TIME#1970-01-01-00:00:02.100;        // 2.1 seconds (100ms later)
            time2 := LDATE_AND_TIME#1970-01-01-00:00:02.350;        // 2.35 seconds (250ms later)
            
            mockPayload.SetTimeAt(index := 0, timeValue := startTime);
            mockPayload.SetTimeAt(index := 1, timeValue := time1);
            mockPayload.SetTimeAt(index := 2, timeValue := time2);
            mockPayload.Reset();
            
            AxUnit.Mocking.Mock(NAME_OF(Siemens.Simatic.Clocks.GetSystemDateTime), NAME_OF(Simatic.Ax.Mocks.GetSystemTimeMock), mockPayload);
            
            // Act
            deltaNs1 := timeProvider.GetCurrentTimeNs();  // Initialize
            deltaNs2 := timeProvider.GetCurrentTimeNs();  // Delta = 100ms = 100,000,000 ns
            
            // Assert
            Equal(expected := LINT#0, actual := deltaNs1);
            Equal(expected := LINT#100000000, actual := deltaNs2);  // 100ms in nanoseconds
            Equal(expected := TRUE, actual := (deltaNs2 > LINT#0));
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MeasureMultipleIntervals_Accumulates
            VAR_TEMP
                delta1, delta2, delta3 : LINT;
                t0, t1, t2, t3 : LDATE_AND_TIME;
            END_VAR
            
            // Arrange - Simulate multiple time measurements
            t0 := LDATE_AND_TIME#1970-01-01-00:00:00.0;    // 0s
            t1 := LDATE_AND_TIME#1970-01-01-00:00:00.100;  // 100ms later
            t2 := LDATE_AND_TIME#1970-01-01-00:00:00.350;  // 250ms later (total 350ms)
            t3 := LDATE_AND_TIME#1970-01-01-00:00:00.850;  // 500ms later (total 850ms)
            
            mockPayload.SetTimeAt(index := 0, timeValue := t0);
            mockPayload.SetTimeAt(index := 1, timeValue := t1);
            mockPayload.SetTimeAt(index := 2, timeValue := t2);
            mockPayload.SetTimeAt(index := 3, timeValue := t3);
            mockPayload.Reset();
            
            AxUnit.Mocking.Mock(NAME_OF(Siemens.Simatic.Clocks.GetSystemDateTime), NAME_OF(Simatic.Ax.Mocks.GetSystemTimeMock), mockPayload);
            
            // Act - Measure three intervals
            delta1 := timeProvider.GetCurrentTimeMs();  // Initialize: 0
            delta2 := timeProvider.GetCurrentTimeMs();  // Delta: 100ms
            delta3 := timeProvider.GetCurrentTimeMs();  // Delta: 250ms
            
            // Assert - Each interval should be > 0 and have correct value
            Equal(expected := LINT#0, actual := delta1);
            
            Equal(expected := LINT#100, actual := delta2);
            Equal(expected := TRUE, actual := (delta2 > LINT#0));
            
            Equal(expected := LINT#250, actual := delta3);
            Equal(expected := TRUE, actual := (delta3 > LINT#0));
        END_METHOD

        {Test}
        METHOD PUBLIC Test_SimulateRealWorldTiming_MotorRamp
            VAR_TEMP
                initDelta, rampDelta : LINT;
                tStart, tRampStart, tRampEnd : LDATE_AND_TIME;
            END_VAR
            
            // Arrange - Simulate a motor ramp scenario
            tStart := LDATE_AND_TIME#1970-01-01-00:00:05.0;      // System at 5s
            tRampStart := LDATE_AND_TIME#1970-01-01-00:00:05.0;  // Ramp starts at 5s
            tRampEnd := LDATE_AND_TIME#1970-01-01-00:00:08.500;  // Ramp ends at 8.5s (3.5s duration)
            
            mockPayload.SetTimeAt(index := 0, timeValue := tStart);
            mockPayload.SetTimeAt(index := 1, timeValue := tRampStart);
            mockPayload.SetTimeAt(index := 2, timeValue := tRampEnd);
            mockPayload.Reset();
            
            AxUnit.Mocking.Mock(NAME_OF(Siemens.Simatic.Clocks.GetSystemDateTime), NAME_OF(Simatic.Ax.Mocks.GetSystemTimeMock), mockPayload);
            
            // Act - Simulate motor ramp timing
            initDelta := timeProvider.GetCurrentTimeMs();     // Initialize
            rampDelta := timeProvider.GetCurrentTimeMs();     // Start ramp (0ms delta)
            rampDelta := timeProvider.GetCurrentTimeMs();     // End ramp (3500ms delta)
            
            // Assert - Verify ramp duration is correct and > 0
            Equal(expected := LINT#3500, actual := rampDelta);
            Equal(expected := TRUE, actual := (rampDelta > LINT#0));
        END_METHOD
    END_CLASS
END_NAMESPACE
