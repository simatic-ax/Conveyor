USING AxUnit.Assert;
USING Simatic.Ax.Motor;
USING Simatic.Ax.AutomationBase;
USING AxUnit;
USING Simatic.Ax.Mocks;

NAMESPACE MotorGenericTests.Validation
    /// Validation tests for MotorGeneric parameter checking
    /// Tests configuration validation and error handling
    {TestFixture}
    CLASS MotorGenericValidationTest
        VAR PROTECTED
            motor : MotorGeneric;
            motorStateless : MotorGeneric;
            mockRelease : MockRelease;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            motor := motorStateless;
            mockRelease.SetReleased(TRUE);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ValidConfiguration_MotorStarts
            // Arrange - Valid configuration
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - Mock timer to show ramping
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should start
            Equal(expected := TRUE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ZeroTargetSpeed_MotorDoesNotStart
            // Arrange - Invalid: zero target speed
            motor.MaxSpeed := 0.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_NegativeTargetSpeed_MotorDoesNotStart
            // Arrange - Invalid: negative target speed
            motor.MaxSpeed := -1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ExcessiveTargetSpeed_MotorDoesNotStart
            // Arrange - Invalid: exceeds MAX_SPEED (2.0 m/s)
            motor.MaxSpeed := 2.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ZeroAcceleration_MotorDoesNotStart
            // Arrange - Invalid: zero acceleration
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 0.0;
            motor.MaxDeceleration := 1.0;
            
            // Act
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_NegativeAcceleration_MotorDoesNotStart
            // Arrange - Invalid: negative acceleration
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := -1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ExcessiveAcceleration_MotorDoesNotStart
            // Arrange - Invalid: exceeds MAX_ACCELERATION (2.0 m/s²)
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 2.5;
            motor.MaxDeceleration := 1.0;
            
            // Act
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ZeroDeceleration_MotorDoesNotStart
            // Arrange - Invalid: zero deceleration
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 0.0;
            
            // Act
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_NegativeDeceleration_MotorDoesNotStart
            // Arrange - Invalid: negative deceleration
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := -1.0;
            
            // Act
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ExcessiveDeceleration_MotorDoesNotStart
            // Arrange - Invalid: exceeds MAX_DECELERATION (2.0 m/s²)
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 2.5;
            
            // Act
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MaxValidTargetSpeed_MotorStarts
            // Arrange - Valid: exactly at MAX_SPEED (2.0 m/s)
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - Mock timer to show at speed
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should start and reach speed
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            InRange(number_1 := motor.GetCurrentSpeed(), number_2 := 2.0, tolerance := 0.01);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MaxValidAcceleration_MotorStarts
            // Arrange - Valid: exactly at MAX_ACCELERATION (2.0 m/s²)
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 2.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - Mock timer to show at speed
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should start and reach speed
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MaxValidDeceleration_MotorStarts
            // Arrange - Valid: exactly at MAX_DECELERATION (2.0 m/s²)
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 2.0;
            motor.MaxDeceleration := 2.0;
            
            // Act - Start and reach speed
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.StartMotor();
            motor.Update();
            
            // Stop and complete deceleration
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor should stop properly
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_SmallValidValues_MotorStarts
            // Arrange - Valid: small but positive values
            motor.MaxSpeed := 0.1;
            motor.MaxAcceleration := 0.1;
            motor.MaxDeceleration := 0.1;
            
            // Act - Mock timer to show at speed
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should start and reach speed
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ExternalReleaseNotSet_MotorIsReleased
            // Arrange - No ExternalRelease set (NULL)
            motor.ExternalRelease := NULL;
            
            // Act & Assert
            Equal(expected := TRUE, actual := motor.IsReleased());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ExternalReleaseTrue_MotorIsReleased
            // Arrange
            mockRelease.SetReleased(TRUE);
            motor.ExternalRelease := mockRelease;
            
            // Act & Assert
            Equal(expected := TRUE, actual := motor.IsReleased());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ExternalReleaseFalse_MotorNotReleased
            // Arrange
            mockRelease.SetReleased(FALSE);
            motor.ExternalRelease := mockRelease;
            
            // Act & Assert
            Equal(expected := FALSE, actual := motor.IsReleased());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ExternalReleaseFalse_MotorDoesNotStart
            // Arrange
            mockRelease.SetReleased(FALSE);
            motor.ExternalRelease := mockRelease;
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should not start when not released
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ExternalReleaseTrue_MotorStarts
            // Arrange
            mockRelease.SetReleased(TRUE);
            motor.ExternalRelease := mockRelease;
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should start when released
            Equal(expected := TRUE, actual := motor.IsRunning());
        END_METHOD
    END_CLASS

    /// Mock release for testing
    CLASS MockRelease IMPLEMENTS IRelease
        VAR PRIVATE
            _released : BOOL := TRUE;
        END_VAR

        METHOD PUBLIC SetReleased
            VAR_INPUT
                released : BOOL;
            END_VAR
            _released := released;
        END_METHOD

        METHOD PUBLIC IsReleased : BOOL
            IsReleased := _released;
        END_METHOD
    END_CLASS
END_NAMESPACE
