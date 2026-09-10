USING AxUnit.Assert;
USING Simatic.Ax.Motor;

NAMESPACE MotorSimulatedTests.Interruption
    /// Test fixture for MotorSimulated ramp-up interruption scenarios
    {TestFixture}
    CLASS MotorSimulatedInterruptionTest
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
        METHOD PUBLIC Test_StopDuringRampUp_InterruptsRamp
            VAR_TEMP
                speed : LREAL;
            END_VAR

            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000); // 1 second
            motor.Update();

            // Motor should be at 0.5 m/s with tolerance
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 0.5, tolerance := 0.01);

            // Act - Stop during ramp-up
            Motor.StopMotor();
            motor.Update(); // Initialize stop

            // Assert - Motor should still be running (decelerating)
            Equal(expected := TRUE, actual := motor.IsRunning());

            // Decelerate to zero
            timeProvider.AdvanceTime(DeltaMs := LINT#1000); // 1 second to decelerate
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopDuringRampUp_DeceleratesGradually
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // 2 seconds
            motor.Update(); // Speed should be 1.0 m/s

            // Act - Stop and update
            Motor.StopMotor();
            motor.Update(); // Initialize stop
            timeProvider.AdvanceTime(DeltaMs := LINT#500); // 0.5 seconds
            motor.Update();

            // Assert - Speed should have decreased by 0.25 m/s (not jump to 0)
            InRange(number_1 := motor.GetCurrentSpeed(), number_2 := 0.75, tolerance := 0.01);
            Equal(expected := TRUE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RestartAfterInterruption_StartsFromZero
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // 2 seconds
            motor.Update(); // Speed should be 1.0 m/s
            Motor.StopMotor();
            motor.Update(); // Initialize stop
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // 2 seconds to stop
            motor.Update();

            // Act - Restart motor
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000); // 1 second
            motor.Update();

            // Assert - Should ramp from 0, not from previous speed
            InRange(number_1 := motor.GetCurrentSpeed(), number_2 := 0.5, tolerance := 0.01);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MultipleInterruptions
            VAR_TEMP
                speed : LREAL;
            END_VAR

            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            // Act & Assert - First cycle
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000); // 1 second
            motor.Update();
            InRange(number_1 := motor.GetCurrentSpeed(), number_2 := 0.5, tolerance := 0.01);
            Motor.StopMotor();
            motor.Update(); // Initialize stop
            timeProvider.AdvanceTime(DeltaMs := LINT#1000); // 1 second to stop
            motor.Update();
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());

            // Act & Assert - Second cycle
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1500); // 1.5 seconds
            motor.Update();
            speed := motor.GetCurrentSpeed();
            InRange(number_1 := speed, number_2 := 0.75, tolerance := 0.01);
            Motor.StopMotor();
            motor.Update(); // Initialize stop
            timeProvider.AdvanceTime(DeltaMs := LINT#1500); // 1.5 seconds to stop
            motor.Update();
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopAtEndOfRampUp_DeceleratesNormally
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#4000); // 4 seconds
            motor.Update();

            // Motor has reached target
            Equal(expected := 2.0, actual := motor.GetCurrentSpeed());

            // Act - Stop after ramp complete
            Motor.StopMotor();
            motor.Update(); // Initialize stop

            // Assert - Should be decelerating
            Equal(expected := TRUE, actual := motor.IsRunning());

            // Complete deceleration
            timeProvider.AdvanceTime(DeltaMs := LINT#4000); // 4 seconds to stop
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ImmediateStopAfterStart
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();

            // Act - Stop immediately without any update
            Motor.StopMotor();

            // Assert - Motor should not be running (speed is still 0)
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD
    END_CLASS

END_NAMESPACE
