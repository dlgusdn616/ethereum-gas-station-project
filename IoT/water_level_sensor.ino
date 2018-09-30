const int WATER_SENSOR_PIN0 = A0;
void setup() {
    Serial.begin(9600);
}
void loop() {
    int sensorVal0 = analogRead(WATER_SOURCE_PIN0);
    Serial.print("0 sensor value = ");
    serial.println(sensorval0);
    delay(3000);
}
