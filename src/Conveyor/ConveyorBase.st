USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.IO.Input;
USING System.Timer;
USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.Motor;

NAMESPACE Simatic.Ax.Conveyor

    /// Standard transport module for a uni-directional conveyor with one stop sensor
    ///  ________  _________________________________________|_____  _______
    ///    Prev  \/ Conveyor: Material flow: downward    -> |     \/ Next
    ///          || <- ReadyToReceive/ReadyToDeliver    -> |     ||
    ///          ||                    Delivering -> |     ||
    ///  ________/\_________________________________________|_____/\_______
    ///                                             |
    ///                                        Stop Sensor
    ///
    /// States of the Transport module:
    /// - ReadyToReceive: Signals to upstream (previous) conveyor
    /// - ReadyToDeliver: Signals to downstream (next) conveyor
    /// - Delivering: Active material transfer to next conveyor
    ///
    /// Features:
    /// - Automatic startup and operating mode management
    /// - Material flow control with previous/next conveyor coordination
    /// - Stop position monitoring with sensor supervision
    /// - Manual and automatic operation modes
    /// - Motor control via IMotor interface (supports NullMotor pattern)
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    CLASS ConveyorBase
        EXTENDS EquipmentBase
        IMPLEMENTS IConveyor
        VAR CONSTANT
            /// Default normal operating speed in m/s
            DEFAULT_AUTOMATIC_SPEED : LREAL := 1.5;
            /// Default slow speed for precise positioning in m/s
            DEFAULT_MANUAL_SPEED : LREAL := 0.5;
            /// Default motor acceleration in m/s²
            DEFAULT_ACCELERATION : LREAL := 1.0;
            /// Default motor deceleration in m/s²
            DEFAULT_DECELERATION : LREAL := 1.0;
        END_VAR
        VAR PUBLIC
            /// Conveyor identifier name
            Name : STRING[30];
            /// Stop position sensor (required - ConfigError if NULL)
            StopSensor : IBinSignal;
            /// Motor off-delay time after transfer completion
            OffDelayTime : TIME := T#5s;
            /// Reference to previous (upstream) conveyor
            PrevConveyor : IDeliverer;
            /// Reference to next (downstream) conveyor
            NextConveyor : IReceiver;
            /// Motor instance via Dependency Injection (uses NullMotor if NULL)
            Motor : IMotor;
            /// Normal operating speed in m/s
            AutomaticSpeed : LREAL := DEFAULT_AUTOMATIC_SPEED;
            /// Slow speed for precise positioning in m/s
            ManualSpeed : LREAL := DEFAULT_MANUAL_SPEED;
            /// Motor acceleration rate in m/s²
            Acceleration : LREAL := DEFAULT_ACCELERATION;
            /// Motor deceleration rate in m/s²
            Deceleration : LREAL := DEFAULT_DECELERATION;
            /// Sensor Blocked Time
            SensorBlockedTime : LTIME := T#5s;
        END_VAR
        VAR PROTECTED
            /// Internal flag indicating motor should run
            _conveyorShouldRun : BOOL;
            /// Previous motor state for edge detection
            _previousMotorState : BOOL;
            /// Null Object Pattern implementation for when no motor is configured
            _nullMotor : NullMotor;
            /// Null Object Pattern implementation for when no next conveyor is configured (end of line)
            _nullReceiver : NullReceiver;
        END_VAR
        VAR
            /// Off-delay timer for motor control
            conveyorOffDelay : OffDelay;
            /// Internal flag for conveyor follow-up time
            _conveyorFollowUpTimeActive : BOOL;
            /// Ready to deliver logic
            _rtd : ReadyToDeliver;
            /// Ready to receive logic
            _rtr : ReadyToReceive;
            /// Stop position monitoring
            _stopPosition : StopPosition;
            /// Manual start flag
            _startManual : BOOL;
            /// Automatic release flag
            _autoRelease : BOOL;
            /// Rising edge detection for auto release
            _autoReleaseRis : BOOL;
            /// Previous auto release state
            _autoReleaseOld : BOOL;
            /// Manual released
            _manualRelease : BOOL;
        END_VAR
        /// Initialize conveyor and all internal objects
        /// Validates configuration and applies Null Object Pattern for motor

        METHOD PROTECTED OVERRIDE InitUser
            // Apply Null Object Pattern: If no next conveyor is configured (end of line), use NullReceiver
            // This must be done BEFORE assigning to _rtd.NextReceiver
            IF (NextConveyor = NULL) THEN
                NextConveyor := _nullReceiver;
            END_IF;
            // Apply Null Object Pattern: If no motor is configured, use NullMotor
            IF (Motor = NULL) THEN
                Motor := _nullMotor;
            END_IF;
            _rtd.equipment := THIS;
            _rtd.NextReceiver := NextConveyor;
            _rtd.StopPosition := _stopPosition;
            _rtr.StopPosition := THIS;
            _rtr.equipment := THIS;
            _rtr.PrevConveyor := PrevConveyor;
            _stopPosition.StopSensor := StopSensor;
            _stopPosition.Equipment := THIS;
            _stopPosition.Deliverer := _rtd;
            _stopPosition.SensorMonitoringTime := SensorBlockedTime;
            IF (StopSensor = NULL) THEN
                THIS.SetError(errorState := ErrorState#ConfigError, errorText := 'StopSensor not configured');
            END_IF;
            IF (ExternalRelease = NULL) THEN
                THIS.SetError(errorState := ErrorState#ConfigError, errorText := 'Release not configured');
            END_IF;
        END_METHOD
        /// Cyclic execution of the conveyor
        /// Must be called every PLC cycle
        /// Evaluates states, controls motor, and coordinates with adjacent conveyors

        METHOD OVERRIDE RunCyclicUserCode
            VAR_TEMP
                _stopStatus : BOOL;
                _rtrStatus : ReceiveState;
                _rtdStatus : DeliverState;
                _currentStartupStatus : StartUpStatus;
                _externalRelease : BOOL;
                _conveyorStartRis : BOOL;
                _conveyorStartFal : BOOL;
            END_VAR
            _currentStartupStatus := THIS.GetStartupStatus();
            _autoRelease := _currentStartupStatus = StartUpStatus#AutoStartedUp;
            _manualRelease := _currentStartupStatus = StartUpStatus#Manual;
            _autoReleaseRis := _autoRelease AND NOT (_autoReleaseOld);
            _autoReleaseOld := _autoRelease;
            _externalRelease := ExternalRelease.IsReleased();
            _stopStatus := _stopPosition.EvaluateStopPos();
            _rtdStatus := _rtd.EvaluateDeliverStatus();
            _rtrStatus := _rtr.EvaluateReceiveStatus();

            // Evaluate motor run condition and control motor
            _conveyorShouldRun := THIS.ConveyorRunCondition(isReleased := _externalRelease);
            _conveyorStartRis := _conveyorShouldRun AND NOT _previousMotorState;
            _conveyorStartFal := NOT _conveyorShouldRun AND _previousMotorState;
            _previousMotorState := _conveyorShouldRun;
            
            // Only call StartMotor/StopMotor on state changes (edge detection)
            IF _conveyorStartRis THEN
                // Rising edge: Start motor with speed based on operating mode
                IF Mode.GetOperatingMode() = OperatingModes#Manual THEN
                    Motor.StartMotor(targetSpeed := ManualSpeed, acceleration := Acceleration);
                ELSE
                    Motor.StartMotor(targetSpeed := AutomaticSpeed, acceleration := Acceleration);
                END_IF;
            ELSIF _conveyorStartFal THEN
                // Falling edge: Stop motor with configured deceleration
                Motor.StopMotor(deceleration := Deceleration);
            END_IF;
            // Call Update() cyclically for ramp control
            IF (Motor <> NULL) THEN
                Motor.Update();
            END_IF;
        END_METHOD
        /// Evaluates the motor run condition based on multiple factors
        /// Returns TRUE if motor should run, FALSE otherwise
        /// Considers manual mode, automatic coordination, and off-delay timing

        METHOD PROTECTED ConveyorRunCondition : BOOL
            VAR_INPUT
                isReleased : BOOL;
            END_VAR
            VAR_TEMP
                run : BOOL;
                prohibitRunning : BOOL;
                result : BOOL;
                thisDeliverStatus : DeliverState;
                thisReceiveStatus : ReceiveState;
                nextReceiveStatus : ReceiveState;
                prevDeliverStatus : DeliverState;
                triggerCondition : BOOL;
                triggerNextReadyToDeliver : BOOL;
                triggerNextDelivering : BOOL;
                triggerPrevReadyToDeliver : BOOL;
                triggerPrevDelivering : BOOL;
                triggerAutoReleaseEmpty : BOOL;
                currentOperatingMode : OperatingModes;
                followUpSignal : BOOL;
            END_VAR
            IF (THIS.GetError() = ErrorState#ConfigError) THEN
                RETURN;
            END_IF;
            followUpSignal := _conveyorFollowUpTimeActive;
            _conveyorFollowUpTimeActive := FALSE;
            currentOperatingMode := Mode.GetOperatingMode();
            // Motor runs in manual mode
            IF _manualRelease AND isReleased AND currentOperatingMode = OperatingModes#Manual THEN
                ConveyorRunCondition := _startManual;
                RETURN;
            END_IF;
            // when the conveyor is switched automatic but the auto release is lost... -> stop
            IF NOT (_autoRelease) AND (currentOperatingMode = OperatingModes#Automatic) THEN
                ConveyorRunCondition := FALSE;
                RETURN;
            END_IF;
            // Cache status calls to minimize function calls
            thisDeliverStatus := THIS.DeliverStatus();
            thisReceiveStatus := THIS.ReceiveStatus();
            // Evaluate individual trigger conditions
            // run when next conveyor is ReadyToReceive and this conveyor ReadyToDeliver
            IF (NextConveyor <> NULL) THEN
                nextReceiveStatus := NextConveyor.ReceiveStatus();
                triggerNextReadyToDeliver := thisDeliverStatus = DeliverState#ReadyToDeliver AND nextReceiveStatus = ReceiveState#ReadyToReceive;
                // During Delivering, keep motor running regardless of next conveyor state
                triggerNextDelivering := thisDeliverStatus = DeliverState#Delivering;
            END_IF;
            // run when previous conveyor is ReadyToDeliver and this conveyor ReadyToReceive or Receiving
            IF (PrevConveyor <> NULL) THEN
                prevDeliverStatus := PrevConveyor.DeliverStatus();
                triggerPrevReadyToDeliver := thisReceiveStatus = ReceiveState#ReadyToReceive AND prevDeliverStatus = DeliverState#ReadyToDeliver;
                triggerPrevDelivering := (thisReceiveStatus = ReceiveState#ReadyToReceive OR thisReceiveStatus = ReceiveState#Receiving) AND prevDeliverStatus = DeliverState#Delivering;
            END_IF;
            // run after auto startup when conveyor is empty
            triggerAutoReleaseEmpty := _autoReleaseRis AND NOT (THIS.IsOccupied());
            // Combine all trigger conditions and call RetriggerConveyor only once
            triggerCondition := triggerNextReadyToDeliver OR triggerNextDelivering OR triggerPrevReadyToDeliver OR triggerPrevDelivering OR triggerAutoReleaseEmpty;
            result := THIS.RetriggerConveyor(triggerCondition);
            IF (NOT triggerCondition AND NOT THIS.IsOccupied()) THEN
                _conveyorFollowUpTimeActive := followUpSignal;
            END_IF;
            // Stop in case of:
            IF THIS.GetStartupStatus() <> StartUpStatus#AutoStartedUp THEN
                _conveyorFollowUpTimeActive := FALSE;
            END_IF;
            // Offdelay for conveyor (Can be probibited by prohibitRunning)
            conveyorOffDelay(signal := _conveyorFollowUpTimeActive, duration := OffDelayTime);
            prohibitRunning := FALSE;
            IF (NextConveyor <> NULL) THEN
                prohibitRunning := thisDeliverStatus = DeliverState#ReadyToDeliver AND NOT (nextReceiveStatus = ReceiveState#ReadyToReceive);
                IF (_autoRelease AND (NOT _stopPosition.IsOccupied() OR thisDeliverStatus = DeliverState#Delivering)) THEN
                    prohibitRunning := FALSE;
                END_IF;
            END_IF;
            // run in manual mode
            run := (conveyorOffDelay.output AND NOT prohibitRunning);
            ConveyorRunCondition := run;
        END_METHOD
        /// Retriggers the conveyor follow-up time
        /// Used internally to extend motor run time

        METHOD PROTECTED RetriggerConveyor : BOOL
            VAR_INPUT
                trig : BOOL;
            END_VAR
            IF (trig) THEN
                _conveyorFollowUpTimeActive := TRUE;
                RetriggerConveyor := TRUE;
            END_IF;
        END_METHOD
        
        /// Manually triggers conveyor start in automatic mode
        /// Only works if AutoStartedUp and stop position is not occupied

        METHOD PUBLIC TriggerStartInAutomatic
            IF (THIS.GetStartupStatus() = StartUpStatus#AutoStartedUp AND NOT (_stopPosition.IsOccupied())) THEN
                _conveyorFollowUpTimeActive := TRUE;
            END_IF;
        END_METHOD
        /// Returns the current delivery state
        /// Used by downstream conveyors to coordinate material transfer

        METHOD PUBLIC DeliverStatus : DeliverState
            DeliverStatus := _rtd.DeliverStatus();
        END_METHOD
        /// Returns the current receive state
        /// Used by upstream conveyors to determine if material can be transferred

        METHOD PUBLIC ReceiveStatus : ReceiveState
            ReceiveStatus := _rtr.ReceiveStatus();
        END_METHOD
        /// Returns whether the stop position is occupied
        /// TRUE = Material present, FALSE = Position free

        METHOD PUBLIC IsOccupied : BOOL
            IsOccupied := _stopPosition.IsOccupied();
        END_METHOD
        /// Starts the conveyor in manual mode
        /// Returns TRUE if start command accepted, FALSE otherwise
        /// Requires manual operating mode and external release

        METHOD PUBLIC StartManual : BOOL
            IF (Mode.GetOperatingMode() = OperatingModes#Manual) AND (ExternalRelease.IsReleased()) THEN
                _startManual := TRUE;
            END_IF;
            StartManual := TRUE;
        END_METHOD
        /// Stops the conveyor immediately
        /// Clears manual start flag and initiates motor deceleration

        METHOD PUBLIC Stop
            _startManual := FALSE;
        END_METHOD
        /// Returns whether a transfer is currently in progress
        /// TRUE = Transfer active, FALSE = No transfer

        METHOD PUBLIC Delivering : BOOL
            Delivering := _rtd.DeliverStatus() = DeliverState#Delivering;
        END_METHOD
        /// Returns the raw stop sensor status
        /// TRUE = Sensor covered, FALSE = Sensor free

        METHOD PUBLIC StopSensorStatus : BOOL
            ;
        END_METHOD
        /// Returns whether the motor is currently running
        /// TRUE = Motor running, FALSE = Motor stopped

        METHOD PUBLIC ConveyorIsRunning : BOOL
            IF Motor <> NULL THEN
                ConveyorIsRunning := Motor.IsRunning();
            ELSE
                ConveyorIsRunning := FALSE;
            END_IF;
        END_METHOD

        /// Resets the conveyor fault state and internal control logic
        /// Clears errors, stops motor, and resets all state machines including supervision
        /// Should be called when ResetActive signal is triggered
        /// Note: Reset is only possible if the stop sensor is not blocked (covered)

        METHOD PROTECTED OVERRIDE ResetFaultUser : BOOL
            // Call base class reset to clear equipment-level errors
            ResetFaultUser := _stopPosition.Reset();
        END_METHOD
    END_CLASS

END_NAMESPACE
