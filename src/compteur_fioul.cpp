#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <TCS34725.h>
#include "credentials.h"
#include "RemoteDebug.h" //wireless debugging

#define sec_to_ms(T) (T * 1000L)
#define RG_THRESHOLD 10
#define B_THRESHOLD 1
#define POSTING_INTERVAL 30 * 1000L //send data to thingspeak maximum every 30sec

/* WiFi configuration */
const char *ssid = WIFI_SSID;
const char *password = WIFI_PASSWD;
bool burnerPreviouslyOn = false;
unsigned long startTime;
unsigned long lastRunTime;

/* ThingSpeak settings */
#define POSTING_URL "http://api.thingspeak.com/update"
unsigned long lastConnectionTime = 0;

/* Color sensor */
TCS34725 tcs;

/* Remote Debug */
RemoteDebug Debug;

/* Counters */
unsigned long burnerTime = 0;

int wifiSetup(void);
bool isBurnerOn();
unsigned long runningTime(unsigned long startTime, unsigned long stopTime);
void sendThingSpeakhttpRequest(unsigned long burnerTime);

void setup(void)
{
  Serial.begin(115200);
  wifiSetup();
  Wire.begin();
  if (!tcs.attach(Wire))
    Serial.println("ERROR: TCS34725 NOT FOUND !!!");

  tcs.integrationTime(50); // ms
  tcs.gain(TCS34725::Gain::X01);

  Debug.begin(WiFi.getHostname());
  // ready to goto loop
}

void loop(void)
{
  bool burnerCurrentlyOn = isBurnerOn();
  if (burnerCurrentlyOn)
  {
    if (!burnerPreviouslyOn)
    {
      //initialize times
      startTime = millis();
      burnerPreviouslyOn = true;
      debugI("Brûleur ON");
    }
  }
  else
  {
    unsigned long currTime = millis();
    //burner turned off
    if (burnerPreviouslyOn)
    {
      //check if it was really on or only in preheating mode (status LED was flashing)
      unsigned long rTime = runningTime(startTime, currTime);
      if (rTime > sec_to_ms(5))
      {
        //burner was on
        lastRunTime = rTime;
        burnerPreviouslyOn = false;
        debugI("Brûleur OFF \n");
        debugI("Brûleur ON pendant %d \n", rTime);
        //send to MQTT
        if (currTime - lastConnectionTime > POSTING_INTERVAL)
        {
          sendThingSpeakhttpRequest(rTime);
        }
      }
      else
      {
        burnerPreviouslyOn = false;
        //false positive
        debugI("Faux positif");
      }
    }
  }

  if (Debug.isActive(Debug.VERBOSE))
  { // Debug message info
    TCS34725::Color color = tcs.color();
    char s[128];
    snprintf(s, sizeof(s), "R : %f, G: %f, B: %f", color.r, color.g, color.b);
    Debug.printf(s);
    delay(2000);
  }
  Debug.handle(); //remote debug
}

/* utility functions */

int wifiSetup(void)
{
  WiFi.begin(ssid, password);
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }
  Serial.print("Connected, IP address: ");
  Serial.println(WiFi.localIP());
  Serial.print("Hostname: ");
  Serial.println(WiFi.getHostname());
  return 1;
}

bool isBurnerOn()
{
  while (!tcs.available())
  {
    // Serial.println("waiting for sensor to become available");
  }
  TCS34725::Color color = tcs.color();

  if (color.g > RG_THRESHOLD && (color.r - color.g) < RG_THRESHOLD && color.b < B_THRESHOLD)
  {
    return true;
  }
  return false;
}

unsigned long runningTime(unsigned long startTime, unsigned long stopTime)
{
  return stopTime - startTime;
}

void sendThingSpeakhttpRequest(unsigned long burnerTime)
{

  // Make sure there is an Internet connection.
  if (WiFi.status() != WL_CONNECTED)
  {
    wifiSetup();
  }

  HTTPClient http;
  if (!http.begin(POSTING_URL))
  {

    debugI("Connection failed");
    lastConnectionTime = millis();
    return;
  }
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  String httpRequestData = "api_key=" + String(WRITE_API_KEY) + "&field1=" + String(burnerTime / 1000.);
  // Send HTTP POST request
  int httpResponseCode = http.POST(httpRequestData);
  if (httpResponseCode == 200)
  {
    debugI("Successfully sent data to ThingSpeak");
  }
  else
  {
    debugI("Thingspeak server error, code : %d", httpResponseCode);
  }
  lastConnectionTime = millis();
  http.end();
}