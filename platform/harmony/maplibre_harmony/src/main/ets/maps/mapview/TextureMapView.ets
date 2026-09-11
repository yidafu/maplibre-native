/**
 * TextureMapView - map view rendering into an XComponentType.TEXTURE surface.
 *
 * Mirrors the two-component convention used by Android map SDKs (MapView /
 * TextureMapView): identical props, callbacks and ornaments to MapView; only
 * the render surface differs. Equivalent to MapView({ surfaceType: 'texture' }).
 *
 * - 'texture' mode composites the map into the ArkUI render tree (like iOS
 *   MLNMapView's layer-backed view), enabling transforms, effects and reliable
 *   overlay of sibling components.
 * - MapView (XComponentType.SURFACE) keeps the exclusive-surface fast path.
 *
 * The render mode is fixed at construction; switching modes requires
 * rebuilding the component.
 */

import { MapView } from './NativeMapView';
import { MapLibreMap } from '../MapLibreMap';
import { MapLibreMapOptions } from '../MapLibreMapOptions';

@Component
export struct TextureMapView {
  // ========== Mirrored MapView props ==========
  @Prop styleUrl: string;
  @Prop initialLatitude: number = 30.2741;
  @Prop initialLongitude: number = 120.1551;
  @Prop initialZoom: number = 6;
  @Prop initialBearing: number = 0;
  @Prop initialPitch: number = 0;
  @Prop debugMode: boolean = false;
  @Prop mapOptions: MapLibreMapOptions | undefined = undefined;
  // ========== Mirrored MapView callbacks ==========
  onMapViewCreated?: (map: MapLibreMap) => void;
  onMapReady?: (map: MapLibreMap) => void | Promise<void>;
  onMapLoaded?: () => void;
  onMapError?: (error: string) => void;
  // Declarative child support (passed through to the inner MapView)
  @BuilderParam children?: () => void;

  // Trailing-closure passthrough: re-emit the caller's builder inside MapView.
  @Builder
  passChildren() {
    this.children?.()
  }

  build() {
    MapView({
      styleUrl: this.styleUrl,
      initialLatitude: this.initialLatitude,
      initialLongitude: this.initialLongitude,
      initialZoom: this.initialZoom,
      initialBearing: this.initialBearing,
      initialPitch: this.initialPitch,
      debugMode: this.debugMode,
      mapOptions: this.mapOptions,
      surfaceType: 'texture',
      onMapViewCreated: this.onMapViewCreated,
      onMapReady: this.onMapReady,
      onMapLoaded: this.onMapLoaded,
      onMapError: this.onMapError
    }) {
      this.passChildren()
    }
  }
}
