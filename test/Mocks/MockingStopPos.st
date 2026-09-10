NAMESPACE Simatic.Ax.Conveyor.Mocks

    CLASS MockingStopPos
        IMPLEMENTS IStopPos
        VAR PUBLIC
            Occupied : BOOL;
            Sensor : BOOL;
        END_VAR

    METHOD PUBLIC IsOccupied : BOOL
        IsOccupied := Occupied;
    END_METHOD

    METHOD PUBLIC StopSensorStatus : BOOL
        StopSensorStatus := Sensor;
    END_METHOD
END_CLASS

END_NAMESPACE
