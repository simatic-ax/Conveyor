USING Simatic.Ax.AutomationBase;
USING Simatic.Ax.IO.Input;
USING System.Timer;

NAMESPACE Simatic.Ax.Conveyor

    /// Internal class managing stop position monitoring and occupancy detection
    /// Monitors stop sensor and determines logical occupancy state
    /// Includes sensor blocking detection with timeout error handling
    {axcode:docs-v0:@simatic-ax/conveyor:MyClass.md}
    CLASS INTERNAL StopPosition
        IMPLEMENTS IStopPos
        VAR PUBLIC
            /// Physical stop sensor input
            StopSensor : IBinSignal;
            /// Reference to parent equipment for error handling
            Equipment : IEquipmentBase;
            /// Reference to deliverer for transfer status
            Deliverer : IDeliverer;
            /// Timeout for sensor monitoring (default: 60s)
            SensorMonitoringTime : LTIME := LTIME#60s;
        END_VAR
        VAR PROTECTED
            /// Logical occupancy state (TRUE = occupied, FALSE = free)
            _itemInStopPosition : BOOL;
            /// Internal error flag
            _hasError : BOOL;
            /// Sensor blocking supervision with timeout detection
            _SensorBlocked : Supervision := (behavior := SupervisionBehavior#Reaction);
            /// Current startup status
            _startUpStatus : StartUpStatus;
            /// Previous startup status for edge detection
            _startUpStatusOld : BOOL;
            /// Raw sensor status (TRUE = covered, FALSE = free)
            _stopSensorCovered : BOOL;
            /// Previous delivering status for edge detection
            _deliveringOld : BOOL;
            /// Debug counter: How often Start() was called
            _startCallCounter : INT := 0;
        END_VAR
        /// Evaluates stop position status and updates occupancy state
        /// Monitors sensor for blocking during transfer and sets error if timeout occurs
        /// Returns current occupancy status

        METHOD PUBLIC EvaluateStopPos : BOOL
            VAR_TEMP
                _delivering : BOOL; // transfer in progress
                _startedUpRis : BOOL;
                _startedUp : BOOL;
                _deliveringRis : BOOL;
            END_VAR
            // Read signals to avoid mutiple method calls
            _SensorBlocked.timeout := SensorMonitoringTime;
            _delivering := Deliverer.DeliverStatus() = DeliverState#Delivering;
            _startUpStatus := Equipment.GetStartupStatus();
            _startedUp := _startUpStatus = StartUpStatus#AutoStartedUp;
            _stopSensorCovered := StopSensor.Q();
            // Detect rising edge of delivering (transfer starts)
            _deliveringRis := _delivering AND NOT (_deliveringOld);
            // Start supervision whenever a transfer is active and monitoring is not yet running
            IF (_delivering AND NOT _SensorBlocked.IsActive()) THEN
                _SensorBlocked.Start();
                _startCallCounter := _startCallCounter + 1; // Debug counter
            END_IF;
            // Stop supervision when sensor becomes free or transfer stops
            IF ((NOT (_stopSensorCovered) OR NOT (_delivering)) AND _SensorBlocked.IsActive()) THEN
                _SensorBlocked.Stop();
            END_IF;
            // Execute supervision monitoring
            _SensorBlocked.Execute(signal := _stopSensorCovered AND _delivering);
            // Check for timeout error
            _hasError := _SensorBlocked.GetError() = SupervisionError#TIMEOUT;
            IF (NOT _hasError AND _delivering AND _stopSensorCovered AND _SensorBlocked.IsActive()) THEN
                _hasError := TRUE;
            END_IF;
            IF (_hasError) THEN
                Equipment.SetError(errorState := ErrorState#OtherError, errorText := 'Sensor blocked timeout');
            END_IF;
            // Update occupancy logic
            IF (_stopSensorCovered AND _startUpStatus = StartUpStatus#AutoStartedUp) THEN
                _itemInStopPosition := TRUE;
            END_IF;
            IF (_itemInStopPosition) THEN
                // Delete occupied status when
                // transfer in progress and not sensor
                // or on StartingUp->StartedUp-Transition
                // but just, when sensor is not covered
                IF ((_delivering OR (_startUpStatus = StartUpStatus#AutoStartingUp)) AND NOT (_stopSensorCovered)) THEN
                    _itemInStopPosition := FALSE;
                END_IF;
            END_IF;
            // Store old delivering value for edge detection
            _deliveringOld := _delivering;
            EvaluateStopPos := _itemInStopPosition;
        END_METHOD
        /// Returns whether the stop position is logically occupied
        /// TRUE = Material present, FALSE = Position free

        METHOD PUBLIC IsOccupied : BOOL
            IsOccupied := _itemInStopPosition;
        END_METHOD
        /// Returns the raw stop sensor status
        /// TRUE = Sensor covered, FALSE = Sensor free

        METHOD PUBLIC StopSensorStatus : BOOL
            StopSensorStatus := _stopSensorCovered;
        END_METHOD
        /// Resets the stop position supervision and clears all internal states
        /// Stops active supervision monitoring and clears error flags

        METHOD PUBLIC Reset : BOOL
            _stopSensorCovered := StopSensor.Q();
            IF NOT (_stopSensorCovered) THEN
                // Stop active supervision
                _SensorBlocked.Stop();
                // Reset supervision state
                _SensorBlocked.Reset();
                // Clear error flag
                _hasError := FALSE;
                // Reset edge detection flags
                _deliveringOld := FALSE;
                _startUpStatusOld := FALSE;
                Reset := TRUE;
            ELSE
                Reset := FALSE;
            END_IF;
        END_METHOD
    END_CLASS

END_NAMESPACE
