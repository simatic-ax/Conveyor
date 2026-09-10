NAMESPACE Simatic.Ax.Conveyor
    /// Main conveyor interface combining all conveyor functionality
    /// Extends IReceiver, IDeliverer, and IStopPos interfaces
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    INTERFACE IConveyor EXTENDS IReceiver, IDeliverer, IStopPos
        /// Manually triggers conveyor start in automatic mode
        /// Only works if startup status is AutoStartedUp and stop position is not occupied
        METHOD TriggerStartInAutomatic
        END_METHOD
        
        /// Starts the conveyor in manual mode
        /// Returns TRUE if start command was accepted, FALSE otherwise
        /// Requires manual operating mode and external release
        METHOD StartManual : BOOL
        END_METHOD
        
        /// Stops the conveyor immediately
        /// Clears manual start flag and initiates motor deceleration
        METHOD Stop
        END_METHOD
    END_INTERFACE

END_NAMESPACE
