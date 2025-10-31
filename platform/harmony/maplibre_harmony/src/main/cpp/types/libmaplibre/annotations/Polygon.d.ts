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
    constructor(options: any);
    
    /**
     * 获取多边形的点坐标
     */
    getPoints(): any[];
    
    /**
     * 设置多边形的点坐标
     * @param points 点坐标数组
     */
    setPoints(points: any[]): void;
    
    /**
     * 添加一个点
     * @param point 点坐标
     */
    addPoint(point: any): void;
    
    /**
     * 在指定位置插入一个点
     * @param index 插入位置
     * @param point 点坐标
     */
    insertPoint(index: number, point: any): void;
    
    /**
     * 移除指定索引的点
     * @param index 点索引
     */
    removePoint(index: number): any;
    
    /**
     * 获取孔洞列表
     */
    getHoles(): any[][];
    
    /**
     * 设置孔洞列表
     * @param holes 孔洞数组
     */
    setHoles(holes: any[][]): void;
    
    /**
     * 添加一个孔洞
     * @param hole 孔洞点坐标数组
     */
    addHole(hole: any[]): void;
    
    /**
     * 移除指定索引的孔洞
     * @param index 孔洞索引
     */
    removeHole(index: number): any[];
    
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
     * 设置 ID
     * @param id ID 数值
     */
    setId(id: number): void;
    
    /**
     * 设置关联的地图对象（内部使用）
     * @param map 地图对象
     */
    setMapLibreMap(map: any): void;
}

