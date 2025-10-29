/**
 * RasterDemSource - 栅格 DEM 数据源
 * 
 * 用于加载数字高程模型数据
 */
export class RasterDemSource {
    /**
     * 构造栅格 DEM 数据源
     * @param id 数据源 ID
     * @param options 可选配置
     */
    constructor(id: string, options?: any);
    
    /**
     * 获取数据源 ID
     */
    getId(): string;
    
    /**
     * 获取原生指针（内部使用）
     */
    
    /**
     * 获取数据 URL
     */
    getUrl(): string;
    
    /**
     * 设置数据 URL
     * @param url 数据 URL
     */
    setUrl(url: string): void;
}
