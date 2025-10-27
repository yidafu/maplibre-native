import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * LocationComponent 性能监控工具
 * 用于追踪和优化性能瓶颈
 */
export class PerformanceMonitor {
  private static readonly TAG: string = 'LocationPerformance';
  private static enabled: boolean = false;
  
  // 性能指标
  private static metrics: Map<string, PerformanceMetric> = new Map();
  
  // 帧率计算
  private static frameCount: number = 0;
  private static lastFpsTime: number = 0;
  private static currentFps: number = 0;

  /**
   * 启用性能监控
   */
  static enable(): void {
    this.enabled = true;
    hilog.info(DOMAIN, PerformanceMonitor.TAG, 'Performance monitoring enabled');
  }

  /**
   * 禁用性能监控
   */
  static disable(): void {
    this.enabled = false;
    hilog.info(DOMAIN, PerformanceMonitor.TAG, 'Performance monitoring disabled');
  }

  /**
   * 开始计时
   */
  static startTiming(label: string): void {
    if (!this.enabled) return;
    
    const metric: PerformanceMetric = {
      label: label,
      startTime: Date.now(),
      count: 0,
      totalTime: 0,
      minTime: Infinity,
      maxTime: 0,
      avgTime: 0
    };
    
    this.metrics.set(label, metric);
  }

  /**
   * 结束计时
   */
  static endTiming(label: string): void {
    if (!this.enabled) return;
    
    const metric = this.metrics.get(label);
    if (!metric || !metric.startTime) return;
    
    const duration = Date.now() - metric.startTime;
    metric.count++;
    metric.totalTime += duration;
    metric.minTime = Math.min(metric.minTime, duration);
    metric.maxTime = Math.max(metric.maxTime, duration);
    metric.avgTime = metric.totalTime / metric.count;
    
    if (duration > 16) { // 超过一帧时间（60fps）
      hilog.warn(DOMAIN, PerformanceMonitor.TAG, 
        `Slow operation: ${label} took ${duration.toFixed(2)}ms`);
    }
  }

  /**
   * 记录帧
   */
  static recordFrame(): void {
    if (!this.enabled) return;
    
    this.frameCount++;
    
    const now = Date.now();
    if (now - this.lastFpsTime >= 1000) {
      this.currentFps = this.frameCount;
      this.frameCount = 0;
      this.lastFpsTime = now;
      
      if (this.currentFps < 50) { // 低于 50 FPS 警告
        hilog.warn(DOMAIN, PerformanceMonitor.TAG, `Low FPS detected: ${this.currentFps}`);
      }
    }
  }

  /**
   * 获取当前 FPS
   */
  static getCurrentFps(): number {
    return this.currentFps;
  }

  /**
   * 记录内存使用
   */
  static recordMemoryUsage(label: string): void {
    if (!this.enabled) return;
    
    // 注意：鸿蒙可能没有直接的内存 API，这里简化处理
    hilog.debug(DOMAIN, PerformanceMonitor.TAG, `Memory checkpoint: ${label}`);
  }

  /**
   * 打印性能报告
   */
  static printReport(): void {
    if (!this.enabled || this.metrics.size === 0) return;
    
    hilog.info(DOMAIN, PerformanceMonitor.TAG, '=== Performance Report ===');
    hilog.info(DOMAIN, PerformanceMonitor.TAG, `Current FPS: ${this.currentFps}`);
    
    this.metrics.forEach((metric, label) => {
      if (metric.count > 0) {
        hilog.info(DOMAIN, PerformanceMonitor.TAG, 
          `${label}: count=${metric.count}, avg=${metric.avgTime.toFixed(2)}ms, ` +
          `min=${metric.minTime.toFixed(2)}ms, max=${metric.maxTime.toFixed(2)}ms`);
      }
    });
    
    hilog.info(DOMAIN, PerformanceMonitor.TAG, '=========================');
  }

  /**
   * 重置统计
   */
  static reset(): void {
    this.metrics.clear();
    this.frameCount = 0;
    this.lastFpsTime = 0;
    this.currentFps = 0;
    hilog.info(DOMAIN, PerformanceMonitor.TAG, 'Performance metrics reset');
  }

  /**
   * 测量函数执行时间
   */
  static measure<T>(label: string, fn: () => T): T {
    if (!this.enabled) {
      return fn();
    }

    this.startTiming(label);
    try {
      return fn();
    } finally {
      this.endTiming(label);
    }
  }

  /**
   * 测量异步函数执行时间
   */
  static async measureAsync<T>(label: string, fn: () => Promise<T>): Promise<T> {
    if (!this.enabled) {
      return fn();
    }

    this.startTiming(label);
    try {
      return await fn();
    } finally {
      this.endTiming(label);
    }
  }
}

/**
 * 性能指标接口
 */
interface PerformanceMetric {
  label: string;
  startTime: number;
  count: number;
  totalTime: number;
  minTime: number;
  maxTime: number;
  avgTime: number;
}

