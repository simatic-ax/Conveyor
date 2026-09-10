USING Simatic.Ax.AutomationBase;

NAMESPACE Simatic.Ax.Motor
    /// Interface for motor control
    /// Defines the interface for motor control of a conveyor system
    /// All parameters are configured via public properties before calling methods
    INTERFACE IMotor
        /// Starts the motor with specified parameters
        /// targetSpeed: Target speed in m/s
        /// acceleration: Acceleration rate in m/s²
        METHOD StartMotor
            VAR_INPUT
                targetSpeed : LREAL;
                acceleration : LREAL;
            END_VAR
        END_METHOD

        /// Stops the motor with specified deceleration
        /// deceleration: Deceleration rate in m/s²
        METHOD StopMotor
            VAR_INPUT
                deceleration : LREAL;
            END_VAR
        END_METHOD

        /// Returns the current speed of the motor in m/s
        METHOD GetCurrentSpeed : LREAL
        END_METHOD

        /// Returns whether the motor is currently running
        /// TRUE = Motor running, FALSE = Motor stopped
        METHOD IsRunning : BOOL
        END_METHOD

        /// Returns whether the motor has reached the target speed
        /// TRUE = At target speed, FALSE = Still accelerating/decelerating
        METHOD IsAtSpeed : BOOL
        END_METHOD

        /// Returns whether the motor is currently ramping up
        /// TRUE = Ramping up to target speed, FALSE = Not ramping up
        METHOD IsRampingUp : BOOL
        END_METHOD
                
        /// Returns whether the motor is released
        /// TRUE = Motor is released and can start, FALSE = Motor is blocked
        METHOD IsReleased : BOOL
        END_METHOD

        /// Cyclic update method - must be called regularly for ramp control
        /// Processes acceleration/deceleration based on elapsed time
        METHOD Update
        END_METHOD
    END_INTERFACE

END_NAMESPACE
