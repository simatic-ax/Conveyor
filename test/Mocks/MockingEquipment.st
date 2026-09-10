USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor.Mocks

    CLASS MockEquiment
        IMPLEMENTS IEquipmentBase
        VAR PUBLIC
            MockError : BOOL;
            MockStatus : StartUpStatus;
            MockErrorCode : WORD;
            MockErrorText : STRING[30];
        END_VAR
        VAR PROTECTED
            _error : BOOL;
        END_VAR

        METHOD PUBLIC HasError : BOOL
            HasError := MockError;
        END_METHOD

        METHOD PUBLIC GetStartupStatus : StartUpStatus
            GetStartupStatus := MockStatus;
        END_METHOD

        METHOD PUBLIC GetError : WORD
            GetError := MockErrorCode;
        END_METHOD
        
        METHOD PUBLIC RunCyclic
            ;
        END_METHOD

        METHOD PUBLIC SetError
            VAR_INPUT
                errorState : WORD;
            END_VAR
            _error := TRUE;
            MockErrorCode := errorState;
        END_METHOD

        METHOD PUBLIC SetError
            VAR_INPUT
                errorState : WORD;
                errorText : STRING[30];
            END_VAR
            _error := TRUE;
            MockErrorCode := errorState;
            MockErrorText := errorText;
        END_METHOD

        METHOD PUBLIC GetErrorText : STRING[30]
            GetErrorText := MockErrorText;
        END_METHOD

        METHOD PUBLIC ResetFault
            _error := FALSE;
            MockError := FALSE;
            MockErrorCode := WORD#0;
            MockErrorText := '';
        END_METHOD
    END_CLASS

END_NAMESPACE
