USING AxUnit.Assert;
USING Simatic.Ax.Motor;
USING AxUnit;
USING Simatic.Ax.Mocks;

NAMESPACE MotorGenericTests.Interruption
    /// Interruption tests for MotorGeneric
    /// Tests motor behavior when stopped during ramp-up or ramp-down
    {TestFixture}
    CLASS MotorGenericInterruptionTest
        VAR PROTECTED
            motor : MotorGeneric;
            motorStateless : MotorGeneric;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            motor := motorStateless;
            
            // Configure motor
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopDuringRampUp_MotorStopsRamping
            // Arrange - Mock OnDelay to return FALSE (still ramping)
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor is ramping up
            Equal(expected := TRUE, actual := motor.IsRampingUp());
            Equal(expected := FALSE, actual := motor.IsAtSpeed());
            
            // Act - Stop during ramp-up
            motor.StopMotor();
            motor.Update();
            
            // Assert - Motor stops ramping immediately
            Equal(expected := FALSE, actual := motor.IsRampingUp());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopDuringRampUp_MotorEntersDeceleration
            // Arrange - Start and ramp up partially
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Act - Stop during ramp-up, mock OffDelay to return TRUE (decelerating)
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_true');
            motor.Update();
            
            // Assert - Motor is still running (OffDelay active)
            Equal(expected := TRUE, actual := motor.IsRunning());
            Equal(expected := FALSE, actual := motor.IsRampingUp());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopDuringRampUp_EventuallyStops
            // Arrange - Start and ramp up partially
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Act - Stop during ramp-up and complete deceleration
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor is stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := FALSE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RestartAfterInterruption_StartsNewRamp
            // Arrange - Start, interrupt, then stop completely
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Act - Restart motor
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Assert - Motor starts new ramp from beginning
            Equal(expected := TRUE, actual := motor.IsRampingUp());
            Equal(expected := FALSE, actual := motor.IsAtSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MultipleInterruptions_MotorHandlesCorrectly
            VAR_TEMP
                cycle : INT;
            END_VAR
            
            // Act & Assert - Multiple start/stop cycles during ramp-up
            FOR cycle := 1 TO 3 DO
                // Start - mock ramping
                AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
                motor.StartMotor();
                motor.Update();
                Equal(expected := TRUE, actual := motor.IsRampingUp());
                
                // Stop - complete deceleration
                motor.StopMotor();
                AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
                AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
                motor.Update();
                Equal(expected := FALSE, actual := motor.IsRunning());
            END_FOR;
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ImmediateStopAfterStart_MotorHandles
            // Arrange & Act - Start and immediately stop
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            motor.StopMotor();
            
            // Complete deceleration
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor stops properly
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopAtEndOfRampUp_MotorDecelerates
            // Arrange - Reach target speed
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.StartMotor();
            motor.Update();
            
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            // Act - Stop at target speed, mock OffDelay to return TRUE (decelerating)
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_true');
            motor.Update();
            Equal(expected := TRUE, actual := motor.IsRunning());
            
            // Complete deceleration
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor is stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RapidStartStopSequence_MotorStable
            // Act - Rapid start/stop sequence
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.Update();
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor is stable and stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_StopDuringRampUp_GetCurrentSpeedReturnsZero
            VAR_TEMP
                speed : LREAL;
            END_VAR
            
            // Arrange - Start and ramp up partially
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            // Act - Stop during ramp-up
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_true');
            motor.Update();
            
            speed := motor.GetCurrentSpeed();
            
            // Assert - GetCurrentSpeed returns 0 (not at speed)
            Equal(expected := 0.0, actual := speed);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_InterruptionWithDifferentSpeeds_HandlesCorrectly
            // Test 1: Interrupt at low speed
            motor.MaxSpeed := 0.5;
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
            
            // Test 2: Interrupt at high speed
            motor.MaxSpeed := 2.0;
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.StartMotor();
            motor.Update();
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD
    END_CLASS
END_NAMESPACE
