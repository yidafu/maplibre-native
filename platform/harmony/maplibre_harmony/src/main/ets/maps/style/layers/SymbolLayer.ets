/**
 * SymbolLayer - 封装类
 */
import maplibre from 'libmaplibre.so';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();
  private constructor() {}
}

export class SymbolLayer {
  private nativeInstance: maplibre.SymbolLayer;

  constructor(idOrMarker: string | InternalMarker, sourceId: string = "", nativeOrNothing?: maplibre.SymbolLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.SymbolLayer(idOrMarker, sourceId);
    } else {
      throw new Error('Invalid SymbolLayer constructor arguments');
    }
  }

  static create(id: string, sourceId: string = ""): SymbolLayer {
    return new SymbolLayer(id, sourceId);
  }

  static fromNative(nativeInstance: maplibre.SymbolLayer): SymbolLayer {
    return new SymbolLayer(InternalMarker.INSTANCE, "", nativeInstance);
  }

  getNative(): maplibre.SymbolLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  getSourceId(): string {
    return this.nativeInstance.getSourceId();
  }

  setVisibility(visibility: 'visible' | 'none'): SymbolLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): SymbolLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): SymbolLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setFilter(filter: Object[]): SymbolLayer {
    this.nativeInstance.setFilter(filter);
    return this;
  }

  // ========== Symbol 图标属性方法 ==========

  setIconImage(value: ESObject): SymbolLayer {
    this.nativeInstance.setIconImage(value);
    return this;
  }

  setIconSize(value: ESObject): SymbolLayer {
    this.nativeInstance.setIconSize(value);
    return this;
  }

  setIconRotate(value: ESObject): SymbolLayer {
    this.nativeInstance.setIconRotate(value);
    return this;
  }

  setIconAnchor(value: ESObject): SymbolLayer {
    this.nativeInstance.setIconAnchor(value);
    return this;
  }

  setIconAllowOverlap(value: ESObject): SymbolLayer {
    this.nativeInstance.setIconAllowOverlap(value);
    return this;
  }

  setIconOpacity(value: ESObject): SymbolLayer {
    this.nativeInstance.setIconOpacity(value);
    return this;
  }
}
