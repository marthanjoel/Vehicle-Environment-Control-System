# Vehicle Environment Control System - README

## Project Overview

The Vehicle Environment Control System is an Arduino-based safety monitoring system for vehicles. It continuously monitors environmental conditions inside the vehicle, detects potential hazards, and provides visual and audible alerts.

### Features

* Monitors cabin temperature and humidity using a DHT11 sensor.
* Monitors engine temperature using an LM35 temperature sensor.
* Detects fire using a flame sensor.
* Visual alerts via RGB LED (Green = safe, Red = danger).
* Audible alerts via buzzer.
* Relay module simulates automatic action (e.g., ventilation/window control).
* Alerts triggered when:

  * Flame is detected.
  * Engine temperature exceeds 200°C.
  * Cabin temperature exceeds 35°C.

## Components Used

* Arduino UNO or compatible board.
* DHT11 temperature & humidity sensor (cabin monitoring).
* LM35 temperature sensor (engine monitoring).
* Flame sensor (fire detection).
* RGB LED (status indication).
* Buzzer (alert sound).
* 5V Relay module (HVAC/window simulation).
* 10kΩ resistor for flame sensor pull-down.
* Breadboard and connecting wires.

## Wiring Instructions

### DHT11 Sensor

* VCC → Arduino 5V
* GND → Arduino GND
* DATA → Arduino Digital Pin 2

### LM35 Sensor

* Left pin → 5V
* Middle pin → Analog pin A0
* Right pin → GND

### Flame Sensor

* VCC → 5V
* GND → GND
* DO → Digital pin 3
* Add 10kΩ resistor from DO to GND (pull-down)

### RGB LED

* Red → Pin 9 (with current-limiting resistor if needed)
* Green → Pin 10
* Blue → Pin 11 (not used)
* Common cathode → GND

### Buzzer

* Positive → Pin 7
* Negative → GND

### Relay Module

* IN → Pin 8
* VCC → 5V
* GND → GND
* NO & COM → connect external device if needed (simulation only)

## Code Description

1. **Setup:** Initializes serial communication, sensor, pins, and sets initial LED and relay states.
2. **Loop:**

   * Reads cabin temperature & humidity from DHT11.
   * Reads engine temperature from LM35.
   * Reads flame sensor digital output.
   * Checks thresholds:

     * Engine temperature > 200°C → triggers alert.
     * Cabin temperature > 35°C → relay ON.
     * Flame detected → triggers alert.
     * Humidity > 70% → displayed as info only.
   * Updates RGB LED and buzzer.
   * Controls relay according to conditions.
   * Prints formatted data on Serial Monitor.

## Serial Monitor Output

The system prints a table every 2 seconds:

```
Cabin Temp | Humidity | Flame | Engine Temp | Status
28.7 C    | 59.2 %   | 0     | 150.3 C     | System Safe
28.7 C    | 59.2 %   | 1     | 320.0 C     | FIRE! & OVERHEATING!
```

* Flame = 1 → fire detected
* Flame = 0 → no fire
* Status updates according to alerts

## Notes

* The flame sensor requires a **10kΩ pull-down resistor** to prevent false alerts.
* LM35 analog pin must be connected properly; otherwise, it may read extreme values.
* The relay simulates automatic control for ventilation or windows; a real fan or motor is optional.
* The system is fully functional even without external devices connected to the relay.

## Safety and Testing

* Test flame sensor with safe methods (e.g., lighter at safe distance).
* Do not touch LM35 with hot objects above safe temperatures.
* Ensure all wiring is secure to prevent false readings.

## Demo Instructions

1. Power the Arduino.
2. Observe RGB LED: Green = safe.
3. Simulate fire → Flame LED turns red, buzzer sounds, relay activates.
4. Increase engine temperature in code (for demo) → Red LED, buzzer, relay activate.
5. Monitor Serial Monitor for real-time readings and alerts.

## Conclusion

This Vehicle Environment Control System demonstrates how Arduino can be used for real-time monitoring, alerting, and simulated automatic responses in vehicles, improving both safety and comfort.
