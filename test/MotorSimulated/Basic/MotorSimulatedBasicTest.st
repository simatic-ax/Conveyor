USING AxUnit.Assert;
USING Simatic.Ax.Motor;

NAMESPACE MotorSimulatedTests.Basic
    /// Test fixture for basic MotorSimulated functionality
    {TestFixture}
    CLASS MotorSimulatedBasicTest
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
        METHOD PUBLIC Test_InitialState_MotorNotRunning
            // Arrange & Act
            // Motor in initial state

            // Assert
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartMotor_InitializesRampUp
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            // Act
            Motor.StartMotor();
            motor.Update(); // First update initializes

            // Assert - Motor should not be running yet (speed = 0)
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartMotor_BeginsAcceleration
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            // Act
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000); // Advance 1 second
            motor.Update(); // Should accelerate: 0.5 m/s² * 1s = 0.5 m/s

            // Assert - Motor should be running and have speed > 0
            Equal(expected := TRUE, actual := motor.IsRunning());
            Equal(expected := 0.5, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopMotor_InitiatesDeceleration
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 1.0; // 1.0 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // Advance 2 seconds
            motor.Update(); // Speed should be 1.0 m/s

            // Act
            Motor.StopMotor();

            // Assert - Motor should still be running (decelerating)
            Equal(expected := TRUE, actual := motor.IsRunning());
            Equal(expected := 1.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopMotor_DeceleratesToZero
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²
            motor.MaxDeceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // Advance 2 seconds
            motor.Update(); // Speed should be 1.0 m/s

            // Act - Stop and decelerate
            Motor.StopMotor();
            motor.Update(); // Initialize stop
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // Advance 2 seconds (should decelerate 1.0 m/s)
            motor.Update();

            // Assert - Motor should be stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentSpeed_ReturnsCurrentSpeed
            VAR_TEMP
                speed : LREAL;
            END_VAR

            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#2000); // Advance 2 seconds
            motor.Update(); // Speed should be 1.0 m/s

            // Act
            speed := motor.GetCurrentSpeed();

            // Assert
            Equal(expected := 1.0, actual := speed);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_ReachesTargetSpeed
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#4000); // Advance 4 seconds (enough to reach 2.0 m/s)
            motor.Update();

            // Assert - Motor should be at target speed
            Equal(expected := TRUE, actual := motor.IsRunning());
            Equal(expected := 2.0, actual := motor.GetCurrentSpeed());
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            Equal(expected := FALSE, actual := motor.IsRampingUp());
        END_METHOD
    END_CLASS

END_NAMESPACE
