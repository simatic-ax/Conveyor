USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor
    /// Internal class managing receive state logic
    /// Evaluates when conveyor is ready to receive material from upstream conveyor
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    CLASS INTERNAL ReadyToReceive
        IMPLEMENTS IReceiver
        VAR PUBLIC
            /// Reference to stop position for occupancy status
            StopPosition : IStopPos;
            /// Reference to parent equipment for startup status
            Equipment : IEquipmentBase;
            /// Reference to previous (upstream) conveyor for transfer coordination
            PrevConveyor : IDeliverer;
        END_VAR
        VAR PROTECTED
            /// Internal receive state
            _internalReceiveState : ReceiveState;
        END_VAR

        /// Evaluates and updates the receive state based on stop position occupancy and previous conveyor status
        /// State transitions:
        /// - Idle -> ReadyToReceive: Stop position is free and AutoStartedUp
        /// - ReadyToReceive -> Receiving: Previous conveyor starts Delivering
        /// - Receiving -> Idle: Stop position becomes occupied or transfer completes
        /// - Any -> Idle: Not AutoStartedUp
        METHOD PUBLIC EvaluateReceiveStatus : ReceiveState
            VAR_TEMP
                isOccupied : BOOL;
                startupStatus : StartUpStatus;
                prevDeliverState : DeliverState;
            END_VAR

            isOccupied := StopPosition.IsOccupied();
            startupStatus := Equipment.GetStartupStatus();
            
            // Get previous conveyor delivery state if available
            IF (PrevConveyor <> NULL) THEN
                prevDeliverState := PrevConveyor.DeliverStatus();
            ELSE
                prevDeliverState := DeliverState#Idle;
            END_IF;
            
            // State machine logic
            IF (StopPosition <> NULL) THEN
                // Check if previous conveyor is transferring material to us
                // Stay in Receiving state as long as previous conveyor is in Delivering
                IF (prevDeliverState = DeliverState#Delivering) THEN
                    _internalReceiveState := ReceiveState#Receiving;
                ELSIF (NOT isOccupied) AND (prevDeliverState <> DeliverState#Delivering) THEN
                    _internalReceiveState := ReceiveState#ReadyToReceive;
                ELSIF isOccupied THEN
                    _internalReceiveState := ReceiveState#Idle;
                END_IF;
            END_IF;
            
            // No ReadyToReceive when not Automatic Release available
            IF (startupStatus <> StartUpStatus#AutoStartedUp) THEN
                _internalReceiveState := ReceiveState#Idle;
            END_IF;
            
            EvaluateReceiveStatus := _internalReceiveState;
        END_METHOD

        METHOD PUBLIC ReceiveStatus : ReceiveState
            ReceiveStatus := _internalReceiveState;
        END_METHOD
    END_CLASS

END_NAMESPACE
