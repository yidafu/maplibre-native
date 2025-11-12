import maplibre from 'libmaplibre.so';
import type { LightSpecification, TransitionOptions } from 'libmaplibre.so';

interface LightPositionInput {
  radial: number;
  azimuthal: number;
  polar?: number;
}

interface LightPositionState {
  radial: number;
  azimuthal: number;
  polar: number;
}

interface NativeLightPosition {
  radial: number;
  azimuthal: number;
  polar: number;
}

class InternalMarker {
  static readonly INSTANCE: InternalMarker = new InternalMarker();

  private constructor() {
  }
}

/**
 * Light - style lighting controller (API parity with Android/iOS).
 *
 * Obtain via `Style.getLight()` or `MapLibreMap.getLight()`.
 */
export class Light {
  static readonly _TYPE_: string = 'Light';
  private nativeInstance: maplibre.Light;

  private constructor(_: InternalMarker, nativeInstance: maplibre.Light) {
    this.nativeInstance = nativeInstance;
  }

  static fromNative(nativeInstance: maplibre.Light): Light {
    return new Light(InternalMarker.INSTANCE, nativeInstance);
  }

  getNative(): maplibre.Light {
    return this.nativeInstance;
  }

  getAnchor(): 'map' | 'viewport' {
    return this.nativeInstance.getAnchor() as 'map' | 'viewport';
  }

  setAnchor(anchor: 'map' | 'viewport'): Light {
    this.nativeInstance.setAnchor(anchor);
    return this;
  }

  private normalizePosition(position: LightPositionInput | number[]): LightPositionState {
    let normalized: LightPositionState = { radial: 0, azimuthal: 0, polar: 0 };

    if (position instanceof Array) {
      const length: number = position.length;
      normalized.radial = length >= 1 ? (position[0] as number) : 0;
      normalized.azimuthal = length >= 2 ? (position[1] as number) : 0;
      normalized.polar = length >= 3 ? (position[2] as number) : 0;
      return normalized;
    }

    const input: LightPositionInput = position as LightPositionInput;
    normalized.radial = input.radial;
    normalized.azimuthal = input.azimuthal;
    normalized.polar = input.polar === undefined ? 0 : input.polar;
    return normalized;
  }

  getPosition(): LightPositionState {
    const raw = this.nativeInstance.getPosition() as NativeLightPosition;
    const result: LightPositionState = { radial: raw.radial, azimuthal: raw.azimuthal, polar: raw.polar };
    return result;
  }

  setPosition(position: LightPositionInput | number[]): Light {
    const normalized = this.normalizePosition(position);
    this.nativeInstance.setPosition(normalized);
    return this;
  }

  getPositionTransition(): TransitionOptions {
    return this.nativeInstance.getPositionTransition() as TransitionOptions;
  }

  setPositionTransition(duration: number, delay: number = 0): Light {
    this.nativeInstance.setPositionTransition(duration, delay);
    return this;
  }

  getColor(): string {
    return this.nativeInstance.getColor() as string;
  }

  setColor(color: string): Light {
    this.nativeInstance.setColor(color);
    return this;
  }

  getColorTransition(): TransitionOptions {
    return this.nativeInstance.getColorTransition() as TransitionOptions;
  }

  setColorTransition(duration: number, delay: number = 0): Light {
    this.nativeInstance.setColorTransition(duration, delay);
    return this;
  }

  getIntensity(): number {
    return this.nativeInstance.getIntensity() as number;
  }

  setIntensity(intensity: number): Light {
    this.nativeInstance.setIntensity(intensity);
    return this;
  }

  getIntensityTransition(): TransitionOptions {
    return this.nativeInstance.getIntensityTransition() as TransitionOptions;
  }

  setIntensityTransition(duration: number, delay: number = 0): Light {
    this.nativeInstance.setIntensityTransition(duration, delay);
    return this;
  }

  toSpecification(): LightSpecification {
    const position = this.getPosition();
    return {
      anchor: this.getAnchor(),
      position: [position.radial, position.azimuthal, position.polar],
      color: this.getColor(),
      intensity: this.getIntensity()
    };
  }
}

/**
 * LightOptions - legacy alias for backward compatibility.
 *
 * @deprecated Use `Light` or `LightSpecification` instead.
 */
export type LightOptions = LightSpecification;
