import maplibre from 'libmaplibre.so';
import { LatLng } from '../geometry/LatLng';
// import { ComponentContent } from '@kit.ArkUI';

import { Marker } from './Marker';

// Constants (aligned with iOS/mbgl)
const PITCH_MAX_DEGREES = 60; // mbgl::util::PITCH_MAX is approximately 60 degrees
const DEFAULT_VIEW_SIZE = 40;

/**
 * Drag state enumeration
 *
 * Mirrors iOS `MLNAnnotationViewDragState`
 */
export enum DragState {
  None = 0, // Not dragging
  Starting = 1, // Dragging started
  Dragging = 2, // Drag in progress
  Canceling = 3, // Drag canceled
  Ending = 4 // Drag finished
}

/**
 * Center offset
 *
 * Adjusts the view's center relative to the marker position.
 * Positive values shift right/down; negative values shift left/up.
 */
export interface CenterOffset {
  dx: number; // Horizontal offset in points
  dy: number; // Vertical offset in points
}

/**
 * ViewPosition - Screen-space view position
 */
interface ViewPosition {
  x: number;
  y: number;
}

/**
 * AnnotationView state container
 */
export class AnnotationViewState {
  selected: boolean = false;
  enabled: boolean = true;
  draggable: boolean = false;
  dragState: DragState = DragState.None;
  scalesWithViewingDistance: boolean = false;
  rotatesToMatchCamera: boolean = false;
}

/**
 * AnnotationView protocol
 *
 * Mirrors iOS `MLNAnnotationView`
 */
export interface AnnotationViewProtocol {
  reuseIdentifier: string | null;

  prepareForReuse(): void;

  setSelected(selected: boolean, animated: boolean): void;

  setDragState(state: DragState, animated: boolean): void;
}

/**
 * AnnotationView - Custom marker view component
 *
 * Enables ArkTS components to render marker visuals, offering rich customization and interaction.
 *
 * **Key features**:
 * - Custom content via `@BuilderParam`
 * - Selection management (tap to toggle)
 * - Drag support (long-press to start)
 * - View reuse (`reuseIdentifier`)
 * - Distance-based scaling (`scalesWithViewingDistance`)
 * - Camera-aligned rotation (`rotatesToMatchCamera`)
 * - Smooth animations
 *
 * **Reference implementations**:
 * - iOS: `MLNAnnotationView` (UIView subclass with full view hierarchy)
 * - Android: Custom layout XML or View
 *
 * **Lifecycle**:
 * 1. Creation - obtained from delegate or reuse pool
 * 2. `aboutToAppear` - initialize position and transforms
 * 3. Update - respond to camera changes
 * 4. `prepareForReuse` - reset mutable state for reuse
 * 5. Destroy - remove from map
 *
 * **Usage example**:
 * ```typescript
 * // Basic usage - default icon
 * AnnotationView({
 *   marker: myMarker,
 *   reuseIdentifier: "default-pin",
 *   screenX: 100,
 *   screenY: 200
 * })
 * 
* // Advanced usage – custom content
 * AnnotationView({
 *   marker: myMarker,
 *   reuseIdentifier: "custom-pin",
 *   customContentBuilder: () => {
 *     Column() {
 *       Image($r('app.media.custom_marker'))
 *         .width(40)
 *         .height(40)
 *       Text(this.marker.getTitle())
 *         .fontSize(12)
 *         .fontColor(Color.White)
 *         .backgroundColor(Color.Red)
 *         .padding(4)
 *         .borderRadius(4)
 *     }
 *   },
 *   screenX: 100,
 *   screenY: 200,
 *   scalesWithViewingDistance: true,
 *   rotatesToMatchCamera: true
 * })
 * ```
 * 
 * **Performance tips**:
 * - Use `reuseIdentifier` to enable view reuse
 * - Avoid heavy work in `customContentBuilder`
 * - Use `scalesWithViewingDistance` carefully when many views exist
 * - Tune `zIndex` to minimize overdraw
 * 
 * @see {@link AnnotationViewDelegate} Delegate definition
 * @see {@link AnnotationViewConfig} Configuration options
 * @see {@link AnnotationViewManager} Manager implementation
 */
