USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Conveyor.Mocks

    /// Mock implementation of IResetCommand for testing
    /// Simulates reset manager behavior without actual reset logic
    CLASS MockResetManager
        IMPLEMENTS IResetCommand
        VAR PUBLIC
            /// Tracks if GetResetCommand was called
            GetResetCommandCallCount : INT := 0;
            /// Tracks if ReportError was called
            ReportErrorCallCount : INT := 0;
            /// Simulated reset command state
            ResetCommandActive : BOOL := FALSE;
        END_VAR

        /// Returns TRUE when a reset command is active
        METHOD PUBLIC ResetFaultRequest : BOOL
            GetResetCommandCallCount := GetResetCommandCallCount + 1;
            ResetFaultRequest := ResetCommandActive;
        END_METHOD

        /// Equipment calls this to report it has an active error
        METHOD PUBLIC ReportError
            ReportErrorCallCount := ReportErrorCallCount + 1;
        END_METHOD

        /// Resets the mock state for test isolation
        METHOD PUBLIC Reset
            GetResetCommandCallCount := 0;
            ReportErrorCallCount := 0;
            ResetCommandActive := FALSE;
        END_METHOD
    END_CLASS

END_NAMESPACE
