USING Simatic.Ax.Motor;
USING Simatic.Ax.IO.Output;
USING Simatic.Ax.AutomationBase;

NAMESPACE Examples
    /// Example class demonstrating MotorGeneric usage with physical output control
    /// This class shows various use cases of motor control including output handling and release control
    CLASS MotorGenericExample
        VAR
            // Motor instance
            _motor : MotorGeneric;
            
            // Physical output for motor control
            _motorOutput : IBinOutput;
            
            // External release for motor (optional - motor is always released if NULL)
            _motorRelease : IRelease;
            
            // Status variables
            _motorRunning : BOOL;
            _currentSpeed : LREAL;
            _targetReached : BOOL;
            _isRamping : BOOL;
            
            // Control variables
            _startButton : BOOL;
            _stopButton : BOOL;
            _emergencyStop : BOOL;
        END_VAR
        
        /// Initialize the motor
        METHOD PUBLIC Initialize
            // Configure motor parameters
            _motor.MaxSpeed := 2.0;                 // 2.0 m/s maximum speed
            _motor.MaxAcceleration := 1.0;          // 1.0 m/s² maximum acceleration
            _motor.MaxDeceleration := 1.5;          // 1.5 m/s² maximum deceleration
            
            // Assign motor output (will be controlled automatically)
            _motor.MotorOutput := _motorOutput;
            
            // Optional: Assign external release to control when motor can start
            // If not set, motor is always released
            _motor.ExternalRelease := _motorRelease;
            
            // Configure output address (example: Q0.0)
            _motorOutput.SetOutputAddress(address := %Q0.0);
        END_METHOD
        
        /// Cyclic execution - must be called regularly
        METHOD PUBLIC Execute
            // Emergency stop has highest priority
            IF _emergencyStop THEN
                _motor.StopMotor(deceleration := 2.0);  // Fast stop with max deceleration, output OFF
                RETURN;
            END_IF;
            
            // Start button pressed
            IF _startButton AND NOT _motor.IsRunning() THEN
                _motor.StartMotor(targetSpeed := 1.5, acceleration := 0.5);  // Starts motor and sets output ON
            END_IF;
            
            // Stop button pressed
            IF _stopButton AND _motor.IsRunning() THEN
                _motor.StopMotor(deceleration := 1.0);  // Stops motor and sets output OFF
            END_IF;
            
            // Update motor control (must be called every cycle)
            _motor.Update();
            
            // Write output to hardware
            _motorOutput.WriteCyclic();
            
            // Update status
            THIS.UpdateStatus();
        END_METHOD
        
        /// Updates the status variables
        METHOD PRIVATE UpdateStatus
            _motorRunning := _motor.IsRunning();
            _currentSpeed := _motor.GetCurrentSpeed();
            _targetReached := _motor.IsAtSpeed();
            _isRamping := _motor.IsRampingUp();
        END_METHOD
        
        /// Returns the current motor status
        METHOD PUBLIC GetMotorRunning : BOOL
            GetMotorRunning := _motorRunning;
        END_METHOD
        
        /// Returns the current speed
        METHOD PUBLIC GetCurrentSpeed : LREAL
            GetCurrentSpeed := _currentSpeed;
        END_METHOD
        
        /// Returns whether the target speed has been reached
        METHOD PUBLIC IsTargetReached : BOOL
            IsTargetReached := _targetReached;
        END_METHOD
        
        /// Returns whether motor is currently ramping up
        METHOD PUBLIC IsRamping : BOOL
            IsRamping := _isRamping;
        END_METHOD
    END_CLASS
    
    /// Advanced example: Conveyor with MotorGeneric integration
    /// Shows how to integrate MotorGeneric with ConveyorBase
    /// Requires: USING Simatic.Ax.Conveyor;
    (*
    CLASS ConveyorWithMotorGeneric EXTENDS ConveyorBase
        VAR
            // Motor for conveyor belt
            _motor : MotorGeneric;
            
            // Motor output
            _motorOutput : IBinOutput;
            
            // Configuration
            _normalSpeed : LREAL := 1.5;      // 1.5 m/s
            _acceleration : LREAL := 1.0;     // 1.0 m/s²
            _deceleration : LREAL := 1.5;     // 1.5 m/s²
        END_VAR
        
        /// Initialization
        METHOD PROTECTED OVERRIDE InitUser
            // Base initialization
            SUPER.InitUser();
            
            // Configure motor
            _motor.MaxSpeed := 2.0;
            _motor.MaxAcceleration := 1.0;
            _motor.MaxDeceleration := 1.5;
            _motor.MotorOutput := _motorOutput;
            
            // Optional: Share conveyor's ExternalRelease with motor
            // This ensures motor can only start when conveyor is released
            _motor.ExternalRelease := THIS.ExternalRelease;
            
            // Configure output address
            _motorOutput.SetOutputAddress(address := %Q0.1);
            
            // Assign motor to conveyor base
            THIS.Motor := _motor;
            
            // Configure conveyor speeds
            THIS.AutomaticSpeed := _normalSpeed;
            THIS.ManualSpeed := 0.5;
            THIS.Acceleration := _acceleration;
            THIS.Deceleration := _deceleration;
        END_METHOD
        
        /// Cyclic execution
        METHOD OVERRIDE RunCyclicUserCode
            // Execute base logic (handles motor start/stop automatically)
            SUPER.RunCyclicUserCode();
            
            // Update motor control
            _motor.Update();
            
            // Write output to hardware
            _motorOutput.WriteCyclic();
        END_METHOD
        
        /// Returns the current motor speed
        METHOD PUBLIC GetMotorSpeed : LREAL
            GetMotorSpeed := _motor.GetCurrentSpeed();
        END_METHOD
        
        /// Checks if motor is running
        METHOD PUBLIC IsMotorRunning : BOOL
            IsMotorRunning := _motor.IsRunning();
        END_METHOD
        
        /// Checks if motor has reached target speed
        METHOD PUBLIC IsMotorAtSpeed : BOOL
            IsMotorAtSpeed := _motor.IsAtSpeed();
        END_METHOD
    END_CLASS
    *)
    
    /// Simple example without physical output (simulation mode)
    CLASS MotorSimulationExample
        VAR
            _motor : MotorGeneric;
        END_VAR
        
        METHOD PUBLIC Initialize
            // Configure motor without output
            _motor.MaxSpeed := 2.0;
            _motor.MaxAcceleration := 1.0;
            _motor.MaxDeceleration := 1.0;
            // MotorOutput is NULL - no physical output control
        END_METHOD
        
        METHOD PUBLIC Execute
            // Motor works normally without output control
            _motor.Update();
        END_METHOD
        
        METHOD PUBLIC Start
            _motor.StartMotor(targetSpeed := 2.0, acceleration := 1.0);  // No output is controlled
        END_METHOD
        
        METHOD PUBLIC Stop
            _motor.StopMotor(deceleration := 1.0);  // No output is controlled
        END_METHOD
    END_CLASS
    
END_NAMESPACE
