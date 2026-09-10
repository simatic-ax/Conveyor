NAMESPACE Simatic.Ax.Conveyor
    /// Interface for conveyor receive functionality
    /// Provides status information about readiness to receive material from upstream conveyors
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    INTERFACE INTERNAL IReceiver
        /// Returns the current receive state of the conveyor
        /// Used by upstream conveyors to determine if material can be transferred
        METHOD ReceiveStatus : ReceiveState
        END_METHOD
    END_INTERFACE

    TYPE
        /// Receive state enumeration
        /// Idle:            Not ready to receive material (stop position occupied or not started up)
        /// ReadyToReceive:  Ready to accept material from upstream conveyor (stop position free)
        ReceiveState : (Idle, ReadyToReceive, Receiving) := Idle;
    END_TYPE

END_NAMESPACE