@Component
export struct AnnotationView {
  @Prop marker: Marker;
  @Prop reuseIdentifier: string | null = null;
  @State private viewState: AnnotationViewState = new AnnotationViewState();
  @State private viewOpacity: number = 1; // Renamed to avoid conflicts
  @State private viewScale: number = 1; // Renamed to avoid conflicts
  @State private rotation: number = 0;
  // Screen-space position
  @Prop screenX: number = 0;
  @Prop screenY: number = 0;
  @Prop centerOffset: CenterOffset = { dx: 0, dy: 0 };
  // Anchor (default bottom-center)
  @Prop anchorU: number = 0.5;
  @Prop anchorV: number = 1.0;
  // Configuration flags
  @Prop isDraggable: boolean = false;
  @Prop scalesWithViewingDistance: boolean = false;
  @Prop rotatesToMatchCamera: boolean = false;
  @Prop isEnabled: boolean = true;
  @Prop selected: boolean = false;
  @Prop viewAlpha: number = 1;
  @Prop baseZIndex: number = -1;
  @Prop preferredWidth: number | null = null;
  @Prop preferredHeight: number | null = null;
  // Visibility
  @Prop visible: boolean = true;
  @Prop nativeScale: number = 1;
  @Prop nativeRotation: number = 0;
  @Prop nativeOpacity: number = 1;
  @Prop reuseVersion: number = 0;
  // Custom content builder
  @BuilderParam customContentBuilder?: () => void;
  // View dimensions (for layout calculations)
  private viewWidth: number = DEFAULT_VIEW_SIZE;
  private viewHeight: number = DEFAULT_VIEW_SIZE;
  // Transform tracking (for incremental updates)
  private lastAppliedScale: number = 1;
  private lastAppliedRotation: number = 0;
  // Drag state
  private dragStartX: number = 0;
  private dragStartY: number = 0;
  private currentDragX: number = 0;
  private currentDragY: number = 0;
  // Map-related data (advanced features)
  @Prop mapBearing: number = 0;
  @Prop mapPitch: number = 0;
  @Prop screenHeight: number = 800;
  // Computed position/transform (consumed by build)
  @State private computedPosX: number = 0;
  @State private computedPosY: number = 0;
  @State private computedScale: number = 1;
  @State private computedRotation: number = 0;
  // Callbacks (names adjusted to avoid CustomComponent collisions)
  onSelect?: (marker: Marker) => void;
  onDeselect?: (marker: Marker) => void;
  onMarkerDragStart?: (marker: Marker) => void; // Renamed to avoid conflicts
  onDrag?: (marker: Marker, screenX: number, screenY: number) => void;
  onMarkerDragEnd?: (marker: Marker, screenX: number, screenY: number) => void; // Renamed to avoid conflicts
  // Cached external configuration
  private viewAlphaInternal: number = 1;
  private baseZIndexInternal: number = 1;
  private lastSelectedProp: boolean = false;
  private lastReuseVersion: number = -1;

  /**
   * Prepare for reuse (reset state)
   *
   * Mirrors iOS `MLNAnnotationView.prepareForReuse`.
   * Called when the view is dequeued to reset mutable state.
   */
  public prepareForReuse(): void {
    this.viewState.selected = false;
    this.viewState.dragState = DragState.None;
    this.viewOpacity = 1;
    this.viewScale = 1;
    this.rotation = 0;
    this.lastAppliedScale = 1;
    this.lastAppliedRotation = 0;
    this.viewAlphaInternal = 1;
    this.baseZIndexInternal = 1;
    this.lastSelectedProp = false;
    this.updateComputedProperties();
  }

  /**
   * Toggle selection state
   */
  public setSelected(selected: boolean, animated: boolean): void {
    if (this.viewState.selected === selected) {
      return;
    }

    this.viewState.selected = selected;

    // Animation attributes automatically apply to state changes
    this.viewScale = selected ? 1.2 : 1.0;
    this.viewOpacity = selected ? 1.0 : 0.8;

    this.updateComputedProperties();

    // Fire selection callbacks
    if (selected && this.onSelect) {
      this.onSelect(this.marker);
    } else if (!selected && this.onDeselect) {
      this.onDeselect(this.marker);
    }
  }

  /**
   * Update drag state
   *
   * Follows iOS `MLNAnnotationView.setDragState:animated:`.
   * Applies distinct animations for each drag state.
   */
  public setDragState(state: DragState, animated: boolean): void {
    const prevState = this.viewState.dragState;
    this.viewState.dragState = state;

    // Inspired by the animation logic of iOS MBXAnnotationView
    switch (state) {
      case DragState.None:
        this.viewScale = 1.0;
        this.viewOpacity = 1.0;
        break;

      case DragState.Starting:
        // Bounce up quickly when dragging starts
        this.viewScale = 1.5;
        this.viewOpacity = 0.95;
        break;

      case DragState.Dragging:
        // Maintain a larger scale while dragging
        this.viewScale = 1.3;
        this.viewOpacity = 0.9;
        break;

      case DragState.Canceling:
        // Snap back quickly when canceled
        this.viewScale = 1.0;
        this.viewOpacity = 1.0;
        break;

      case DragState.Ending:
        // Ease back after drag ends
        this.viewScale = 1.0;
        this.viewOpacity = 1.0;
        break;
    }

    this.updateComputedProperties();
  }

