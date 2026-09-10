# MotorGeneric - Simple Generic Motor Class

## Overview

The [`MotorGeneric`](../src/Motor/MotorGeneric.st) class provides a simple interface for generic motors that only require a start signal to operate. It simulates linear ramp-up behavior using fixed, preconfigured parameters and supports physical output control via the `ItfBinOutput` interface.

## Key Features

- **Simple Operation**: Only requires StartMotor() and StopMotor() calls
- **Fixed Parameters**: Target speed, acceleration, and deceleration set during configuration
- **Linear Ramp-Up/Down**: Smooth, predictable speed changes
- **Physical Output Control**: Automatic control of motor on/off signal via ItfBinOutput
- **Interruption Handling**: Clean stop during ramp-up
- **Status Monitoring**: Real-time ramp progress tracking
- **IEC 61131-3 Compliant**: Standard Structured Text implementation
- **IMotor Interface**: Universal interchangeability with other motor types

## Class Structure

### Public Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `MaxSpeed` | LREAL | Maximum allowed speed in m/s (default: 2.0) |
| `MaxAcceleration` | LREAL | Maximum allowed acceleration in m/s² (default: 2.0) |
| `MaxDeceleration` | LREAL | Maximum allowed deceleration in m/s² (default: 2.0) |
| `MotorOutput` | IBinOutput | Binary output for motor on/off signal control |
| `ExternalRelease` | IRelease | External release control (NULL = always released) |

### Methods

#### Basic Control

**`StartMotor(targetSpeed, acceleration)`**
- Starts the motor with specified target speed and acceleration
- Validates configuration before starting
- **Automatically calls `MotorOutput.SetOn()` if output is configured**
- Respects `ExternalRelease` - motor only starts if released
- Parameters:
  - `targetSpeed` (LREAL) - Target speed in m/s (limited by MaxSpeed)
  - `acceleration` (LREAL) - Acceleration rate in m/s² (limited by MaxAcceleration)

**`StopMotor(deceleration)`**
- Stops the motor with specified deceleration
- **Automatically calls `MotorOutput.SetOff()` if output is configured**
- Parameter:
  - `deceleration` (LREAL) - Deceleration rate in m/s² (limited by MaxDeceleration)

**`Update()`**
- Cyclic update method for motor control
- Must be called regularly (e.g., every PLC cycle)
- Updates internal timers and manages output state

#### Status Queries

**`GetCurrentSpeed() : LREAL`**
- Returns the current simulated speed in m/s

**`IsRunning() : BOOL`**
- Returns TRUE if motor is currently running (speed > tolerance)

**`IsAtSpeed() : BOOL`**
- Returns TRUE if motor has reached target speed

**`IsRampingUp() : BOOL`**
- Returns TRUE if motor is currently ramping up to target speed

**`IsReleased() : BOOL`**
- Returns TRUE if motor is released and can start
- Returns FALSE if blocked by ExternalRelease

## Usage Examples

### Example 1: Basic Motor Control with Output

```iecst
USING Simatic.Ax.Motor;
USING Simatic.Ax.IO.Output;

VAR
    motor : MotorGeneric;
    motorOutput : IBinOutput;
END_VAR

// Configuration
motor.MaxSpeed := 2.0;                 // 2.0 m/s maximum
motor.MaxAcceleration := 1.0;          // 1.0 m/s² maximum
motor.MaxDeceleration := 1.5;          // 1.5 m/s² maximum
motor.MotorOutput := motorOutput;      // Connect physical output

// Configure output (link to hardware address)
motorOutput.SetOutputAddress(address := %Q0.0);

// Start motor with specific parameters - output will be set to ON automatically
motor.StartMotor(targetSpeed := 1.5, acceleration := 0.5);

// Cyclic update (call every PLC cycle)
motor.Update();

// Check status
IF motor.IsAtSpeed() THEN
    // Target speed reached
    ;
END_IF;

// Stop motor with specific deceleration - output will be set to OFF automatically
motor.StopMotor(deceleration := 1.0);
```

### Example 2: Conveyor Application with Motor Output

