# @simatic-ax/conveyor

## Description

A comprehensive conveyor system library for SIMATIC AX providing standardized transport module functionality with automatic startup, operating modes, and material flow control.

## Install this package

Enter:

```cli
apax add @simatic-ax/conveyor
```

## Namespace

```st
USING Simatic.Ax.Conveyor;
USING Simatic.Ax.AutomationFramework;
```

## Documentation

### Detailed Component Documentation

- **[Conveyor System](docs/Conveyor.md)** - Complete conveyor functionality, state machines, and configuration
- **[Motor System](docs/Motor.md)** - Motor control, interfaces, and implementations
- **[TimeProvider System](docs/TimeProvider.md)** - Time measurement for motor ramp control
- **[Testing](docs/Testing.md)** - Test structure, test cases, and testing best practices

### Quick Overview

#### ConveyorBase
Main conveyor class providing:
- Automatic startup and operating mode management
- Material flow control with previous/next conveyor coordination
- Stop position monitoring
- Manual and automatic operation modes

See [Conveyor Documentation](docs/Conveyor.md) for detailed information.

#### Motor System
- **IMotor Interface**: Universal motor control interface
- **MotorGeneric**: Timer-based motor with OnDelay/OffDelay for simple ramp control
- **MotorSimulated**: TimeProvider-based motor with precise ramp simulation
- **NullMotor**: Null Object Pattern implementation

See [Motor Documentation](docs/Motor.md) for detailed information.

#### TimeProvider System
- **ITimeProvider Interface**: Abstraction for time measurement
- **SystemTimeProvider**: Real-time measurements using PLC system clock
- **ManualTimeProvider**: Manual time control for testing

See [TimeProvider Documentation](docs/TimeProvider.md) for detailed information.

#### Control Logic
- **ReadyToDeliver**: Manages delivery state and transfer coordination
- **ReadyToReceive**: Manages receive state and readiness
- **StopPosition**: Monitors stop sensor and occupancy status

#### States
- **DeliverState**: Idle, ReadyToDeliver, TransferInProgress
- **ReceiveState**: Idle, ReadyToReceive
- **StartUpStatus**: NotReleased, AutoStartingUp, AutoStartedUp, InternalError

## Example

### Complete Conveyor Line Setup

This example demonstrates a complete three-conveyor line with motors, sensors, and I/O mapping.

#### Configuration

```st
USING Simatic.Ax.Conveyor;
USING Simatic.Ax.IO.Input;
USING Simatic.Ax.IO.Output;
USING Simatic.Ax.Motor;

CONFIGURATION MyConfiguration
    TASK Main(Priority := 1);
    
    PROGRAM P1 WITH Main: MainProgram;
        
    VAR_GLOBAL
        // Time provider for motors (shared by all motors)
        TimeProvider : SystemTimeProvider;
        
        // Global operating mode and release for all conveyors
        GlobalOpMode : OperatingMode;
        GlobalRelease : Release;
        
        // Motor outputs for physical control
        MotorOutput1 : BinOutput;
        MotorOutput2 : BinOutput;
        MotorOutput3 : BinOutput;
        
        // Motors for each conveyor with initialization
        // Note: ExternalRelease can be set optionally to control when motor can start
        // If ExternalRelease is set, motor can only start when release is TRUE
        // If ExternalRelease is NULL (not set), motor is always released
        
        // Option 1: MotorGeneric (Timer-based, simpler)
        // Uses OnDelay/OffDelay timers for ramp control
        Motor1 : MotorGeneric := (
            MaxSpeed := 2.0,
            MaxAcceleration := 1.0,
            MaxDeceleration := 1.5,
            MotorOutput := MotorOutput1,
            ExternalRelease := GlobalRelease  // Share conveyor's release
        );
        
        // Option 2: MotorSimulated (TimeProvider-based, more precise)
        // Uses TimeProvider for precise ramp simulation
        Motor2 : MotorSimulated := (
            TargetSpeed := 1.5,
            FixedAcceleration := 1.0,
            FixedDeceleration := 1.0,
            TimeProvider := TimeProvider,
            EnableRampControl := TRUE,
            MotorOutput := MotorOutput2,
            ExternalRelease := GlobalRelease  // Share conveyor's release
        );
        
        // Mix and match motor types as needed
        Motor3 : MotorGeneric := (
            MaxSpeed := 2.0,
            MaxAcceleration := 1.0,
            MaxDeceleration := 1.5,
            MotorOutput := MotorOutput3,
            ExternalRelease := GlobalRelease  // Share conveyor's release
        );
        
        // Stop sensors for each conveyor
        StopSensor1 : BinSignal;
        StopSensor2 : BinSignal;
        StopSensor3 : BinSignal;
        
        // Conveyor line consisting of three conveyors with initialization
        Conveyor1 : ConveyorBase := (
            Name := 'Conveyor_1',
            StopSensor := StopSensor1,
            Motor := Motor1,
            NextConveyor := Conveyor2,
            PrevConveyor := NULL,
            OffDelayTime := T#5s,
            AutomaticSpeed := 1.5,
            ManualSpeed := 0.5,
            Acceleration := 1.0,
            Deceleration := 1.5,
            SensorBlockedTime := T#5s,
            Mode := GlobalOpMode,
            ExternalRelease := GlobalRelease
        );
        Conveyor2 : ConveyorBase := (
            Name := 'Conveyor_2',
            StopSensor := StopSensor2,
            Motor := Motor2,
            NextConveyor := Conveyor3,
            PrevConveyor := Conveyor1,
            OffDelayTime := T#5s,
            AutomaticSpeed := 1.5,
            ManualSpeed := 0.5,
            Acceleration := 1.0,
            Deceleration := 1.5,
            SensorBlockedTime := T#5s,
            Mode := GlobalOpMode,
            ExternalRelease := GlobalRelease
        );
        Conveyor3 : ConveyorBase := (
            Name := 'Conveyor_3',
            StopSensor := StopSensor3,
            Motor := Motor3,
            NextConveyor := NULL,
            PrevConveyor := Conveyor2,
            OffDelayTime := T#5s,
            AutomaticSpeed := 1.5,
            ManualSpeed := 0.5,
            Acceleration := 1.0,
            Deceleration := 1.5,
            SensorBlockedTime := T#5s,
            Mode := GlobalOpMode,
            ExternalRelease := GlobalRelease
        );
        
        // Physical I/O mapping - Map these to your actual PLC inputs
        // Example addresses - adjust according to your hardware
        HW_StopSensor1 AT %I0.0 : BOOL;  // Digital Input 0.0
        HW_StopSensor2 AT %I0.1 : BOOL;  // Digital Input 0.1
        HW_StopSensor3 AT %I0.2 : BOOL;  // Digital Input 0.2
        
        // Motor outputs - Map these to your actual PLC outputs
        HW_Motor1_Run AT %Q0.0 : BOOL;   // Digital Output 0.0
        HW_Motor2_Run AT %Q0.1 : BOOL;   // Digital Output 0.1
        HW_Motor3_Run AT %Q0.2 : BOOL;   // Digital Output 0.2
    END_VAR
END_CONFIGURATION
```

