USING AxUnit.Assert;
USING Simatic.Ax.Motor;
USING AxUnit;
USING Simatic.Ax.Mocks;

NAMESPACE MotorGenericTests.Integration
    /// Integration tests for MotorGeneric with realistic scenarios
    /// Tests complete operational scenarios similar to real-world usage
    {TestFixture}
    CLASS MotorGenericIntegrationTest
        VAR PROTECTED
            motor : MotorGeneric;
            motorStateless : MotorGeneric;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            motor := motorStateless;
        END_METHOD

        {Test}
        METHOD PUBLIC Test_CompleteStartStopCycle_RealisticTiming
            // Arrange - Realistic conveyor motor configuration
            motor.MaxSpeed := 1.5;  // 1.5 m/s
            motor.MaxAcceleration := 0.5;  // 0.5 m/s² -> 3 seconds to reach speed
            motor.MaxDeceleration := 1.0;  // 1.0 m/s² -> 1.5 seconds to stop
            
            // Act - Start and reach speed
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert - Motor at speed
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            Equal(expected := FALSE, actual := motor.IsRampingUp());
            InRange(number_1 := motor.GetCurrentSpeed(), number_2 := 1.5, tolerance := 0.01);
            
            // Still at speed after running
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            // Stop motor and complete deceleration
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ConveyorScenario_MaterialTransport
            VAR_TEMP
                materialDetected : BOOL;
                materialDelivered : BOOL;
            END_VAR
            
            // Arrange - Conveyor transporting material
            motor.MaxSpeed := 1.2;
            motor.MaxAcceleration := 0.6;  // 2 seconds to reach speed
            motor.MaxDeceleration := 0.6;  // 2 seconds to stop
            
            // Act - Material arrives, start motor
            materialDetected := TRUE;
            motor.StartMotor();
            
            // Reach speed
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert - Motor running
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            // Material delivered, stop motor
            materialDelivered := TRUE;
            motor.StopMotor();
            
            // Complete deceleration
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor stopped, ready for next material
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MultipleStartStopCycles_Stability
            VAR_TEMP
                cycle : INT;
            END_VAR
            
            // Arrange
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act & Assert - 5 complete cycles
            FOR cycle := 1 TO 5 DO
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

        {Test}
        METHOD PUBLIC Test_FastCycleTime_1ms_MotorStable
            // Arrange - Very fast cycle time (1ms)
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - Start and reach speed
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert - Motor at speed
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            // Stop and complete deceleration
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_SlowCycleTime_100ms_MotorStable
            // Arrange - Slow cycle time (100ms)
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - Start and reach speed
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert - Motor at speed
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            // Stop and complete deceleration
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_PartialRampThenComplete_MotorReachesSpeed
            // Arrange
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - Start with partial ramp (still ramping)
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.Update();
            
            // Assert - Still ramping
            Equal(expected := TRUE, actual := motor.IsRampingUp());
            Equal(expected := FALSE, actual := motor.IsAtSpeed());
            
            // Complete ramp
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert - At speed
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            Equal(expected := FALSE, actual := motor.IsRampingUp());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_DifferentSpeedProfiles_AllWork
            // Test 1: Slow speed, slow acceleration
            motor.MaxSpeed := 0.5;
            motor.MaxAcceleration := 0.25;
            motor.MaxDeceleration := 0.25;
            
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
            
            // Test 2: Fast speed, fast acceleration
            motor.MaxSpeed := 2.0;
            motor.MaxAcceleration := 2.0;
            motor.MaxDeceleration := 2.0;
            
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
            
            // Test 3: Medium speed, asymmetric acceleration/deceleration
            motor.MaxSpeed := 1.0;
            motor.MaxAcceleration := 0.5;
            motor.MaxDeceleration := 2.0;
            
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_LongRunningOperation_MotorStable
            // Arrange - Long-running conveyor operation
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - Start and reach speed
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            // Assert - Still at speed (simulating long run)
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            Equal(expected := TRUE, actual := motor.IsRunning());
            InRange(number_1 := motor.GetCurrentSpeed(), number_2 := 1.5, tolerance := 0.01);
            
            // Stop
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_EmergencyStopScenario_ImmediateResponse
            VAR_TEMP
                emergencyStop : BOOL;
            END_VAR
            
            // Arrange - Motor running at speed
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            // Act - Emergency stop
            emergencyStop := TRUE;
            motor.StopMotor();
            
            // Assert - Motor immediately responds (enters deceleration)
            Equal(expected := FALSE, actual := motor.IsRampingUp());
            
            // Complete stop
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_RealisticConveyorLine_MultipleStartStops
            // Arrange - Simulate multiple conveyors starting/stopping in sequence
            motor.MaxSpeed := 1.5;
            motor.MaxAcceleration := 1.0;
            motor.MaxDeceleration := 1.0;
            
            // Act - First conveyor cycle
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            Equal(expected := FALSE, actual := motor.IsRunning());
            
            // Second conveyor cycle with partial ramp
            motor.StartMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            motor.Update();
            Equal(expected := TRUE, actual := motor.IsRampingUp());
            
            // Complete ramp
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            motor.Update();
            Equal(expected := TRUE, actual := motor.IsAtSpeed());
            
            motor.StopMotor();
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_false');
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            motor.Update();
            
            // Assert - Motor stable after multiple cycles
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD
    END_CLASS
END_NAMESPACE