```iecst
USING Simatic.Ax.Motor;
USING Simatic.Ax.IO.Output;

VAR
    conveyorMotor : MotorGeneric;
    motorOutput : IBinOutput;
    startButton : BOOL;
    stopButton : BOOL;
    emergencyStop : BOOL;
END_VAR

// Configuration (done once during initialization)
conveyorMotor.MaxSpeed := 2.0;              // 2.0 m/s maximum
conveyorMotor.MaxAcceleration := 1.0;       // 1.0 m/s² maximum
conveyorMotor.MaxDeceleration := 1.5;       // 1.5 m/s² maximum
conveyorMotor.MotorOutput := motorOutput;
motorOutput.SetOutputAddress(address := %Q0.1);

// Cyclic execution
IF emergencyStop THEN
    conveyorMotor.StopMotor(deceleration := 1.5);  // Emergency stop, output OFF
ELSIF startButton AND NOT conveyorMotor.IsRunning() THEN
    conveyorMotor.StartMotor(targetSpeed := 1.2, acceleration := 0.8); // Start motor, output ON
ELSIF stopButton AND conveyorMotor.IsRunning() THEN
    conveyorMotor.StopMotor(deceleration := 1.0);  // Normal stop, output OFF
END_IF;

// Update motor control (must be called every cycle)
conveyorMotor.Update();

// Write outputs to hardware
motorOutput.WriteCyclic();
```

### Example 3: Motor Without Physical Output (Simulation)

```iecst
USING Simatic.Ax.Motor;

VAR
    motor : MotorGeneric;
END_VAR

// Configuration without MotorOutput
motor.MaxSpeed := 2.0;
motor.MaxAcceleration := 1.0;
motor.MaxDeceleration := 1.0;
// MotorOutput is NULL - no physical output control

// Motor will work normally, but no physical output is controlled
motor.StartMotor(targetSpeed := 2.0, acceleration := 1.0);
motor.Update();
motor.StopMotor(deceleration := 1.0);
```

### Example 4: Monitoring Ramp Progress

```iecst
VAR
    motor : MotorGeneric;
    currentSpeed : LREAL;
    isRamping : BOOL;
END_VAR

// Configure motor
motor.MaxSpeed := 2.0;
motor.MaxAcceleration := 1.0;

// Start motor
motor.StartMotor(targetSpeed := 1.5, acceleration := 0.5);

// Cyclic monitoring
motor.Update();

currentSpeed := motor.GetCurrentSpeed();
isRamping := motor.IsRampingUp();

IF motor.IsAtSpeed() THEN
    // Target speed reached, proceed with operation
    ;
END_IF;
```

### Example 5: Integration with ConveyorBase

```iecst
USING Simatic.Ax.Conveyor;
USING Simatic.Ax.Motor;
USING Simatic.Ax.IO.Output;

VAR
    conveyor : ConveyorBase;
    motor : MotorGeneric;
    motorOutput : IBinOutput;
    release : IRelease;
END_VAR

// Configure motor
motor.MaxSpeed := 2.0;
motor.MaxAcceleration := 1.0;
motor.MaxDeceleration := 1.5;
motor.MotorOutput := motorOutput;
motor.ExternalRelease := release;
motorOutput.SetOutputAddress(address := %Q0.2);

// Assign motor to conveyor
conveyor.Motor := motor;
conveyor.AutomaticSpeed := 1.5;
conveyor.ManualSpeed := 0.5;
conveyor.Acceleration := 1.0;
conveyor.Deceleration := 1.5;

// Conveyor will automatically control motor start/stop with configured speeds
// Motor output will be controlled automatically
conveyor.RunCyclic();
motor.Update();
motorOutput.WriteCyclic();
```

## Motor Output Control

### ItfBinOutput Interface

The `MotorOutput` property uses the `ItfBinOutput` interface from the `@simatic-ax/io` package. This interface provides:

- **`SetOn()`**: Sets the output to TRUE (motor ON)
- **`SetOff()`**: Sets the output to FALSE (motor OFF)

### Automatic Output Control

The motor automatically controls the output:

| Motor Action | Output State | Method Called |
|-------------|--------------|---------------|
| `StartMotor()` | ON (TRUE) | `MotorOutput.SetOn()` |
| `StopMotor()` | OFF (FALSE) | `MotorOutput.SetOff()` |

