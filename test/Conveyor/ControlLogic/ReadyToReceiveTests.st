USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Conveyor

    {TestFixture}
    CLASS ReadyToReceiveTests
        VAR
            rtr : ReadyToReceive;
            rtrStateless : ReadyToReceive;
            conv : MockingConveyor;
            convStateless : MockingConveyor;
            eq : MockEquiment;
            eqStateless : MockEquiment;
            prevConv : MockingConveyor;
            prevConvStateless : MockingConveyor;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            // Initialize stateless instances for each test
            rtr := rtrStateless;
            conv := convStateless;
            eq := eqStateless;
            prevConv := prevConvStateless;
        END_METHOD
        
        METHOD PUBLIC Setup
            rtr.StopPosition := conv;
            rtr.equipment := eq; 
            ;
        END_METHOD
        {Test}
        METHOD PUBLIC ReadyToReceive_Is_True_when_conveyor_is_not_occupied_and_autostarted
            THIS.Setup();
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            conv.OCC := FALSE;
            rtr.EvaluateReceiveStatus();
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#ReadyToReceive);
        END_METHOD
        {Test}
        METHOD PUBLIC ReadyToReceive_Is_FALSE_when_conveyor_is_occupied_and_not_in_autostarted
            THIS.Setup();
            conv.OCC := TRUE;
            eq.MockStatus := StartUpStatus#AutoStartingUp;
            Equal(expected := FALSE, actual := rtr.ReceiveStatus() = ReceiveState#ReadyToReceive);
            eq.MockStatus := StartUpStatus#NotReleased;
            Equal(expected := FALSE, actual := rtr.ReceiveStatus() = ReceiveState#ReadyToReceive);
            eq.MockStatus := StartUpStatus#InternalError;
            Equal(expected := FALSE, actual := rtr.ReceiveStatus() = ReceiveState#ReadyToReceive);
        END_METHOD
        {Test}
        METHOD PUBLIC ReadyToReceive_Is_FALSE_when_conveyor_is_not_occupied_but_starting_up
            THIS.Setup();
            conv.OCC := FALSE;
            eq.MockStatus := StartUpStatus#AutoStartingUp;
            Equal(expected := FALSE, actual := rtr.ReceiveStatus() = ReceiveState#ReadyToReceive);
        END_METHOD
        
        {Test}
        METHOD PUBLIC Receiving_state_continues_when_sensor_becomes_occupied_during_transfer
            // Arrange - Setup with previous conveyor in Delivering
            THIS.Setup();
            prevConv := prevConvStateless;
            rtr.PrevConveyor := prevConv;
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            conv.OCC := FALSE;
            prevConv.RTD := DeliverState#Delivering;
            
            // Act - Evaluate receive status while transfer is in progress and not occupied
            rtr.EvaluateReceiveStatus();
            
            // Assert - Should be in Receiving state
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Receiving);
            
            // Act - Sensor becomes occupied (material arrives) but transfer still in progress
            conv.OCC := TRUE;
            rtr.EvaluateReceiveStatus();
            
            // Assert - Should STILL be in Receiving state (not Idle)
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Receiving);
            
            // Act - Transfer completes (previous conveyor goes to Idle)
            prevConv.RTD := DeliverState#Idle;
            rtr.EvaluateReceiveStatus();
            
            // Assert - Now should be Idle because occupied and no transfer
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Idle);
        END_METHOD
        
        {Test}
        METHOD PUBLIC Receiving_state_maintained_throughout_transfer_regardless_of_occupancy
            // Arrange - Setup with previous conveyor in Delivering
            THIS.Setup();
            prevConv := prevConvStateless;
            rtr.PrevConveyor := prevConv;
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            prevConv.RTD := DeliverState#Delivering;
            
            // Test Case 1: Not occupied during transfer
            conv.OCC := FALSE;
            rtr.EvaluateReceiveStatus();
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Receiving);
            
            // Test Case 2: Becomes occupied during transfer
            conv.OCC := TRUE;
            rtr.EvaluateReceiveStatus();
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Receiving);
            
            // Test Case 3: Remains occupied during transfer
            conv.OCC := TRUE;
            rtr.EvaluateReceiveStatus();
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Receiving);
            
            // Test Case 4: Becomes free again during transfer (edge case)
            conv.OCC := FALSE;
            rtr.EvaluateReceiveStatus();
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Receiving);
        END_METHOD
        
        {Test}
        METHOD PUBLIC Transition_from_Receiving_to_Idle_only_after_transfer_completes
            // Arrange - Setup receiving material from previous conveyor
            THIS.Setup();
            prevConv := prevConvStateless;
            rtr.PrevConveyor := prevConv;
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            conv.OCC := FALSE;
            prevConv.RTD := DeliverState#Delivering;
            
            // Act - Start receiving
            rtr.EvaluateReceiveStatus();
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Receiving);
            
            // Act - Material arrives (sensor covered)
            conv.OCC := TRUE;
            rtr.EvaluateReceiveStatus();
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Receiving);
            
            // Act - Previous conveyor completes transfer
            prevConv.RTD := DeliverState#Idle;
            rtr.EvaluateReceiveStatus();
            
            // Assert - Now should transition to Idle (occupied, no transfer)
            Equal(expected := TRUE, actual := rtr.ReceiveStatus() = ReceiveState#Idle);
        END_METHOD
    END_CLASS

END_NAMESPACE