#### Main Program

```st
USING Simatic.Ax.Conveyor;
USING Simatic.Ax.IO.Input;
USING Simatic.Ax.IO.Output;
USING Simatic.Ax.Motor;

PROGRAM MainProgram
    VAR_EXTERNAL
        // Conveyor line consisting of three conveyors
        Conveyor1 : ConveyorBase;
        Conveyor2 : ConveyorBase;
        Conveyor3 : ConveyorBase;
        
        // Global operating mode and release
        GlobalOpMode : OperatingMode;
        GlobalRelease : Release;
        
        // Motors for each conveyor (can be MotorGeneric or MotorSimulated)
        Motor1 : MotorGeneric;
        Motor2 : MotorSimulated;
        Motor3 : MotorGeneric;
        
        // Motor outputs
        MotorOutput1 : BinOutput;
        MotorOutput2 : BinOutput;
        MotorOutput3 : BinOutput;
        
        // Stop sensors for each conveyor
        StopSensor1 : BinSignal;
        StopSensor2 : BinSignal;
        StopSensor3 : BinSignal;
        
        // Physical I/O
        HW_StopSensor1 : BOOL;
        HW_StopSensor2 : BOOL;
        HW_StopSensor3 : BOOL;
        HW_Motor1_Run : BOOL;
        HW_Motor2_Run : BOOL;
        HW_Motor3_Run : BOOL;
    END_VAR
    
    VAR
        _initialized : BOOL := FALSE;
    END_VAR

    VAR_TEMP
    END_VAR
    // ========================================
    // CYCLIC EXECUTION - Called every PLC cycle
    // ========================================
    
    // 1. Read physical inputs and update BinSignals
    StopSensor1.ReadCyclic(signal := HW_StopSensor1);
    StopSensor2.ReadCyclic(signal := HW_StopSensor2);
    StopSensor3.ReadCyclic(signal := HW_StopSensor3);
    
    // 2. Execute conveyor logic (includes motor control)
    //    ConveyorBase automatically calls StartMotor(targetSpeed, acceleration)/StopMotor(deceleration)
    //    which in turn calls MotorOutput.SetOn()/SetOff()
    Conveyor1.RunCyclic();
    Conveyor2.RunCyclic();
    Conveyor3.RunCyclic();
    
    // 3. Update motor ramp control (for smooth acceleration/deceleration)
    Motor1.Update();
    Motor2.Update();
    Motor3.Update();
    
    // 4. Write motor outputs to physical hardware
    //    Motor outputs are automatically controlled by StartMotor()/StopMotor()
    MotorOutput1.WriteCyclic(Q => HW_Motor1_Run);
    MotorOutput2.WriteCyclic(Q => HW_Motor2_Run);
    MotorOutput3.WriteCyclic(Q => HW_Motor3_Run);
    
END_PROGRAM
```

For more examples and detailed usage, see:
- [Conveyor Documentation](docs/Conveyor.md)
- [Motor Documentation](docs/Motor.md)
- [TimeProvider Documentation](docs/TimeProvider.md)

## Contribution

Thanks for your interest in contributing. Anybody is free to report bugs, unclear documentation, and other problems regarding this repository in the Issues section or, even better, is free to propose any changes to this repository using Merge Requests.

## License and Legal information

Please read the [Legal information](LICENSE.md)
