USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor

    /// Tests for motor behavior during Delivering state
    /// Verifies that motor continues running during transfer regardless of next conveyor state changes
    {TestFixture}
    CLASS MotorRunsDuringDeliveringTest
        VAR
            conv : ConveyorBase;
            convStateless : ConveyorBase;
            nextConv : MockingConveyor;
            nextConvStateless : MockingConveyor;
            sensor : MockBinSignal;
            sensorStateless : MockBinSignal;
            relTrue : MockIsReleased_TRUE;
            relTrueStateless : MockIsReleased_TRUE;
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
            conv.OffDelayTime := T#2s;
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_pass_trough');
        END_METHOD

        {Test}
        METHOD PUBLIC Motor_continues_running_during_Delivering_when_next_conveyor_changes_state
            // Arrange - Setup conveyor with sensor covered and next conveyor ready
            nextConv.RTR := ReceiveState#ReadyToReceive;
            sensor.QValue := TRUE;  // Item on sensor
            
            // Act - Run cyclic execution to start transfer
            conv.RunCyclic();
            
            // Assert - Motor should be running and transfer in progress
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Delivering);
            
            // Act - Next conveyor changes state to Receiving (simulating material arriving)
            nextConv.RTR := ReceiveState#Receiving;
            conv.RunCyclic();
            
            // Assert - Motor should STILL be running despite next conveyor state change
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Delivering);
            
            // Act - Continue running while sensor still covered (transfer ongoing)
            conv.RunCyclic();
            
            // Assert - Motor should continue running during transfer
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Delivering);
        END_METHOD

        {Test}
        METHOD PUBLIC Motor_continues_running_during_Delivering_over_multiple_cycles
            // Arrange - Setup conveyor with sensor covered and next conveyor ready
            nextConv.RTR := ReceiveState#ReadyToReceive;
            sensor.QValue := TRUE;  // Item on sensor
            
            // Act - Run cyclic execution to start transfer
            conv.RunCyclic();
            
            // Assert - Transfer should be in progress
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Delivering);
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Run multiple cycles while in Delivering
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Assert - Motor should remain running throughout the transfer
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Delivering);
        END_METHOD

        {Test}
        METHOD PUBLIC Motor_stops_only_after_transfer_completes_and_offdelay_expires
            // Arrange - Setup conveyor with sensor covered and next conveyor ready
            nextConv.RTR := ReceiveState#ReadyToReceive;
            sensor.QValue := TRUE;  // Item on sensor
            
            // Act - Run cyclic execution to start transfer
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Item leaves sensor (transfer completes)
            sensor.QValue := FALSE;
            conv.RunCyclic();
            
            // Assert - Transfer should be complete, motor still running due to off-delay
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Idle);
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Simulate off-delay timer expiring
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            nextConv.RTR := ReceiveState#Idle;
            conv.RunCyclic();
            
            // Assert - Now motor should stop after off-delay expires
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
    END_CLASS

END_NAMESPACE
