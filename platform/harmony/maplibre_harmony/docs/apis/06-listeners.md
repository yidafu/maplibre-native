# Listeners Module

## Overview

The Listeners module provides comprehensive event notification interfaces for map operations. Following Android/iOS patterns, these listeners enable reactive programming and event-driven map interactions.

## Categories

- [Camera Events](#camera-events) - Camera movement and state changes
- [Map Loading Events](#map-loading-events) - Map and style loading lifecycle
- [Rendering Events](#rendering-events) - Frame and rendering notifications
- [Style Events](#style-events) - Style loading and image management
- [Gesture Events](#gesture-events) - User input and touch gestures
- [Marker Events](#marker-events) - Marker interactions
- [Other Events](#other-events) - Shader compilation, glyphs, tiles, sprites

---

## Camera Events

### OnCameraWillChangeListener

Fired when camera is about to change.

```typescript
interface OnCameraWillChangeListener {
  onCameraWillChange(animated: boolean): void;
}
```

**Example:**
```typescript
map.addOnCameraWillChangeListener({
  onCameraWillChange: (animated) => {
    console.info(`Camera will change (animated: ${animated})`);
  }
});
```

### OnCameraIsChangingListener

Fired repeatedly while camera is changing.

```typescript
interface OnCameraIsChangingListener {
  onCameraIsChanging(): void;
}
```

### OnCameraDidChangeListener

Fired when camera change completes.

```typescript
interface OnCameraDidChangeListener {
  onCameraDidChange(animated: boolean): void;
}
```

---

## Map Loading Events

### OnWillStartLoadingMapListener

Fired before map starts loading.

```typescript
interface OnWillStartLoadingMapListener {
  onWillStartLoadingMap(): void;
}
```

### OnDidFinishLoadingMapListener

Fired when map finishes loading.

```typescript
interface OnDidFinishLoadingMapListener {
  onDidFinishLoadingMap(): void;
}
```

### OnDidFailLoadingMapListener

Fired when map loading fails.

```typescript
interface OnDidFailLoadingMapListener {
  onDidFailLoadingMap(error: string): void;
}
```

**Example:**
```typescript
map.addOnDidFinishLoadingMapListener({
  onDidFinishLoadingMap: () => {
    console.info('Map loaded successfully!');
    // Perform post-load operations
  }
});

map.addOnDidFailLoadingMapListener({
  onDidFailLoadingMap: (error) => {
    console.error(`Map load failed: ${error}`);
  }
});
```

---

## Rendering Events

### OnWillStartRenderingFrameListener

Fired before each frame renders.

```typescript
interface OnWillStartRenderingFrameListener {
  onWillStartRenderingFrame(): void;
}
```

### OnDidFinishRenderingFrameListener

Fired after each frame renders.

```typescript
interface OnDidFinishRenderingFrameListener {
  onDidFinishRenderingFrame(fully: boolean): void;
}
```

**Parameters:**
- `fully: boolean` - Whether frame was fully rendered

### OnDidFinishRenderingFrameWithStatsListener

Fired after each frame with rendering statistics.

```typescript
interface OnDidFinishRenderingFrameWithStatsListener {
  onDidFinishRenderingFrame(fully: boolean, stats: RenderingStats): void;
}
```

**Example:**
```typescript
map.addOnDidFinishRenderingFrameWithStatsListener({
  onDidFinishRenderingFrame: (fully, stats) => {
    const fps = stats.getEstimatedFps();
    console.info(`FPS: ${fps.toFixed(1)}, Fully rendered: ${fully}`);
  }
});
```

### OnWillStartRenderingMapListener

Fired before map starts rendering.

```typescript
interface OnWillStartRenderingMapListener {
  onWillStartRenderingMap(): void;
}
```

### OnDidFinishRenderingMapListener

Fired when map finishes rendering.

```typescript
interface OnDidFinishRenderingMapListener {
  onDidFinishRenderingMap(fully: boolean): void;
}
```

---

## Style Events

### OnDidFinishLoadingStyleListener

Fired when style finishes loading.

```typescript
interface OnDidFinishLoadingStyleListener {
  onDidFinishLoadingStyle(): void;
}
```

**Example:**
```typescript
map.addOnDidFinishLoadingStyleListener({
  onDidFinishLoadingStyle: () => {
    console.info('Style loaded, safe to add layers now');
    // Add custom layers
  }
});
```

### OnStyleImageMissingListener

Fired when a required style image is missing.

```typescript
interface OnStyleImageMissingListener {
  onStyleImageMissing(imageId: string): void;
}
```

**Example:**
```typescript
map.addOnStyleImageMissingListener({
  onStyleImageMissing: (imageId) => {
    console.warn(`Missing image: ${imageId}`);
    // Load and add missing image
  }
});
```

### OnCanRemoveUnusedStyleImageListener

Fired when a style image is no longer needed.

```typescript
interface OnCanRemoveUnusedStyleImageListener {
  onCanRemoveUnusedStyleImage(imageId: string): boolean;
}
```

**Returns:** `true` to allow removal, `false` to keep

---

## Gesture Events

### OnMapClickListener

Fired when map is clicked/tapped.

```typescript
interface OnMapClickListener {
  onMapClick(latLng: LatLng): boolean;
}
```

**Returns:** `true` to consume event, `false` to propagate

**Example:**
```typescript
map.addOnMapClickListener({
  onMapClick: (latLng) => {
    console.info(`Map clicked at: ${latLng.latitude}, ${latLng.longitude}`);
    
    // Query features at click point
    const point = map.pixelForLatLng(latLng.latitude, latLng.longitude);
    const features = map.queryRenderedFeatures(point);
    
    if (features.length > 0) {
      console.info(`Clicked on ${features.length} feature(s)`);
      return true;  // Consume event
    }
    
    return false;  // Let event propagate
  }
});
```

### OnMapLongClickListener

Fired when map is long-pressed.

```typescript
interface OnMapLongClickListener {
  onMapLongClick(latLng: LatLng): boolean;
}
```

### OnMoveListener

Fired during pan/move gestures.

```typescript
interface OnMoveListener {
  onMoveBegin(detector: MoveGestureDetector): boolean;
  onMove(detector: MoveGestureDetector): boolean;
  onMoveEnd(detector: MoveGestureDetector): void;
}
```

### OnScaleListener

Fired during pinch-to-zoom gestures.

```typescript
interface OnScaleListener {
  onScaleBegin(detector: ScaleGestureDetector): boolean;
  onScale(detector: ScaleGestureDetector): boolean;
  onScaleEnd(detector: ScaleGestureDetector): void;
}
```

### OnRotateListener

Fired during rotation gestures.

```typescript
interface OnRotateListener {
  onRotateBegin(detector: RotateGestureDetector): boolean;
  onRotate(detector: RotateGestureDetector): boolean;
  onRotateEnd(detector: RotateGestureDetector): void;
}
```

### OnTiltListener

Fired during tilt/pitch gestures.

```typescript
interface OnTiltListener {
  onTiltBegin(detector: TiltGestureDetector): boolean;
  onTilt(detector: TiltGestureDetector): boolean;
  onTiltEnd(detector: TiltGestureDetector): void;
}
```

### OnDoubleTapListener

Fired on double-tap gestures.

```typescript
interface OnDoubleTapListener {
  onDoubleTap(point: Point): boolean;
}
```

### OnQuickZoomListener

Fired during quick-zoom (double-tap and drag) gestures.

```typescript
interface OnQuickZoomListener {
  onQuickZoomBegin(detector: QuickZoomGestureDetector): boolean;
  onQuickZoom(detector: QuickZoomGestureDetector): boolean;
  onQuickZoomEnd(detector: QuickZoomGestureDetector): void;
}
```

---

## Marker Events

### OnMarkerClickListener

Fired when a marker is clicked.

```typescript
interface OnMarkerClickListener {
  onMarkerClick(marker: Marker): boolean;
}
```

**Example:**
```typescript
map.addOnMarkerClickListener({
  onMarkerClick: (marker) => {
    console.info(`Marker clicked: ${marker.getTitle()}`);
    map.selectMarker(marker);  // Show info window
    return true;
  }
});
```

### OnMarkerLongClickListener

Fired when a marker is long-pressed.

```typescript
interface OnMarkerLongClickListener {
  onMarkerLongClick(marker: Marker): boolean;
}
```

### OnMarkerDragListener

Fired during marker drag operations.

```typescript
interface OnMarkerDragListener {
  onMarkerDragStart(marker: Marker): void;
  onMarkerDrag(marker: Marker): void;
  onMarkerDragEnd(marker: Marker): void;
}
```

**Example:**
```typescript
map.addOnMarkerDragListener({
  onMarkerDragStart: (marker) => {
    console.info('Drag started');
  },
  onMarkerDrag: (marker) => {
    const pos = marker.getPosition();
    console.info(`Dragging: ${pos.latitude}, ${pos.longitude}`);
  },
  onMarkerDragEnd: (marker) => {
    const pos = marker.getPosition();
    console.info(`Dropped at: ${pos.latitude}, ${pos.longitude}`);
    // Save new position
  }
});
```

### OnMarkerSelectListener

Fired when marker selection changes.

```typescript
interface OnMarkerSelectListener {
  onMarkerSelected(marker: Marker): void;
  onMarkerDeselected(marker: Marker): void;
}
```

---

## Other Events

### OnDidBecomeIdleListener

Fired when map becomes idle (no rendering/loading).

```typescript
interface OnDidBecomeIdleListener {
  onDidBecomeIdle(): void;
}
```

### OnSourceChangedListener

Fired when a data source changes.

```typescript
interface OnSourceChangedListener {
  onSourceChanged(sourceId: string): void;
}
```

### Shader Compilation Events

```typescript
interface OnPreCompileShaderListener {
  onPreCompileShader(shaderName: string): void;
}

interface OnPostCompileShaderListener {
  onPostCompileShader(shaderName: string): void;
}

interface OnShaderCompileFailedListener {
  onShaderCompileFailed(shaderName: string, error: string): void;
}
```

### Glyph Loading Events

```typescript
interface OnGlyphsRequestedListener {
  onGlyphsRequested(fontStack: string, range: string): void;
}

interface OnGlyphsLoadedListener {
  onGlyphsLoaded(fontStack: string, range: string): void;
}

interface OnGlyphsErrorListener {
  onGlyphsError(fontStack: string, range: string, error: string): void;
}
```

### Tile Events

```typescript
interface OnTileActionListener {
  onTileAction(operation: TileOperation, sourceId: string, tileId: string): void;
}
```

**TileOperation enum:**
- `LOAD` - Tile is loading
- `REMOVE` - Tile is removed
- `ERROR` - Tile loading error

### Sprite Events

```typescript
interface OnSpriteRequestedListener {
  onSpriteRequested(): void;
}

interface OnSpriteLoadedListener {
  onSpriteLoaded(): void;
}

interface OnSpriteErrorListener {
  onSpriteError(error: string): void;
}
```

---

## Complete Example

```typescript
import {
  NativeMapView,
  MapLibreMap,
  OnMapClickListener,
  OnCameraDidChangeListener,
  OnDidFinishRenderingFrameWithStatsListener,
  OnMarkerClickListener,
  LatLng,
  Marker
} from '@ohos/maplibre';

@Entry
@Component
struct ListenersExample {
  private map: MapLibreMap | null = null;

  // Define listeners
  private mapClickListener: OnMapClickListener = {
    onMapClick: (latLng: LatLng) => {
      console.info(`Clicked: ${latLng.latitude}, ${latLng.longitude}`);
      
      // Add marker at click location
      const marker = new Marker({
        position: latLng,
        title: 'New Marker'
      });
      this.map?.addMarker(marker);
      
      return true;
    }
  };

  private cameraListener: OnCameraDidChangeListener = {
    onCameraDidChange: (animated) => {
      const zoom = this.map?.getZoom();
      const bearing = this.map?.getBearing();
      console.info(`Camera: zoom=${zoom?.toFixed(2)}, bearing=${bearing?.toFixed(1)}°`);
    }
  };

  private fpsListener: OnDidFinishRenderingFrameWithStatsListener = {
    onDidFinishRenderingFrame: (fully, stats) => {
      const fps = stats.getEstimatedFps();
      if (fps < 30) {
        console.warn(`Low FPS: ${fps.toFixed(1)}`);
      }
    }
  };

  build() {
    NativeMapView({
      styleUrl: "https://demotiles.maplibre.org/style.json",
      onMapViewCreated: (mapLibreMap) => {
        this.map = mapLibreMap;
        this.setupListeners();
      }
    })
      .width('100%')
      .height('100%')
  }

  private setupListeners() {
    if (!this.map) return;

    // Register all listeners
    this.map.addOnMapClickListener(this.mapClickListener);
    this.map.addOnCameraDidChangeListener(this.cameraListener);
    this.map.addOnDidFinishRenderingFrameWithStatsListener(this.fpsListener);

    // Map loading
    this.map.addOnDidFinishLoadingMapListener({
      onDidFinishLoadingMap: () => {
        console.info('Map loaded!');
      }
    });

    // Style loading
    this.map.addOnDidFinishLoadingStyleListener({
      onDidFinishLoadingStyle: () => {
        console.info('Style loaded!');
      }
    });

    console.info('All listeners registered');
  }

  aboutToDisappear() {
    // Clean up listeners
    if (this.map) {
      this.map.removeOnMapClickListener(this.mapClickListener);
      this.map.removeOnCameraDidChangeListener(this.cameraListener);
      this.map.removeOnDidFinishRenderingFrameWithStatsListener(this.fpsListener);
    }
  }
}
```

---

**Last Updated:** 2025-11-04  
**Version:** 1.0.0

