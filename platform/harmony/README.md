# MapLibre Native for HarmonyOS

OpenGL-based vector map rendering library for HarmonyOS platform.

> 📦 **Package**: `maplibre-harmony` | 🔖 **Version**: 0.1.0-alpha.1 | 📄 **License**: BSD-2-Clause

## Project Structure

```
platform/harmony/
├── maplibre_harmony/          # HAR module (publishable package)
│   ├── src/main/ets/          # ArkTS API layer
│   ├── src/main/cpp/          # C++ NAPI bridge
│   └── README.md              # 👉 Full documentation
├── entry/                     # Demo application
├── src/                       # Platform implementation
└── harmony.cmake              # Build configuration
```

## Quick Start

### Requirements

- HarmonyOS SDK 5.0.0+ (API 12)
- DevEco Studio 5.0.5+
- Node.js 18.0+

### Build

```bash
cd platform/harmony/maplibre_harmony

# Set environment (macOS)
export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
export NODE_HOME=/Applications/DevEco-Studio.app/Contents/tools/node

# Build release HAR
./pre-release.sh
```

**Output**: `maplibre_harmony/build/default/outputs/default/maplibre-harmony.har`

## Usage

```typescript
import { NativeMapView, MapLibreMap } from 'maplibre-harmony';

@Entry
@Component
struct MapPage {
  build() {
    NativeMapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      onMapReady: (map: MapLibreMap) => {
        console.log('Map ready!');
      }
    })
  }
}
```

For complete examples and API documentation, see **[maplibre_harmony/README.md](maplibre_harmony/README.md)**.

## Features

- ✅ Vector map rendering (OpenGL ES 3.0)
- ✅ Full gesture support (pan, zoom, rotate, tilt)
- ✅ Markers, polylines, polygons
- ✅ Camera animations (move, animate, flyTo)
- ✅ Runtime styling and data sources
- ✅ 26 event listeners (Android/iOS compatible)
- ✅ Offline maps and snapshots
- ✅ Thread-safe, DPI-aware

See **[Feature Comparison Table](maplibre_harmony/README.md#feature-comparison-harmonyos-vs-android-vs-ios)** for detailed comparison with Android/iOS.

## Documentation

- **[maplibre_harmony/README.md](maplibre_harmony/README.md)** - Complete package documentation
- **[API Documentation](maplibre_harmony/docs/api/)** - API reference and guides
- **[00_START_HERE.md](00_START_HERE.md)** - Developer setup guide
- **[BUILD_AND_TEST.md](BUILD_AND_TEST.md)** - Build instructions

## Architecture

```text
                      User Actions (Touch/API Calls)
                                    │
                                    ▼
        ┌───────────────────────────────────────────────────┐
        │         Application Layer (ArkTS/TypeScript)       │
        │                                                    │
        │    NativeMapView  ──▶  MapLibreMap API           │
        │    (XComponent)        (Map Control Interface)    │
        └────────────────────┬──────────────────────────────┘
                             │ NAPI Calls
                             ▼
        ┌───────────────────────────────────────────────────┐
        │           NAPI Bridge Layer (C++)                  │
        │                                                    │
        │    Type Conversion  ←→  ThreadSafe  ←→  Bindings │
        └────────────────────┬──────────────────────────────┘
                             │ C++ Objects
                             ▼
        ┌───────────────────────────────────────────────────┐
        │         MapLibre Core Engine (C++)                │
        │                                                    │
        │    NativeMapView (Core Map Logic)                 │
        │    Camera | Style | Annotations | Query           │
        └────────┬───────────────────────────┬──────────────┘
                 │                           │
    UI Thread    │                           │  Render Thread
                 │                           │
                 ▼                           ▼
        ┌─────────────────┐       ┌──────────────────────┐
        │   Event          │       │   Rendering System   │
        │   Callbacks      │       │                      │
        │                 │       │   OpenGL ES 3.0      │
        │   ThreadSafe    │       │   EGL Context        │
        │   Callback      │       │   Render Thread      │
        └─────────────────┘       └──────────┬───────────┘
                                             │
                                             ▼
        ┌───────────────────────────────────────────────────┐
        │         HarmonyOS System Layer                     │
        │                                                    │
        │  XComponent | libuv | EGL | libcurl | SQLite     │
        └────────────────────┬──────────────────────────────┘
                             │
                             ▼
                     GPU Hardware → Screen Display
```

### Key Concepts

- **Layered Architecture**: ArkTS → NAPI → Core → System
- **Bidirectional Communication**: API Calls (Downstream) + Event Callbacks (Upstream)  
- **Multi-Threading**: Separate UI Thread and Render Thread
- **Thread-Safe**: ThreadSafeCallback ensures cross-thread safety
- **Hardware-Accelerated**: OpenGL ES 3.0 + VSync synchronization

Details: See **[Architecture Documentation](maplibre_harmony/docs/)**

## Troubleshooting

**Build issues?** 
```bash
# Clean and rebuild
cd platform/harmony/maplibre_harmony
rm -rf build/ .cxx/
./pre-release.sh
```

**Map not rendering?**
1. Check OpenGL ES 3.0 support
2. Verify style URL accessibility
3. Check logs: `hdc hilog | grep MapLibre`

**More help:** See **[Troubleshooting Guide](maplibre_harmony/docs/troubleshooting/TROUBLESHOOTING.md)**

## Testing

```bash
# Run demo app
cd platform/harmony
hdc install entry/build/default/outputs/default/entry-default-signed.hap
```

## Contributing

Contributions welcome! Please:
1. Follow C++17/20 and ArkTS conventions
2. Update documentation for new features
3. Ensure tests pass before submitting PR

See **[CONTRIBUTING.md](../../CONTRIBUTING.md)** for details.

## Links

- 📦 **Package**: [maplibre-harmony on npm](https://www.npmjs.com/package/maplibre-harmony) (coming soon)
- 🏠 **Homepage**: https://github.com/yidafu/maplibre-react-native/tree/hmos/harmony
- 🐛 **Issues**: https://github.com/yidafu/maplibre-react-native/issues
- 🌐 **MapLibre**: https://maplibre.org
- 📚 **HarmonyOS Docs**: https://developer.huawei.com/consumer/en/harmonyos/

## License

BSD-2-Clause - See [LICENSE.md](../../LICENSE.md)

---

**Made with ❤️ for the HarmonyOS community**