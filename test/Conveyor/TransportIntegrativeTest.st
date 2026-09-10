USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor

    /// Integration tests for transport control logic
    /// Verifies interaction between ReadyToDeliver, ReadyToReceive, and StopPosition components
    {TestFixture}
    CLASS TransportIntegrativeTest
        VAR
            _rtd : ReadyToDeliver;
            _rtdStateless : ReadyToDeliver;
            _rtr : ReadyToReceive;
            _rtrStateless : ReadyToReceive;
            _stop : StopPosition;
            _stopStateless : StopPosition;
            conv : MockingConveyor;
            convStateless : MockingConveyor;
            eq : MockEquiment;
            eqStateless : MockEquiment;
            stopsensor : MockBinSignal;
            stopsensorStateless : MockBinSignal;
            nextConv : MockingConveyor;
            nextConvStateless : MockingConveyor;
            prevConv : MockingConveyor;
            prevConvStateless : MockingConveyor;
            _internalDeliverState : DeliverState;
            _internalReceiveState : ReceiveState;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            // Initialize stateless instances for each test
            _rtd := _rtdStateless;
            _rtr := _rtrStateless;
            _stop := _stopStateless;
            conv := convStateless;
            eq := eqStateless;
            stopsensor := stopsensorStateless;
            nextConv := nextConvStateless;
            prevConv := prevConvStateless;
        END_METHOD
        
        METHOD PUBLIC Setup
            _rtd.equipment := eq;
            _rtd.NextReceiver := nextConv;
            _rtd.StopPosition := _stop;
            _rtr.StopPosition := conv;
            _rtr.equipment := eq;
            _stop.StopSensor := stopsensor;
            _stop.Equipment := eq;
            _stop.Deliverer := _rtd;
            ;
        END_METHOD
        {Test}
        METHOD PUBLIC ReadyToDeliver_Is_True_when_conveyor_is_occupied_and_autostarted
            // Arrange - Setup transport control logic with occupied conveyor
            THIS.Setup();
            nextConv.RTR := ReceiveState#ReadyToReceive;  // Next conveyor ready
            eq.MockStatus := StartUpStatus#AutoStartedUp;  // Equipment auto-started
            stopsensor.QValue := TRUE;  // Stop sensor covered (item present)

            // Act - First evaluation cycle
            _stop.EvaluateStopPos();
            _internalDeliverState := _rtd.EvaluateDeliverStatus();
            _internalReceiveState := _rtr.EvaluateReceiveStatus();

            // Assert - Transfer should be in progress, ready to receive
            Equal(expected := TRUE, actual := _internalDeliverState = DeliverState#Delivering);
            Equal(expected := TRUE, actual := _internalReceiveState = ReceiveState#ReadyToReceive);

            // Act - Second evaluation cycle (verify state persistence)
            _stop.EvaluateStopPos();
            _internalDeliverState := _rtd.EvaluateDeliverStatus();
            _internalReceiveState := _rtr.EvaluateReceiveStatus();

            // Assert - States should remain consistent
            Equal(expected := TRUE, actual := _internalDeliverState = DeliverState#Delivering);
            Equal(expected := TRUE, actual := _internalReceiveState = ReceiveState#ReadyToReceive);

            // Act - Third evaluation cycle (verify continued stability)
            _stop.EvaluateStopPos();
            _internalDeliverState := _rtd.EvaluateDeliverStatus();
            _internalReceiveState := _rtr.EvaluateReceiveStatus();

            // Assert - States should still be consistent across multiple cycles
            Equal(expected := TRUE, actual := _internalDeliverState = DeliverState#Delivering);
            Equal(expected := TRUE, actual := _internalReceiveState = ReceiveState#ReadyToReceive);

            
        END_METHOD
     
    END_CLASS


END_NAMESPACE
