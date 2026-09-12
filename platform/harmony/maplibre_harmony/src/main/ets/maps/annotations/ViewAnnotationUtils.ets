/**
 * ViewAnnotation Utilities
 *
 * Common utility functions for ViewAnnotation and AnnotationView rendering.
 * Provides consistent value transformation, validation, and coordinate handling.
 */

// ============================================================================
// Shared option types
// ============================================================================

/**
 * Center offset
 *
 * Adjusts a floating view's center relative to its anchor point.
 * Positive values shift right/down; negative values shift left/up.
 */
export interface CenterOffset {
  dx: number; // Horizontal offset in logical pixels
  dy: number; // Vertical offset in logical pixels
}

// ============================================================================
// Constants
// ============================================================================

/**
 * Epsilon values for floating-point comparisons
 */
export const POSITION_EPSILON = 0.1;
export const SIZE_EPSILON = 0.1;
export const SCALE_EPSILON = 0.01;
export const ROTATION_EPSILON = 0.01;
export const OPACITY_EPSILON = 0.01;

/**
 * Pixel ratio bounds for validation
 */
export const MAX_RATIO_MULTIPLIER = 4;
export const MIN_RATIO_MULTIPLIER = 0.25;

// ============================================================================
// Length Conversion
// ============================================================================

/**
 * Convert a numeric value to ArkUI Length string (vp units)
 *
 * @param value - Numeric value to convert
 * @returns Length string in vp units, or 0 for invalid values
 */
export function toLength(value: number): Length {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return `${value}vp`;
}

// ============================================================================
// Opacity Utilities
// ============================================================================

/**
 * Clamp opacity value to valid range [0, 1]
 *
 * @param value - Opacity value to clamp
 * @returns Clamped value in range [0, 1], or 1 for invalid values
 */
export function clampOpacity(value: number): number {
  if (!Number.isFinite(value)) {
    return 1;
  }
  if (value <= 0) {
    return 0;
  }
  if (value >= 1) {
    return 1;
  }
  return value;
}

/**
 * Normalize opacity value (alias for clampOpacity for compatibility)
 *
 * @param value - Opacity value to normalize
 * @returns Normalized value in range [0, 1]
 */
export function normalizeOpacity(value: number): number {
  return clampOpacity(value);
}

// ============================================================================
// Transform Utilities
// ============================================================================

/**
 * Sanitize scale value for rendering
 *
 * @param value - Scale value to sanitize
 * @returns Sanitized scale (>= 0), or 1 for invalid values
 */
export function sanitizeScale(value: number): number {
  if (!Number.isFinite(value) || value <= 0) {
    return 1;
  }
  return value;
}

/**
 * Sanitize rotation angle for rendering
 *
 * @param value - Rotation angle to sanitize
 * @returns Sanitized rotation (finite), or 0 for invalid values
 */
export function sanitizeRotation(value: number): number {
  if (!Number.isFinite(value)) {
    return 0;
  }
  return value;
}

// ============================================================================
// Floating-Point Comparison
// ============================================================================

/**
 * Check if two numbers are close enough (within epsilon)
 *
 * @param first - First number
 * @param second - Second number
 * @param epsilon - Maximum allowed difference
 * @returns true if numbers are within epsilon, false otherwise
 */
export function numbersClose(first: number, second: number, epsilon: number): boolean {
  if (!Number.isFinite(first) || !Number.isFinite(second)) {
    return first === second;
  }
  return Math.abs(first - second) <= epsilon;
}

/**
 * Check if two floating-point values are approximately equal
 * Uses standard epsilon values based on context
 *
 * @param first - First value
 * @param second - Second value
 * @param epsilonType - Type of epsilon to use
 * @returns true if values are approximately equal
 */

export function areValuesClose(
  first: number,
  second: number,
  epsilonType: 'position' | 'size' | 'scale' | 'rotation' | 'opacity' = 'position'
): boolean {
  const epsilonMap: Record<string, number> = {
    "position": POSITION_EPSILON,
    "size": SIZE_EPSILON,
    "scale": SCALE_EPSILON,
    "rotation": ROTATION_EPSILON,
    "opacity": OPACITY_EPSILON
  };
  return numbersClose(first, second, epsilonMap[epsilonType]);
}

// ============================================================================
// Pixel Ratio Handling
// ============================================================================

/**
 * Resolve and validate frame pixel ratio
 *
 * @param frameRatio - Pixel ratio from frame data
 * @param fallback - Fallback pixel ratio to use if invalid
 * @param frameId - Frame identifier for logging
 * @returns Valid pixel ratio
 */
export function resolveFramePixelRatio(frameRatio: number, fallback: number, frameId: number): number {
  const safeFallback = fallback > 0 ? fallback : 1;
  if (!Number.isFinite(frameRatio) || frameRatio <= 0) {
    return safeFallback;
  }

  // Warn if pixel ratio is significantly different from expected
  if (frameRatio > safeFallback * MAX_RATIO_MULTIPLIER || frameRatio < safeFallback * MIN_RATIO_MULTIPLIER) {
    console.warn(
      `[ViewAnnotationUtils] frame ${frameId} pixelRatio ${frameRatio.toFixed(2)} out of expected range, fallback=${safeFallback.toFixed(2)}`
    );
    return safeFallback;
  }
  return frameRatio;
}

// ============================================================================
// Coordinate Conversion
// ============================================================================

/**
 * Convert screen pixel coordinates to logical coordinates
 *
 * @param pixelValue - Value in screen pixels
 * @param pixelRatio - Screen pixel ratio
 * @returns Logical coordinate value
 */
export function pixelsToLogical(pixelValue: number, pixelRatio: number): number {
  if (pixelRatio <= 0 || !Number.isFinite(pixelRatio)) {
    return pixelValue;
  }
  return pixelValue / pixelRatio;
}

/**
 * Convert logical coordinates to screen pixel coordinates
 *
 * @param logicalValue - Logical coordinate value
 * @param pixelRatio - Screen pixel ratio
 * @returns Value in screen pixels
 */
export function logicalToPixels(logicalValue: number, pixelRatio: number): number {
  if (pixelRatio <= 0 || !Number.isFinite(pixelRatio)) {
    return logicalValue;
  }
  return logicalValue * pixelRatio;
}

// ============================================================================
// Value Validation
// ============================================================================

/**
 * Check if a numeric value is valid for rendering
 *
 * @param value - Value to validate
 * @returns true if value is valid (finite and non-negative for sizes)
 */
export function isValidRenderValue(value: number, requireNonNegative: boolean = true): boolean {
  if (!Number.isFinite(value)) {
    return false;
  }
  if (requireNonNegative && value < 0) {
    return false;
  }
  return true;
}

/**
 * Clamp a numeric value to a valid range
 *
 * @param value - Value to clamp
 * @param min - Minimum allowed value
 * @param max - Maximum allowed value
 * @returns Clamped value
 */
export function clampValue(value: number, min: number, max: number): number {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
