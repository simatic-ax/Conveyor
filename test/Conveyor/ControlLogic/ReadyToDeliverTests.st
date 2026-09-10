USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Conveyor

    {TestFixture}
    CLASS ReadyToDeliverTests
        VAR
            rtd : ReadyToDeliver;
            rtdStateless : ReadyToDeliver;
            conv : MockingStopPos;
            convStateless : MockingStopPos;
            eq : MockEquiment;
            eqStateless : MockEquiment;
        END_VAR
        
        {TestSetup}
        METHOD PUBLIC TestSetup
            // Initialize stateless instances for each test
            rtd := rtdStateless;
            conv := convStateless;
            eq := eqStateless;
        END_METHOD
        
        METHOD PUBLIC Setup
            rtd.StopPosition := conv;
            rtd.equipment := eq; 
            ;
        END_METHOD
        {Test}
        METHOD PUBLIC ReadyToDeliver_Is_True_when_conveyor_is_occupied_and_autostarted
            THIS.Setup();
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            conv.Occupied := TRUE;
            rtd.EvaluateDeliverStatus();
            Equal(expected := TRUE, actual := rtd.DeliverStatus() = DeliverState#ReadyToDeliver);
        END_METHOD
        {Test}
        METHOD PUBLIC ReadyToDeliver_Is_FALSE_when_conveyor_is_occupied_and_not_in_autostarted
            THIS.Setup();
            conv.Occupied := TRUE;
            eq.MockStatus := StartUpStatus#AutoStartingUp;
            Equal(expected := FALSE, actual := rtd.DeliverStatus() = DeliverState#ReadyToDeliver);
            eq.MockStatus := StartUpStatus#NotReleased;
            Equal(expected := FALSE, actual := rtd.DeliverStatus() = DeliverState#ReadyToDeliver);
            eq.MockStatus := StartUpStatus#InternalError;
            Equal(expected := FALSE, actual := rtd.DeliverStatus() = DeliverState#ReadyToDeliver);
        END_METHOD
        {Test}
        METHOD PUBLIC ReadyToDeliver_Is_FALSE_when_conveyor_is_not_occupied_but_in_automatic
            THIS.Setup();
            conv.Occupied := FALSE;
            eq.MockStatus := StartUpStatus#AutoStartingUp;
            Equal(expected := FALSE, actual := rtd.DeliverStatus() = DeliverState#ReadyToDeliver);
        END_METHOD
    END_CLASS

END_NAMESPACE
