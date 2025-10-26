# MapLibre Native for HarmonyOS

MapLibre Native port for HarmonyOS platform.

## Project Structure

```
platform/harmony/
├── maplibre_harmony/          # Main HarmonyOS module
│   ├── src/main/
│   │   ├── ets/               # TypeScript/ArkTS code
│   │   │   ├── maps/          # Map API and gesture handling
│   │   │   └── pages/         # Demo pages
│   │   └── cpp/               # Native C++ bridge (NAPI)
│   └── Index.ets              # Module entry point
├── src/                       # Additional native implementations
├── platform/                  # Platform-specific implementations
├── docs/                      # Documentation
│   └── archived/              # Archived analysis and logs
├── build-profile.json5        # HarmonyOS build configuration
├── oh-package.json5           # HarmonyOS package configuration
└── README.md                  # This file

```

## Quick Start

### Build
```bash
# Build the HarmonyOS module
./build.sh
```

### Documentation

- **[00_START_HERE.md](00_START_HERE.md)** - Start here for project overview
- **[BUILD_AND_TEST.md](BUILD_AND_TEST.md)** - Build and test instructions
- **[STATUS.md](STATUS.md)** - Current implementation status
- **[TODO_FEATURES.md](TODO_FEATURES.md)** - Planned features and improvements

### Architecture Documentation

- **[README_LIBUV_AND_TIMER.md](README_LIBUV_AND_TIMER.md)** - Timer system design
- **[README_TIMER_THREAD_POOL.md](README_TIMER_THREAD_POOL.md)** - Thread pool implementation
- **[SCRIPTS_README.md](SCRIPTS_README.md)** - Build scripts documentation

## Recent Changes

See [README_RECENT_CHANGES.md](README_RECENT_CHANGES.md) for the latest updates.

## Key Features

- ✅ Full gesture support (pan, pinch, rotate, tilt)
- ✅ Vector tile rendering
- ✅ Style API compatibility
- ✅ Marker support
- ✅ Camera animations
- ✅ DPI/High-resolution display support
- ✅ Optimized rendering pipeline

## Gesture System

The gesture system has been recently improved with:
- Incremental zoom calculation (Android style)
- Fixed rotation anchor points (iOS style)
- DPI-aware coordinate transformation
- Gesture mutex control to prevent conflicts
- Performance optimizations with cached pixelRatio

## Architecture

### Native Bridge (NAPI)
- `native_map_view_harmony.cpp/hpp` - Main NAPI bridge
- `napi_utils.h` - NAPI helper utilities
- `harmony_renderer_frontend.cpp/hpp` - Rendering frontend
- `harmony_gl_renderer_backend.cpp/hpp` - OpenGL backend

### TypeScript/ArkTS Layer
- `MapLibreMap.ets` - Main map API
- `MapGestureDetector.ets` - Gesture handling
- `UiSettings.ets` - UI configuration
- `NativeMapView.ets` - XComponent wrapper

## Development

### Requirements
- HarmonyOS SDK 5.0+
- DevEco Studio
- CMake 3.20+

### Testing
Run the demo app on a HarmonyOS device or emulator.

## License

See [LICENSE.md](../../LICENSE.md) in the root directory.

