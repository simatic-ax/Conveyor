USING Simatic.Ax.IO.Input;
NAMESPACE Simatic.Ax.Conveyor.Mocks

    CLASS MockBinSignal
        IMPLEMENTS IBinSignal
        VAR PUBLIC 
            QValue : BOOL;
            QRisValue : BOOL;
            QFalValue : BOOL;
        END_VAR

    
        METHOD PUBLIC Q : BOOL
            Q := QValue;
        END_METHOD

        METHOD PUBLIC QRis : BOOL
            QRis := QRisValue;
        END_METHOD

        METHOD PUBLIC QFal : BOOL
            QFal := QFalValue;
        END_METHOD

        METHOD PUBLIC QBad : BOOL
            ;
        END_METHOD
END_CLASS
END_NAMESPACE
