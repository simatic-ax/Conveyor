USING Simatic.Ax.IO.Output;
USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Motor
    /// Simulated motor class with precise ramp control via TimeProvider
    /// This class provides detailed simulation of motor behavior with configurable ramps.
    /// Uses TimeProvider for precise time-based speed calculations.
    /// Implements IMotor interface for universal interchangeability with other motor types.
    ///
    /// Features:
    /// - Precise acceleration/deceleration ramps via TimeProvider
    /// - Optional physical output control (MotorOutput)
    /// - Optional external release control (ExternalRelease)
    /// - Precise timing via TimeProvider interface
    ///
    /// Usage example with initializer (recommended):
    /// VAR
    ///     timeProvider : SystemTimeProvider;
    ///     motorOutput : BinOutput;
    ///     motorRelease : ItfRelease;
    ///     motor : MotorSimulated := (
    ///         MaxSpeed := 1.5,              // Required: 1.5 m/s
    ///         MaxAcceleration := 0.5,        // Required: 0.5 m/s²
    ///         MaxDeceleration := 1.0,        // Required: 1.0 m/s²
    ///         TimeProvider := timeProvider,    // Required: for ramp control
    ///         MotorOutput := motorOutput,      // Optional: physical output
    ///         ExternalRelease := motorRelease  // Optional: release control (NULL = always released)
    ///     );
    /// END_VAR
    ///
    /// // Operation
    /// motor.StartMotor();  // Motor starts with fixed ramp-up (if ExternalRelease allows)
    /// motor.Update();      // Must be called cyclically for ramp control
    /// motor.StopMotor();   // Motor decelerates to stop
    CLASS MotorSimulated IMPLEMENTS IMotor
        VAR CONSTANT
            // Default values
            MAX_SPEED : LREAL := 2.0; // [m/s]
            MAX_ACCELERATION : LREAL := 2.0; // [m/s²]
            MAX_DECELERATION : LREAL := 2.0; // [m/s²]
            SPEED_TOLERANCE : LREAL := 0.01; // [m/s]
        END_VAR

        VAR PUBLIC
            /// Overwrite default MAX_ACCELERATION rate (in m/s²)
            MaxAcceleration : LREAL := MAX_ACCELERATION;
            
            /// Overwrite default MAX_DECELERATION rate (in m/s²)
            MaxDeceleration : LREAL := MAX_DECELERATION;
            
            /// Overwrite default MAX_SPEED that motor should reach (in m/s)
            MaxSpeed : LREAL := MAX_SPEED;
            
            /// Time provider interface (must be set before using the motor)
            TimeProvider : ITimeProvider;
            
            /// Enables ramp control for smooth acceleration/deceleration
            /// If FALSE, motor jumps directly to target speed (useful for simulation)
            EnableRampControl : BOOL := TRUE;
            
            /// Binary output for motor on/off signal
            /// This output is set to ON when motor is running, OFF when stopped
            MotorOutput : IBinOutput;
            
            /// External release interface - motor can only start when released
            /// This prevents unauthorized motor starts from external calls
            /// If NULL, motor is always released (backward compatibility)
            ExternalRelease : IRelease;
        END_VAR
        
        VAR PROTECTED
            /// Current simulated speed of the motor
            _currentSpeed : LREAL := 0.0;
            
            /// Current acceleration value
            _currentAcceleration : LREAL := 0.0;
        END_VAR
        
        VAR PRIVATE
            // Internal state tracking
            _isRampingUp : BOOL := FALSE;
            _isStopping : BOOL := FALSE;
            _lastUpdateTimeNs : LINT := LINT#0;
            _isFirstUpdate : BOOL := TRUE;
            
            // Effective values used for current operation
            _effectiveSpeed : LREAL := 0.0;
            _effectiveAcceleration : LREAL := 0.0;
            _effectiveDeceleration : LREAL := 0.0;
        END_VAR
        
        /// Starts the motor with specified parameters
        /// targetSpeed: Target speed in m/s (limited by MaxSpeed)
        /// acceleration: Acceleration rate in m/s² (limited by MaxAcceleration)
        METHOD PUBLIC StartMotor
            VAR_INPUT
                targetSpeed : LREAL;
                acceleration : LREAL;
            END_VAR
            VAR_TEMP
                effectiveSpeed : LREAL;
                effectiveAcceleration : LREAL;
            END_VAR
            
            // Validate configuration before starting
            IF NOT THIS.ValidateConfiguration() THEN
                RETURN;
            END_IF;
            
            // Limit targetSpeed to MaxSpeed
            effectiveSpeed := targetSpeed;
            IF effectiveSpeed > MaxSpeed THEN
                effectiveSpeed := MaxSpeed;
            END_IF;
            IF effectiveSpeed <= 0.0 THEN
                effectiveSpeed := MaxSpeed;
            END_IF;
            
            // Limit acceleration to MaxAcceleration
            effectiveAcceleration := acceleration;
            IF effectiveAcceleration > MaxAcceleration THEN
                effectiveAcceleration := MaxAcceleration;
            END_IF;
            IF effectiveAcceleration <= 0.0 THEN
                effectiveAcceleration := MaxAcceleration;
            END_IF;
            
            // Store effective values for Update() method
            _effectiveSpeed := effectiveSpeed;
            _effectiveAcceleration := effectiveAcceleration;
            
            // Store current acceleration
            _currentAcceleration := effectiveAcceleration;
            
            // If ramp control is disabled, jump to target speed immediately
            IF NOT EnableRampControl THEN
                _currentSpeed := effectiveSpeed;
                _isRampingUp := FALSE;
            ELSE
                // Initialize ramp-up process
                _isRampingUp := TRUE;
            END_IF;
            
            _isStopping := FALSE;
            _isFirstUpdate := TRUE;
            
            // Set motor output to ON
            IF MotorOutput <> NULL THEN
                MotorOutput.SetOn();
            END_IF;
        END_METHOD
        
        /// Stops the motor with specified deceleration
        /// deceleration: Deceleration rate in m/s² (limited by MaxDeceleration)
        METHOD PUBLIC StopMotor
            VAR_INPUT
                deceleration : LREAL;
            END_VAR
            VAR_TEMP
                effectiveDeceleration : LREAL;
            END_VAR
            
            // Limit deceleration to MaxDeceleration
            effectiveDeceleration := deceleration;
            IF effectiveDeceleration > MaxDeceleration THEN
                effectiveDeceleration := MaxDeceleration;
            END_IF;
            IF effectiveDeceleration <= 0.0 THEN
                effectiveDeceleration := MaxDeceleration;
            END_IF;
            
            // Store effective deceleration for Update() method
            _effectiveDeceleration := effectiveDeceleration;
            
            // If ramp control is disabled, stop immediately
            IF NOT EnableRampControl THEN
                _currentSpeed := 0.0;
                _isStopping := FALSE;
                _isRampingUp := FALSE;
            ELSE
                // Start deceleration process
                _isStopping := TRUE;
                _isRampingUp := FALSE;
                _isFirstUpdate := TRUE;
            END_IF;
            
            // Set motor output to OFF
            IF MotorOutput <> NULL THEN
                MotorOutput.SetOff();
            END_IF;
        END_METHOD
        
        /// Returns the current simulated speed of the motor (IMotor interface)
        METHOD PUBLIC GetCurrentSpeed : LREAL
            GetCurrentSpeed := _currentSpeed;
        END_METHOD
        
        /// Returns whether the motor is currently running (IMotor interface)
        /// TRUE = Motor running (speed > tolerance), FALSE = Motor stopped
        METHOD PUBLIC IsRunning : BOOL
            VAR_TEMP
                absSpeed : LREAL;
            END_VAR
            
            // Calculate absolute speed
            absSpeed := _currentSpeed;
            IF absSpeed < 0.0 THEN
                absSpeed := -absSpeed;
            END_IF;
            
            // Use tolerance to avoid floating-point precision issues
            IsRunning := absSpeed > SPEED_TOLERANCE;
        END_METHOD
        
        /// Returns whether the motor is currently ramping up
        /// TRUE = Ramping up to target speed, FALSE = Not ramping up
        METHOD PUBLIC IsRampingUp : BOOL
            IsRampingUp := _isRampingUp;
        END_METHOD
        
        /// Returns whether the motor is released
        /// TRUE = Motor is released and can start, FALSE = Motor is blocked
        METHOD PUBLIC IsReleased : BOOL
            IF ExternalRelease <> NULL THEN
                IsReleased := ExternalRelease.IsReleased();
            ELSE
                // If no ExternalRelease is set, motor is always released (backward compatibility)
                IsReleased := TRUE;
            END_IF;
        END_METHOD
        
        /// Returns whether the motor has reached the target speed (IMotor interface)
        /// TRUE = At target speed, FALSE = Still ramping up
        METHOD PUBLIC IsAtSpeed : BOOL
            VAR_TEMP
                tolerance : LREAL := SPEED_TOLERANCE;
                difference : LREAL;
            END_VAR
            
            // Calculate absolute difference
            difference := _currentSpeed - MaxSpeed;
            IF difference < 0.0 THEN
                difference := -difference;
            END_IF;
            
            IsAtSpeed := (difference <= tolerance) AND NOT _isRampingUp;
        END_METHOD
        
        /// Cyclic update method - must be called regularly to simulate ramp-up/down
        /// Uses the configured TimeProvider to calculate elapsed time in nanoseconds for precision
        METHOD PUBLIC Update
            VAR_TEMP
                currentTimeNs : LINT;
                deltaTimeNs : LINT;
                deltaTimeSeconds : LREAL;
                speedChange : LREAL;
                absCurrentSpeed : LREAL;
                absTargetSpeed : LREAL;
            END_VAR
            
            // Check if time provider is set
            IF TimeProvider = NULL THEN
                RETURN;
            END_IF;
            
            // Get current time from time provider in nanoseconds for precision
            currentTimeNs := TimeProvider.GetCurrentTimeNs();
            
            // Initialize on first update
            IF _isFirstUpdate THEN
                _lastUpdateTimeNs := currentTimeNs;
                _isFirstUpdate := FALSE;
                RETURN;
            END_IF;
            
            // Calculate delta time in nanoseconds
            deltaTimeNs := currentTimeNs - _lastUpdateTimeNs;
            IF deltaTimeNs <= LINT#0 THEN
                RETURN; // Invalid time delta, skip this update
            END_IF;
            _lastUpdateTimeNs := currentTimeNs;
            
            // Convert nanoseconds to seconds for calculation (1 second = 1,000,000,000 ns)
            deltaTimeSeconds := TO_LREAL(deltaTimeNs) / 1000000000.0;
            
            // Handle stopping (deceleration)
            IF _isStopping THEN
                // Calculate speed change: deceleration * time
                speedChange := MaxDeceleration * deltaTimeSeconds;
                
                // Calculate absolute current speed
                absCurrentSpeed := _currentSpeed;
                IF absCurrentSpeed < 0.0 THEN
                    absCurrentSpeed := -absCurrentSpeed;
                END_IF;
                
                // Check if we can stop completely
                IF absCurrentSpeed <= speedChange THEN
                    _currentSpeed := 0.0;
                    _isStopping := FALSE;
                    _currentAcceleration := 0.0;
                ELSE
                    // Decelerate towards zero
                    IF _currentSpeed > 0.0 THEN
                        _currentSpeed := _currentSpeed - speedChange;
                    ELSE
                        _currentSpeed := _currentSpeed + speedChange;
                    END_IF;
                END_IF;
                RETURN;
            END_IF;
            
            // Handle ramping up (acceleration)
            IF _isRampingUp THEN
                // Calculate speed change: acceleration * time (integrator)
                speedChange := MaxAcceleration * deltaTimeSeconds;
                
                // Calculate absolute values for comparison
                absCurrentSpeed := _currentSpeed;
                IF absCurrentSpeed < 0.0 THEN
                    absCurrentSpeed := -absCurrentSpeed;
                END_IF;
                
                absTargetSpeed := MaxSpeed;
                IF absTargetSpeed < 0.0 THEN
                    absTargetSpeed := -absTargetSpeed;
                END_IF;
                
                // Check if we've reached or exceeded target speed
                IF absCurrentSpeed + speedChange >= absTargetSpeed THEN
                    _currentSpeed := MaxSpeed;
                    _isRampingUp := FALSE;
                    _currentAcceleration := 0.0;
                ELSE
                    // Continue accelerating towards target
                    IF MaxSpeed > 0.0 THEN
                        _currentSpeed := _currentSpeed + speedChange;
                    ELSE
                        _currentSpeed := _currentSpeed - speedChange;
                    END_IF;
                END_IF;
            END_IF;
        END_METHOD
        
        /// Validates the motor configuration
        /// Returns TRUE if configuration is valid, FALSE otherwise
        /// Supports both positive (forward) and negative (reverse) speeds
        /// Acceleration and deceleration must always be positive
        METHOD PROTECTED ValidateConfiguration : BOOL
            VAR_TEMP
                isValid : BOOL := TRUE;
                absTargetSpeed : LREAL;
            END_VAR
            
            // Check if motor is released (prevents unauthorized starts)
            IF ExternalRelease <> NULL THEN
                IF NOT ExternalRelease.IsReleased() THEN
                    isValid := FALSE;
                END_IF;
            END_IF;
            
            // Check if TimeProvider is set (required for motor operation)
            IF TimeProvider = NULL THEN
                isValid := FALSE;
            END_IF;
            
            // Calculate absolute speed for validation
            absTargetSpeed := MaxSpeed;
            IF absTargetSpeed < 0.0 THEN
                absTargetSpeed := -absTargetSpeed;
            END_IF;
            
            // Check if absolute MaxSpeed must not exceed MAX_SPEED
            IF absTargetSpeed > MAX_SPEED THEN
                isValid := FALSE;
            END_IF;
            
            // Check if MaxAcceleration is positive and within limits
            IF MaxAcceleration <= 0.0 OR MaxAcceleration > MAX_ACCELERATION THEN
                isValid := FALSE;
            END_IF;
            
            // Check if MaxDeceleration is positive and within limits
            IF MaxDeceleration <= 0.0 OR MaxDeceleration > MAX_DECELERATION THEN
                isValid := FALSE;
            END_IF;
            
            ValidateConfiguration := isValid;
        END_METHOD
        
    END_CLASS

END_NAMESPACE

