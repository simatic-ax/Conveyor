USING AxUnit.Assert;
USING Simatic.Ax.Motor;

NAMESPACE MotorSimulatedTests.Integration
    /// Integration tests for complete MotorSimulated scenarios
    {TestFixture}
    CLASS MotorSimulatedIntegrationTest
        VAR PROTECTED
            motor : MotorSimulated;
            motorStateless : MotorSimulated;
            timeProvider : ManualTimeProvider;
            timeProviderStateless : ManualTimeProvider;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            // Reset motor and time provider to stateless instances for each test
            motor := motorStateless;
            timeProvider := timeProviderStateless;
            motor.TimeProvider := timeProvider;
        END_METHOD

        {Test}
        METHOD PUBLIC Test_CompleteStartStopCycle
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            // Act & Assert - Start
            Motor.StartMotor();
            motor.Update(); // Initialize
            Equal(expected := FALSE, actual := motor.IsRunning()); // Speed still 0
            Equal(expected := FALSE, actual := motor.IsAtSpeed());

            // Act & Assert - Ramp up (halfway)
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // 2 seconds
            motor.Update();
            Equal(expected := 1.0, actual := motor.GetCurrentSpeed());
            Equal(expected := TRUE, actual := motor.IsRunning());
            Equal(expected := FALSE, actual := motor.IsAtSpeed());
            Equal(expected := TRUE, actual := motor.IsRampingUp());

            // Act & Assert - Ramp up (complete)
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // Another 2 seconds
            motor.Update();
            Equal(expected := 2.0, actual := motor.GetCurrentSpeed());
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            Equal(expected := FALSE, actual := motor.IsRampingUp());

            // Act & Assert - Stop (initiate deceleration)
            Motor.StopMotor();
            motor.Update(); // Initialize stop
            Equal(expected := TRUE, actual := motor.IsRunning()); // Still running (decelerating)

            // Decelerate to zero
            timeProvider.AdvanceTime(DeltaMs := LINT#4000); // 4 seconds (enough to stop)
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RealisticConveyorScenario_100msCycles
            VAR_TEMP
                i : INT;
                finalSpeed : LREAL;
            END_VAR

            // Arrange - Realistic conveyor setup
            motor.MaxSpeed := 1.5; // 1.5 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize

            // Act - Simulate 30 cycles of 100ms each (3 seconds total)
            FOR i := 1 TO 30 DO
                timeProvider.AdvanceTime(DeltaMs := LINT#100);
                motor.Update();
            END_FOR;

            // Assert - Should have reached target speed (with tolerance)
            finalSpeed := motor.GetCurrentSpeed();
            InRange(number_1 := finalSpeed, number_2 := 1.5, tolerance := 0.01);
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MultipleStartStopCycles
            VAR_TEMP
                cycle : INT;
            END_VAR

            // Arrange
            motor.MaxSpeed := 1.0; // 1.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            // Act & Assert - Multiple cycles
            FOR cycle := 1 TO 3 DO
                Motor.StartMotor();
                motor.Update(); // Initialize

                timeProvider.AdvanceTime(DeltaMs := LINT#2000); // 2 seconds to reach 1.0 m/s
                motor.Update();
                Equal(expected := 1.0, actual := motor.GetCurrentSpeed());

                Motor.StopMotor();
                motor.Update(); // Initialize stop
                timeProvider.AdvanceTime(DeltaMs := LINT#2000); // 2 seconds to stop
                motor.Update();
                Equal(expected := FALSE, actual := motor.IsRunning());
                Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
            END_FOR;
        END_METHOD

        {Test}
        METHOD PUBLIC Test_PartialRampUpThenComplete
            VAR_TEMP
                speed : LREAL;
            END_VAR

            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize

            // Act - Partial ramp
            timeProvider.AdvanceTime(DeltaMs := LINT#1000); // 1 second
            motor.Update();
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 0.5, tolerance := 0.01);

            // Continue ramping
            timeProvider.AdvanceTime(DeltaMs := LINT#1000); // Another 1 second
            motor.Update();
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 1.0, tolerance := 0.01);

            // Complete ramp
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // Another 2 seconds
            motor.Update();

            // Assert
            Equal(expected := 2.0, actual := motor.GetCurrentSpeed());
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_SlowRampWithManySmallUpdates
            VAR_TEMP
                i : INT;
                finalSpeed : LREAL;
            END_VAR

            // Arrange - Very slow ramp
            motor.MaxSpeed := 0.5; // 0.5 m/s
            motor.MaxAcceleration := 0.05; // 0.05 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize

            // Act - 100 updates of 100ms each (10 seconds total)
            FOR i := 1 TO 100 DO
                timeProvider.AdvanceTime(DeltaMs := LINT#100);
                motor.Update();
            END_FOR;

            // Assert - Check with tolerance for floating point precision
            finalSpeed := motor.GetCurrentSpeed();
            InRange(number_1 := finalSpeed, number_2 := 0.5, tolerance := 0.01);
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_FastRampWithLargeUpdates
            // Arrange - Fast ramp
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 2.0; // 2.0 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize

            // Act - Single large update (1 second)
            timeProvider.AdvanceTime(DeltaMs := LINT#1000);
            motor.Update();

            // Assert
            Equal(expected := 2.0, actual := motor.GetCurrentSpeed());
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD
    END_CLASS

END_NAMESPACE
