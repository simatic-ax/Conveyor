USING Simatic.Ax.Conveyor;
USING Simatic.Ax.AutomationBase;
NAMESPACE Simatic.Ax
    FUNCTION HasConfigErrorTest : BOOL
        VAR_IN_OUT
            eq : ConveyorBase;
        END_VAR
        eq.RunCyclic();  // Init is now called automatically by RunCyclic
        IF eq.GetError() = ErrorState#ConfigError THEN
            HasConfigErrorTest := TRUE;
            RETURN;
        END_IF;
        ;
    END_FUNCTION
END_NAMESPACE
