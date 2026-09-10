# Testing Documentation

## Overview

This document describes the test structure and test cases for the Conveyor system. All tests are written using the AxUnit testing framework.

## Test Structure

```
test/
├── Conveyor Tests
│   ├── ConveyorAutoStartupTest.st
│   ├── ConveyorManualModeTest.st
│   ├── ConveyorMotorIntegrationTest.st
│   ├── ConveyorOccupiedStatus.st
│   ├── ExtendRunningForConveyorTest.st
│   ├── ReadyToDeliverTests.st
│   ├── ReadyToReceiveTests.st
│   ├── ReceiveFromPreviousConveyor.st
│   ├── StopPositionTest.st
│   ├── TransportIntegrativeTest.st
│   └── TransportToNextConveyorTest.st
│
├── Motor Tests
│   └── MotorGeneric/
│       ├── Basic/MotorGenericBasicTest.st
│       ├── Integration/MotorGenericIntegrationTest.st
│       ├── Interruption/MotorGenericInterruptionTest.st
│       ├── Validation/MotorGenericValidationTest.st
│       └── RampPrecision/MotorGenericRampPrecisionTest.st
│
├── TimeProvider Tests
│   └── TimeProvider/TimeProviderTest.st
│
└── Mocks
    ├── MockMotor.st
    ├── MockingConveyor.st
    ├── MockingEquipment.st
    ├── MockingOperatingModes.st
    └── timer/GetSystemTimeMock.st
```

---

## Conveyor Tests

### ConveyorAutoStartupTest
Tests automatic startup behavior of conveyors.

**Test Cases:**
- Automatic startup sequence
- Startup status transitions
- Auto-release functionality
- Startup with occupied stop position

### ConveyorManualModeTest
Tests manual mode operation.

**Test Cases:**
- Manual start command
- Manual stop command
- Mode switching between manual and automatic
- Release requirements in manual mode

### ConveyorMotorIntegrationTest
Tests integration between conveyor and motor control.

**Test Cases:**
- Motor starts when conveyor conditions are met
- Motor stops when conditions are no longer met
- Motor speed control
- Motor state synchronization with conveyor state

### ConveyorOccupiedStatus
Tests stop position occupancy detection.

**Test Cases:**
- Occupancy detection when sensor is covered
- Occupancy clearing during transfer
- Occupancy state persistence
- Edge cases with sensor transitions

### ReadyToDeliverTests
Tests delivery state logic.

**Test Cases:**
- Transition to ReadyToDeliver when occupied
- Transition to TransferInProgress when next conveyor ready
- Transition back to Idle after transfer complete
- State behavior without automatic release

### ReadyToReceiveTests
Tests receive state logic.

**Test Cases:**
- Transition to ReadyToReceive when stop position free
- Transition to Idle when stop position occupied
- State behavior during startup
- State behavior without automatic release

### StopPositionTest
Tests stop position monitoring and sensor supervision.

**Test Cases:**
- Stop sensor status detection
- Occupancy logic evaluation
- Sensor blocking detection with timeout
- Error handling for blocked sensors

### TransportToNextConveyorTest
Tests material transfer to downstream conveyor.

**Test Cases:**
- Transfer initiation when next conveyor ready
- Transfer completion detection
- Motor control during transfer
- Off-delay timing after transfer

### ReceiveFromPreviousConveyor
Tests material reception from upstream conveyor.

**Test Cases:**
- Ready to receive signaling
- Material acceptance from previous conveyor
- Stop position occupancy after reception
- Coordination with upstream conveyor states

### TransportIntegrativeTest
End-to-end integration tests for complete transport scenarios.

**Test Cases:**
- Multi-conveyor transport chain
- Material flow through multiple conveyors
- Coordinated start/stop sequences
- Error propagation through chain

---

## Motor Tests

### MotorGenericBasicTest
Basic functionality tests for MotorGeneric class.

**Test Cases:**
- **Test_StartMotor_SetsRunningState**: Verifies motor enters running state after start
- **Test_StopMotor_ClearsRunningState**: Verifies motor stops and clears running state
- **Test_GetCurrentSpeed_InitiallyZero**: Verifies initial speed is zero
- **Test_IsAtSpeed_InitiallyFalse**: Verifies IsAtSpeed is false initially
- **Test_StartMotor_WithoutTimeProvider_DoesNotCrash**: Validates graceful handling of missing TimeProvider
- **Test_Update_WithoutTimeProvider_DoesNotCrash**: Validates Update() handles missing TimeProvider

### MotorGenericIntegrationTest
Integration tests with TimeProvider.

