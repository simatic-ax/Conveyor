USING AxUnit.Assert;
USING Simatic.Ax.Motor;
USING AxUnit;
USING Simatic.Ax.Mocks;

NAMESPACE MotorGenericTests.RampPrecision
    /// Ramp precision tests for MotorGeneric with timer-based control
    /// Tests motor behavior during acceleration and deceleration phases
    {TestFixture}
    CLASS MotorGenericRampPrecisionTest
        VAR PROTECTED
            motor : MotorGeneric;
            motorStateless : MotorGeneric;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            motor := motorStateless;
            
            // Configure motor with known parameters
            motor.MaxSpeed := 2.0;  // 2.0 m/s
            motor.MaxAcceleration := 0.5;  // 0.5 m/s²
            motor.MaxDeceleration := 0.5;  // 0.5 m/s²
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_IsRampingUpDuringAcceleration
            // Arrange
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 1.0;  // 1.0 m/s² -> 2 seconds to reach 2.0 m/s
            
            // Act - Mock OnDelay to return FALSE (still ramping)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor should be ramping up
            Equal(expected := TRUE, actual := motor.IsRampingUp());
            Equal(expected := FALSE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_ReachesTargetSpeedAfterAccelerationTime
            // Arrange - 2.0 m/s with 1.0 m/s² = 2 seconds
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 1.0;
            motor.StartMotor();
            
            // Act - Mock OnDelay to return TRUE (acceleration complete)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            Equal(expected := FALSE, actual := motor.IsRampingUp());
            InRange(number_1 := motor.GetCurrentSpeed(), number_2 := 2.0, tolerance := 0.01);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_GetCurrentSpeed_ReturnsZeroDuringRamp
            VAR_TEMP
                speed : LREAL;
            END_VAR
            
            // Arrange
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.StartMotor();
            
            // Act - Mock OnDelay to return FALSE (still ramping)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.Update();
            
            speed := motor.GetCurrentSpeed();
            
            // Assert - GetCurrentSpeed returns 0 during ramp (not at speed yet)
            Equal(expected := 0.0, actual := speed);
            Equal(expected := TRUE, actual := motor.IsRampingUp());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_GetCurrentSpeed_ReturnsTargetWhenAtSpeed
            VAR_TEMP
                speed : LREAL;
            END_VAR
            
            // Arrange
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.StartMotor();
            
            // Act - Mock OnDelay to return TRUE (at speed)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            speed := motor.GetCurrentSpeed();
            
            // Assert - GetCurrentSpeed returns TargetSpeed when at speed
            InRange(number_1 := speed, number_2 := 1.5, tolerance := 0.01);
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampDown_IsRunningDuringDeceleration
            // Arrange - Start and reach target speed
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.StartMotor();
            motor.Update();
            
            // Act - Stop motor, mock OffDelay to return TRUE (still decelerating)
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_true');
            motor.StopMotor();
            motor.Update();
            
            // Assert - Motor is still running (OffDelay active)
            Equal(expected := TRUE, actual := motor.IsRunning());
            Equal(expected := FALSE, actual := motor.IsRampingUp());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampDown_StopsAfterDecelerationTime
            // Arrange - Start and reach target speed
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.StartMotor();
            motor.Update();
            
            // Act - Stop motor and complete deceleration
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor should be stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := FALSE, actual := motor.IsAtSpeed());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_DifferentAccelerationRates
            // Test 1: Fast acceleration (2.0 m/s²)
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 2.0;
            motor.StartMotor();
            
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            // Reset - Stop motor
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Test 2: Slow acceleration (0.5 m/s²) - still ramping
            motor.MaxAcceleration := 0.5;
            motor.StartMotor();
            
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.Update();
            
            // Should still be ramping
            Equal(expected := TRUE, actual := motor.IsRampingUp());
            Equal(expected := FALSE, actual := motor.IsAtSpeed());
            
            // Now complete acceleration
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Now should be at speed
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampUp_SmallTargetSpeed
            // Arrange - Small target speed
            motor.MaxSpeed := 0.5;
            motor.MaxAcceleration := 1.0;
            motor.StartMotor();
            
            // Act - Mock OnDelay to return TRUE (at speed)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            InRange(number_1 := motor.GetCurrentSpeed(), number_2 := 0.5, tolerance := 0.01);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RampDown_DifferentDecelerationRates
            // Test 1: Fast deceleration (2.0 m/s²)
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 2.0;
            motor.MaxDeceleration := 2.0;
            motor.StartMotor();
            
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            Equal(expected := FALSE, actual := motor.IsRunning());
            
            // Test 2: Slow deceleration (0.5 m/s²) - still running during deceleration
            motor.MaxDeceleration := 0.5;
            motor.StartMotor();
            
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_true');
            motor.Update();
            
            // Should still be running during deceleration
            Equal(expected := TRUE, actual := motor.IsRunning());
            
            // Complete deceleration
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Now should be stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MultipleStartStopCycles
            VAR_TEMP
                cycle : INT;
            END_VAR
            
            // Arrange
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act & Assert - Multiple cycles
            FOR cycle := 1 TO 3 DO
                // Start and reach speed
                motor.StartMotor();
                AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
                motor.Update();
                Equal(expected := TRUE, actual := motor.IsAtSpeed());
                
                // Stop and complete deceleration
                motor.StopMotor();
                AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
                AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
                motor.Update();
                Equal(expected := FALSE, actual := motor.IsRunning());
            END_FOR;
        END_METHOD
    END_CLASS
END_NAMESPACE
