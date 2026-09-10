USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor

    /// Tests for end-of-line conveyor behavior with NullReceiver
    /// Verifies that the last conveyor in a line can complete transfers without a next conveyor
    {TestFixture}
    CLASS EndOfLineConveyorTest
        VAR
            conv : ConveyorBase;
            convStateless : ConveyorBase;
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
            nullReceiver : NullReceiver;
            nullReceiverStateless : NullReceiver;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            // Initialize stateless instances for each test
            conv := convStateless;
            sensor := sensorStateless;
            relTrue := relTrueStateless;
            autoStart := autoStartStateless;
            mode := modeStateless;
            mockMotor := mockMotorStateless;
            mockMotor.Reset();
            nullReceiver := nullReceiverStateless;
            
            // Setup end-of-line conveyor (no NextConveyor configured)
            conv.NextConveyor := NULL;  // End of line - will use NullReceiver
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
        METHOD PUBLIC EndOfLine_conveyor_starts_transfer_when_sensor_covered
            // Arrange - End of line conveyor with no next conveyor
            sensor.QValue := FALSE;
            
            // Act - Run cyclic to initialize
            conv.RunCyclic();
            
            // Act - Item arrives on sensor
            sensor.QValue := TRUE;
            conv.RunCyclic();
            
            // Assert - Conveyor should start transfer even without next conveyor
            Equal(expected := TRUE, actual := conv.IsOccupied());
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Delivering);
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC EndOfLine_conveyor_continues_running_until_item_leaves
            // Arrange - Start with item on sensor
            THIS.EndOfLine_conveyor_starts_transfer_when_sensor_covered();
            
            // Assert - Motor should be running
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Continue running while item is on sensor
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            conv.RunCyclic();
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Item leaves sensor (transfer complete)
            sensor.QValue := FALSE;
            conv.RunCyclic();
            
            // Assert - Transfer should be complete, motor still running due to off-delay
            Equal(expected := TRUE, actual := conv.DeliverStatus() = DeliverState#Idle);
            Equal(expected := FALSE, actual := conv.IsOccupied());
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC EndOfLine_conveyor_stops_after_offdelay_expires
            // Arrange - Complete transfer and wait for off-delay
            THIS.EndOfLine_conveyor_continues_running_until_item_leaves();
            
            // Assert - Motor still running after transfer
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Simulate off-delay timer expiring
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            conv.RunCyclic();
            
            // Assert - Motor should stop after off-delay expires
            Equal(expected := FALSE, actual := mockMotor.IsRunning());
        END_METHOD
{Test}
METHOD PUBLIC NullReceiver_always_signals_ReadyToReceive
    // Arrange - NullReceiver already initialized in TestSetup
    
            
            // Act & Assert - NullReceiver should always return ReadyToReceive
            Equal(expected := TRUE, actual := nullReceiver.ReceiveStatus() = ReceiveState#ReadyToReceive);
            
            // Call multiple times to ensure consistent behavior
            Equal(expected := TRUE, actual := nullReceiver.ReceiveStatus() = ReceiveState#ReadyToReceive);
            Equal(expected := TRUE, actual := nullReceiver.ReceiveStatus() = ReceiveState#ReadyToReceive);
        END_METHOD
    END_CLASS

END_NAMESPACE
