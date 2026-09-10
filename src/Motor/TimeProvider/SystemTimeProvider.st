USING Siemens.Simatic.Clocks;

NAMESPACE Simatic.Ax.Motor
    /// System time provider using Siemens.Simatic.Clocks
    /// Returns the delta time (time difference) between consecutive calls
    CLASS SystemTimeProvider IMPLEMENTS ITimeProvider
        VAR PRIVATE
            _systemDateTime : LDATE_AND_TIME;
            _currentTimeNs : LINT;
            _lastTimeNs : LINT;
            _firstCall : BOOL := TRUE;
        END_VAR
        
        /// Returns the delta time in milliseconds since the last call
        /// On first call, returns 0
        METHOD PUBLIC GetCurrentTimeMs : LINT
            VAR_TEMP
                deltaTimeNs : LINT;
                deltaTimeMs : LINT;
            END_VAR
            
            // Get current system date and time
            GetSystemDateTime(value => _systemDateTime);
            
            // Convert LDATE_AND_TIME to nanoseconds
            // LDATE_AND_TIME represents time in nanoseconds since 1970-01-01
            _currentTimeNs := TO_LINT(TO_LWORD(_systemDateTime));
            
            // Calculate delta time
            IF _firstCall THEN
                // First call: no delta, initialize last time
                _firstCall := FALSE;
                _lastTimeNs := _currentTimeNs;
                deltaTimeMs := LINT#0;
            ELSE
                // Calculate time difference in nanoseconds
                deltaTimeNs := _currentTimeNs - _lastTimeNs;
                
                // Convert nanoseconds to milliseconds (1 ms = 1,000,000 ns)
                deltaTimeMs := deltaTimeNs / LINT#1000000;
                
                // Update last time for next call
                _lastTimeNs := _currentTimeNs;
            END_IF;
            
            GetCurrentTimeMs := deltaTimeMs;
        END_METHOD
        
        /// Returns the delta time in nanoseconds since the last call
        /// On first call, returns 0
        METHOD PUBLIC GetCurrentTimeNs : LINT
            VAR_TEMP
                deltaTimeNs : LINT;
            END_VAR
            
            // Get current system date and time
            GetSystemDateTime(value => _systemDateTime);
            
            // Convert LDATE_AND_TIME to nanoseconds
            _currentTimeNs := TO_LINT(TO_LWORD(_systemDateTime));
            
            // Calculate delta time
            IF _firstCall THEN
                // First call: no delta, initialize last time
                _firstCall := FALSE;
                _lastTimeNs := _currentTimeNs;
                deltaTimeNs := LINT#0;
            ELSE
                // Calculate time difference in nanoseconds
                deltaTimeNs := _currentTimeNs - _lastTimeNs;
                
                // Update last time for next call
                _lastTimeNs := _currentTimeNs;
            END_IF;
            
            GetCurrentTimeNs := deltaTimeNs;
        END_METHOD
    END_CLASS

END_NAMESPACE