**Test Cases:**
- **Test_MotorRampUp_WithManualTimeProvider**: Tests complete ramp-up sequence with manual time control
- **Test_MotorRampDown_WithManualTimeProvider**: Tests deceleration to stop
- **Test_MotorReachesTargetSpeed**: Verifies motor reaches configured target speed
- **Test_IsAtSpeed_TrueWhenTargetReached**: Validates IsAtSpeed flag when target reached
- **Test_MultipleStartStop_Cycles**: Tests repeated start/stop operations
- **Test_SpeedCalculation_Precision**: Validates speed calculation accuracy

### MotorGenericInterruptionTest
Tests for interruption scenarios.

**Test Cases:**
- **Test_StopDuringRampUp**: Tests stopping motor while ramping up
- **Test_StartDuringRampDown**: Tests restarting motor during deceleration
- **Test_ChangeTargetSpeed_DuringOperation**: Tests changing target speed while running
- **Test_DisableRampControl_DuringRamp**: Tests disabling ramp control mid-operation
- **Test_TimeProvider_Discontinuity**: Tests handling of time discontinuities

### MotorGenericValidationTest
Configuration validation tests.

**Test Cases:**
- **Test_InvalidTargetSpeed_TooHigh**: Validates rejection of excessive target speed
- **Test_InvalidAcceleration_Negative**: Validates rejection of negative acceleration
- **Test_InvalidAcceleration_TooHigh**: Validates rejection of excessive acceleration
- **Test_InvalidDeceleration_Negative**: Validates rejection of negative deceleration
- **Test_InvalidDeceleration_TooHigh**: Validates rejection of excessive deceleration
- **Test_ValidConfiguration_Accepted**: Validates acceptance of valid configuration
- **Test_BidirectionalSpeed_Positive**: Tests positive (forward) speed
- **Test_BidirectionalSpeed_Negative**: Tests negative (reverse) speed

### MotorGenericRampPrecision Test
Precision tests for ramp calculations.

**Test Cases:**
- **Test_RampUp_LinearAcceleration**: Validates linear acceleration profile
- **Test_RampDown_LinearDeceleration**: Validates linear deceleration profile
- **Test_SmallTimeSteps_Accuracy**: Tests accuracy with small time increments
- **Test_LargeTimeSteps_Stability**: Tests stability with large time increments
- **Test_SpeedOvershoot_Prevention**: Validates prevention of speed overshoot
- **Test_NanosecondPrecision**: Tests nanosecond-level timing precision

---

## TimeProvider Tests

### ManualTimeProviderTest
Tests for manual time control in testing scenarios.

**Test Cases:**
- **Test_GetCurrentTimeMs_InitiallyZero**: Verifies initial time is zero
- **Test_GetCurrentTimeNs_InitiallyZero**: Verifies initial time in nanoseconds is zero
- **Test_AdvanceTime_IncreasesMilliseconds**: Tests time advancement in milliseconds
- **Test_AdvanceTime_IncreasesNanoseconds**: Tests nanosecond update when advancing milliseconds
- **Test_AdvanceTimeNs_IncreasesNanoseconds**: Tests time advancement in nanoseconds
- **Test_AdvanceTimeNs_UpdatesMilliseconds**: Tests millisecond update when advancing nanoseconds
- **Test_AdvanceTime_Multiple_Accumulates**: Tests accumulation of multiple time advances
- **Test_MixedAdvance_BothMethodsWork**: Tests mixing millisecond and nanosecond advances
- **Test_MeasureTimeInterval_Milliseconds**: Measures real time interval in milliseconds (> 0)
- **Test_MeasureTimeInterval_Nanoseconds**: Measures real time interval in nanoseconds (> 0)
- **Test_MeasureMultipleIntervals_Accumulates**: Measures multiple consecutive intervals
- **Test_SimulateRealWorldTiming_MotorRamp**: Simulates realistic motor ramp timing scenario

### SystemTimeProviderTest
Tests for system time provider with mocking.

**Test Cases:**
- **Test_GetCurrentTimeMs_ReturnsLINT**: Verifies return type and initialization
- **Test_GetCurrentTimeNs_ReturnsLINT**: Verifies nanosecond return type
- **Test_GetCurrentTimeMs_SecondCall_ReturnsDelta**: Tests delta time calculation in milliseconds
- **Test_GetCurrentTimeNs_SecondCall_ReturnsDelta**: Tests delta time calculation in nanoseconds
- **Test_BothMethods_ReturnConsistentValues**: Validates consistency between ms and ns methods
- **Test_MeasureTimeInterval_Milliseconds_WithMockedTime**: Measures 250ms interval with mock
- **Test_MeasureTimeInterval_Nanoseconds_WithMockedTime**: Measures 100ms interval in nanoseconds
- **Test_MeasureMultipleIntervals_Accumulates**: Tests multiple interval measurements
- **Test_SimulateRealWorldTiming_MotorRamp**: Simulates 3.5s motor ramp with mocked time

