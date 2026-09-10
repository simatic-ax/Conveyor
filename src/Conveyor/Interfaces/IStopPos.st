NAMESPACE Simatic.Ax.Conveyor
    /// Interface for stop position monitoring
    /// Provides information about stop position occupancy and sensor status
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    INTERFACE INTERNAL IStopPos
        /// Returns whether the stop position is logically occupied
        /// TRUE = Material present at stop position, FALSE = Stop position free
        METHOD IsOccupied : BOOL
        END_METHOD
        
        /// Returns the raw stop sensor status
        /// TRUE = Sensor covered, FALSE = Sensor free
        METHOD StopSensorStatus : BOOL
        END_METHOD
    END_INTERFACE
END_NAMESPACE
