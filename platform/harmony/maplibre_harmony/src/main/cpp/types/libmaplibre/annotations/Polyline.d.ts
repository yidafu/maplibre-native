import type { LatLng } from '../NativeMapView';

/**
 * 折线选项接口
 */
export interface PolylineOptions {
    /** 折线的点坐标数组 */
    points: LatLng[];
    /** 线条颜色（可选，默认 #000000） */
    color?: string;
    /** 线条宽度（可选，默认 10） */
    width?: number;
    /** 线条透明度（可选，默认 1.0，范围 0-1） */
    alpha?: number;
    /** 是否可见（可选，默认 true） */
    visible?: boolean;
    /** Z 轴顺序（可选，默认 0） */
    zIndex?: number;
    /** 线条样式/虚线模式（可选，如 [5, 5] 表示 5px 实线 5px 空白） */
    pattern?: number[] | null;
    /** 连接类型（可选，默认 'round'，可选值：'round' | 'bevel' | 'miter'） */
    jointType?: string;
    /** 端点类型（可选，默认 'round'，可选值：'round' | 'butt' | 'square'） */
    capType?: string;
}

/**
 * Polyline - 折线标注类（NAPI 对象）
 * 
 * 用于在地图上显示折线标注，支持颜色、宽度、样式等
 */
export class Polyline {
    /**
     * 构造函数
     * @param options 折线选项
     */
    constructor(options: PolylineOptions);
    
    /**
     * 获取折线的点坐标
     * @returns 点坐标数组
     */
    getPoints(): LatLng[];
    
    /**
     * 设置折线的点坐标
     * @param points 点坐标数组
     */
    setPoints(points: LatLng[]): void;
    
    /**
     * 添加一个点到折线末尾
     * @param point 点坐标
     */
    addPoint(point: LatLng): void;
    
    /**
     * 在指定位置插入一个点
     * @param index 插入位置索引
     * @param point 点坐标
     */
    insertPoint(index: number, point: LatLng): void;
    
    /**
     * 移除指定索引的点
     * @param index 点索引
     * @returns 被移除的点坐标，如果索引无效则返回 null
     */
    removePoint(index: number): LatLng | null;
    
    /**
     * 获取线条颜色
     * @returns 颜色字符串
     */
    getColor(): string;
    
    /**
     * 设置线条颜色
     * @param color 颜色字符串（如 '#FF0000' 或 'red'）
     */
    setColor(color: string): void;
    
    /**
     * 获取线条宽度
     * @returns 宽度值（像素）
     */
    getWidth(): number;
    
    /**
     * 设置线条宽度
     * @param width 宽度值（像素）
     */
    setWidth(width: number): void;
    
    /**
     * 获取线条透明度
     * @returns 透明度值（0-1）
     */
    getAlpha(): number;
    
    /**
     * 设置线条透明度
     * @param alpha 透明度值（0-1，0 为完全透明，1 为完全不透明）
     */
    setAlpha(alpha: number): void;
    
    /**
     * 获取可见性
     * @returns 是否可见
     */
    getVisible(): boolean;
    
    /**
     * 设置可见性
     * @param visible 是否可见
     */
    setVisible(visible: boolean): void;
    
    /**
     * 获取 Z-index（Z 轴顺序）
     * @returns Z-index 值
     */
    getZIndex(): number;
    
    /**
     * 设置 Z-index（Z 轴顺序）
     * @param zIndex Z-index 值（数值越大，显示层级越高）
     */
    setZIndex(zIndex: number): void;
    
    /**
     * 获取线条样式/虚线模式
     * @returns 样式数组或 null（如 [5, 5] 表示 5px 实线 5px 空白）
     */
    getPattern(): number[] | null;
    
    /**
     * 设置线条样式/虚线模式
     * @param pattern 样式数组或 null（如 [5, 5] 表示 5px 实线 5px 空白）
     */
    setPattern(pattern: number[] | null): void;
    
    /**
     * 获取线条连接类型
     * @returns 连接类型（'round' | 'bevel' | 'miter'）
     */
    getJointType(): string;
    
    /**
     * 设置线条连接类型
     * @param jointType 连接类型（'round' | 'bevel' | 'miter'）
     */
    setJointType(jointType: string): void;
    
    /**
     * 获取线条端点类型
     * @returns 端点类型（'round' | 'butt' | 'square'）
     */
    getCapType(): string;
    
    /**
     * 设置线条端点类型
     * @param capType 端点类型（'round' | 'butt' | 'square'）
     */
    setCapType(capType: string): void;
    
    /**
     * 获取折线 ID
     * @returns ID 数值
     */
    getId(): number;
    
    /**
     * 设置折线 ID（内部使用）
     * @internal
     * @param id ID 数值
     */
    setId(id: number): void;
    
    // 注意：setMapLibreMap 是内部实现细节，不在公开 API 中暴露
    // ETS 层的 Polyline 封装类会处理 MapLibreMap 的关联
}

