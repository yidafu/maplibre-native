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
    /** 聚类半径 */
    clusterRadius?: number;
    /** 聚类最大缩放级别 */
    clusterMaxZoom?: number;
    /** 聚类最小点数 */
    clusterMinPoints?: number;
    /** 聚类属性 */
    clusterProperties?: Record<string, any>;
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

export type GeoJsonData = string | Geometry | Feature | FeatureCollection;

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
     */
    setGeoJson(data: GeoJsonData): void;
    
    /**
     * 设置 GeoJSON 数据（同步）
     * 支持多种数据格式：
     * - GeoJSON 字符串
     * - Geometry 对象 (Point, LineString, Polygon, etc.)
     * - Feature 对象
     * - FeatureCollection 对象
     * @param data GeoJSON 数据
     */
    setGeoJsonSync(data: GeoJsonData): void;
    
    /**
     * 从 URL 加载 GeoJSON 数据
     * @param url GeoJSON 数据 URL
     */
    setUrl(url: string): void;
    
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
