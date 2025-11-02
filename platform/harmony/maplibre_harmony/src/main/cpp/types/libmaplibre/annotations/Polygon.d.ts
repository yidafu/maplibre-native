import type { LatLng } from '../NativeMapView';

/**
 * 多边形选项接口
 */
export interface PolygonOptions {
    /** 多边形的点坐标数组 */
    points: LatLng[];
    /** 孔洞数组（可选） */
    holes?: LatLng[][];
    /** 填充颜色（可选） */
    fillColor?: string;
    /** 描边颜色（可选） */
    strokeColor?: string;
    /** 描边宽度（可选） */
    strokeWidth?: number;
    /** 填充透明度（可选，0-1） */
    fillAlpha?: number;
    /** 描边透明度（可选，0-1） */
    strokeAlpha?: number;
    /** 是否可见（可选） */
    visible?: boolean;
    /** Z 轴顺序（可选） */
    zIndex?: number;
}

/**
 * Polygon - 多边形标注类（NAPI 对象）
 * 
 * 用于在地图上显示多边形标注，支持填充、描边、孔洞等
 */
export class Polygon {
    /**
     * 构造函数
     * @param options 多边形选项
     */
    constructor(options: PolygonOptions);
    
    /**
     * 获取多边形的点坐标
     * @returns 点坐标数组
     */
    getPoints(): LatLng[];
    
    /**
     * 设置多边形的点坐标
     * @param points 点坐标数组
     */
    setPoints(points: LatLng[]): void;
    
    /**
     * 添加一个点
     * @param point 点坐标
     */
    addPoint(point: LatLng): void;
    
    /**
     * 在指定位置插入一个点
     * @param index 插入位置
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
     * 获取孔洞列表
     * @returns 孔洞数组，每个孔洞是一个点坐标数组
     */
    getHoles(): LatLng[][];
    
    /**
     * 设置孔洞列表
     * @param holes 孔洞数组
     */
    setHoles(holes: LatLng[][]): void;
    
    /**
     * 添加一个孔洞
     * @param hole 孔洞点坐标数组
     */
    addHole(hole: LatLng[]): void;
    
    /**
     * 移除指定索引的孔洞
     * @param index 孔洞索引
     * @returns 被移除的孔洞点坐标数组，如果索引无效则返回 null
     */
    removeHole(index: number): LatLng[] | null;
    
    /**
     * 获取填充颜色
     */
    getFillColor(): string;
    
    /**
     * 设置填充颜色
     * @param color 颜色字符串
     */
    setFillColor(color: string): void;
    
    /**
     * 获取描边颜色
     */
    getStrokeColor(): string;
    
    /**
     * 设置描边颜色
     * @param color 颜色字符串
     */
    setStrokeColor(color: string): void;
    
    /**
     * 获取描边宽度
     */
    getStrokeWidth(): number;
    
    /**
     * 设置描边宽度
     * @param width 宽度值
     */
    setStrokeWidth(width: number): void;
    
    /**
     * 获取填充透明度
     */
    getFillAlpha(): number;
    
    /**
     * 设置填充透明度
     * @param alpha 透明度值 (0-1)
     */
    setFillAlpha(alpha: number): void;
    
    /**
     * 获取描边透明度
     */
    getStrokeAlpha(): number;
    
    /**
     * 设置描边透明度
     * @param alpha 透明度值 (0-1)
     */
    setStrokeAlpha(alpha: number): void;
    
    /**
     * 获取可见性
     */
    getVisible(): boolean;
    
    /**
     * 设置可见性
     * @param visible 是否可见
     */
    setVisible(visible: boolean): void;
    
    /**
     * 获取 Z-index
     */
    getZIndex(): number;
    
    /**
     * 设置 Z-index
     * @param zIndex Z 轴顺序
     */
    setZIndex(zIndex: number): void;
    
    /**
     * 获取 ID
     */
    getId(): number;
    
    /**
     * 设置 ID（内部使用）
     * @internal
     * @param id ID 数值
     */
    setId(id: number): void;
    
    // 注意：setMapLibreMap 是内部实现细节，不在公开 API 中暴露
    // ETS 层的 Polygon 封装类会处理 MapLibreMap 的关联
}

