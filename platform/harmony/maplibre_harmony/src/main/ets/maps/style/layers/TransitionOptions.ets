/**
 * TransitionOptions - 过渡选项
 * 使用 NAPI 模块中的类型定义
 */
import maplibre from 'libmaplibre.so';

export type TransitionOptions = maplibre.TransitionOptions;

/**
 * 创建过渡选项
 */
export function createTransitionOptions(duration: number = 300, delay: number = 0): TransitionOptions {
  return { 
    duration: Math.max(0, duration), 
    delay: Math.max(0, delay) 
  };
}
