USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor

    /// Tests for conveyor occupied status detection
    /// Verifies occupied state based on sensor coverage, operating mode, and startup status
    {TestFixture}
    CLASS ConveyorOccupiedStatus
        VAR
            conv : ConveyorBase;
            convStateless : ConveyorBase;
            mockOperatingMode : MockOperatingMode;
            mockOperatingModeStateless : MockOperatingMode;
            relTrue : MockIsReleased_TRUE;
            relTrueStateless : MockIsReleased_TRUE;
            relFalse : MockIsReleased_FALSE;
            relFalseStateless : MockIsReleased_FALSE;
            autoStart : MockAutoStartup;
            autoStartStateless : MockAutoStartup;
            sensorMockQ_QRis_True : MockBinSignal := (QValue := TRUE, QRisValue := TRUE, QFalValue := FALSE);
            sensorMockQ_True : MockBinSignal := (QValue := TRUE, QRisValue := FALSE, QFalValue := FALSE);
            sensorMockQ_False : MockBinSignal := (QValue := FALSE, QRisValue := FALSE, QFalValue := FALSE);
            convNext : MockingConveyor;
            convNextStateless : MockingConveyor;
            mockMotor : MockMotor;
            mockMotorStateless : MockMotor;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC Setup
            // Initialize stateless instances for each test
            conv := convStateless;
            mockOperatingMode := mockOperatingModeStateless;
            relTrue := relTrueStateless;
            relFalse := relFalseStateless;
            autoStart := autoStartStateless;
            convNext := convNextStateless;
            mockMotor := mockMotorStateless;
            mockMotor.Reset();
        END_METHOD
        
        METHOD PUBLIC SetupAutoStarted
            conv.StopSensor := sensorMockQ_False;
            conv.Motor := mockMotor;
            mockOperatingMode.mode := OperatingModes#Automatic;
            conv.Mode := mockOperatingMode;
            conv.Motor := mockMotor;
            conv.ExternalRelease := relTrue;
            conv.ExternalAutoStartup := autoStart;
            conv.NextConveyor := convNext;
            autoStart.startupStatus := StartUpStatus#AutoStartedUp;
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_is_not_occupied_by_default
            // Arrange - Setup conveyor in auto-started state with no sensor coverage
            THIS.SetupAutoStarted();

            // Verify configuration is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Run cyclic execution
            conv.RunCyclic();
            
            // Assert - Conveyor should not be occupied without sensor coverage
            Equal(expected := FALSE, actual := conv.IsOccupied());
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_Is_occupied_when_sensor_covered_and_automatic_is_on_while_next_is_not_rtr
            // Arrange - Setup conveyor in automatic mode with sensor covered
            THIS.SetupAutoStarted();
            conv.StopSensor := sensorMockQ_True;  // Sensor covered
            conv.Motor := mockMotor;
            // Next conveyor not ready to receive (default state)
            
            // Verify configuration is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Run cyclic execution
            conv.RunCyclic();
            
            // Assert - Conveyor should be occupied when sensor is covered in automatic mode
            Equal(expected := TRUE, actual := conv.IsOccupied());
        END_METHOD
        {Test}
        METHOD PUBLIC Conveyor_Ignores_occupied_state_when_in_manual
            // Arrange - Setup conveyor in manual mode with sensor covered
            THIS.SetupAutoStarted();
            conv.ExternalAutoStartup := NULL;
            conv.StopSensor := sensorMockQ_True;  // Sensor covered
            conv.Motor := mockMotor;
            mockOperatingMode.mode := OperatingModes#Manual;  // Manual mode
            
            // Verify configuration is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(conv));
            
            // Act - Run cyclic execution
            conv.RunCyclic();
            
            // Assert - Conveyor should not report occupied in manual mode (occupied detection disabled)
            Equal(expected := FALSE, actual := conv.IsOccupied());
            
        END_METHOD

        {Test}
        METHOD PUBLIC Conveyor_Is_occupied_when_sensor_covered_and_switch_to_automatic_while_next_is_not_rtr
            // Arrange - Setup conveyor with sensor covered, starting in manual mode
            conv.StopSensor := sensorMockQ_True;  // Sensor covered
            conv.Motor := mockMotor;
            mockOperatingMode.mode := OperatingModes#Manual;
            conv.Mode := mockOperatingMode;
            conv.ExternalRelease := relTrue;
            conv.ExternalAutoStartup := autoStart;
            conv.NextConveyor := convNext;
            
            // Act - Test in NotReleased state (manual mode)
            autoStart.startupStatus := StartUpStatus#NotReleased;
            conv.RunCyclic();
            
            // Assert - Not occupied in manual/not released state
            Equal(expected := FALSE, actual := conv.IsOccupied());
            
            // Act - Test during startup sequence
            autoStart.startupStatus := StartUpStatus#AutoStartingUp;
            conv.RunCyclic();
            
            // Assert - Not occupied during startup
            Equal(expected := FALSE, actual := conv.IsOccupied());
            
            // Act - Complete startup to automatic mode
            autoStart.startupStatus := StartUpStatus#AutoStartedUp;
            conv.RunCyclic();
            
            // Assert - Now occupied after fully started in automatic mode
            Equal(expected := TRUE, actual := conv.IsOccupied());
        END_METHOD
    END_CLASS

END_NAMESPACE
