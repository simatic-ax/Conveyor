USING Simatic.Ax.IO.Input;
USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor
    /// Internal class managing delivery state logic
    /// Evaluates when material is ready to deliver and coordinates transfer with next conveyor
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    CLASS INTERNAL ReadyToDeliver
        IMPLEMENTS IDeliverer
        VAR PUBLIC
            /// Reference to parent equipment for startup status
            Equipment : IEquipmentBase;
            /// Reference to next (downstream) conveyor receiver
            NextReceiver : IReceiver;
            /// Reference to stop position for occupancy status
            StopPosition : IStopPos;
        END_VAR
        VAR PROTECTED
            /// Internal delivery state
            _internalDeliverState : DeliverState;
        END_VAR

        /// Returns the current delivery state
        METHOD PUBLIC DeliverStatus : DeliverState
            DeliverStatus := _internalDeliverState;
        END_METHOD

        /// Evaluates and updates the delivery state based on stop position and next conveyor status
        /// State transitions:
        /// - Idle -> ReadyToDeliver: Stop position becomes occupied
        /// - ReadyToDeliver -> Delivering: Next conveyor signals ReadyToReceive or Receiving
        /// - Delivering -> Idle: Material leaves stop position
        METHOD PUBLIC EvaluateDeliverStatus : DeliverState
            VAR_TEMP
                isOccupied : BOOL;
                stopSensorStatus : BOOL;
                nextReceiveStatus : ReceiveState;
            END_VAR
            
            isOccupied := StopPosition.IsOccupied();
            stopSensorStatus := StopPosition.StopSensorStatus();

            // The conveyor is ready to deliver when:
            // - Conveyor is Occupied
            // - A transfer is active when next conveyor is ReadyToReceive or already Receiving
            // - Only in automatic mode (AutoStartedUp)
            IF (isOccupied) THEN
                _internalDeliverState := DeliverState#ReadyToDeliver;
            END_IF;
            
            IF (NextReceiver <> NULL) THEN
                nextReceiveStatus := NextReceiver.ReceiveStatus();
                // Start transfer when next conveyor is ReadyToReceive or already Receiving
                IF (isOccupied AND (nextReceiveStatus = ReceiveState#ReadyToReceive OR nextReceiveStatus = ReceiveState#Receiving)) THEN
                    _internalDeliverState := DeliverState#Delivering;
                END_IF;
                // Transfer complete when material has left stop position
                IF (_internalDeliverState = DeliverState#Delivering AND NOT(stopSensorStatus) AND NOT(isOccupied)) THEN
                    _internalDeliverState := DeliverState#Idle;
                END_IF;
            END_IF;
            
            // No ReadyToDeliver when not Automatic Release available
            IF (Equipment.GetStartupStatus() <> StartUpStatus#AutoStartedUp) THEN
                _internalDeliverState := DeliverState#Idle;
            END_IF;
            
            EvaluateDeliverStatus := _internalDeliverState;
        END_METHOD
    END_CLASS

END_NAMESPACE
