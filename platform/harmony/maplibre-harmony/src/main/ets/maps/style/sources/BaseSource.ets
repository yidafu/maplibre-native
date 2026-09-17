/**
 * BaseSource - shared wrapper base for the ETS source classes.
 *
 * Hosts the wrapped native instance plus the dual-mode construction tag and
 * the getNative/getId surface that every NAPI source object exposes.
 * Subclasses keep their _TYPE_ token, constructor specifics and
 * source-specific accessors.
 */

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

  protected constructor(nativeInstance: T) {
    this.nativeInstance = nativeInstance;
  }

  getNative(): T {
    return this.nativeInstance;
  }

  getId(): string {
    return (this.nativeInstance as Object as NativeSourceCore).getId();
  }
}
