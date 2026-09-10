USING AxUnit.Mocking;
NAMESPACE Simatic.Ax.Mocks
    FUNCTION GetSystemTimeMock
        VAR_OUTPUT
            value : LDATE_AND_TIME;
        END_VAR
        VAR_TEMP
            p : REF_TO GetSystemTimerPayload;
        END_VAR
        p ?= AxUnit.Mocking.GetPayload();
        value := p^.GetValue();
    END_FUNCTION

    CLASS GetSystemTimerPayload IMPLEMENTS IPayload
        VAR PUBLIC
            systemTime : LDATE_AND_TIME;
            /// Array of time values to return on consecutive calls
            /// If empty or exhausted, returns systemTime
            timeSequence : ARRAY[0..9] OF LDATE_AND_TIME;
            /// Number of valid entries in timeSequence
            sequenceLength : INT := 0;
        END_VAR
        VAR PROTECTED
            _callCount : INT := 0;
        END_VAR
        
        METHOD PUBLIC GetValue : LDATE_AND_TIME
            VAR_TEMP
                result : LDATE_AND_TIME;
            END_VAR
            
            // If we have a sequence and haven't exhausted it, use sequence
            IF (sequenceLength > 0) AND (_callCount < sequenceLength) THEN
                result := timeSequence[_callCount];
            ELSE
                // Otherwise use the default systemTime
                result := systemTime;
            END_IF;
            
            _callCount := _callCount + 1;
            GetValue := result;
        END_METHOD
        
        /// Reset the call counter (useful for test setup)
        METHOD PUBLIC Reset
            _callCount := 0;
        END_METHOD
        
        /// Set a time sequence for consecutive calls
        /// Example: SetSequence with 3 values will return those on first 3 calls
        METHOD PUBLIC SetTimeAt
            VAR_INPUT
                index : INT;
                timeValue : LDATE_AND_TIME;
            END_VAR
            
            IF (index >= 0) AND (index <= 9) THEN
                timeSequence[index] := timeValue;
                IF index >= sequenceLength THEN
                    sequenceLength := index + 1;
                END_IF;
            END_IF;
        END_METHOD
    END_CLASS

END_NAMESPACE
