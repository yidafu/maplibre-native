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
    constructor(options: any);
    
    /**
     * 获取折线的点坐标
     */
    getPoints(): any[];
    
    /**
     * 设置折线的点坐标
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
     * 获取线条颜色
     */
    getColor(): string;
    
    /**
     * 设置线条颜色
     * @param color 颜色字符串
     */
    setColor(color: string): void;
    
    /**
     * 获取线条宽度
     */
    getWidth(): number;
    
    /**
     * 设置线条宽度
     * @param width 宽度值
     */
    setWidth(width: number): void;
    
    /**
     * 获取透明度
     */
    getAlpha(): number;
    
    /**
     * 设置透明度
     * @param alpha 透明度值 (0-1)
     */
    setAlpha(alpha: number): void;
    
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
     * 获取线条样式
     */
    getPattern(): number[] | null;
    
    /**
     * 设置线条样式
     * @param pattern 样式数组
     */
    setPattern(pattern: number[] | null): void;
    
    /**
     * 获取连接类型
     */
    getJointType(): string;
    
    /**
     * 设置连接类型
     * @param jointType 连接类型
     */
    setJointType(jointType: string): void;
    
    /**
     * 获取端点类型
     */
    getCapType(): string;
    
    /**
     * 设置端点类型
     * @param capType 端点类型
     */
    setCapType(capType: string): void;
    
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