  /**
   * Calculate position taking anchor and center offset into account
   */
  private calculatePosition(): ViewPosition {
    // While dragging use drag position
    if (this.viewState.dragState === DragState.Dragging) {
      const pos: ViewPosition = {
        x: this.currentDragX - (this.viewWidth * this.anchorU) + this.centerOffset.dx,
        y: this.currentDragY - (this.viewHeight * this.anchorV) + this.centerOffset.dy
      };
      return pos;
    }

    // Normal path
    const pos: ViewPosition = {
      x: this.screenX - (this.viewWidth * this.anchorU) + this.centerOffset.dx,
      y: this.screenY - (this.viewHeight * this.anchorV) + this.centerOffset.dy
    };
    return pos;
  }

  /**
   * Update computed properties
   */
  private updateComputedProperties(): void {
    const pos = this.calculatePosition();
    this.computedPosX = pos.x;
    this.computedPosY = pos.y;
    this.computedScale = this.calculateScale();
    this.computedRotation = this.calculateRotation();
  }

  aboutToAppear() {
    this.handleReuseSignal();
    this.syncStateWithProps(true);
    this.updateComputedProperties();
  }

  aboutToRender() {
    this.handleReuseSignal();
    this.syncStateWithProps(false);
    this.updateComputedProperties();
  }

  private handleReuseSignal(): void {
    if (this.lastReuseVersion === -1) {
      this.lastReuseVersion = this.reuseVersion;
      return;
    }

    if (this.reuseVersion !== this.lastReuseVersion) {
      this.prepareForReuse();
      this.lastReuseVersion = this.reuseVersion;
    }
  }

  private syncStateWithProps(initial: boolean): void {
    this.viewState.enabled = this.isEnabled;
    this.viewState.draggable = this.isEnabled && this.isDraggable;

    this.viewState.scalesWithViewingDistance = this.scalesWithViewingDistance;
    this.viewState.rotatesToMatchCamera = this.rotatesToMatchCamera;

    if (this.preferredWidth !== null && this.preferredWidth > 0) {
      this.viewWidth = this.preferredWidth;
    }

    if (this.preferredHeight !== null && this.preferredHeight > 0) {
      this.viewHeight = this.preferredHeight;
    }

    this.viewAlphaInternal = this.viewAlpha >= 0 ? this.viewAlpha : 1;
    this.baseZIndexInternal = this.baseZIndex >= 0 ? this.baseZIndex : (this.marker.getZIndex() || 1);

    if (initial || this.lastSelectedProp !== this.selected) {
      this.applyExternalSelection(this.selected);
      this.lastSelectedProp = this.selected;
    }
  }

  private applyExternalSelection(selected: boolean): void {
    if (this.viewState.selected === selected) {
      return;
    }

    this.viewState.selected = selected;
    this.viewScale = selected ? 1.2 : 1.0;
    this.viewOpacity = selected ? 1.0 : 0.8;
  }

  /**
   * Calculate scale factor based on viewing distance
   *
   * Mirrors iOS `MLNAnnotationView.updateScaleTransformForViewingDistance`.
   *
   * Implementation steps:
   * 1. Compute normalized screen position (0.0 = top, 1.0 = bottom)
   * 2. Determine maximum scale reduction = 1.0 - normalized position
   * 3. Determine pitch intensity = current pitch / maximum pitch
   * 4. Final scale = 1.0 - (max reduction * pitch intensity)
   *
   * Results in smaller views near the horizon to mimic perspective.
   */
  private calculateScale(): number {
    let baseScale = this.viewScale * (this.nativeScale || 1);

    // Skip distance-based scaling when disabled or actively dragging
    if (!this.viewState.scalesWithViewingDistance ||
      this.viewState.dragState === DragState.Dragging ||
      this.screenHeight <= 0 ||
      this.mapPitch <= 0) {
    return baseScale;
    }

    // Normalized Y position of the view center (0.0 = top, 1.0 = bottom)
    const normalizedY = Math.max(0, Math.min(1, this.screenY / this.screenHeight));

    // Maximum reduction: larger near the top (horizon)
    const maxScaleReduction = 1.0 - normalizedY;

    // Pitch intensity: proportion of max pitch (clamped to avoid negatives)
    const pitch = Math.max(0, this.mapPitch);
    const pitchIntensity = Math.min(1.0, pitch / PITCH_MAX_DEGREES);

    // Compute pitch-adjusted scale
    // Range: 1.0 (no pitch) -> 0.0 (max pitch at horizon)
    const pitchAdjustedScale = 1.0 - (maxScaleReduction * pitchIntensity);

    // Avoid shrinking below a reasonable size
    const distanceScale = Math.max(0.3, pitchAdjustedScale);

    return baseScale * distanceScale;
  }

