USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor

    /// Tests for receiving items from previous conveyor
    /// Verifies conveyor starts when previous conveyor signals ready to deliver or transfer in progress
    {TestFixture}
    CLASS ReceiveFromPreviousConveyor
        VAR
            conv, convStateless : ConveyorBase;
            nextConv, nextConvStateless : MockingConveyor;
            prevConv, prevConvStateless : MockingConveyor;
            sensor, sensorStateless : MockBinSignal;
            relTrue,  relTrueStateless : MockIsReleased_TRUE;
            relFalse, relFalseStateless : MockIsReleased_FALSE;
            autoStart, autoStartStateless : MockAutoStartup := (startupStatus := StartUpStatus#AutoStartedUp);
            mode, modeStateless : MockOperatingMode;
            mockMotor, mockMotorStateless : MockMotor;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            // Initialize stateless instances for each test
            conv := convStateless;
            nextConv := nextConvStateless;
            prevConv := prevConvStateless;
            sensor := sensorStateless;
            relTrue := relTrueStateless;
            relFalse := relFalseStateless;
            autoStart := autoStartStateless;
            mode := modeStateless;
            mockMotor := mockMotorStateless;
            mockMotor.Reset();
            
            conv.NextConveyor := nextConv;
            conv.PrevConveyor := prevConv;
            conv.StopSensor := sensor;
            conv.Motor := mockMotor;
            conv.ExternalRelease := relTrue;
            conv.ExternalAutoStartup := autoStart;
            conv.StopSensor := sensor;
            conv.Motor := mockMotor;
            conv.Mode := mode;
            conv.Motor := mockMotor;
            mode.mode := OperatingModes#Automatic;
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_pass_trough');

        END_METHOD
        
        {Test}
        METHOD PUBLIC Idle_Conveyor_Starts_direct_On_Previous_Conveyor_is_ReadyToDeilver
            VAR_TEMP
                motorIsReleased : BOOL;
            END_VAR
            
            // Arrange - Setup conveyor with no sensor coverage, fully started
            sensor.QValue := FALSE;
            autoStart.startupStatus := StartUpStatus#AutoStartedUp;
            
            // Act - Run cyclic for initial home position run
            conv.RunCyclic();
            
            // Assert - Motor should be running for home position
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Simulate home position run finished (off delay expires)
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            conv.RunCyclic();
            motorIsReleased := mockMotor.IsRunning();
            
            // Assert - Motor should stop after home position run completes
            Equal(expected := FALSE, actual := motorIsReleased);
            
            // Act - Previous conveyor announces ready to deliver
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_pass_trough');
            prevConv.RTD := DeliverState#ReadyToDeliver;
            conv.RunCyclic();
            
            // Assert - Motor should start immediately when previous conveyor is ready to deliver
            Equal(expected := TRUE, actual := mockMotor.IsRunning());

        END_METHOD

        {Test}
        METHOD PUBLIC Idle_Conveyor_Starts_direct_On_Previous_Conveyor_is_Delivering
            VAR_TEMP
                motorIsReleased : BOOL;
            END_VAR
            
            // Arrange - Setup conveyor with no sensor coverage, fully started
            sensor.QValue := FALSE;
            autoStart.startupStatus := StartUpStatus#AutoStartedUp;
            
            // Act - Run cyclic for initial home position run
            conv.RunCyclic();
            
            // Assert - Motor should be running for home position
            Equal(expected := TRUE, actual := mockMotor.IsRunning());
            
            // Act - Simulate home position run finished (off delay expires)
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_false');
            conv.RunCyclic();
            motorIsReleased := mockMotor.IsRunning();
            
            // Assert - Motor should stop after home position run completes
            Equal(expected := FALSE, actual := motorIsReleased);
            
            // Act - Previous conveyor announces transfer in progress
            AxUnit.Mocking.Mock('System.Timer.OffDelay', 'Simatic.Ax.Mocks.OffDelayMock_pass_trough');
            prevConv.RTD := DeliverState#Delivering;
            conv.RunCyclic();
            
            // Assert - Motor should start immediately when previous conveyor has transfer in progress
            Equal(expected := TRUE, actual := mockMotor.IsRunning());

        END_METHOD
    END_CLASS

END_NAMESPACE
