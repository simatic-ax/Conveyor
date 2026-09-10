# MotorGeneric Class Tests

Comprehensive test suite for the [`MotorGeneric`](../../src/Motor/MotorGeneric.st) class - a simple generic motor with fixed ramp-up parameters.

## Test Organization

Tests are organized by context into separate folders:

### 1. Basic Tests (`test/MotorGeneric/Basic/`)
**File:** [`MotorGenericBasicTest.st`](Basic/MotorAsyncBasicTest.st)

Tests fundamental motor operations:
- ✅ Initial state verification
- ✅ Start motor functionality
- ✅ Stop motor functionality
- ✅ Speed retrieval
- ✅ Reset functionality

**Tests: 7**

### 2. Ramp-Up Tests (`test/MotorGeneric/RampUp/`)
**File:** [`MotorGenericRampUpTest.st`](RampUp/MotorAsyncRampUpTest.st)

Tests ramp-up simulation logic:
- ✅ Linear speed increase (half time, quarter time)
- ✅ Reaching target speed
- ✅ Behavior beyond ramp time
- ✅ Multiple small updates
- ✅ Very small cycle times (10ms)
- ✅ Ramp from non-zero speed

**Tests: 7**

### 3. Interruption Tests (`test/MotorGeneric/Interruption/`)
**File:** [`MotorGenericInterruptionTest.st`](Interruption/MotorAsyncInterruptionTest.st)

Tests ramp-up interruption scenarios:
- ✅ Stop during ramp-up
- ✅ Immediate effect of stop
- ✅ Restart after interruption
- ✅ Multiple interruptions
- ✅ Stop at end of ramp-up
- ✅ Immediate stop after start

**Tests: 6**

### 4. Validation Tests (`test/MotorGeneric/Validation/`)
**File:** [`MotorGenericValidationTest.st`](Validation/MotorAsyncValidationTest.st)

Tests parameter validation:
- ✅ Zero/negative target speed
- ✅ Zero/negative acceleration
- ✅ Zero/negative ramp time
- ✅ Valid parameter acceptance
- ✅ Very small valid values

**Tests: 8**

### 5. Status Tests (`test/MotorGeneric/Status/`)
**File:** [`MotorGenericStatusTest.st`](Status/MotorAsyncStatusTest.st)

Tests status and monitoring methods:
- ✅ IsRampingUp() status
- ✅ HasReachedTargetSpeed() detection
- ✅ GetElapsedRampTime() tracking
- ✅ GetRemainingRampTime() calculation

**Tests: 10**

### 6. Integration Tests (`test/MotorGeneric/Integration/`)
**File:** [`MotorGenericIntegrationTest.st`](Integration/MotorAsyncIntegrationTest.st)

Tests complete operational scenarios:
- ✅ Complete start/stop cycles
- ✅ Realistic conveyor scenarios (10ms cycles)
- ✅ Multiple start/stop cycles
- ✅ Partial ramp-up then complete
- ✅ Slow ramp with many small updates
- ✅ Fast ramp with large updates

**Tests: 6**

## Total Test Coverage

**44 tests** covering:
- Basic motor operations
- Linear ramp-up simulation
- Ramp interruption handling
- Parameter validation
- Status monitoring
- Realistic operational scenarios

## Running the Tests

### Run All MotorGeneric Tests

```bash
# Run all tests
apax test

# Run with LLVM engine (fast simulation)
apax test --engine llvm

# Run with coverage
apax test --engine llvm --coverage
```

### Run Specific Test Context

```bash
# Run only basic tests
apax test --filter "MotorGenericTests.Basic"

# Run only ramp-up tests
apax test --filter "MotorGenericTests.RampUp"

# Run only interruption tests
apax test --filter "MotorGenericTests.Interruption"

# Run only validation tests
apax test --filter "MotorGenericTests.Validation"

# Run only status tests
apax test --filter "MotorGenericTests.Status"

# Run only integration tests
apax test --filter "MotorGenericTests.Integration"
```

## Test Scenarios

