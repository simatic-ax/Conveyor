USING Simatic.Ax.Motor;
USING Simatic.Ax.AutomationBase;

NAMESPACE MotorTests.Mocks
    /// Mock motor for testing conveyor integration
    /// Simulates motor behavior without actual motor control
    CLASS MockMotor IMPLEMENTS IMotor
        VAR PUBLIC
            // Motor configuration properties (same as MotorGeneric)
            FixedAcceleration : LREAL := 2.0;  // m/s²
            FixedDeceleration : LREAL := 2.0;  // m/s²
            TargetSpeed : LREAL := 10.0;       // m/s
            EnableRampControl : BOOL := TRUE;
            
            // Test control flags
            SimulateStartFailure : BOOL := FALSE;
            SimulateAtSpeed : BOOL := TRUE;
            
            // Counters for test verification
            StartMotorCallCount : INT := 0;
            StopMotorCallCount : INT := 0;
        END_VAR
        
        VAR PROTECTED
            _isRunning : BOOL := FALSE;
            _currentSpeed : LREAL := 0.0;
            _isAtSpeed : BOOL := FALSE;
            _isReleased : BOOL := TRUE;
            _externalRelease : IRelease;
        END_VAR
        
        /// Starts the motor with specified parameters
        METHOD PUBLIC StartMotor
            VAR_INPUT
                targetSpeed : LREAL;
                acceleration : LREAL;
            END_VAR
            
            StartMotorCallCount := StartMotorCallCount + 1;
            
            // Update parameters if provided
            IF targetSpeed > 0.0 THEN
                THIS.TargetSpeed := targetSpeed;
            END_IF;
            IF acceleration > 0.0 THEN
                THIS.FixedAcceleration := acceleration;
            END_IF;
            
            IF NOT SimulateStartFailure THEN
                _isRunning := TRUE;
                
                // Simulate immediate speed if configured or ramp control disabled
                IF SimulateAtSpeed OR NOT EnableRampControl THEN
                    _currentSpeed := THIS.TargetSpeed;
                    _isAtSpeed := TRUE;
                ELSE
                    _currentSpeed := 0.0;
                    _isAtSpeed := FALSE;
                END_IF;
            END_IF;
        END_METHOD
        
        /// Stops the motor with specified deceleration
        METHOD PUBLIC StopMotor
            VAR_INPUT
                deceleration : LREAL;
            END_VAR
            
            StopMotorCallCount := StopMotorCallCount + 1;
            
            // Update deceleration if provided
            IF deceleration > 0.0 THEN
                FixedDeceleration := deceleration;
            END_IF;
            
            _isRunning := FALSE;
            _currentSpeed := 0.0;
            _isAtSpeed := FALSE;
        END_METHOD
        
        /// Returns current speed
        METHOD PUBLIC GetCurrentSpeed : LREAL
            GetCurrentSpeed := _currentSpeed;
        END_METHOD
        
        /// Returns whether motor is running
        METHOD PUBLIC IsRunning : BOOL
            IsRunning := _isRunning;
        END_METHOD
        
        /// Returns whether motor is at target speed
        METHOD PUBLIC IsAtSpeed : BOOL
            IsAtSpeed := _isAtSpeed;
        END_METHOD
        
        /// Returns whether motor is ramping up
        /// Always returns FALSE for mock (simplified behavior)
        METHOD PUBLIC IsRampingUp : BOOL
            IsRampingUp := FALSE;
        END_METHOD
        
        /// Sets the release status of the motor
        METHOD PUBLIC SetReleased
            VAR_INPUT
                released : BOOL;
            END_VAR
            _isReleased := released;
        END_METHOD
        
        /// Returns whether the motor is released
        METHOD PUBLIC IsReleased : BOOL
            IF _externalRelease <> NULL THEN
                IsReleased := _externalRelease.IsReleased();
            ELSE
                IsReleased := _isReleased;
            END_IF;
        END_METHOD

        /// Cyclic update method - mock implementation (does nothing)
        METHOD PUBLIC Update
            ; // Mock implementation - no operation needed
        END_METHOD
        
        /// Resets all counters and states
        METHOD PUBLIC Reset
            _isRunning := FALSE;
            _currentSpeed := 0.0;
            _isAtSpeed := FALSE;
            StartMotorCallCount := 0;
            StopMotorCallCount := 0;
            SimulateStartFailure := FALSE;
            SimulateAtSpeed := TRUE;
            FixedAcceleration := 2.0;
            FixedDeceleration := 2.0;
            TargetSpeed := 10.0;
            EnableRampControl := TRUE;
        END_METHOD
        
        /// Simulates motor reaching target speed
        METHOD PUBLIC SimulateReachTargetSpeed
            IF _isRunning THEN
                _currentSpeed := TargetSpeed;
                _isAtSpeed := TRUE;
            END_IF;
        END_METHOD
    END_CLASS
END_NAMESPACE
