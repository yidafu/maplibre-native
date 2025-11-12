/**
 * Widget layout type definitions.
 *
 * Uses the native HarmonyOS ArkUI layout system.
 */

import { Margins } from '../types/NativeTypes';

/**
 * 2D offset values.
 */
export interface Offset2D {
  x: number;
  y: number;
}

/**
 * Widget position configuration.
 *
 * Harmony-style layout using ArkUI Alignment + Margins.
 */
export interface WidgetPosition {
  /** ArkUI alignment. */
  alignment: Alignment;
  /** Four-side margins (vp). */
  margins: Margins;
  /** Additional offset (optional, vp). */
  offset?: Offset2D;
}

/**
 * Widget layout helper.
 *
 * Provides convenience methods to create and compute component positions.
 */
export class WidgetLayoutHelper {
  /**
   * Create a full position configuration from Alignment and Margins.
   */
  static createPosition(
    alignment: Alignment,
    margins: Margins = { left: 0, top: 0, right: 0, bottom: 0 },
    offset?: Offset2D
  ): WidgetPosition {
    return { alignment, margins, offset };
  }
  
  /**
   * Compute the effective offset (Alignment + Margins).
   *
   * Automatically selects the appropriate margins based on Alignment.
   */
  static calculateOffset(position: WidgetPosition): Offset2D {
    const alignment = position.alignment;
    const margins = position.margins;
    const offset = position.offset;
    let x = offset?.x || 0;
    let y = offset?.y || 0;
    
    // Add margins according to the alignment.
    switch (alignment) {
      case Alignment.TopStart:
        x += margins.left;
        y += margins.top;
        break;
      case Alignment.Top:
        y += margins.top;
        x += (margins.left - margins.right) / 2;
        break;
      case Alignment.TopEnd:
        x -= margins.right;
        y += margins.top;
        break;
      case Alignment.Start:
        x += margins.left;
        y += (margins.top - margins.bottom) / 2;
        break;
      case Alignment.Center:
        x += (margins.left - margins.right) / 2;
        y += (margins.top - margins.bottom) / 2;
        break;
      case Alignment.End:
        x -= margins.right;
        y += (margins.top - margins.bottom) / 2;
        break;
      case Alignment.BottomStart:
        x += margins.left;
        y -= margins.bottom;
        break;
      case Alignment.Bottom:
        y -= margins.bottom;
        x += (margins.left - margins.right) / 2;
        break;
      case Alignment.BottomEnd:
        x -= margins.right;
        y -= margins.bottom;
        break;
    }
    
    return { x, y };
  }
  
  /**
   * Preset position: top-left.
   */
  static topLeft(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.TopStart,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Preset position: top-center.
   */
  static topCenter(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.Top,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Preset position: top-right.
   */
  static topRight(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.TopEnd,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Preset position: center-left.
   */
  static centerLeft(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.Start,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Preset position: centered.
   */
  static center(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.Center,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Preset position: center-right.
   */
  static centerRight(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.End,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Preset position: bottom-left.
   */
  static bottomLeft(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.BottomStart,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Preset position: bottom-center.
   */
  static bottomCenter(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.Bottom,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Preset position: bottom-right.
   */
  static bottomRight(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.BottomEnd,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * Backward compatibility: convert from OrnamentPosition.
   *
   * @param position OrnamentPosition enum value (0-3).
   * @returns Alignment
   */
  static ornamentPositionToAlignment(position: number): Alignment {
    switch (position) {
      case 0: // TopLeft
        return Alignment.TopStart;
      case 1: // TopRight
        return Alignment.TopEnd;
      case 2: // BottomLeft
        return Alignment.BottomStart;
      case 3: // BottomRight
        return Alignment.BottomEnd;
      default:
        return Alignment.TopEnd;
    }
  }
  
  /**
   * Backward compatibility: convert Alignment back to OrnamentPosition.
   *
   * @param alignment Alignment enum value.
   * @returns OrnamentPosition (0-3), or null if it cannot be mapped.
   */
  static alignmentToOrnamentPosition(alignment: Alignment): number | null {
    switch (alignment) {
      case Alignment.TopStart:
        return 0; // TopLeft
      case Alignment.TopEnd:
        return 1; // TopRight
      case Alignment.BottomStart:
        return 2; // BottomLeft
      case Alignment.BottomEnd:
        return 3; // BottomRight
      default:
        return null; // Not one of the four corners.
    }
  }
}

