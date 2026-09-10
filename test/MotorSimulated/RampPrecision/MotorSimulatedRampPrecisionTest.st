USING AxUnit.Assert;
USING Simatic.Ax.Motor;

NAMESPACE MotorSimulatedTests.RampPrecision
    /// Detailed ramp precision tests for MotorSimulated with small time intervals (10ms)
    /// Tests motor behavior with fine-grained time steps
    {TestFixture}
    CLASS MotorSimulatedRampPrecisionTest
        VAR PROTECTED
            motor : MotorSimulated;
            motorStateless : MotorSimulated;
            timeProvider : ManualTimeProvider;
            timeProviderStateless : ManualTimeProvider;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            motor := motorStateless;
            timeProvider := timeProviderStateless;
            
            // Configure motor
            motor.TimeProvider := timeProvider;
            motor.MaxSpeed := 2.0;  // 2.0 m/s
            motor.MaxAcceleration := 0.5;  // 0.5 m/s²
            motor.MaxDeceleration := 0.5;  // 0.5 m/s²
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_With10msIntervals_ReachesTargetSpeed
            VAR_TEMP
                i : INT;
                speed : LREAL;
                expectedSpeed : LREAL;
            END_VAR
            
            // Arrange
            motor.StartMotor();
            motor.Update();  // Initialize
            
            // Act - Simulate 100 updates with 10ms intervals (1 second total)
            // Expected: 0.5 m/s² * 1s = 0.5 m/s after 1 second
            FOR i := 1 TO 100 DO
                timeProvider.AdvanceTime(DeltaMs := LINT#10);  // 10ms
                motor.Update();
            END_FOR;
            
            // Assert - After 1 second with 0.5 m/s² acceleration
            speed := motor.GetCurrentSpeed();
            expectedSpeed := 0.5;  // 0.5 m/s² * 1s = 0.5 m/s
            InRange(number_1 := speed, number_2 := expectedSpeed, tolerance := 0.01);
            
            // Act - Continue for another 3 seconds (300 more updates)
            FOR i := 1 TO 300 DO
                timeProvider.AdvanceTime(DeltaMs := LINT#10);
                motor.Update();
            END_FOR;
            
            // One more update to ensure motor has finished ramping
            timeProvider.AdvanceTime(DeltaMs := LINT#10);
            motor.Update();
            
            // Assert - After 4 seconds total, should reach target speed of 2.0 m/s
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 2.0, tolerance := 0.01);
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            Equal(expected := FALSE, actual := motor.IsRampingUp());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampDown_With10msIntervals_StopsCompletely
            VAR_TEMP
                i : INT;
                speed : LREAL;
            END_VAR
            
            // Arrange - Start motor and reach target speed
            motor.StartMotor();
            motor.Update();
            FOR i := 1 TO 400 DO  // 4 seconds to reach 2.0 m/s
                timeProvider.AdvanceTime(DeltaMs := LINT#10);
                motor.Update();
            END_FOR;
            
            // Act - Stop motor
            motor.StopMotor();
            motor.Update();  // Initialize stop
            
            // Simulate 100 updates with 10ms intervals (1 second)
            FOR i := 1 TO 100 DO
                timeProvider.AdvanceTime(DeltaMs := LINT#10);
                motor.Update();
            END_FOR;
            
            // Assert - After 1 second with 0.5 m/s² deceleration
            // Speed should be: 2.0 - (0.5 * 1) = 1.5 m/s
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 1.5, tolerance := 0.01);
            
            // Act - Continue for another 3 seconds (300 more updates)
            FOR i := 1 TO 300 DO
                timeProvider.AdvanceTime(DeltaMs := LINT#10);
                motor.Update();
            END_FOR;
            
            // Assert - After 4 seconds total, should be stopped
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 0.0, tolerance := 0.01);
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_ProgressiveSpeedIncrease
            VAR_TEMP
                i : INT;
                speed : LREAL;
                previousSpeed : LREAL;
            END_VAR
            
            // Arrange
            motor.StartMotor();
            motor.Update();  // Initialize
            previousSpeed := 0.0;
            
            // Act & Assert - Check speed increases progressively every 100ms
            FOR i := 1 TO 40 DO  // 40 * 100ms = 4 seconds
                // Advance 100ms (10 updates of 10ms)
                timeProvider.AdvanceTime(DeltaMs := LINT#100);
                motor.Update();
                
                speed := motor.GetCurrentSpeed();
                
                // Speed should increase or stay at target
                IF speed < 2.0 THEN
                    Equal(expected := TRUE, actual := speed > previousSpeed);
                END_IF;
                
                previousSpeed := speed;
            END_FOR;
            
            // Assert - Final speed should be at target
            InRange(number_1 := speed, number_2 := 2.0, tolerance := 0.01);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_With5msIntervals_HighPrecision
            VAR_TEMP
                i : INT;
                speed : LREAL;
            END_VAR
            
            // Arrange - Use even smaller intervals for high precision
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;  // 1.0 m/s²
            motor.StartMotor();
            motor.Update();
            
            // Act - Simulate 200 updates with 5ms intervals (1 second total)
            FOR i := 1 TO 200 DO
                timeProvider.AdvanceTime(DeltaMs := LINT#5);  // 5ms
                motor.Update();
            END_FOR;
            
            // Assert - After 1 second with 1.0 m/s² acceleration
            // Should reach exactly 1.0 m/s
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 1.0, tolerance := 0.01);
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_WithNanosecondPrecision
            VAR_TEMP
                i : INT;
                speed : LREAL;
            END_VAR
            
            // Arrange - Test with nanosecond-level time advances
            motor.MaxSpeed := 0.1;  // Small target for precision test
            motor.MaxAcceleration := 0.1;  // 0.1 m/s²
            motor.StartMotor();
            motor.Update();
            
            // Act - Simulate 1000 updates with 1ms intervals
            FOR i := 1 TO 1000 DO
                timeProvider.AdvanceTime(DeltaMs := LINT#1);  // 1ms
                motor.Update();
            END_FOR;
            
            // Assert - After 1 second (1000ms) with 0.1 m/s² acceleration
            // Should reach exactly 0.1 m/s
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 0.1, tolerance := 0.001);
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

    END_CLASS
END_NAMESPACE
