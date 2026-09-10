NAMESPACE Simatic.Ax.Motor
    /// Interface for time providers
    /// Allows different time sources to be used for motor ramp-up simulation
    INTERFACE ITimeProvider
        /// Returns the delta time in milliseconds since last call
        METHOD GetCurrentTimeMs : LINT
        END_METHOD
        
        /// Returns the delta time in nanoseconds since last call
        METHOD GetCurrentTimeNs : LINT
        END_METHOD
    END_INTERFACE

END_NAMESPACE
