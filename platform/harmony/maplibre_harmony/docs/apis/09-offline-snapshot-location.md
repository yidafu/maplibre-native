# Offline, Snapshot & Location Modules

## Overview

This document covers offline map management, map snapshot generation, and location services integration.

---

## Offline Module

### OfflineManager

Singleton class for managing offline map regions.

```typescript
class OfflineManager {
  static getInstance(context: UIAbilityContext): OfflineManager;
  
  listOfflineRegions(): Promise<OfflineRegion[]>;
  createOfflineRegion(
    definition: OfflineRegionDefinition,
    metadata: ArrayBuffer
  ): Promise<OfflineRegion>;
  mergeOfflineRegions(
    path: string,
    callback: (progress: number) => void
  ): Promise<void>;
}
```

### OfflineRegion

Represents an offline map region.

```typescript
class OfflineRegion {
  getID(): number;
  getDefinition(): OfflineRegionDefinition;
  getMetadata(): ArrayBuffer;
  getStatus(): Promise<OfflineRegionStatus>;
  
  download(): void;
  pause(): void;
  resume(): void;
  delete(): Promise<void>;
  
  setObserver(observer: OfflineRegionObserver): void;
}
```

### OfflineRegionDefinition

```typescript
class OfflineTilePyramidRegionDefinition implements OfflineRegionDefinition {
  constructor(
    styleURL: string,
    bounds: LatLngBounds,
    minZoom: number,
    maxZoom: number,
    pixelRatio: number = 1.0
  );
}
```

### OfflineRegionStatus

```typescript
interface OfflineRegionStatus {
  downloadState: OfflineRegionDownloadState;
  completedResourceCount: number;
  completedResourceSize: number;
  requiredResourceCount: number;
  downloadProgress: number;  // 0-100
}

enum OfflineRegionDownloadState {
  INACTIVE,
  ACTIVE
}
```

### OfflineRegionObserver

```typescript
interface OfflineRegionObserver {
  onStatusChanged(status: OfflineRegionStatus): void;
  onError(error: OfflineRegionError): void;
  onComplete(): void;
}
```

### Usage Example

```typescript
import { OfflineManager, OfflineTilePyramidRegionDefinition, LatLngBounds, LatLng } from '@ohos/maplibre';

// Get manager instance
const offlineManager = OfflineManager.getInstance(getContext());

// Define region
const bounds = new LatLngBounds(
  new LatLng(40.0, 116.0),
  new LatLng(39.0, 117.0)
);

const definition = new OfflineTilePyramidRegionDefinition(
  'https://demotiles.maplibre.org/style.json',
  bounds,
  0,   // minZoom
  16   // maxZoom
);

// Create region with metadata
const metadata = new TextEncoder().encode('Beijing offline map').buffer;
const region = await offlineManager.createOfflineRegion(definition, metadata);

// Set observer
region.setObserver({
  onStatusChanged: (status) => {
    console.info(`Progress: ${status.downloadProgress.toFixed(1)}%`);
    console.info(`Downloaded: ${status.completedResourceCount}/${status.requiredResourceCount}`);
  },
  onError: (error) => {
    console.error(`Download error: ${error.message}`);
  },
  onComplete: () => {
    console.info('Download complete!');
  }
});

// Start download
region.download();

// Pause/resume
region.pause();
region.resume();

// List regions
const regions = await offlineManager.listOfflineRegions();
console.info(`${regions.length} offline regions`);

// Delete region
await region.delete();
```

---

## Snapshot Module

### MapSnapshotter

Generate static map images.

```typescript
class MapSnapshotter {
  constructor(options: SnapshotOptions);
  
  start(callback: SnapshotReadyCallback, errorHandler?: SnapshotErrorHandler): void;
  cancel(): void;
  setObserver(observer: MapSnapshotterObserver): void;
}

interface SnapshotOptions {
  styleURL: string;
  size: Size;
  pixelRatio: number;
  cameraPosition?: CameraPosition;
  region?: LatLngBounds;
}

interface Size {
  width: number;
  height: number;
}

interface SnapshotReadyCallback {
  onSnapshotReady(snapshot: MapSnapshot): void;
}

interface SnapshotErrorHandler {
  onError(error: string): void;
}
```

