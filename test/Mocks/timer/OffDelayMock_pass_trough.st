NAMESPACE Simatic.Ax.Mocks
    FUNCTION_BLOCK OffDelayMock_pass_trough
        VAR_INPUT
            duration : LTIME;
            signal : BOOL;
        END_VAR
        VAR_OUTPUT
            output : BOOL;
            elapsedTime : LTIME;
        END_VAR
        output := signal;
    END_FUNCTION_BLOCK
END_NAMESPACE
