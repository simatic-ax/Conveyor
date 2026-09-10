# Motor Class Tests

This directory contains comprehensive tests for the [`MotorClass`](../src/Motor/MotorClass.st) implementation.

## Test Files

### 1. MotorClassTest.st
Unit tests covering individual functionality:

#### Test Fixtures:
- **MotorInitializationTest** - Tests initialization and default values
- **MotorStartTest** - Tests motor start functionality with various parameters
- **MotorStopTest** - Tests motor stop behavior with and without ramp control
- **MotorSetSpeedTest** - Tests speed changes during operation
- **MotorRampControlTest** - Tests acceleration and deceleration ramps
- **MotorEmergencyStopTest** - Tests emergency stop functionality
- **MotorTargetSpeedTest** - Tests target speed detection
- **MotorResetTest** - Tests reset functionality
- **MotorConfigurationTest** - Tests configuration limits and custom settings

**Total Tests: ~30 unit tests**

### 2. MotorIntegrationTest.st
Integration tests with realistic scenarios:

#### Test Fixtures:
- **MotorIntegrationTest** - Complete operational scenarios
  - Complete start/stop cycles
  - Speed changes during operation
  - Realistic conveyor scenarios with 10ms cycles
  - Emergency stop during acceleration
  - Multiple start/stop cycles
  - Speed limit changes during operation
  - Ramp control toggle during operation

- **MotorEdgeCaseTest** - Edge cases and boundary conditions
  - Zero speed start
  - Maximum speed start
  - Very small cycle times
  - Reset after emergency stop
  - Multiple initializations

**Total Tests: ~15 integration tests**

## Running the Tests

### Using APAX CLI

```bash
# Run all tests
apax test

# Run with specific engine
apax test --engine llvm

# Run with coverage
apax test --engine llvm --coverage
```

### Test Coverage

The test suite covers:
- ✅ Initialization and configuration
- ✅ Motor start with parameter validation
- ✅ Motor stop with and without ramp control
- ✅ Speed changes during operation
- ✅ Ramp control (acceleration/deceleration)
- ✅ Emergency stop
- ✅ Target speed detection
- ✅ Reset functionality
- ✅ Configuration limits
- ✅ Edge cases and boundary conditions
- ✅ Realistic operational scenarios

## Test Structure

Each test follows the AAA pattern:
- **Arrange**: Set up the test conditions
- **Act**: Execute the functionality being tested
- **Assert**: Verify the expected results

Example:
```iecst
{Test}
METHOD PUBLIC Test_StartMotor_WithoutRampControl_SetsSpeedImmediately
    // Arrange
    motor.Init();
    motor.EnableRampControl := FALSE;
    
    // Act
    motor.StartMotor(Speed := REAL#50.0, Acceleration := REAL#10.0);
    
    // Assert
    Equal(expected := TRUE, actual := motor.GetMotorStatus());
    Equal(expected := REAL#50.0, actual := motor.GetCurrentSpeed());
END_METHOD
```

## Key Test Scenarios

### 1. Basic Functionality
- Motor initialization with default values
- Starting motor with various speeds and accelerations
- Stopping motor with immediate and ramped deceleration
- Changing speed during operation

### 2. Parameter Validation
- Speed limits (0-100%, custom MaxSpeedLimit)
- Acceleration limits (0.1-100 %/s)
- Negative value handling
- Out-of-range value clamping

### 3. Ramp Control
- Gradual acceleration to target speed
- Gradual deceleration when stopping
- Speed changes with ramp control
- Realistic cycle times (10ms)

### 4. Safety Features
- Emergency stop (immediate stop)
- Reset after emergency stop
- Motor status tracking

### 5. Edge Cases
- Zero speed operation
- Maximum speed operation
- Very small cycle times (1ms)
- Multiple start/stop cycles
- Configuration changes during operation

## Expected Results

All tests should pass with the following assertions:
- Motor status correctly reflects running/stopped state
- Speed values are within configured limits
- Ramp control produces smooth acceleration/deceleration
- Emergency stop immediately halts the motor
- Parameter validation prevents invalid values

## Continuous Integration

These tests are designed to run in CI/CD pipelines:
- Fast execution (< 1 second for all tests)
- No external dependencies
- Deterministic results
- Clear pass/fail indicators

## Adding New Tests

When adding new functionality to MotorClass:

1. Add unit tests in `MotorClassTest.st` for isolated functionality
2. Add integration tests in `MotorIntegrationTest.st` for complete scenarios
3. Follow the existing naming convention: `Test_<Functionality>_<Condition>_<ExpectedResult>`
4. Use the AAA pattern (Arrange, Act, Assert)
5. Add comments explaining complex test scenarios

## Troubleshooting

### Common Issues

**Tests fail with "MotorClass not found"**
- Ensure `src/Motor/MotorClass.st` exists
- Check namespace is `Simatic.Ax.Motor`
- Run `apax install` to update dependencies

**Timing-related test failures**
- Check cycle time calculations
- Verify ramp control is enabled/disabled as expected
- Review acceleration/deceleration values

**Assertion failures**
- Check REAL value comparisons (use tolerance for floating-point)
- Verify test setup (Init() called, correct configuration)
- Review expected vs actual values in test output

## See Also

- [MotorClass Documentation](../docs/MotorClass.md)
- [MotorClass Implementation](../src/Motor/MotorClass.st)
- [Usage Examples](../examples/MotorExample.st)
