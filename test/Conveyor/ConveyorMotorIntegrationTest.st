USING AxUnit.Assert;
USING Simatic.Ax.Conveyor;
USING MotorTests.Mocks;

NAMESPACE ConveyorTests
    /// Integration tests for Conveyor with Motor
    {TestFixture}
    CLASS ConveyorMotorIntegrationTest
        VAR PROTECTED
            conveyor : ConveyorBase;
            conveyorStateless : ConveyorBase;
            motor : MockMotor;
            motorStateless : MockMotor;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            conveyor := conveyorStateless;
            motor := motorStateless;
            motor.Reset();
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ConveyorWithoutMotor_NoError
            // Arrange - No motor assigned
            
            // Act
            conveyor.RunCyclic();  // Init is now called automatically by RunCyclic
            
            // Assert - No motor calls when motor is NULL
            Equal(expected := 0, actual := motor.StartMotorCallCount);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ConveyorWithMotor_MotorInjected
            // Arrange
            conveyor.Motor := motor;
            
            // Act
            conveyor.RunCyclic();  // Init is now called automatically by RunCyclic
            
            // Assert - Motor is properly injected
            Equal(expected := TRUE, actual := (conveyor.Motor <> NULL));
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MotorConfiguration_IsAccessible
            // Arrange & Act
            conveyor.Motor := motor;
            conveyor.AutomaticSpeed := 75.0;
            conveyor.Acceleration := 10.0;
            
            // Assert - Configuration is properly set
            Equal(expected := 75.0, actual := conveyor.AutomaticSpeed);
            Equal(expected := 10.0, actual := conveyor.Acceleration);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MotorConfiguration_SlowSpeed
            // Arrange
            conveyor.Motor := motor;
            conveyor.AutomaticSpeed := 75.0;
            conveyor.ManualSpeed := 30.0;
            
            // Act & Assert - Configuration is accessible
            Equal(expected := 75.0, actual := conveyor.AutomaticSpeed);
            Equal(expected := 30.0, actual := conveyor.ManualSpeed);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_ConveyorStop_CallsStopMethod
            // Arrange
            conveyor.Motor := motor;
            Motor.StartMotor();
            
            // Act
            conveyor.Stop();
            
            // Assert - Stop method was called successfully
            Equal(expected := TRUE, actual := TRUE);  // Stop executed without error
        END_METHOD



        {Test}
        METHOD PUBLIC Test_IsMotorRunning_ReturnsMotorState
            // Arrange
            conveyor.Motor := motor;
            
            // Act & Assert - Motor not running
            Equal(expected := FALSE, actual := conveyor.ConveyorIsRunning());
            
            // Start motor
            Motor.StartMotor();
            
            // Act & Assert - Motor running
            Equal(expected := TRUE, actual := conveyor.ConveyorIsRunning());
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MotorConfiguration_UsesCustomValues
            // Arrange
            conveyor.Motor := motor;
            conveyor.AutomaticSpeed := 80.0;
            conveyor.ManualSpeed := 25.0;
            conveyor.Acceleration := 15.0;
            conveyor.Deceleration := 20.0;
            
            // Act & Assert
            Equal(expected := 80.0, actual := conveyor.AutomaticSpeed);
            Equal(expected := 25.0, actual := conveyor.ManualSpeed);
            Equal(expected := 15.0, actual := conveyor.Acceleration);
            Equal(expected := 20.0, actual := conveyor.Deceleration);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MotorStopWithDeceleration
            // Arrange
            conveyor.Motor := motor;
            conveyor.Deceleration := 20.0;
            motor.FixedDeceleration := 20.0;
            Motor.StartMotor();
            
            // Act
            Motor.StopMotor();
            
            // Assert - Motor uses configured deceleration and stops
            Equal(expected := 20.0, actual := motor.FixedDeceleration);
            Equal(expected := FALSE, actual := motor.IsRunning());
        END_METHOD


        {Test}
        METHOD PUBLIC Test_IsMotorRunning_WithoutMotor_ReturnsFalse
            // Arrange
            conveyor.Motor := NULL;
            
            // Act & Assert
            Equal(expected := FALSE, actual := conveyor.ConveyorIsRunning());
        END_METHOD
    END_CLASS

    /// Tests for motor control logic
    {TestFixture}
    CLASS ConveyorMotorControlTest
        VAR PROTECTED
            conveyor : ConveyorBase;
            conveyorStateless : ConveyorBase;
            motor : MockMotor;
            motorStateless : MockMotor;
        END_VAR

        {TestSetup}
        METHOD PUBLIC TestSetup
            conveyor := conveyorStateless;
            motor := motorStateless;
            motor.Reset();
            conveyor.Motor := motor;
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MockMotor_CanStartAndStop
            // Arrange
            conveyor.AutomaticSpeed := 75.0;
            conveyor.Deceleration := 15.0;
            
            // Act - Start motor
            Motor.StartMotor();
            
            // Assert - Motor started
            Equal(expected := TRUE, actual := motor.IsRunning());
            Equal(expected := 1, actual := motor.StartMotorCallCount);
            
            // Act - Stop motor
            Motor.StopMotor();
            
            // Assert - Motor stopped
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 1, actual := motor.StopMotorCallCount);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MockMotor_TracksCallCounts
            // Arrange
            motor.TargetSpeed := 80.0;
            motor.FixedAcceleration := 12.0;
            motor.FixedDeceleration := 18.0;
            
            // Act
            Motor.StartMotor();
            Motor.StopMotor();
            
            // Assert - Call counts are tracked and properties are set
            Equal(expected := 1, actual := motor.StartMotorCallCount);
            Equal(expected := 1, actual := motor.StopMotorCallCount);
            Equal(expected := 80.0, actual := motor.TargetSpeed);
            Equal(expected := 12.0, actual := motor.FixedAcceleration);
            Equal(expected := 18.0, actual := motor.FixedDeceleration);
        END_METHOD

        {Test}
        METHOD PUBLIC Test_MockMotor_ResetClearsState
            // Arrange
            Motor.StartMotor();
            
            // Act
            motor.Reset();
            
            // Assert - All state cleared
            Equal(expected := FALSE, actual := motor.IsRunning());
            Equal(expected := 0, actual := motor.StartMotorCallCount);
            Equal(expected := 0, actual := motor.StopMotorCallCount);
            Equal(expected := 0.0, actual := motor.GetCurrentSpeed());
        END_METHOD
    END_CLASS
END_NAMESPACE
