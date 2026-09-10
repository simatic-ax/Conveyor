USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax.Conveyor.Mocks

    CLASS MockAutoStartup
        IMPLEMENTS IAutoStartup
        VAR PUBLIC 
            startupStatus : StartUpStatus;
        END_VAR
        METHOD PUBLIC Status : StartUpStatus
            Status := startupStatus;
        END_METHOD
    END_CLASS
END_NAMESPACE
