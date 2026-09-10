USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor

    /// Tests for extended running behavior of conveyor
    /// Verifies motor continues running after base position until timeout
    {TestFixture}
    CLASS ExtendRunningForConveyorTest
        VAR
            conv : ConveyorBase;
            convStateless : ConveyorBase;
            nextConv : MockingConveyor;
            nextConvStateless : MockingConveyor;
            sensor : MockBinSignal;
            sensorStateless : MockBinSignal;
            relTrue : MockIsReleased_TRUE;
            relTrueStateless : MockIsReleased_TRUE;
            relFalse : MockIsReleased_FALSE;
            relFalseStateless : MockIsReleased_FALSE;
            autoStart : MockAutoStartup := (startupStatus := StartUpStatus#AutoStartedUp);
            autoStartStateless : MockAutoStartup := (startupStatus := StartUpStatus#AutoStartedUp);
            mode : MockOperatingMode;
            modeStateless : MockOperatingMode;
            mockMotor : MockMotor;
            mockMotorStateless : MockMotor;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            // Initialize stateless instances for each test
            conv := convStateless;
            nextConv := nextConvStateless;
            sensor := sensorStateless;
            relTrue := relTrueStateless;
            relFalse := relFalseStateless;
            autoStart := autoStartStateless;
            mode := modeStateless;
            mockMotor := mockMotorStateless;
            mockMotor.Reset();
            
            // Setup conveyor configuration
            conv.NextConveyor := nextConv;
            conv.StopSensor := sensor;
            conv.Motor := mockMotor;
            conv.ExternalRelease := relTrue;
            conv.Mode := mode;
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_Stopps_after_base_position_run_after_timeout
            // Arrange - Setup conveyor in manual mode, not released
            conv.ExternalAutoStartup := autoStart;
            autoStart.startupStatus := StartUpStatus#NotReleased;
            
            // Mock timer to pass through immediately (no delay)
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_pass_trough');
            
            mode.mode := OperatingModes#Manual;
            sensor.QValue := FALSE;  // No item on sensor
            
            // Act - Run cyclic in manual mode
            conv.RunCyclic();
            
            // Assert - Motor should not be running in manual mode without release
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
            
            // Act - Switch to automatic mode and complete startup
            mode.mode := OperatingModes#Automatic;
            autoStart.startupStatus := StartUpStatus#AutoStartedUp;
            conv.RunCyclic();
            
            // Assert - Motor should start running after switching to automatic with completed startup
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
        END_METHOD
    END_CLASS

END_NAMESPACE
