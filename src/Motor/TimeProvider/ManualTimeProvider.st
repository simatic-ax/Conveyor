NAMESPACE Simatic.Ax.Motor
    /// Manual time provider for testing and simulation
    /// Allows manual control of time progression
    CLASS ManualTimeProvider IMPLEMENTS ITimeProvider
        VAR PUBLIC
            /// Current time in milliseconds (can be set manually)
            CurrentTimeMs : LINT;
            /// Current time in nanoseconds (can be set manually)
            CurrentTimeNs : LINT;
        END_VAR
        
        /// Returns the manually set current time in milliseconds
        METHOD PUBLIC GetCurrentTimeMs : LINT
            GetCurrentTimeMs := CurrentTimeMs;
        END_METHOD
        
        /// Returns the manually set current time in nanoseconds
        METHOD PUBLIC GetCurrentTimeNs : LINT
            GetCurrentTimeNs := CurrentTimeNs;
        END_METHOD
        
        /// Advances the time by specified milliseconds
        METHOD PUBLIC AdvanceTime
            VAR_INPUT
                DeltaMs : LINT;
            END_VAR
            
            CurrentTimeMs := CurrentTimeMs + DeltaMs;
            CurrentTimeNs := CurrentTimeNs + (DeltaMs * LINT#1000000);
        END_METHOD
        
        /// Advances the time by specified nanoseconds
        METHOD PUBLIC AdvanceTimeNs
            VAR_INPUT
                DeltaNs : LINT;
            END_VAR
            
            CurrentTimeNs := CurrentTimeNs + DeltaNs;
            CurrentTimeMs := CurrentTimeMs + (DeltaNs / LINT#1000000);
        END_METHOD
    END_CLASS

END_NAMESPACE
