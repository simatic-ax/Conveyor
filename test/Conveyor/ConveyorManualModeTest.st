USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor

    /// Tests for conveyor manual mode operation
    /// Verifies manual start/stop behavior, release conditions, and mode transitions
    {TestFixture}
    CLASS TestConveyorManualMode
        VAR
            conv : ConveyorBase;
            convStateless : ConveyorBase;
            mockMan : MockOperatingMode;
            mockManStateless : MockOperatingMode;
            relTrue : MockIsReleased_TRUE;
            relTrueStateless : MockIsReleased_TRUE;
            relFalse : MockIsReleased_FALSE;
            relFalseStateless : MockIsReleased_FALSE;
            StopSensor : MockBinSignal := (QValue := TRUE);
            mockMotor : MockMotor;
            mockMotorStateless : MockMotor;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC Setup
            // Initialize stateless instances for each test
            conv := convStateless;
            mockMan := mockManStateless;
            relTrue := relTrueStateless;
            relFalse := relFalseStateless;
            mockMotor := mockMotorStateless;
            mockMotor.Reset();
        END_METHOD
        
        {Test}
        METHOD PUBLIC ConveyorIsStoppedByDefault
            // Arrange - Setup conveyor in automatic mode with release
            conv.StopSensor := StopSensor;
            conv.Motor := mockMotor;
            mockMan.mode := OperatingModes#Automatic;
            conv.Mode := mockMan;
            conv.ExternalRelease := relTrue;
            
            // Verify configuration is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Run cyclic execution twice
            conv.RunCyclic();
            
            // Assert - Motor should remain stopped without explicit start command
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
            
            // Act - Run cyclic again
            conv.RunCyclic();
            
            // Assert - Motor should still be stopped
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_InManualMode_RunReleasedOnManualStart
            // Arrange - Setup conveyor in manual mode with release
            conv.StopSensor := StopSensor;
            conv.Motor := mockMotor;
            conv.Mode := mockMan;  // Default mode is Manual
            conv.ExternalRelease := relTrue;
            
            // Act - Issue manual start command and run cyclic
            conv.StartManual();
            conv.RunCyclic();
            
            // Assert - Motor should be running after manual start
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
        END_METHOD
        {Test}
        METHOD PUBLIC NotReleased_Conveyor_DoNotSetRunRelease
            // Arrange - Setup conveyor without release signal
            conv.StopSensor := StopSensor;
            conv.Motor := mockMotor;
            conv.Mode := mockMan;
            conv.ExternalRelease := relFalse;  // No release signal
            
            // Verify configuration is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Run cyclic, then issue manual start, then run cyclic again
            conv.RunCyclic();
            conv.StartManual();
            conv.RunCyclic();
            
            // Assert - Motor should not run without release signal
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
        {Test}
        METHOD PUBLIC ConveyorManualRunning_Stops_when_release_signal_has_left
            // Arrange - Setup conveyor running in manual mode
            conv.StopSensor := StopSensor;
            conv.Motor := mockMotor;
            THIS.Conveyor_InManualMode_RunReleasedOnManualStart();
            
            // Act - Run cyclic while motor is running
            conv.RunCyclic();
            
            // Assert - Motor should still be running
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Run cyclic again
            conv.RunCyclic();
            
            // Assert - Motor should still be running
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Remove release signal and run cyclic
            conv.ExternalRelease := relFalse;
            conv.RunCyclic();
            
            // Assert - Motor should stop when release signal is lost
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_InAutomaticMode_IsNotRunReleasedOnManualStart
            // Arrange - Setup conveyor in automatic mode with release
            conv.StopSensor := StopSensor;
            conv.Motor := mockMotor;
            mockMan.mode := OperatingModes#Automatic;
            conv.Mode := mockMan;
            conv.ExternalRelease := relTrue;
            
            // Verify configuration is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Issue manual start command (should be ignored in automatic mode)
            conv.StartManual();
            conv.RunCyclic();
            
            // Assert - Motor should not run because manual start is ignored in automatic mode
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
        {Test}
        METHOD PUBLIC ConveyorRunningInManualMode_Stops_on_Stop_Command
            // Arrange - Setup conveyor running in manual mode
            conv.StopSensor := StopSensor;
            conv.Motor := mockMotor;
            THIS.Conveyor_InManualMode_RunReleasedOnManualStart();
            
            // Act - Issue stop command and run cyclic
            conv.Stop();
            conv.RunCyclic();
            
            // Assert - Motor should stop after stop command
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
    END_CLASS

END_NAMESPACE
