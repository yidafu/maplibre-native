/**
 * Widget 布局类型定义
 * 
 * 使用鸿蒙 ArkUI 原生的布局系统
 */

import { Margins } from '../types/NativeTypes';

/**
 * 2D 偏移量
 */
export interface Offset2D {
  x: number;
  y: number;
}

/**
 * Widget 位置配置
 * 
 * 使用 ArkUI Alignment + Margins 的鸿蒙风格布局
 */
export interface WidgetPosition {
  /** ArkUI 对齐方式 */
  alignment: Alignment;
  /** 四边边距（vp） */
  margins: Margins;
  /** 额外偏移（可选，vp） */
  offset?: Offset2D;
}

/**
 * Widget 布局辅助类
 * 
 * 提供便捷方法来创建和计算组件位置
 */
export class WidgetLayoutHelper {
  /**
   * 从 Alignment 和 Margins 创建完整的位置配置
   */
  static createPosition(
    alignment: Alignment,
    margins: Margins = { left: 0, top: 0, right: 0, bottom: 0 },
    offset?: Offset2D
  ): WidgetPosition {
    return { alignment, margins, offset };
  }
  
  /**
   * 计算实际的偏移量（Alignment + Margins）
   * 
   * 根据 Alignment 自动从 Margins 中选择合适的边距
   */
  static calculateOffset(position: WidgetPosition): Offset2D {
    const alignment = position.alignment;
    const margins = position.margins;
    const offset = position.offset;
    let x = offset?.x || 0;
    let y = offset?.y || 0;
    
    // 根据对齐方式添加边距
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
   * 预设位置：左上角
   */
  static topLeft(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.TopStart,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 预设位置：顶部居中
   */
  static topCenter(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.Top,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 预设位置：右上角
   */
  static topRight(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.TopEnd,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 预设位置：左侧居中
   */
  static centerLeft(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.Start,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 预设位置：完全居中
   */
  static center(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.Center,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 预设位置：右侧居中
   */
  static centerRight(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.End,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 预设位置：左下角
   */
  static bottomLeft(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.BottomStart,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 预设位置：底部居中
   */
  static bottomCenter(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.Bottom,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 预设位置：右下角
   */
  static bottomRight(margins?: Margins): WidgetPosition {
    return WidgetLayoutHelper.createPosition(
      Alignment.BottomEnd,
      margins || { left: 10, top: 10, right: 10, bottom: 10 }
    );
  }
  
  /**
   * 向后兼容：从 OrnamentPosition 转换
   * 
   * @param position OrnamentPosition 枚举值（0-3）
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
   * 向后兼容：将 Alignment 转换回 OrnamentPosition
   * 
   * @param alignment Alignment 枚举
   * @returns OrnamentPosition（0-3），如果无法映射则返回 null
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
        return null; // 不是四个角之一
    }
  }
}