---

## Test Mocks

### MockMotor
Mock implementation of IMotor for testing conveyor integration.

**Features:**
- Configurable properties (TargetSpeed, Acceleration, Deceleration)
- Test control flags (SimulateStartFailure, SimulateAtSpeed)
- Call counters for verification (StartMotorCallCount, StopMotorCallCount)
- Controllable state (running, speed, at speed)
- Reset functionality for test isolation

**Methods:**
- `StartMotor()`: Simulates motor start with configurable behavior
- `StopMotor()`: Simulates motor stop
- `GetCurrentSpeed()`: Returns simulated current speed
- `IsRunning()`: Returns simulated running state
- `IsAtSpeed()`: Returns simulated at-speed state
- `IsRampingUp()`: Returns FALSE (simplified mock behavior)
- `Reset()`: Resets all states and counters
- `SimulateReachTargetSpeed()`: Manually sets motor to target speed

### GetSystemTimeMock
Mock for system time provider enabling deterministic time control in tests.

**Features:**
- Time sequence support for multiple consecutive time values
- Configurable time progression
- Call counting for verification
- Reset functionality

**Properties:**
- `systemTime`: Default time value
- `timeSequence`: Array of up to 10 time values for consecutive calls
- `sequenceLength`: Number of valid sequence entries

**Methods:**
- `GetValue()`: Returns time value based on call count and sequence
- `Reset()`: Resets call counter
- `SetTimeAt(index, timeValue)`: Sets time value at specific sequence position

**Usage Example:**
```st
// Set up time sequence: 1s, 1.25s, 1.5s
mockPayload.SetTimeAt(index := 0, timeValue := LDATE_AND_TIME#1970-01-01-00:00:01.0);
mockPayload.SetTimeAt(index := 1, timeValue := LDATE_AND_TIME#1970-01-01-00:00:01.250);
mockPayload.SetTimeAt(index := 2, timeValue := LDATE_AND_TIME#1970-01-01-00:00:01.500);
mockPayload.Reset();

// Install mock
AxUnit.Mocking.Mock(NAME_OF(Siemens.Simatic.Clocks.GetSystemDateTime), 
                    NAME_OF(Simatic.Ax.Mocks.GetSystemTimeMock), 
                    mockPayload);
```

---

## Running Tests

### Prerequisites
- AxUnit framework installed
- APAX build system configured
- Test dependencies installed via `apax install`

### Execute All Tests
```bash
apax test
```

### Execute Specific Test Suite
```bash
apax test --filter "MotorGeneric"
```

### Execute with Coverage (LLVM engine)
```bash
apax test --engine llvm --coverage
```

---

## Test Best Practices

### 1. Use Descriptive Test Names
```st
// ✓ Good
{Test}
METHOD PUBLIC Test_MotorStartsWhenConveyorConditionsMet

// ✗ Bad
{Test}
METHOD PUBLIC Test1
```

### 2. Follow Arrange-Act-Assert Pattern
```st
{Test}
METHOD PUBLIC Test_Example
    VAR_TEMP
        result : BOOL;
    END_VAR
    
    // Arrange
    motor.TargetSpeed := 1.5;
    motor.TimeProvider := timeProvider;
    
    // Act
    motor.StartMotor();
    
    // Assert
    Equal(expected := TRUE, actual := motor.IsRunning());
END_METHOD
```

### 3. Use Test Fixtures for Setup/Teardown
```st
{TestFixture}
CLASS MyTest
    VAR PROTECTED
        motor : MotorGeneric;
        timeProvider : ManualTimeProvider;
    END_VAR
    
    {TestSetup}
    METHOD PUBLIC TestSetup
        motor := motorStateless;
        timeProvider := timeProviderStateless;
    END_METHOD
END_CLASS
```

### 4. Test One Concept Per Test
```st
// ✓ Good - tests one thing
{Test}
METHOD PUBLIC Test_MotorStops_WhenStopMotorCalled

// ✗ Bad - tests multiple things
{Test}
METHOD PUBLIC Test_MotorStartsStopsAndReachesSpeed
```

### 5. Use Mocks for External Dependencies
```st
// ✓ Good - uses mock
motor.TimeProvider := manualTimeProvider;

// ✗ Bad - uses real system time (non-deterministic)
motor.TimeProvider := systemTimeProvider;
```

---

## See Also

- [Motor Documentation](Motor.md)
- [TimeProvider Documentation](TimeProvider.md)
- [Conveyor Documentation](Conveyor.md)
- [Main README](../README.md)
