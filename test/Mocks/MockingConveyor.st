NAMESPACE Simatic.Ax.Conveyor.Mocks

    CLASS MockingConveyor
        IMPLEMENTS IConveyor
        VAR PUBLIC
            RTD : DeliverState;
            RTR : ReceiveState;
            TIP : BOOL;
            OCC : BOOL;
        END_VAR

        METHOD PUBLIC TriggerStartInAutomatic
            ;
        END_METHOD

        METHOD PUBLIC StartManual : BOOL
            ;
        END_METHOD

        METHOD PUBLIC Stop
            ;
        END_METHOD

        METHOD PUBLIC IsOccupied : BOOL
            IsOccupied := OCC;
        END_METHOD

        METHOD PUBLIC MotorOnIsReleased : BOOL
            ;
        END_METHOD

        METHOD PUBLIC ReceiveStatus : ReceiveState
            ReceiveStatus := RTR;
        END_METHOD

        METHOD PUBLIC DeliverStatus : DeliverState
            DeliverStatus := RTD;
        END_METHOD

        METHOD PUBLIC Delivering : BOOL
            Delivering := TIP;
        END_METHOD

    METHOD PUBLIC StopSensorStatus : BOOL
        ;
    END_METHOD
END_CLASS

END_NAMESPACE