### NULL Safety

If `MotorOutput` is NULL (not configured), the motor works normally without controlling any physical output. This is useful for:
- Simulation environments
- Testing without hardware
- Virtual motors

## Ramp Control

### Timer-Based Ramp Control

The motor uses OnDelay and OffDelay timers for acceleration and deceleration:

**Acceleration (OnDelay):**
- Ramp time calculated as: `RampTime = TargetSpeed / Acceleration`
- Motor is "ramping up" while OnDelay timer is active
- Motor reaches "at speed" when OnDelay timer completes

**Deceleration (OffDelay):**
- Ramp time calculated as: `RampTime = CurrentSpeed / Deceleration`
- Motor continues running while OffDelay timer is active
- Motor stops when OffDelay timer completes

## Parameter Validation

The motor automatically limits parameters:
- ✅ `targetSpeed`: Limited to `MaxSpeed` (default: 2.0 m/s)
- ✅ `acceleration`: Limited to `MaxAcceleration` (default: 2.0 m/s²)
- ✅ `deceleration`: Limited to `MaxDeceleration` (default: 2.0 m/s²)
- ✅ `ExternalRelease`: If NULL, motor is always released (backward compatibility)

If parameters are invalid (≤ 0), defaults to maximum values.

## Best Practices

### 1. Configuration
Set all parameters before calling `StartMotor()`:
```iecst
motor.MaxSpeed := 2.0;
motor.MaxAcceleration := 1.0;
motor.MaxDeceleration := 1.5;
motor.MotorOutput := motorOutput;      // Optional
motor.ExternalRelease := release;      // Optional
motor.StartMotor(targetSpeed := 1.5, acceleration := 0.5);
```

### 2. Cyclic Updates
Call `Update()` every PLC cycle:
```iecst
// In cyclic task (e.g., OB1)
motor.Update();
```

### 3. Output Handling
Remember to call `WriteCyclic()` on the output:
```iecst
motor.Update();
motorOutput.WriteCyclic();  // Write to hardware
```

### 4. Emergency Stop
Use `StopMotor()` with high deceleration for emergency stop:
```iecst
IF emergencyCondition THEN
    motor.StopMotor(deceleration := 2.0);  // Fast deceleration stop, output OFF
END_IF;
```

### 5. Status Monitoring
Check status before operations:
```iecst
IF NOT motor.IsRunning() THEN
    motor.StartMotor();
END_IF;
```

## Technical Details

### Thread Safety
Designed for cyclic execution in a single task. For multi-task usage, implement appropriate synchronization.

### Performance
- Minimal computational overhead
- Timer-based control logic
- Suitable for fast cycle times (1-10ms)
- Simple state management

### Memory
- Small memory footprint
- No dynamic allocation
- Fixed-size variables
- Two timer instances (OnDelay, OffDelay)

## Troubleshooting

### Motor Won't Start
- Check `ExternalRelease` is released (or NULL)
- Verify parameters are valid (> 0)
- Ensure `StartMotor()` is called with valid parameters
- Check `IsReleased()` returns TRUE

### Output Not Working
- Verify `MotorOutput` is configured (not NULL)
- Check output address is correct
- Ensure `WriteCyclic()` is called on output
- Verify hardware wiring

### Ramp Too Fast/Slow
- Adjust acceleration/deceleration parameters in `StartMotor()`/`StopMotor()`
- Verify `Update()` is called every cycle
- Check timer calculations

### Speed Not Increasing
- Ensure `Update()` is called cyclically
- Check `IsRunning()` returns TRUE
- Verify `IsRampingUp()` returns TRUE during acceleration
- Check `ExternalRelease` is not blocking motor

## See Also

- [MotorGeneric Implementation](../src/Motor/MotorGeneric.st)
- [MotorGeneric Tests](../test/MotorGeneric/README_MotorGenericTests.md)
- [IMotor Interface](../src/Motor/IMotor.st)
- [TimeProvider Documentation](TimeProvider.md)
- [@simatic-ax/io Package](https://github.com/simatic-ax/io)
