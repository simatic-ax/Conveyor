USING Simatic.Ax.IO.Output;
USING Simatic.Ax.AutomationBase;
USING System.Timer;

NAMESPACE Simatic.Ax.Motor
    /// Simplified generic motor class with timer-based control
    /// This class provides a simple interface for motors using OnDelay/OffDelay timers.
    /// IsRunning is based on timer output states.
    /// IsAtSpeed indicates when acceleration is complete.
    /// Implements IMotor interface for universal interchangeability with other motor types.
    ///
    /// Features:
    /// - Timer-based start/stop with OnDelay for acceleration and OffDelay for deceleration
    /// - Simple IsRunning logic based on timer states
    /// - Optional physical output control (MotorOutput)
    /// - Optional external release control (ExternalRelease)
    ///
    /// Usage example with initializer (recommended):
    /// VAR
    ///     motorOutput : BinOutput;
    ///     motorRelease : ItfRelease;
    ///     motor : MotorGeneric := (
    ///         TargetSpeed := 1.5,              // Required: 1.5 m/s
    ///         Acceleration := 0.5,             // Required: 0.5 m/s²
    ///         Deceleration := 1.0,             // Required: 1.0 m/s²
    ///         MotorOutput := motorOutput,      // Optional: physical output
    ///         ExternalRelease := motorRelease  // Optional: release control (NULL = always released)
    ///     );
    /// END_VAR
    ///
    /// // Operation
    /// motor.StartMotor();  // Motor starts with acceleration ramp (if ExternalRelease allows)
    /// motor.Update();      // Must be called cyclically
    /// motor.StopMotor();   // Motor decelerates to stop
    CLASS MotorGeneric IMPLEMENTS IMotor
        VAR CONSTANT
            // Default values
            MAX_SPEED : LREAL := 2.0; // [m/s]
            MAX_ACCELERATION : LREAL := 2.0; // [m/s²]
            MAX_DECELERATION : LREAL := 2.0; // [m/s²]
            SPEED_TOLERANCE : LREAL := 0.01; // [m/s]
        END_VAR

        VAR PUBLIC
            /// Overwrite default MAX_SPEED 2.0 that motor should reach (in m/s)
            MaxSpeed : LREAL := MAX_SPEED;
            
            /// Overwrite default MAX_ACCELERATION rate (in m/s²)
            MaxAcceleration : LREAL := MAX_ACCELERATION;
            
            /// Overwrite default MAX_DECELERATION rate (in m/s²)
            MaxDeceleration : LREAL := MAX_DECELERATION;
            
            /// Binary output for motor on/off signal
            /// This output is set to ON when motor is running, OFF when stopped
            MotorOutput : IBinOutput;
            
            /// External release interface - motor can only start when released
            /// This prevents unauthorized motor starts from external calls
            /// If NULL, motor is always released (backward compatibility)
            ExternalRelease : IRelease;
        END_VAR
        
        VAR PRIVATE
            // Timers for acceleration and deceleration
            _onDelayTimer : OnDelay;
            _offDelayTimer : OffDelay;
            
            // Internal state
            _startRequested : BOOL := FALSE;
            
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
            
            _startRequested := TRUE;
            
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
            
            _startRequested := FALSE;
            
            // Set motor output to OFF
            IF MotorOutput <> NULL THEN
                MotorOutput.SetOff();
            END_IF;
        END_METHOD
        
        /// Returns the current calculated speed of the motor (IMotor interface)
        /// Returns effective speed when at speed, 0 when stopped
        METHOD PUBLIC GetCurrentSpeed : LREAL
            IF _onDelayTimer.output THEN
                // Motor is at target speed
                GetCurrentSpeed := _effectiveSpeed;
            ELSE
                // Motor is stopped or ramping
                GetCurrentSpeed := 0.0;
            END_IF;
        END_METHOD
        
        /// Returns whether the motor is currently running (IMotor interface)
        /// TRUE = Motor running or ramping, FALSE = Motor stopped
        METHOD PUBLIC IsRunning : BOOL
            // Motor is running if OnDelay output is true OR OffDelay is still active
            IsRunning := _onDelayTimer.output OR _offDelayTimer.output;
        END_METHOD
        
        /// Returns whether the motor is currently ramping up
        /// TRUE = Ramping up to target speed, FALSE = Not ramping up
        METHOD PUBLIC IsRampingUp : BOOL
            // Motor is ramping up if start requested but OnDelay not yet complete
            IsRampingUp := _startRequested AND NOT _onDelayTimer.output;
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
            // Motor is at speed when OnDelay timer has completed
            IsAtSpeed := _onDelayTimer.output;
        END_METHOD
        
        /// Cyclic update method - must be called regularly
        /// Updates timer states using effective values
        METHOD PUBLIC Update
            VAR_TEMP
                accelTime : TIME;
                decelTime : TIME;
            END_VAR
            
            // Calculate acceleration time (time to reach effective speed)
            IF _effectiveAcceleration > 0.0 THEN
                accelTime := TO_TIME(TO_LINT((_effectiveSpeed / _effectiveAcceleration) * 1000.0)); // Convert to milliseconds
            ELSE
                accelTime := T#1s; // Default 1 second
            END_IF;
            
            // Calculate deceleration time (time to stop from effective speed)
            IF _effectiveDeceleration > 0.0 THEN
                decelTime := TO_TIME(TO_LINT((_effectiveSpeed / _effectiveDeceleration) * 1000.0)); // Convert to milliseconds
            ELSE
                decelTime := T#1s; // Default 1 second
            END_IF;
            
            // OnDelay timer for acceleration
            _onDelayTimer(signal := _startRequested, duration := accelTime);
            
            // OffDelay timer for deceleration
            _offDelayTimer(signal := _startRequested, duration := decelTime);
        END_METHOD
        
        /// Validates the motor configuration
        /// Returns TRUE if configuration is valid, FALSE otherwise
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
            
            // Check if TargetSpeed is positive (must be > 0)
            IF MaxSpeed <= 0.0 THEN
                isValid := FALSE;
            END_IF;
            
            // Calculate absolute speed for validation
            absTargetSpeed := MaxSpeed;
            IF absTargetSpeed < 0.0 THEN
                absTargetSpeed := -absTargetSpeed;
            END_IF;
            
            // Check if absolute TargetSpeed must not exceed MAX_SPEED
            IF absTargetSpeed > MAX_SPEED THEN
                isValid := FALSE;
            END_IF;
            
            // Check if Acceleration is positive and within limits
            IF MaxAcceleration <= 0.0 OR MaxAcceleration > MAX_ACCELERATION THEN
                isValid := FALSE;
            END_IF;
            
            // Check if Deceleration is positive and within limits
            IF MaxDeceleration <= 0.0 OR MaxDeceleration > MAX_DECELERATION THEN
                isValid := FALSE;
            END_IF;
            
            ValidateConfiguration := isValid;
        END_METHOD
        
    END_CLASS

END_NAMESPACE
