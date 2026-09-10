# MotorClass - Motor Control for Conveyor Systems

## Overview

The [`MotorClass`](../src/Conveyor/Motor/MotorClass.st) provides a flexible and extensible interface between the [`ConveyorBase`](../src/Conveyor/ConveyorBase.st) and a physical motor. It implements the [`ItfMotor`](../src/Conveyor/Interfaces/ItfMotor.st) interface and offers comprehensive motor control functionality.

## Key Features

- **Speed Control**: Precise control of motor speed (0-100%)
- **Acceleration Ramps**: Smooth acceleration and deceleration
- **Status Monitoring**: Real-time information about motor status and speed
- **Safety Functions**: Emergency stop and parameter validation
- **Extensibility**: Prepared for different motor types and additional parameters

## Class Structure

### Public Attributes

| Attribute | Type | Default | Description |
|----------|-----|---------|-------------|
| `MaxSpeedLimit` | REAL | 100.0 | Maximum allowed speed in % |
| `MinSpeedLimit` | REAL | 0.1 | Minimum speed for motor operation in % |
| `DefaultDeceleration` | REAL | 10.0 | Default deceleration when stopping in %/s |
| `EnableRampControl` | BOOL | TRUE | Enables/disables ramp control |

### Methods

#### Basic Control

**`Init()`**
- Initializes all motor parameters with default values
- Should be called before first use

**`StartMotor(Speed, Acceleration)`**
- Starts the motor with specified speed and acceleration
- Parameters:
  - `Speed`: Target speed in percent (0-100)
  - `Acceleration`: Acceleration in percent/second

**`StopMotor()`**
- Stops the motor with configured deceleration
- With ramp control enabled, performs smooth deceleration

**`SetSpeed(Speed)`**
- Updates the speed of the running motor
- Parameters:
  - `Speed`: New target speed in percent (0-100)

#### Status Queries

**`GetMotorStatus() : BOOL`**
- Returns the current state of the motor
- Return: TRUE = Motor running, FALSE = Motor stopped

**`GetCurrentSpeed() : REAL`**
- Returns the current speed of the motor
- Return: Speed in percent

**`GetCurrentAcceleration() : REAL`**
- Returns the current acceleration of the motor
- Return: Acceleration in percent/second

**`IsAtTargetSpeed() : BOOL`**
- Checks if the motor has reached the target speed
- Return: TRUE when target speed is reached (tolerance: 0.5%)

#### Advanced Functions

**`UpdateMotorSpeed(CycleTime)`**
- Cyclic update for ramp control
- Must be called regularly when ramp control is enabled
- Parameters:
  - `CycleTime`: Cycle time in seconds (e.g. 0.01 for 10ms)

**`EmergencyStop()`**
- Immediate stop without deceleration
- For emergency situations

**`Reset()`**
- Resets all motor parameters
- Motor is stopped and all values set to 0

## Usage Examples

### Example 1: Simple Motor Control

```iecst
VAR
    motor : MotorClass;
END_VAR

// Initialization
motor.Init();

// Start motor at 50% speed with 5%/s acceleration
motor.StartMotor(Speed := REAL#50.0, Acceleration := REAL#5.0);

// Increase speed to 80%
motor.SetSpeed(Speed := REAL#80.0);

// Stop motor
motor.StopMotor();
```

### Example 2: Integration with ConveyorBase

```iecst
NAMESPACE MyApplication

CLASS MyConveyor EXTENDS ConveyorBase
    VAR
        _motor : MotorClass;
        _cycleTime : REAL := REAL#0.01;  // 10ms cycle time
    END_VAR
    
    METHOD PROTECTED OVERRIDE InitUser
        SUPER.InitUser();
        
        // Initialize motor
        _motor.Init();
        _motor.MaxSpeedLimit := REAL#90.0;  // Limit maximum speed to 90%
        _motor.EnableRampControl := TRUE;
    END_METHOD
    
    METHOD OVERRIDE RunCyclicUserCode
        VAR_TEMP
            shouldRun : BOOL;
        END_VAR
        
        // Execute base logic
        SUPER.RunCyclicUserCode();
        
        // Control motor based on conveyor status
        shouldRun := THIS.MotorOnIsReleased();
        
        IF shouldRun AND NOT _motor.GetMotorStatus() THEN
            // Start motor
            _motor.StartMotor(Speed := REAL#75.0, Acceleration := REAL#10.0);
        ELSIF NOT shouldRun AND _motor.GetMotorStatus() THEN
            // Stop motor
            _motor.StopMotor();
        END_IF;
        
        // Update ramp control
        _motor.UpdateMotorSpeed(CycleTime := _cycleTime);
    END_METHOD
END_CLASS

END_NAMESPACE
```

