USING Simatic.Ax.Motor;
USING AxUnit.Assert;
USING AxUnit;
USING Simatic.Ax.Mocks;

NAMESPACE MotorGenericTests.Basic
    {TestFixture}
    CLASS MotorGenericBasicTest
        VAR PROTECTED
            motor : MotorGeneric;
        END_VAR

        {Test}
        METHOD PUBLIC Test_StartMotor_SetsIsRunning
            // Arrange
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - Mock OnDelay to return FALSE (still ramping)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should be running (ramping up)
            Equal(expected := TRUE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StartMotor_IsRampingUp
            // Arrange
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;
            
            // Act - Mock OnDelay to return FALSE (still ramping)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should be ramping up
            Equal(expected := TRUE, actual := motor.IsRampingUp());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_IsAtSpeed_AfterAccelerationTime
            // Arrange - 1.0 m/s with 1.0 m/s² = 1 second acceleration
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;
            motor.StartMotor();
            
            // Act - Mock OnDelay to return TRUE (acceleration complete)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            Equal(expected := FALSE, actual := motor.IsRampingUp());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopMotor_EventuallyStops
            // Arrange - Start and reach target speed
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Mock OnDelay to return TRUE (at speed)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.StartMotor();
            motor.Update();
            
            // Act - Stop motor, mock OffDelay to return TRUE (still decelerating)
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_true');
            motor.StopMotor();
            motor.Update();
            
            // Motor should still be running during deceleration
            Equal(expected := TRUE, actual := motor.IsRunning());
            
            // Mock OffDelay to return FALSE (deceleration complete)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor should be stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentSpeed_ReturnsTargetSpeedWhenAtSpeed
            VAR_TEMP
                speed : LREAL;
            END_VAR
            
            // Arrange
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.StartMotor();
            
            // Mock OnDelay to return TRUE (at speed)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Act
            speed := motor.GetCurrentSpeed();
            
            // Assert
            InRange(number_1 := speed, number_2 := 1.5, tolerance := 0.01);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_GetCurrentSpeed_ReturnsZeroWhenStopped
            VAR_TEMP
                speed : LREAL;
            END_VAR
            
            // Arrange - Motor not started, timers return FALSE
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.MaxSpeed := 1.0;
            motor.Update();
            
            // Act
            speed := motor.GetCurrentSpeed();
            
            // Assert
            Equal(expected := 0.0, actual := speed);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_IsReleased_ReturnsTrueByDefault
            // Arrange - No ExternalRelease set
            
            // Act & Assert
            Equal(expected := TRUE, actual := motor.IsReleased());
        END_METHOD
    END_CLASS
END_NAMESPACE
