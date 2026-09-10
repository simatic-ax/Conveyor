USING AxUnit.Assert;
USING Simatic.Ax.Motor;

NAMESPACE MotorSimulatedTests.Validation
    /// Test fixture for MotorSimulated parameter validation
    {TestFixture}
    CLASS MotorSimulatedValidationTest
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
        METHOD PUBLIC Test_StartWithZeroTargetSpeed_DoesNotStart
            // Arrange
            motor.MaxSpeed := 0.0;
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            // Act
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000);
            motor.Update();

            // Assert - Motor should not start with zero target speed
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartWithNegativeTargetSpeed_Succeeds
            // Arrange - Negative speed for reverse direction
            motor.MaxSpeed := -1.5; // -1.5 m/s (reverse)
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            // Act
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000);
            motor.Update();

            // Assert - Should accept negative speed for reverse
            Equal(expected := TRUE, actual := motor.IsRunning());
            Equal(expected := -0.5, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartWithExcessiveNegativeTargetSpeed_DoesNotStart
            // Arrange - Exceeds MAX_SPEED limit (10 m/s)
            motor.MaxSpeed := -15.0; // -15.0 m/s (exceeds limit)
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            // Act
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000);
            motor.Update();

            // Assert - Should not start because absolute speed exceeds MAX_SPEED
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartWithZeroAcceleration_DoesNotStart
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.0;

            // Act
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000);
            motor.Update();

            // Assert
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartWithNegativeAcceleration_DoesNotStart
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := -0.5; // Invalid negative acceleration

            // Act
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000);
            motor.Update();

            // Assert
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartWithValidParameters_Succeeds
            // Arrange
            motor.MaxSpeed := 2.0; // 2.0 m/s
            motor.MaxAcceleration := 0.5; // 0.5 m/s²

            // Act
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000);
            motor.Update();

            // Assert
            Equal(expected := TRUE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartWithVerySmallValidValues_Succeeds
            // Arrange
            motor.MaxSpeed := 0.1; // 0.1 m/s
            motor.MaxAcceleration := 0.05; // 0.05 m/s²

            // Act
            Motor.StartMotor();
            motor.Update(); // Initialize
            timeProvider.AdvanceTime(DeltaMs := LINT#1000);
            motor.Update();

            // Assert
            Equal(expected := TRUE, actual := motor.IsRunning());
        END_METHOD
    END_CLASS

END_NAMESPACE
