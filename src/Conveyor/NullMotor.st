USING Simatic.Ax.Motor;
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Conveyor
    /// Null Object Pattern implementation for IMotor
    /// This motor does nothing and is used when no real motor is configured
    /// Allows ConveyorBase to work without a motor instance
    CLASS INTERNAL NullMotor IMPLEMENTS IMotor
        /// Does nothing - null object pattern
        METHOD PUBLIC StartMotor
            VAR_INPUT
                targetSpeed : LREAL;
                acceleration : LREAL;
            END_VAR
            ; // No operation - null object pattern
        END_METHOD
        
        /// Does nothing - null object pattern
        METHOD PUBLIC StopMotor
            VAR_INPUT
                deceleration : LREAL;
            END_VAR
            ; // No operation - null object pattern
        END_METHOD
        // bla bla
        /// Always returns 0.0 - null object pattern
        METHOD PUBLIC GetCurrentSpeed : LREAL
            GetCurrentSpeed := 0.0;
        END_METHOD
        
        /// Always returns FALSE - null object pattern
        METHOD PUBLIC IsRunning : BOOL
            IsRunning := FALSE;
        END_METHOD
        
        /// Always returns FALSE - null object pattern
        METHOD PUBLIC IsAtSpeed : BOOL
            IsAtSpeed := FALSE;
        END_METHOD
        
        /// Always returns FALSE - null object pattern
        METHOD PUBLIC IsRampingUp : BOOL
            IsRampingUp := FALSE;
        END_METHOD
        
        /// Does nothing - null object pattern
        METHOD PUBLIC SetReleased
            VAR_INPUT
                released : BOOL;
            END_VAR
            ; // No operation - null object pattern
        END_METHOD
        
        /// Always returns TRUE - null object pattern (always released)
        METHOD PUBLIC IsReleased : BOOL
            IsReleased := TRUE;
        END_METHOD

        /// Does nothing - null object pattern
        METHOD PUBLIC Update
            ; // No operation - null object pattern
        END_METHOD
    END_CLASS
END_NAMESPACE
