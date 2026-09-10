USING Simatic.Ax.AutomationBase;
USING AxUnit.Assert;
USING Simatic.Ax.Conveyor;
USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor.Tests

    {TestFixture}
    CLASS ConveyorResetTest
        VAR
            conveyor : ConveyorBase;
            conveyorStateless : ConveyorBase;
            mockMotor : MockMotor;
            mockMotorStateless : MockMotor;
            mockMode : MockOperatingMode := (Mode := OperatingModes#Manual);
            mockModeStateless : MockOperatingMode := (Mode := OperatingModes#Manual);
            mockRelease : MockIsReleased_TRUE;
            mockReleaseStateless : MockIsReleased_TRUE;
            mockAutoStartup : MockAutoStartup;
            mockAutoStartupStateless : MockAutoStartup;
            mockResetManager : MockResetManager;
            mockResetManagerStateless : MockResetManager;
            sensorMockQ_True : MockBinSignal := (QValue := TRUE, QRisValue := FALSE, QFalValue := FALSE);
            sensorMockQ_False : MockBinSignal := (QValue := FALSE, QRisValue := FALSE, QFalValue := FALSE);
        END_VAR

        {TestSetup}
        METHOD PUBLIC Setup
            // Reset to stateless instances for test isolation
            conveyor := conveyorStateless;
            mockMotor := mockMotorStateless;
            mockMotor.Reset();
            mockMode := mockModeStateless;
            mockRelease := mockReleaseStateless;
            mockAutoStartup := mockAutoStartupStateless;
            mockResetManager := mockResetManagerStateless;
            mockResetManager.Reset();
            
            // Configure conveyor
            conveyor.StopSensor := sensorMockQ_False;
            conveyor.Motor := mockMotor;
            conveyor.ExternalRelease := mockRelease;
            conveyor.Mode := mockMode;
            conveyor.ExternalAutoStartup := mockAutoStartup;
            conveyor.ResetCommand := mockResetManager;
            
            // Set default states
            mockMode.mode := OperatingModes#Automatic;
            mockAutoStartup.startupStatus := StartUpStatus#AutoStartedUp;
            
            // Initialize conveyor by calling RunCyclic (triggers InitUser)
            conveyor.RunCyclic();
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetFault_ClearsManualStartFlag
            // Arrange
            mockMode.mode := OperatingModes#Manual;
            mockAutoStartup.startupStatus := StartUpStatus#Manual;
            conveyor.RunCyclic();
            conveyor.StartManual();
            conveyor.RunCyclic();
            Equal(expected := TRUE, actual := Conveyor.ConveyorIsRunning());
            conveyor.SetError(errorState := WORD#16#8199, errorText := 'any error');
                        
            // Verify motor is running
            Equal(expected := TRUE, actual := mockMotor.StartMotorCallCount > 0);
            
            // Act - trigger reset via ResetManager
            mockResetManager.ResetCommandActive := TRUE;
            conveyor.RunCyclic();
            
            // Assert - manual start flag should be cleared
            mockResetManager.ResetCommandActive := FALSE;
            conveyor.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.StopMotorCallCount > 0);
        END_METHOD




        {Test}
        METHOD PUBLIC Test_ResetFault_AllowsAutoRestart
            // Arrange - setup conveyor with material
            conveyor.StopSensor := sensorMockQ_True;
            conveyor.RunCyclic();
            
            // Simulate error
            conveyor.SetError(errorState := WORD#16#8001, errorText := 'Test error');
            
            // Act - trigger reset via ResetManager
            mockResetManager.ResetCommandActive := TRUE;
            conveyor.RunCyclic();
            
            // Assert - conveyor should be able to auto-restart after reset
            // The auto-release flags are NOT cleared, allowing automatic restart
            mockResetManager.ResetCommandActive := FALSE;
            conveyor.RunCyclic();
            conveyor.TriggerStartInAutomatic();
            conveyor.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.StartMotorCallCount > 0);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetFault_AllowsNormalOperationAfterReset
            // Arrange - trigger reset
            mockResetManager.ResetCommandActive := TRUE;
            conveyor.RunCyclic();
            mockResetManager.ResetCommandActive := FALSE;
            
            // Act - simulate normal operation
            conveyor.StopSensor := sensorMockQ_True;
            conveyor.RunCyclic();
            conveyor.TriggerStartInAutomatic();
            conveyor.RunCyclic();
            
            // Assert - conveyor should be able to start normally
            Equal(expected := TRUE, actual := mockMotor.StartMotorCallCount > 0);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetFault_CanBeCalledMultipleTimes
            // Act - trigger reset multiple times via ResetManager
            mockResetManager.ResetCommandActive := TRUE;
            conveyor.RunCyclic();
            conveyor.RunCyclic();
            conveyor.RunCyclic();
            
            // Assert - should not cause any issues
            mockResetManager.ResetCommandActive := FALSE;
            conveyor.RunCyclic();
            Equal(expected := FALSE, actual := conveyor.HasError());
        END_METHOD
        {Test}
        METHOD PUBLIC Test_ResetFault_WithNullMotor_DoesNotCrash
            // Arrange
            conveyor.Motor := NULL;
            
            // Act & Assert - should not crash when reset is triggered
            mockResetManager.ResetCommandActive := TRUE;
            conveyor.RunCyclic();
            mockResetManager.ResetCommandActive := FALSE;
            conveyor.RunCyclic();
            Equal(expected := FALSE, actual := conveyor.HasError());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetFault_ClearsErrorState
            // Arrange - simulate an error condition
            conveyor.SetError(errorState := WORD#16#8001, errorText := 'Test error');
            Equal(expected := TRUE, actual := conveyor.HasError());
            
            // Act - trigger reset via ResetManager
            mockResetManager.ResetCommandActive := TRUE;
            conveyor.RunCyclic();
            
            // Assert - error should be cleared
            Equal(expected := FALSE, actual := conveyor.HasError());
        END_METHOD

        // {Test}
        // METHOD PUBLIC Test_ResetFault_BlockedWhenSensorStillCovered
        //     // Arrange - simulate sensor blocked during delivering
        //     sensorMockQ_True.QValue := TRUE;
        //     conveyor.StopSensor := sensorMockQ_True;
        //     conveyor.RunCyclic();
        //     conveyor.TriggerStartInAutomatic();
        //     conveyor.RunCyclic();
            
        //     // Simulate error condition
        //     conveyor.SetError(errorState := WORD#16#8001, errorText := 'Sensor blocked');
        //     Equal(expected := TRUE, actual := conveyor.HasError());
            
        //     // Act - try to reset while sensor is still covered via ResetManager
        //     mockResetManager.ResetCommandActive := TRUE;
        //     conveyor.RunCyclic();
            
        //     // Assert - error should NOT be cleared because sensor is still blocked
        //     Equal(expected := TRUE, actual := conveyor.HasError());
        // END_METHOD

        {Test}
        METHOD PUBLIC Test_ResetFault_AllowedWhenSensorCleared
            // Arrange - simulate sensor blocked, then cleared
            sensorMockQ_True.QValue := TRUE;
            conveyor.StopSensor := sensorMockQ_True;
            conveyor.RunCyclic();
            conveyor.TriggerStartInAutomatic();
            conveyor.RunCyclic();
            
            // Simulate error condition
            conveyor.SetError(errorState := WORD#16#8001, errorText := 'Sensor blocked');
            Equal(expected := TRUE, actual := conveyor.HasError());
            
            // Clear the sensor
            conveyor.StopSensor := sensorMockQ_False;
            conveyor.RunCyclic();
            
            // Act - reset after sensor is cleared via ResetManager
            mockResetManager.ResetCommandActive := TRUE;
            conveyor.RunCyclic();
            
            // Assert - error should be cleared now
            Equal(expected := FALSE, actual := conveyor.HasError());
        END_METHOD
    END_CLASS

END_NAMESPACE
