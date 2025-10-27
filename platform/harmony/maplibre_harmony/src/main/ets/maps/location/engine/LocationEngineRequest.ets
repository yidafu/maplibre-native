import geoLocationManager from '@ohos.geoLocationManager';

/**
 * 位置引擎请求配置
 */
export class LocationEngineRequest {
  // 更新间隔（毫秒）
  interval: number = 1000;
  // 最快更新间隔（毫秒）
  fastestInterval: number = 1000;
  // 最小位移距离（米）
  minDisplacement: number = 0;
  // 优先级
  priority: geoLocationManager.LocationRequestPriority = geoLocationManager.LocationRequestPriority.FIRST_FIX;
  // 场景
  scenario: geoLocationManager.LocationRequestScenario = geoLocationManager.LocationRequestScenario.NAVIGATION;
  // 最大精度
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
 * 位置引擎请求建造者
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

