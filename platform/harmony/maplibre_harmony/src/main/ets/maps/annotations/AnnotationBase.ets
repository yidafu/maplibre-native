/**
 * AnnotationBase - shared wrapper base for Marker / Polyline / Polygon.
 *
 * Hosts the wrapped native instance and the dual-mode construction tag used
 * by fromNative(); id semantics differ per annotation (Marker keeps its id in
 * a JS-side field, Polyline/Polygon delegate to the native object), so those
 * stay in the subclasses.
 */

/**
 * Construction tag for the dual-mode constructor pattern: fromNative() passes
 * AnnotationInternalTag.INSTANCE plus the wrapped native object, while user
 * code passes an options object.
 */
export class AnnotationInternalTag {
  static readonly INSTANCE = new AnnotationInternalTag();
  private constructor() {
  }
}

export abstract class AnnotationBase<TN> {
  protected nativeInstance: TN;

  protected constructor(nativeInstance: TN) {
    this.nativeInstance = nativeInstance;
  }

  /**
   * Retrieve the native annotation (internal use).
   */
  getNative(): TN {
    return this.nativeInstance;
  }
}
