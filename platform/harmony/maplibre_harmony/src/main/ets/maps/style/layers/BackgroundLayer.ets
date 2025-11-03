/**
 * BackgroundLayer - 封装类
 */
import maplibre from 'libmaplibre.so';
import type { PropertyValue } from '../expressions/index';
import { convertValue } from './LayerUtils';

class InternalMarker {
  static readonly INSTANCE = new InternalMarker();

  private constructor() {
  }
}

export class BackgroundLayer {
  // 类型标识，用于类型判断（因为 instanceof 在 NAPI 返回的对象上不工作）
  static readonly _TYPE_ = 'BackgroundLayer';
  private nativeInstance: maplibre.BackgroundLayer;

  constructor(idOrMarker: string | InternalMarker, nativeOrNothing?: maplibre.BackgroundLayer) {
    if (idOrMarker === InternalMarker.INSTANCE && nativeOrNothing instanceof Object) {
      this.nativeInstance = nativeOrNothing;
    } else if (typeof idOrMarker === 'string') {
      this.nativeInstance = new maplibre.BackgroundLayer(idOrMarker);
    } else {
      throw new Error('Invalid BackgroundLayer constructor arguments');
    }
  }

  static create(id: string): BackgroundLayer {
    return new BackgroundLayer(id);
  }

  static fromNative(nativeInstance: maplibre.BackgroundLayer): BackgroundLayer {
    return new BackgroundLayer(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.BackgroundLayer {
    return this.nativeInstance;
  }

  getId(): string {
    return this.nativeInstance.getId();
  }

  setVisibility(visibility: 'visible' | 'none'): BackgroundLayer {
    this.nativeInstance.setVisibility(visibility);
    return this;
  }

  setMinZoom(zoom: number): BackgroundLayer {
    this.nativeInstance.setMinZoom(zoom);
    return this;
  }

  setMaxZoom(zoom: number): BackgroundLayer {
    this.nativeInstance.setMaxZoom(zoom);
    return this;
  }

  setBackgroundColor(color: PropertyValue<string>): BackgroundLayer {
    this.nativeInstance.setBackgroundColor(convertValue(color));
    return this;
  }

  setBackgroundOpacity(opacity: PropertyValue<number>): BackgroundLayer {
    this.nativeInstance.setBackgroundOpacity(convertValue(opacity));
    return this;
  }

  setBackgroundPattern(pattern: PropertyValue<string>): BackgroundLayer {
    this.nativeInstance.setBackgroundPattern(convertValue(pattern));
    return this;
  }

  // ========== Getter 方法 ==========

  getBackgroundColor(): string | undefined {
    return this.nativeInstance.getBackgroundColor();
  }

  getBackgroundOpacity(): number | undefined {
    return this.nativeInstance.getBackgroundOpacity();
  }
}
