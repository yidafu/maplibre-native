/**
 * Shared infrastructure for MapLibreMap listener registration.
 *
 * Two shapes of listener exist in the public API:
 * - Wrapper-based native events: the native layer expects concrete listener
 *   objects, so every public listener is wrapped in an error-guarded proxy
 *   before reaching NativeMapView. {@link NativeListenerBinding} records how to
 *   detach one (listener, event) pair so removal and bulk teardown can detach
 *   exactly the proxy that was registered.
 * - Plain fan-out groups dispatched by MapLibreMap itself
 *   (map click, touch, style loaded...): {@link ListenerGroup} replaces the
 *   per-event include/indexOf/splice boilerplate.
 */

/**
 * Error text used when a listener throws during event dispatch.
 */
export function listenerErrorMessage(error: Object): string {
  return error instanceof Error ? `${error.name}: ${error.message}` : `${error}`;
}

/**
 * Detach handle for one (listener, event) registration.
 */
export interface NativeListenerBinding {
  removeFromNative: () => void;
}

/**
 * Ordered fan-out group for plain listener arrays.
 */
export class ListenerGroup<L> {
  private listeners: L[] = [];

  add(listener: L): void {
    if (!this.listeners.includes(listener)) {
      this.listeners.push(listener);
    }
  }

  remove(listener: L): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  getListeners(): L[] {
    return this.listeners;
  }

  size(): number {
    return this.listeners.length;
  }

  clear(): void {
    this.listeners = [];
  }
}