  /**
   * Calculate rotation angle
   *
   * Mirrors iOS `MLNAnnotationView.updateRotateTransform`
   */
  private calculateRotation(): number {
    let rotation = this.marker.getRotation() + (this.nativeRotation || 0);

    // Apply map bearing when rotation is tied to the camera
    if (this.viewState.rotatesToMatchCamera) {
      // Map bearing is clockwise; invert to match iOS behavior
      rotation -= this.mapBearing;
    }

    return rotation;
  }

  /**
   * Create gesture handlers
   *
   * Combines tap, long-press, and drag gestures.
   * Inspired by the gesture configuration of iOS `MLNAnnotationView`.
   */
  private createGestures(): GestureType {
    if (!this.viewState.enabled) {
      return TapGesture({ count: 1 })
        .onAction(() => {
          // Ignore interactions while disabled
        });
    }

    // Primary tap gesture
    const tapGesture = TapGesture({ count: 1 })
      .onAction(() => {
        if (!this.viewState.selected) {
          this.setSelected(true, true);
        }
      });

    // If draggable, compose additional gestures
    if (this.viewState.draggable) {
      // Pan gesture for dragging
      const panGesture = PanGesture({ fingers: 1, distance: 5 })
        .onActionStart((event: GestureEvent) => {
          // When pan begins, ensure we are in dragging state
          if (this.viewState.dragState === DragState.Starting ||
            this.viewState.dragState === DragState.Dragging) {
            this.setDragState(DragState.Dragging, false);
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (this.viewState.dragState === DragState.Dragging) {
            this.updateDrag(event);
            this.updateComputedProperties();
          }
        })
        .onActionEnd((event: GestureEvent) => {
          if (this.viewState.dragState === DragState.Dragging) {
            this.endDrag(event);
          }
        })
        .onActionCancel(() => {
          if (this.viewState.dragState !== DragState.None) {
            this.cancelDrag();
          }
        });

      // Long-press to initiate drag
      const longPressGesture = LongPressGesture({ fingers: 1, repeat: false, duration: 500 })
        .onAction((event: GestureEvent) => {
          this.startDrag(event);
        })
        .onActionEnd(() => {
          // Treat as tap if long-press ends without entering drag
          if (this.viewState.dragState === DragState.Starting) {
            this.cancelDrag();
            this.setSelected(!this.viewState.selected, true);
          }
        });

      // Combine gestures: long-press + drag sequence plus tap
      return GestureGroup(GestureMode.Parallel,
        // Drag sequence: long-press then pan
        GestureGroup(GestureMode.Sequence, longPressGesture, panGesture),
        // Standard tap
        tapGesture
      );
    }

    return tapGesture;
  }

  /**
   * Begin drag sequence
   */
  private startDrag(event: GestureEvent): void {
    if (!this.viewState.draggable) {
      return;
    }

    this.setDragState(DragState.Starting, true);
    this.dragStartX = this.screenX;
    this.dragStartY = this.screenY;
    this.currentDragX = this.screenX;
    this.currentDragY = this.screenY;

    if (this.onMarkerDragStart) {
      this.onMarkerDragStart(this.marker);
    }

    // Transition into dragging after a short delay
    setTimeout(() => {
      if (this.viewState.dragState === DragState.Starting) {
        this.setDragState(DragState.Dragging, false);
      }
    }, 100);
  }

  /**
   * Update ongoing drag
   */
  private updateDrag(event: GestureEvent): void {
    if (this.viewState.dragState !== DragState.Dragging) {
      return;
    }

    // Update drag coordinates
    this.currentDragX = this.dragStartX + event.offsetX;
    this.currentDragY = this.dragStartY + event.offsetY;

    if (this.onDrag) {
      this.onDrag(this.marker, this.currentDragX, this.currentDragY);
    }
  }

  /**
   * Complete the drag
   */
  private endDrag(event: GestureEvent): void {
    if (this.viewState.dragState !== DragState.Dragging) {
      return;
    }

    this.setDragState(DragState.Ending, true);

    if (this.onMarkerDragEnd) {
      this.onMarkerDragEnd(this.marker, this.currentDragX, this.currentDragY);
    }

    // Restore idle state after completion
    setTimeout(() => {
      this.setDragState(DragState.None, false);
    }, 150);
  }

  /**
   * Cancel the drag
   */
  private cancelDrag(): void {
    this.setDragState(DragState.Canceling, true);
    this.currentDragX = this.screenX;
    this.currentDragY = this.screenY;

    setTimeout(() => {
      this.setDragState(DragState.None, false);
    }, 150);
  }

  /**
   * Determine the animation curve
   *
   * Returns different curves per state. Harmony SDK currently only exposes basic curves;
   * ideally SpringMotion/Spring would be used, but they are unavailable.
   */
  private getAnimationCurve(): Curve {
    switch (this.viewState.dragState) {
      case DragState.Starting:
        // Drag starting: accelerate quickly
        return Curve.FastOutSlowIn;
      case DragState.Ending:
        // Drag ending: ease out slowly
        return Curve.FastOutSlowIn;
      case DragState.Canceling:
        // Drag cancel: snap back quickly
        return Curve.FastOutSlowIn;
      default:
      // Default: smooth transition
        return Curve.EaseOut;
    }
  }

  /**
   * Determine animation duration
   */
  private getAnimationDuration(): number {
    switch (this.viewState.dragState) {
      case DragState.Starting:
      case DragState.Ending:
        return 400; // Matches iOS ~0.4s
      case DragState.Canceling:
        return 200;
      default:
        return 250;
    }
  }

  /**
   * Build the view
   *
   * Rendering flow:
   * 1. Render custom content when `customContentBuilder` is provided
   * 2. Otherwise render the marker's default icon
   * 3. Apply transforms (position, scale, rotation, opacity)
   * 4. Attach gestures, animations, and z-index adjustments
   */
  build() {
    Stack() {
      // Content region
      if (this.customContentBuilder) {
        // Render custom content (analogous to iOS subview hierarchy)
        this.customContentBuilder()
      } else {
        // Render default icon (similar to Android marker icon)
        Image(this.marker.getIcon() || $r('app.media.startIcon'))
          .width(this.viewWidth || DEFAULT_VIEW_SIZE)
          .height(this.viewHeight || DEFAULT_VIEW_SIZE)
          .opacity(this.marker.getAlpha())
          .objectFit(ImageFit.Contain)
          .interpolation(ImageInterpolation.High) // High-quality sampling
      }
    }
    .width('auto')
    .height('auto')
    // Position transform
    .position({ x: this.computedPosX, y: this.computedPosY })
    // Combine opacity: marker alpha × view opacity × native opacity
    .opacity(this.viewOpacity * this.marker.getAlpha() * this.viewAlphaInternal * (this.nativeOpacity || 1))
    // Scale transform (distance scaling × state scaling)
    .scale({ 
      x: this.computedScale, 
      y: this.computedScale,
      centerX: '50%',
      centerY: '100%' // Scale from bottom-center to emulate pin effect
    })
    // Rotation transform (marker rotation + camera rotation)
    .rotate({ 
      angle: this.computedRotation,
      centerX: '50%',
      centerY: '100%' // Rotate from bottom-center
    })
    // Animation configuration
    .animation({
      duration: this.getAnimationDuration(),
      curve: this.getAnimationCurve(),
      tempo: 1.0,
      playMode: PlayMode.Normal
    })
    // Visibility
    .visibility(this.visible && this.marker.getVisible() ? Visibility.Visible : Visibility.None)
    // Gesture handling
    .gesture(this.createGestures())
    // Z-index ordering: selected > dragging > marker zIndex > default
    .zIndex(
      this.viewState.selected
        ? this.baseZIndexInternal + 1000
        : (this.viewState.dragState !== DragState.None
            ? this.baseZIndexInternal + 500
            : this.baseZIndexInternal)
    )
    // Track size changes to update layout
    .onAreaChange((oldValue: Area, newValue: Area) => {
      const newWidth = Number(newValue.width);
      const newHeight = Number(newValue.height);
      
      // Update only when size actually changes
      if (newWidth !== this.viewWidth || newHeight !== this.viewHeight) {
        this.viewWidth = newWidth;
        this.viewHeight = newHeight;
        this.updateComputedProperties();
      }
    })
    // Debug helper: assign component ID
    .id(`annotation-view-${this.marker.getId()}`)
  }
}

