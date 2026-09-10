USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
USING MotorTests.Mocks;

NAMESPACE Simatic.Ax.Conveyor

    {TestFixture}
    CLASS TestDemoConfig
        VAR
            op : MockOperatingMode := (mode := OperatingModes#Automatic);
            release : MockIsReleased_TRUE;
            sensor1 : MockBinSignal;
            sensor2 : MockBinSignal;
            sensor3 : MockBinSignal;
            isRuning1 : BOOL;
            isRuning2 : BOOL;
            isRuning3 : BOOL;
            c1 : ConveyorBase;
            c2 : ConveyorBase;
            c3 : ConveyorBase;
     
        END_VAR
        METHOD PUBLIC Setup
            c1.prevConveyor := NULL;
            c1.NextConveyor := c2;
            c1.ExternalRelease := release;
            c1.Mode := op;
            c1.StopSensor := sensor1;
            
            c2.prevConveyor := c1;
            c2.NextConveyor := c3;
            c2.ExternalRelease := release;
            c2.Mode := op;
            c2.StopSensor := sensor1;

            c3.prevConveyor := c2;
            c3.NextConveyor := NULL;
            c3.ExternalRelease := release;
            c3.Mode := op;
            c3.StopSensor := sensor1;
            ;
        END_METHOD
        {Test}
        METHOD PUBLIC Fully_released_Conveyor_is_running_when_Sensor_is_occupied_and_enxt_conv_is_ready_to_receive
            THIS.Setup();
            // Init is now called automatically by RunCyclic
            c1.RunCyclic();
            c2.RunCyclic();
            c3.RunCyclic();
        
            isRuning1 := c1.Motor.IsRunning();
            isRuning2 := c2.Motor.IsRunning();
            isRuning3 := c3.Motor.IsRunning();
        END_METHOD
    END_CLASS

END_NAMESPACE
