import geoLocationManager from '@ohos.geoLocationManager';

/**
 * Location engine request configuration.
 */
export class LocationEngineRequest {
  // Update interval (milliseconds)
  interval: number = 1000;
  // Fastest update interval (milliseconds)
  fastestInterval: number = 1000;
  // Minimum displacement (meters)
  minDisplacement: number = 0;
  // Priority
  priority: geoLocationManager.LocationRequestPriority = geoLocationManager.LocationRequestPriority.FIRST_FIX;
  // Scenario
  scenario: geoLocationManager.LocationRequestScenario = geoLocationManager.LocationRequestScenario.NAVIGATION;
  // Maximum accuracy
  maxAccuracy: number = 0;

  constructor(builder?: LocationEngineRequestBuilder) {
    if (builder) {
      this.interval = builder.interval ?? this.interval;
      this.fastestInterval = builder.fastestInterval ?? this.fastestInterval;
      this.minDisplacement = builder.minDisplacement ?? this.minDisplacement;
      this.priority = builder.priority ?? this.priority;
      this.scenario = builder.scenario ?? this.scenario;
      this.maxAccuracy = builder.maxAccuracy ?? this.maxAccuracy;
    }
  }

  static builder(): LocationEngineRequestBuilder {
    return new LocationEngineRequestBuilder();
  }
}

/**
 * Builder for `LocationEngineRequest`.
 */
export class LocationEngineRequestBuilder {
  interval?: number;
  fastestInterval?: number;
  minDisplacement?: number;
  priority?: geoLocationManager.LocationRequestPriority;
  scenario?: geoLocationManager.LocationRequestScenario;
  maxAccuracy?: number;

  setInterval(interval: number): LocationEngineRequestBuilder {
    this.interval = interval;
    return this;
  }

  setFastestInterval(fastestInterval: number): LocationEngineRequestBuilder {
    this.fastestInterval = fastestInterval;
    return this;
  }

  setMinDisplacement(minDisplacement: number): LocationEngineRequestBuilder {
    this.minDisplacement = minDisplacement;
    return this;
  }

  setPriority(priority: geoLocationManager.LocationRequestPriority): LocationEngineRequestBuilder {
    this.priority = priority;
    return this;
  }

  setScenario(scenario: geoLocationManager.LocationRequestScenario): LocationEngineRequestBuilder {
    this.scenario = scenario;
    return this;
  }

  setMaxAccuracy(maxAccuracy: number): LocationEngineRequestBuilder {
    this.maxAccuracy = maxAccuracy;
    return this;
  }

  build(): LocationEngineRequest {
    return new LocationEngineRequest(this);
  }
}