### Basic Functionality
```iecst
motor.TargetSpeed := REAL#100.0;
motor.FixedAcceleration := REAL#10.0;
motor.RampUpTimeSeconds := REAL#10.0;
motor.StartMotor();
// Motor starts ramping up

motor.Update(CycleTimeSeconds := REAL#5.0);
// Speed is now 50%

motor.StopMotor();
// Motor stops immediately, speed resets to 0
```

### Ramp-Up Simulation
```iecst
// Linear ramp: Speed = InitialSpeed + (TargetSpeed - InitialSpeed) * (ElapsedTime / RampUpTime)
motor.StartMotor();
motor.Update(CycleTimeSeconds := REAL#2.5);
// After 2.5s of 10s ramp: Speed = 0 + (100 - 0) * (2.5 / 10) = 25%
```

### Interruption Handling
```iecst
motor.StartMotor();
motor.Update(CycleTimeSeconds := REAL#3.0);
// Speed is 30%

motor.StopMotor();
// Ramp interrupted, speed reset to 0

motor.StartMotor();
// New ramp starts from 0, not from 30%
```

### Parameter Validation
```iecst
// Invalid configuration - motor won't start
motor.TargetSpeed := REAL#0.0;  // Invalid
motor.StartMotor();
// MotorStatus remains FALSE

// Valid configuration
motor.TargetSpeed := REAL#100.0;
motor.FixedAcceleration := REAL#10.0;
motor.RampUpTimeSeconds := REAL#10.0;
motor.StartMotor();
// MotorStatus is TRUE
```

## Key Features Tested

### 1. Fixed Parameters
- Target speed, acceleration, and ramp time are set during configuration
- Cannot be changed during operation
- Must be valid before motor can start

### 2. Linear Ramp-Up
- Speed increases linearly over configured ramp time
- Formula: `Speed = InitialSpeed + (TargetSpeed - InitialSpeed) * (ElapsedTime / RampUpTime)`
- Ramp completes when elapsed time >= ramp time

### 3. Interruption Handling
- StopMotor() immediately halts ramp-up
- Speed resets to zero
- Next StartMotor() begins new ramp from zero

### 4. Status Monitoring
- `MotorStatus`: Running/stopped state
- `IsRampingUp()`: Currently ramping up
- `HasReachedTargetSpeed()`: Target reached
- `GetElapsedRampTime()`: Time since ramp start
- `GetRemainingRampTime()`: Time until ramp complete

## Test Patterns

All tests follow the AAA pattern:
```iecst
{Test}
METHOD PUBLIC Test_Description
    // Arrange - Set up test conditions
    motor.TargetSpeed := REAL#100.0;
    motor.RampUpTimeSeconds := REAL#10.0;
    
    // Act - Execute the functionality
    motor.StartMotor();
    motor.Update(CycleTimeSeconds := REAL#5.0);
    
    // Assert - Verify expected results
    Equal(expected := REAL#50.0, actual := motor.CurrentSpeed);
END_METHOD
```

## Edge Cases Covered

- ✅ Zero and negative parameters
- ✅ Very small cycle times (1ms, 10ms)
- ✅ Very small valid values (0.1)
- ✅ Immediate stop after start
- ✅ Multiple start/stop cycles
- ✅ Updates beyond ramp time
- ✅ Ramp from non-zero initial speed

## Expected Behavior

### Valid Operation
1. Configure parameters (TargetSpeed, FixedAcceleration, RampUpTimeSeconds)
2. Call StartMotor() - motor starts, ramp begins
3. Call Update(CycleTimeSeconds) cyclically - speed increases linearly
4. When elapsed time >= ramp time - speed = target speed, ramping stops
5. Call StopMotor() - motor stops, speed resets to zero

### Invalid Configuration
- If any parameter is <= 0, StartMotor() does nothing
- MotorStatus remains FALSE
- No ramp-up occurs

### Interruption
- StopMotor() during ramp-up immediately stops motor
- Speed resets to zero
- Ramp-up flag cleared
- Next StartMotor() begins fresh ramp from zero

## See Also

- [MotorGeneric Implementation](../../src/Motor/MotorGeneric.st)
- [MotorGeneric Documentation](../../docs/MotorGeneric.md)
- [Motor Class Tests](../README_MotorTests.md)
