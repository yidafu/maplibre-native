/**
 * 聚类属性配置
 * 
 * 用于在聚类时计算自定义聚合属性
 * 
 * 格式：`{ "propertyName": [operatorExpression, mapExpression] }`
 * 
 * - operatorExpression: 聚合操作符（如 "+", "max", "min" 等）或完整的聚合表达式
 * - mapExpression: 从单个点提取值的 Expression
 * 
 * @example
 * ```
 * {
 *   // 计算最大值
 *   "max": [["max", ["accumulated"], ["get", "sum"]], ["get", "mag"]],
 *   
 *   // 简单求和
 *   "sum": ["+", ["get", "value"]],
 *   
 *   // 计算是否有任何点满足条件
 *   "hasSpecial": ["any", ["==", ["get", "type"], "special"]]
 * }
 * ```
 */
export type ClusterProperties = Record<string, [any[] | string, any[]]>;

/**
 * GeoJSON 数据源选项
 */
export interface GeoJsonOptions {
    /** 最大缩放级别 */
    maxzoom?: number;
    /** 瓦片缓冲区大小 */
    buffer?: number;
    /** 简化容差 */
    tolerance?: number;
    /** 是否启用聚类 */
    cluster?: boolean;
    /** 聚类半径（默认 50） */
    clusterRadius?: number;
    /** 聚类最大缩放级别 */
    clusterMaxZoom?: number;
    /** 聚类最小点数（默认 2） */
    clusterMinPoints?: number;
    /** 
     * 聚类属性 - 使用 Expression 计算聚合属性
     * 
     * 支持在聚类时计算自定义属性，可用于：
     * - 计算聚类中的最大/最小值
     * - 求和、平均值
     * - 检查是否满足某些条件
     * 
     * 每个属性定义为：`[operatorExpr, mapExpr]`
     * - operatorExpr: 聚合操作符或表达式数组
     * - mapExpr: 从单个要素提取值的表达式数组
     * 
     * @example
     * ```typescript
     * clusterProperties: {
     *   "max_magnitude": [
     *     ["max", ["accumulated"], ["get", "max"]],
     *     ["get", "magnitude"]
     *   ],
     *   "sum_value": ["+", ["get", "value"]]
     * }
     * ```
     */
    clusterProperties?: ClusterProperties;
    /** 是否计算线段度量 */
    lineMetrics?: boolean;
    /** 是否生成要素 ID */
    generateId?: boolean;
}

// GeoJSON 类型定义
export interface Geometry {
    type: string;
    coordinates: any;
}

export interface Feature {
    type: 'Feature';
    id?: string | number;
    geometry: Geometry | null;
    properties: Record<string, any>;
}

export interface FeatureCollection {
    type: 'FeatureCollection';
    features: Feature[];
}

export type GeoJsonData = string | Geometry | Feature | FeatureCollection | Object;

/**
 * GeoJsonSource - GeoJSON 数据源
 * 
 * 支持点、线、面等矢量要素，支持聚类功能
 */
export class GeoJsonSource {
    /**
     * 构造 GeoJSON 数据源
     * @param id 数据源 ID
     * @param options 可选配置
     */
    constructor(id: string, options?: GeoJsonOptions);
    
    /**
     * 获取数据源 ID
     */
    getId(): string;
    
    /**
     * 设置 GeoJSON 数据（异步）
     * 支持多种数据格式：
     * - GeoJSON 字符串
     * - Geometry 对象 (Point, LineString, Polygon, etc.)
     * - Feature 对象
     * - FeatureCollection 对象
     * @param data GeoJSON 数据
     * @returns this（支持链式调用）
     */
    setGeoJson(data: GeoJsonData): GeoJsonSource;
    
    /**
     * 设置 GeoJSON 数据（同步）
     * 支持多种数据格式：
     * - GeoJSON 字符串
     * - Geometry 对象 (Point, LineString, Polygon, etc.)
     * - Feature 对象
     * - FeatureCollection 对象
     * @param data GeoJSON 数据
     * @returns this（支持链式调用）
     */
    setGeoJsonSync(data: GeoJsonData): GeoJsonSource;
    
    /**
     * 从 URL 加载 GeoJSON 数据
     * @param url GeoJSON 数据 URL
     * @returns this（支持链式调用）
     */
    setUrl(url: string): GeoJsonSource;
    
    /**
     * 获取数据 URL
     */
    getUrl(): string;
    
    /**
     * 查询数据源要素
     * @param filter 可选过滤器
     * @returns Feature 数组
     */
    querySourceFeatures(filter?: any): Feature[];
    
    /**
     * 获取聚类的子项
     * @param clusterId 聚类 ID 或包含 cluster_id 属性的 Feature
     * @returns 子 Feature 数组
     */
    getClusterChildren(clusterId: number | Feature): Feature[];
    
    /**
     * 获取聚类的叶子节点
     * @param clusterId 聚类 ID 或包含 cluster_id 属性的 Feature
     * @param limit 限制数量，默认 10
     * @param offset 偏移量，默认 0
     * @returns 叶子 Feature 数组
     */
    getClusterLeaves(clusterId: number | Feature, limit?: number, offset?: number): Feature[];
    
    /**
     * 获取聚类展开的缩放级别
     * @param clusterId 聚类 ID 或包含 cluster_id 属性的 Feature
     * @returns 目标缩放级别
     */
    getClusterExpansionZoom(clusterId: number | Feature): number;
}
