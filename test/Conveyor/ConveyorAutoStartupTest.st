USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor
    /// Tests for conveyor automatic startup behavior
    /// Verifies startup sequences, release conditions, and motor control during startup
    {TestFixture}
    CLASS ConveyorAutoStartupTest
        VAR
            conv : ConveyorBase;
            convStateless : ConveyorBase;
            mockMan : MockOperatingMode := (Mode := OperatingModes#Manual);
            mockManStateless : MockOperatingMode := (Mode := OperatingModes#Manual);
            relTrue : MockIsReleased_TRUE;
            relTrueStateless : MockIsReleased_TRUE;
            relFalse : MockIsReleased_FALSE;
            relFalseStateless : MockIsReleased_FALSE;
            autoStart : MockAutoStartup;
            autoStartStateless : MockAutoStartup;
            sensorMockQ_QRis_True : MockBinSignal := (QValue := TRUE, QRisValue := TRUE, QFalValue := FALSE);
            sensorMockQ_True : MockBinSignal := (QValue := TRUE, QRisValue := FALSE, QFalValue := FALSE);
            sensorMockQ_False : MockBinSignal := (QValue := FALSE, QRisValue := FALSE, QFalValue := FALSE);
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
            autoStart := autoStartStateless;
            mockMotor := mockMotorStateless;
            mockMotor.Reset();
        END_METHOD
        
        {Test}
        METHOD PUBLIC Conveyor_Is_Stopped_InAutomatic_Without_Release
            // Arrange - Setup conveyor in automatic mode without release
            mockMan.mode := OperatingModes#Automatic;
            conv.Mode := mockMan;
            conv.Motor := mockMotor;
            conv.ExternalRelease := relTrue;
            conv.ExternalAutoStartup := autoStart;
            conv.StopSensor := sensorMockQ_False;
            autoStart.startupStatus := StartUpStatus#NotReleased;  // Not released
            
            // Verify setup is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Run cyclic execution
            conv.RunCyclic();
            
            // Assert - Motor should not be running without release
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_Is_Stopped_WhileStartingUp
            // Arrange - Setup conveyor during startup phase
            mockMan.mode := OperatingModes#Automatic;
            conv.Mode := mockMan;
            conv.Motor := mockMotor;
            conv.ExternalRelease := relTrue;
            autoStart.startupStatus := StartUpStatus#AutoStartingUp;  // Still starting up
            conv.StopSensor := sensorMockQ_False;
            conv.ExternalAutoStartup := autoStart;
            
            // Verify setup is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Run cyclic execution
            conv.RunCyclic();
            
            // Assert - Motor should not run during startup phase
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_Starts_After_AutoRelease
            // Arrange - Setup conveyor with auto-release completed
            mockMan.mode := OperatingModes#Automatic;
            conv.Mode := mockMan;
            conv.Motor := mockMotor;
            conv.ExternalRelease := relTrue;
            conv.StopSensor := sensorMockQ_False;
            autoStart.startupStatus := StartUpStatus#AutoStartedUp;  // Fully started up
            conv.ExternalAutoStartup := autoStart;
            
            // Mock timer to pass through immediately
            AxUnit.Mocking.Mock(NAME_OF(System.Timer.OffDelay), NAME_OF(Simatic.Ax.Mocks.OffDelayMock_pass_trough));
            
            // Act - Run cyclic execution
            conv.RunCyclic();
            
            // Assert - Motor should be running after auto-release
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_Stopps_after_loosing_release
            // Arrange - First start conveyor, then lose release
            THIS.Conveyor_Starts_After_AutoRelease();
            autoStart.startupStatus := StartUpStatus#NotReleased;  // Lose release
            
            // Verify setup is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Run cyclic execution after losing release
            conv.RunCyclic();
            
            // Assert - Motor should stop after losing release
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
    END_CLASS

END_NAMESPACE
