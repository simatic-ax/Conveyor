USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Conveyor

    /// Tests for stop position occupied detection
    /// Verifies occupied state based on sensor and equipment startup status
    {TestFixture}
    CLASS StopPositionTest
        VAR
            stop : StopPosition;
            stopStateless : StopPosition;
            sens : MockBinSignal;
            sensStateless : MockBinSignal;
            conv : MockingConveyor;
            convStateless : MockingConveyor;
            eq : MockEquiment;
            eqStateless : MockEquiment;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            // Initialize stateless instances for each test
            stop := stopStateless;
            sens := sensStateless;
            conv := convStateless;
            eq := eqStateless;
        END_METHOD

        METHOD PUBLIC Setup
            stop.Equipment := eq;
            stop.Deliverer := conv;
            stop.StopSensor := sens;
            ;
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_not_occupied_when_Q_Sensor_False
            // Arrange - Setup stop position with sensor not covered
            THIS.Setup();
            sens.QValue := FALSE;
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Stop position should not be occupied without sensor coverage
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_not_occupied_when_Q_Sensor_False_And_Equipment_in_automatic
            // Arrange - Setup stop position with sensor not covered, equipment started
            THIS.Setup();
            sens.QValue := FALSE;
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Stop position should not be occupied without sensor coverage (even if started)
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_not_occupied_when_Q_Sensor_True_and_starting_up
            // Arrange - Setup stop position with sensor covered but equipment starting up
            THIS.Setup();
            sens.QValue := TRUE;
            eq.MockStatus := StartUpStatus#AutoStartingUp;
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Stop position should not be occupied during startup (ignore sensor)
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_not_occupied_when_Q_Sensor_True_and_not_released
            // Arrange - Setup stop position with sensor covered but equipment not released
            THIS.Setup();
            sens.QValue := TRUE;
            eq.MockStatus := StartUpStatus#NotReleased;
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Stop position should not be occupied without release (ignore sensor)
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_occupied_when_Q_Sensor_True_and_is_released
            // Arrange - Setup stop position with sensor covered and equipment started
            THIS.Setup();
            sens.QValue := TRUE;
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Stop position should be occupied when sensor covered and equipment started
            Equal(expected := TRUE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC Uncover_Sensor_while_equipment_is_still_started_up_keeps_occupied
            // Arrange - Setup stop position that was occupied
            THIS.Setup();
            THIS.StopPos_is_occupied_when_Q_Sensor_True_and_is_released();
            
            // Act - Sensor becomes uncovered but equipment still started
            sens.QValue := FALSE;
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            stop.EvaluateStopPos();
            
            // Assert - Stop position should remain occupied (latched state)
            Equal(expected := TRUE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC Stored_Occuoied_removes_when_state_Changes_from_StartingUp_to_StartedUp
            // Arrange - Setup stop position that was occupied
            THIS.Setup();
            THIS.StopPos_is_occupied_when_Q_Sensor_True_and_is_released();
            
            // Act - Sensor uncovered and equipment transitions to starting up
            sens.QValue := FALSE;
            eq.MockStatus := StartUpStatus#AutoStartingUp;
            
            // Assert - Stop position should still be occupied (latched)
            Equal(expected := TRUE, actual := stop.IsOccupied());
            
            // Act - Evaluate and then complete startup
            stop.EvaluateStopPos();
            eq.MockStatus := StartUpStatus#AutoStartedUp;
            
            // Assert - Occupied state should clear after startup cycle completes
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD
    END_CLASS

END_NAMESPACE