### Example 3: Advanced Control with Status Monitoring

```iecst
VAR
    motor : MotorClass;
    cycleTime : REAL := REAL#0.01;
    targetReached : BOOL;
    currentSpeed : REAL;
END_VAR

// Initialization
motor.Init();
motor.EnableRampControl := TRUE;
motor.DefaultDeceleration := REAL#15.0;  // Faster deceleration

// Start motor
motor.StartMotor(Speed := REAL#60.0, Acceleration := REAL#8.0);

// Cyclic update (e.g. in OB1 or cyclic task)
motor.UpdateMotorSpeed(CycleTime := cycleTime);

// Query status
IF motor.GetMotorStatus() THEN
    currentSpeed := motor.GetCurrentSpeed();
    targetReached := motor.IsAtTargetSpeed();
    
    IF targetReached THEN
        // Target speed reached - further actions...
        ;
    END_IF;
END_IF;
```

### Example 4: Emergency Stop Function

```iecst
VAR
    motor : MotorClass;
    emergencyStopButton : BOOL;
END_VAR

// Normal motor control
IF NOT emergencyStopButton THEN
    motor.StartMotor(Speed := REAL#70.0, Acceleration := REAL#10.0);
ELSE
    // Emergency stop - immediate stop
    motor.EmergencyStop();
END_IF;
```

### Example 5: Without Ramp Control (Direct Operation)

```iecst
VAR
    motor : MotorClass;
END_VAR

// Initialization
motor.Init();
motor.EnableRampControl := FALSE;  // Disable ramp control

// Motor jumps immediately to target speed
motor.StartMotor(Speed := REAL#100.0, Acceleration := REAL#10.0);

// Speed is changed immediately
motor.SetSpeed(Speed := REAL#50.0);

// Motor stops immediately
motor.StopMotor();
```

## Best Practices

### 1. Initialization
Always call `Init()` before first use to ensure all parameters are correctly initialized.

### 2. Ramp Control
- Enable `EnableRampControl` for smooth speed changes
- Call `UpdateMotorSpeed()` cyclically (e.g. every 10ms)
- Adjust `DefaultDeceleration` to your application

### 3. Speed Limits
Set `MaxSpeedLimit` according to your system requirements to prevent overload.

### 4. Error Handling
Use `EmergencyStop()` in emergency situations for immediate stop without deceleration.

### 5. Status Monitoring
Use `IsAtTargetSpeed()` to check when the motor has reached the desired speed.

## Extension Possibilities

The class is prepared for future extensions:

1. **Different Motor Types**: Derive from `MotorClass` for specific motors (servo, frequency converter, etc.)
2. **Additional Parameters**: Torque, power, temperature
3. **Diagnostics**: Operating hours, error counters, maintenance intervals
4. **Communication**: Integration with Profinet, EtherCAT, etc.

## Technical Details

### Parameter Validation
All input parameters are automatically validated and limited:
- Speed: 0 - MaxSpeedLimit (max. 100%)
- Acceleration: 0.1 - 100 %/s

### Ramp Control
The ramp control calculates the speed change per cycle based on:
- Current speed
- Target speed
- Acceleration/deceleration
- Cycle time

### Thread Safety
The class is designed for cyclic execution in a task. When using in multiple tasks, appropriate synchronization mechanisms should be implemented.

## See Also

- [`ConveyorBase`](../src/Conveyor/ConveyorBase.st) - Base class for conveyor systems
- [`ItfMotor`](../src/Conveyor/Interfaces/ItfMotor.st) - Motor interface
- [`ItfConveyor`](../src/Conveyor/Interfaces/ItfConveyor.st) - Conveyor interface