### MapSnapshot

```typescript
class MapSnapshot {
  getImage(): PixelMap;
  pointForLatLng(latLng: LatLng): Point;
  latLngForPoint(point: Point): LatLng;
}
```

### Usage Example

```typescript
import { MapSnapshotter, SnapshotOptions, CameraPosition, LatLng } from '@ohos/maplibre';

// Create snapshotter
const options: SnapshotOptions = {
  styleURL: 'https://demotiles.maplibre.org/style.json',
  size: { width: 1024, height: 768 },
  pixelRatio: 2.0,
  cameraPosition: new CameraPosition(
    new LatLng(39.9042, 116.4074),
    12,
    0,
    0
  )
};

const snapshotter = new MapSnapshotter(options);

// Generate snapshot
snapshotter.start({
  onSnapshotReady: (snapshot) => {
    console.info('Snapshot ready!');
    const image = snapshot.getImage();
    
    // Save or display image
    // ...
  }
}, {
  onError: (error) => {
    console.error(`Snapshot error: ${error}`);
  }
});

// Cancel if needed
// snapshotter.cancel();
```

---

## Location Module

### LocationComponent

Manages user location display and tracking.

```typescript
class LocationComponent {
  activateLocationComponent(options?: LocationComponentOptions): void;
  deactivateLocationComponent(): void;
  
  isLocationComponentActivated(): boolean;
  isLocationComponentEnabled(): boolean;
  
  setLocationComponentEnabled(enabled: boolean): void;
  setRenderMode(mode: RenderMode): void;
  setCameraMode(mode: CameraMode): void;
  
  getLastKnownLocation(): Location | null;
  
  addOnLocationClickListener(listener: OnLocationClickListener): void;
  addOnCameraTrackingChangedListener(listener: OnCameraTrackingChangedListener): void;
}
```

### LocationComponentOptions

```typescript
interface LocationComponentOptions {
  accuracy: boolean;
  bearing: boolean;
  compass: boolean;
  pulse: boolean;
  pulseFadeEnabled: boolean;
  pulseColor: string;
  accuracyColor: string;
  foregroundTintColor: string;
  backgroundTintColor: string;
  bearingTintColor: string;
  elevation: number;
}
```

### RenderMode

```typescript
enum RenderMode {
  NORMAL,     // Blue dot
  COMPASS,    // Blue dot with heading indicator
  GPS         // Large blue circle (GPS mode)
}
```

### CameraMode

```typescript
enum CameraMode {
  NONE,               // No camera tracking
  NONE_COMPASS,       // No tracking, compass heading
  NONE_GPS,           // No tracking, GPS heading
  TRACKING,           // Track location
  TRACKING_COMPASS,   // Track with compass heading
  TRACKING_GPS,       // Track with GPS heading
  TRACKING_GPS_NORTH  // Track, GPS heading, north up
}
```

### LocationEngine

```typescript
interface LocationEngine {
  requestLocationUpdates(
    request: LocationEngineRequest,
    callback: LocationEngineCallback
  ): void;
  removeLocationUpdates(callback: LocationEngineCallback): void;
  getLastLocation(callback: LocationEngineCallback): void;
}

interface LocationEngineRequest {
  priority: number;
  interval: number;
  fastestInterval: number;
  displacement: number;
}

interface LocationEngineCallback {
  onSuccess(location: Location): void;
  onFailure(error: Error): void;
}
```

### HarmonyLocationEngine

HarmonyOS-specific location engine implementation.

```typescript
class HarmonyLocationEngine implements LocationEngine {
  static getInstance(): HarmonyLocationEngine;
  // Implements LocationEngine interface
}
```

### Usage Example

