NAMESPACE Simatic.Ax.Conveyor
    /// Null Object Pattern implementation for IReceiver
    /// Used as default receiver when no next conveyor is configured (end of line)
    /// Always signals ReadyToReceive to allow the last conveyor to complete transfers
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    CLASS NullReceiver
        IMPLEMENTS IReceiver
        
        /// Returns the receive status
        /// Always returns ReadyToReceive to allow material transfer from previous conveyor
        METHOD PUBLIC ReceiveStatus : ReceiveState
            ReceiveStatus := ReceiveState#ReadyToReceive;
        END_METHOD
    END_CLASS

END_NAMESPACE
