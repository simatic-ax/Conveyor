USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor

    /// Tests for transporting items to next conveyor
    /// Verifies coordination between conveyors using ReadyToReceive signals
    {TestFixture}
    CLASS TransportToNextConveyorTest
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
            conv.ExternalAutoStartup := autoStart;
            conv.Mode := mode;
            mode.mode := OperatingModes#Automatic;
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_pass_trough');
        END_METHOD

        {Test}
        METHOD PUBLIC Fully_released_Conveyor_is_running_when_Sensor_is_occupied_and_enxt_conv_is_ready_to_receive
            // Arrange - Setup conveyor with sensor covered and next conveyor ready
            nextConv.RTR := ReceiveState#ReadyToReceive;
            sensor.QValue := TRUE;  // Item on sensor
            
            // Act - Run cyclic execution
            conv.RunCyclic();
            
            // Assert - Motor should be running and transfer in progress
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Delivering);
            
            // Act - Continue running multiple cycles
            conv.RunCyclic();
            
            // Assert - Motor should remain running
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Fully_released_and_running_Conveyor_stops_when_Sensor_is_occupied_and_next_conveyor_looses_RTR
            // Arrange - Setup conveyor running with transfer in progress
            THIS.Fully_released_Conveyor_is_running_when_Sensor_is_occupied_and_enxt_conv_is_ready_to_receive();
            
            // Verify motor is running
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Next conveyor loses ready to receive signal
            nextConv.RTR := ReceiveState#Idle;
            sensor.QValue := TRUE;  // Item still on sensor
            conv.RunCyclic();
            
            // Assert - Motor should stop when next conveyor is not ready
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Stopped_and_empty_Conveyor_Starts_After_first_sensor_is_covered_and_then_rtr_becomes_true
            // Arrange - Setup stopped conveyor with next conveyor not ready
            nextConv.RTR := ReceiveState#Idle;
            sensor.QValue := FALSE;
            
            // Run once to complete startup and move to basic position
            conv.RunCyclic();
            
            // Act - Simulate home position run completed (off delay expires)
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            conv.RunCyclic();
            
            // Assert - Motor should be stopped after home position
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
            
            // Act - Item arrives on sensor (but next conveyor not ready yet)
            sensor.QValue := TRUE;
            conv.RunCyclic();
            
            // Assert - Motor should remain stopped, but conveyor is occupied
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
            Equal(expected := TRUE, actual := conv.IsOccupied());
            
            // Act - Next conveyor becomes ready to receive
            nextConv.RTR := ReceiveState#ReadyToReceive;
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_true');
            conv.RunCyclic();
            
            // Assert - Motor should start now that both conditions are met
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Stopped_and_empty_Conveyor_Starts_After_rtr_true_and_then_sensor_becomes_covered
            // Arrange - Setup stopped conveyor with next conveyor not ready
            nextConv.RTR := ReceiveState#Idle;
            sensor.QValue := FALSE;
            
            // Run once to complete startup and move to basic position
            conv.RunCyclic();
            
            // Act - Simulate home position run completed (off delay expires)
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            conv.RunCyclic();
            
            // Assert - Motor should be stopped after home position
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
            
            // Act - Next conveyor becomes ready (but no item yet)
            nextConv.RTR := ReceiveState#ReadyToReceive;
            conv.RunCyclic();
            
            // Assert - Motor should remain stopped without item
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
            
            // Act - Item arrives on sensor
            sensor.QValue := TRUE;
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'System.Timer.OffDelay');
            conv.RunCyclic();
            
            // Assert - Conveyor should be occupied and transfer in progress
            Equal(expected := TRUE, actual := conv.IsOccupied());
            Equal(expected := TRUE, actual := conv.Delivering());
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Item leaves sensor (transfer complete)
            sensor.QValue := FALSE;
            conv.RunCyclic();
            
            // Assert - Transfer finished, conveyor no longer occupied
            Equal(expected := FALSE, actual := conv.Delivering());
            Equal(expected := FALSE, actual := conv.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC Conveyor_is_stopped__when_in_inAutomatic_but_without_release
            // Arrange - Setup conveyor in automatic mode without release
            conv.ExternalRelease := relFalse;  // No release signal
            autoStart.startupStatus := StartUpStatus#NotReleased;
            
            // Verify configuration is valid
            Equal(expected := FALSE, actual := HasConfigErrorTest(eq := conv));
            
            // Act - Run cyclic execution
            conv.RunCyclic();
            
            // Assert - Motor should not run without release signal
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
    END_CLASS

END_NAMESPACE
