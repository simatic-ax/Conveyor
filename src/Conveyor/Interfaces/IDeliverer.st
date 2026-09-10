NAMESPACE Simatic.Ax.Conveyor
    /// Interface for conveyor delivery functionality
    /// Provides status information about material delivery to downstream conveyors
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    INTERFACE INTERNAL IDeliverer
        /// Returns the current delivery state of the conveyor
        /// Used by downstream conveyors to coordinate material transfer
        METHOD DeliverStatus : DeliverState
        END_METHOD
    END_INTERFACE

    TYPE
        /// Delivery state enumeration
        /// Idle:                Nothing to transfer, conveyor logically empty
        /// ReadyToDeliver:      Conveyor logically occupied, but no transfer in progress (Conveyor stopped)
        /// Delivering:          Conveyor transferring item to next conveyor (Conveyor is running)
        DeliverState : (Idle, ReadyToDeliver, Delivering) := Idle;
    END_TYPE

END_NAMESPACE
