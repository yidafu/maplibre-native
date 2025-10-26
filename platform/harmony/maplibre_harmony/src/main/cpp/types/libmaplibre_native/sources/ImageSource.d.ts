/**
 * MapLibre Native for HarmonyOS - ImageSource Type Definitions
 * 图像数据源 API
 */

/**
 * 创建图像数据源
 * @param id 数据源 ID
 * @param coordinates 四角坐标 JSON 字符串 [[lon, lat], [lon, lat], [lon, lat], [lon, lat]]
 * @param imageData 可选的图像数据
 * @returns 数据源原生指针
 */
export function create(id: string, coordinates: string, imageData: Uint8Array | null): number;

/**
 * 设置图像 URL
 * @param sourcePtr 数据源指针
 * @param url 图像 URL
 */
export function setUrl(sourcePtr: number, url: string): void;

/**
 * 设置图像数据
 * @param sourcePtr 数据源指针
 * @param imageData 图像数据
 */
export function setImage(sourcePtr: number, imageData: Uint8Array): void;

/**
 * 设置四角坐标
 * @param sourcePtr 数据源指针
 * @param coordinates 四角坐标 JSON 字符串
 */
export function setCoordinates(sourcePtr: number, coordinates: string): void;