```typescript
import {
  LocationComponent,
  LocationComponentOptions,
  RenderMode,
  CameraMode,
  HarmonyLocationEngine
} from '@ohos/maplibre';

// Activate location component
const locationComponent = map.getLocationComponent();

const options: LocationComponentOptions = {
  accuracy: true,
  bearing: true,
  compass: true,
  pulse: true,
  pulseFadeEnabled: true,
  pulseColor: '#4A90E2',
  accuracyColor: 'rgba(74, 144, 226, 0.2)',
  foregroundTintColor: '#4A90E2',
  backgroundTintColor: '#FFFFFF',
  bearingTintColor: '#4A90E2',
  elevation: 5
};

locationComponent.activateLocationComponent(options);
locationComponent.setLocationComponentEnabled(true);

// Set render mode
locationComponent.setRenderMode(RenderMode.COMPASS);

// Set camera mode
locationComponent.setCameraMode(CameraMode.TRACKING_GPS);

// Listen for location clicks
locationComponent.addOnLocationClickListener({
  onLocationComponentClick: () => {
    console.info('Location indicator clicked');
    const location = locationComponent.getLastKnownLocation();
    if (location) {
      console.info(`Current location: ${location.latitude}, ${location.longitude}`);
    }
  }
});

// Listen for camera tracking changes
locationComponent.addOnCameraTrackingChangedListener({
  onCameraTrackingDismissed: () => {
    console.info('Camera tracking stopped');
  },
  onCameraTrackingChanged: (mode: CameraMode) => {
    console.info(`Camera mode changed to: ${mode}`);
  }
});

// Use custom location engine
const locationEngine = HarmonyLocationEngine.getInstance();
const request: LocationEngineRequest = {
  priority: 100,  // High accuracy
  interval: 1000,  // 1 second
  fastestInterval: 500,
  displacement: 0
};

locationEngine.requestLocationUpdates(request, {
  onSuccess: (location) => {
    console.info(`Location update: ${location.latitude}, ${location.longitude}`);
  },
  onFailure: (error) => {
    console.error(`Location error: ${error.message}`);
  }
});
```

### PermissionManager

```typescript
class PermissionManager {
  static checkLocationPermission(context: Context): Promise<boolean>;
  static requestLocationPermission(context: Context): Promise<PermissionRequestResult>;
}

interface PermissionRequestResult {
  granted: boolean;
  shouldShowRationale: boolean;
}
```

### Complete Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  LocationComponent,
  RenderMode,
  CameraMode,
  PermissionManager
} from '@ohos/maplibre';

@Entry
@Component
struct LocationExample {
  private map: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;

  async aboutToAppear() {
    // Check permission
    const hasPermission = await PermissionManager.checkLocationPermission(getContext());
    if (!hasPermission) {
      const result = await PermissionManager.requestLocationPermission(getContext());
      if (!result.granted) {
        console.error('Location permission denied');
        return;
      }
    }
  }

  build() {
    Column() {
      NativeMapView({
        styleURL: "https://demotiles.maplibre.org/style.json",
        onMapViewCreated: (mapLibreMap) => {
          this.map = mapLibreMap;
          this.setupLocation();
        }
      })
        .width('100%')
        .height('90%')
      
      Row() {
        Button('Track')
          .onClick(() => this.locationComponent?.setCameraMode(CameraMode.TRACKING_GPS))
        Button('Compass')
          .onClick(() => this.locationComponent?.setRenderMode(RenderMode.COMPASS))
        Button('Normal')
          .onClick(() => this.locationComponent?.setRenderMode(RenderMode.NORMAL))
      }
      .width('100%')
      .height('10%')
      .justifyContent(FlexAlign.SpaceAround)
    }
  }

  private setupLocation() {
    if (!this.map) return;

    this.locationComponent = this.map.getLocationComponent();
    
    // Activate
    this.locationComponent.activateLocationComponent({
      accuracy: true,
      bearing: true,
      compass: true,
      pulse: true
    });
    
    this.locationComponent.setLocationComponentEnabled(true);
    this.locationComponent.setRenderMode(RenderMode.COMPASS);
    this.locationComponent.setCameraMode(CameraMode.TRACKING);

    // Add listeners
    this.locationComponent.addOnLocationClickListener({
      onLocationComponentClick: () => {
        console.info('Location clicked');
      }
    });
  }
}
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

