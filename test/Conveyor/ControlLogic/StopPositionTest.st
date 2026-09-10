USING Simatic.Ax.Conveyor.Mocks;
USING Simatic.Ax.Conveyor;
USING AxUnit.Assert;
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Conveyor.ControlLogic
    /// Tests for StopPosition monitoring and occupancy detection
    /// Verifies sensor status, occupancy logic, and state transitions
    {TestFixture}
    CLASS StopPositionTest
        VAR PROTECTED
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
            // Reset to stateless instances for test isolation
            stop := stopStateless;
            sens := sensStateless;
            conv := convStateless;
            eq := eqStateless;
        END_METHOD

        /// Helper method to configure test dependencies
        METHOD PROTECTED Setup
            // Arrange - Wire up dependencies
            stop.Equipment := eq;
            stop.Deliverer := conv;
            stop.StopSensor := sens;
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_not_occupied_when_Q_Sensor_False
            // Arrange - Setup with sensor not covered
            THIS.Setup();
            sens.QValue := FALSE;  // Sensor is free
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Should not be occupied
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_not_occupied_when_Q_Sensor_False_And_Equipment_in_automatic
            // Arrange - Setup with sensor free and equipment running
            THIS.Setup();
            sens.QValue := FALSE;  // Sensor is free
            eq.MockStatus := StartUpStatus#AutoStartedUp;  // Equipment is running
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Should not be occupied
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_not_occupied_when_Q_Sensor_True_and_starting_up
            // Arrange - Setup with sensor covered but still starting up
            THIS.Setup();
            sens.QValue := TRUE;  // Sensor is covered
            eq.MockStatus := StartUpStatus#AutoStartingUp;  // Still starting
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Should not be occupied (startup phase)
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_not_occupied_when_Q_Sensor_True_and_not_released
            // Arrange - Setup with sensor covered but not released
            THIS.Setup();
            sens.QValue := TRUE;  // Sensor is covered
            eq.MockStatus := StartUpStatus#NotReleased;  // Not released
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Should not be occupied (not released)
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC StopPos_is_occupied_when_Q_Sensor_True_and_is_released
            // Arrange - Setup with sensor covered and equipment released
            THIS.Setup();
            sens.QValue := TRUE;  // Sensor is covered
            eq.MockStatus := StartUpStatus#AutoStartedUp;  // Equipment is running
            
            // Act - Evaluate stop position
            stop.EvaluateStopPos();
            
            // Assert - Should be occupied
            Equal(expected := TRUE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC Uncover_Sensor_while_equipment_is_still_started_up_keeps_occupied
            // Arrange - First establish occupied state
            THIS.Setup();
            THIS.StopPos_is_occupied_when_Q_Sensor_True_and_is_released();
            
            // Act - Uncover sensor while still running
            sens.QValue := FALSE;  // Sensor becomes free
            eq.MockStatus := StartUpStatus#AutoStartedUp;  // Still running
            stop.EvaluateStopPos();
            
            // Assert - Should remain occupied (material still present)
            Equal(expected := TRUE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC Stored_Occuoied_removes_when_state_Changes_from_StartingUp_to_StartedUp
            // Arrange - First establish occupied state
            THIS.Setup();
            THIS.StopPos_is_occupied_when_Q_Sensor_True_and_is_released();
            
            // Act - Uncover sensor and change to starting up
            sens.QValue := FALSE;  // Sensor becomes free
            eq.MockStatus := StartUpStatus#AutoStartingUp;  // Change to starting up
            Equal(expected := TRUE, actual := stop.IsOccupied());  // Still occupied
            
            stop.EvaluateStopPos();
            eq.MockStatus := StartUpStatus#AutoStartedUp;  // Change to started up
            
            // Assert - Should clear occupied state
            Equal(expected := FALSE, actual := stop.IsOccupied());
        END_METHOD

        {Test}
        METHOD PUBLIC Sensor_Covered_During_Delivery_Is_Monitored
            // Arrange - Setup with sensor covered during delivery
            THIS.Setup();
            sens.QValue := TRUE;  // Sensor is covered
            eq.MockStatus := StartUpStatus#AutoStartedUp;  // Equipment is running
            conv.RTD := DeliverState#Delivering;  // Delivery in progress
            
            // Act - Evaluate stop position with sensor blocked during delivery
            stop.EvaluateStopPos();
            
            // Assert - Stop position should be occupied and sensor status should be TRUE
            // The Supervision is monitoring the blocked sensor condition
            Equal(expected := TRUE, actual := stop.IsOccupied());
            Equal(expected := TRUE, actual := stop.StopSensorStatus());
        END_METHOD

        {Test}
        METHOD PUBLIC Sensor_Remains_Covered_After_Delivery_Completes
            // Arrange - First establish occupied state during delivery
            THIS.Setup();
            sens.QValue := TRUE;  // Sensor is covered
            eq.MockStatus := StartUpStatus#AutoStartedUp;  // Equipment is running
            conv.RTD := DeliverState#Delivering;  // Delivery in progress
            stop.EvaluateStopPos();
            Equal(expected := TRUE, actual := stop.IsOccupied());
            
            // Act - Delivery completes but sensor remains covered (jammed/blocked)
            conv.RTD := DeliverState#Idle;  // Delivery finished
            stop.EvaluateStopPos();
            
            // Assert - Position should remain occupied because sensor is still covered
            // This indicates a potential sensor jam that would trigger timeout in real operation
            Equal(expected := TRUE, actual := stop.IsOccupied());
            Equal(expected := TRUE, actual := stop.StopSensorStatus());
        END_METHOD

        {Test}
        METHOD PUBLIC Jammed_Sensor_Triggers_Timeout_Error_And_Error_Message
            VAR_TEMP
                i : INT;
            END_VAR
            // Arrange - Setup with sensor jammed (covered) during delivery
            THIS.Setup();
            sens.QValue := TRUE;  // Sensor is covered (jammed)
            eq.MockStatus := StartUpStatus#AutoStartedUp;  // Equipment is running
            conv.RTD := DeliverState#Delivering;  // Delivery in progress
            
            // First call to start the supervision monitoring
            stop.EvaluateStopPos();
            
            // Act - Mock OnDelay timer to simulate timeout condition
            // The Supervision class uses OnDelay internally, so mocking it to return TRUE
            // simulates that the timeout has expired after the sensor remained blocked
            AxUnit.Mocking.Mock('System.Timer.OnDelay', 'Simatic.Ax.Mocks.OnDelayMock_true');
            
            // Call again with mocked timer to trigger timeout error
            stop.EvaluateStopPos();
            
            // Assert - Error code and message should be set due to sensor blocking timeout
            Equal(expected := TO_Word(ErrorState#OtherError), actual := eq.MockErrorCode);
            Equal(expected := 'Sensor blocked timeout', actual := eq.GetErrorText());
        END_METHOD
    END_CLASS

END_NAMESPACE
