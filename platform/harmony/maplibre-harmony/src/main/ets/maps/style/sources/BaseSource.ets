/**
 * BaseSource - shared wrapper base for the ETS source classes.
 *
 * Hosts the wrapped native instance plus the dual-mode construction tag and
 * the getNative/getId surface that every NAPI source object exposes.
 * Subclasses keep their _TYPE_ token, constructor specifics and
 * source-specific accessors.
 */

import type { JSONValue } from 'libmaplibre.so';

/**
 * Feature-state surface a source wrapper needs from its host map.
 *
 * Implemented by MapLibreMap and declared here (instead of importing
 * MapLibreMap) to avoid a circular module dependency: sources are loaded
 * before the map that hosts them.
 */
export interface SourceFeatureStateHost {
  setFeatureState(sourceId: string, sourceLayerId: string | undefined, featureId: string,
    state: Record<string, JSONValue>): boolean;
  getFeatureState(sourceId: string, sourceLayerId: string | undefined,
    featureId: string): Record<string, JSONValue> | undefined;
  removeFeatureState(sourceId: string, sourceLayerId: string | undefined, featureId?: string,
    stateKey?: string): boolean;
}

/**
 * Construction tag for the dual-mode constructor pattern: fromNative() passes
 * SourceInternalTag.INSTANCE plus the wrapped native object, while user code
 * passes a plain string id.
 */
export class SourceInternalTag {
  static readonly INSTANCE = new SourceInternalTag();
  private constructor() {
  }
}

/**
 * Shared dual-mode construction for source wrappers.
 *
 * - fromNative() path: tag instance + existing native object -> wrap it.
 * - user path: string id (+ options) -> create the native source.
 */
export function resolveSourceNative<TN extends Object>(
  idOrTag: string | SourceInternalTag,
  optionsOrNative: Object | undefined,
  create: (id: string, options: Object | undefined) => TN,
  className: string
): TN {
  if (idOrTag === SourceInternalTag.INSTANCE && optionsOrNative instanceof Object) {
    return optionsOrNative as TN;
  }
  if (typeof idOrTag === 'string') {
    return create(idOrTag, optionsOrNative);
  }
  throw new Error(`Invalid ${className} constructor arguments`);
}

/** getId() surface shared by every native NAPI source object. */
export interface NativeSourceCore {
  getId(): string;
}

export abstract class BaseSource<T> {
  protected nativeInstance: T;

  /** Host map set by MapLibreMap.addSource(); enables source-level feature state. */
  private featureStateHost?: SourceFeatureStateHost;

  protected constructor(nativeInstance: T) {
    this.nativeInstance = nativeInstance;
  }

  getNative(): T {
    return this.nativeInstance;
  }

  getId(): string {
    return (this.nativeInstance as Object as NativeSourceCore).getId();
  }

  /**
   * Bind (or unbind with undefined) the host map.
   * Called by MapLibreMap.addSource()/removeSource(); @internal
   */
  bindFeatureStateHost(host: SourceFeatureStateHost | undefined): void {
    this.featureStateHost = host;
  }

  /**
   * The host map when this source is attached to a map, undefined otherwise.
   * Source-level feature state APIs report failure (false / undefined) when
   * unbound, mirroring Android's detached-source behavior.
   */
  protected getFeatureStateHost(): SourceFeatureStateHost | undefined {
    return this.featureStateHost;
  }
}
