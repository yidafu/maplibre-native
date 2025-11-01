/**
 * HeatmapLayer - 封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class HeatmapLayer {
  private nativeInstance: maplibre.HeatmapLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.HeatmapLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.HeatmapLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid HeatmapLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): HeatmapLayer {
    return new HeatmapLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.HeatmapLayer): HeatmapLayer {
    return new HeatmapLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.HeatmapLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): HeatmapLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): HeatmapLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): HeatmapLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setFilter(filter: Object[]): HeatmapLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  // ========== Heatmap 样式属性方法 ==========

  setHeatmapRadius(value: ESObject): HeatmapLayer {
    // TODO: 实现 setHeatmapRadius
    return this;
  }

  setHeatmapOpacity(value: ESObject): HeatmapLayer {
    // TODO: 实现 setHeatmapOpacity
    return this;
  }

  setHeatmapIntensity(value: ESObject): HeatmapLayer {
    // TODO: 实现 setHeatmapIntensity
    return this;
  }
}
