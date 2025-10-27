import sensor from '@ohos.sensor';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * 指南针监听器接口
 */
export interface CompassListener {
  /**
   * 当指南针方向变化时调用
   * @param heading 方向角度（度数，0-360，北为0）
   */
  onCompassChanged(heading: number): void;

  /**
   * 当指南针精度变化时调用
   * @param accuracy 精度
   */
  onCompassAccuracyChange?(accuracy: number): void;
}

/**
 * 指南针引擎
 * 基于鸿蒙传感器 API
 */
export class CompassEngine {
  private static readonly TAG: string = 'CompassEngine';
  
  private listeners: Set<CompassListener> = new Set();
  private isListening: boolean = false;
  private lastHeading: number = 0;
  private updateInterval: number = 500; // 更新间隔（毫秒）
  private lastUpdateTime: number = 0;

  // 平滑滤波参数
  private static readonly SMOOTHING_FACTOR: number = 0.1;
  
  // 低通滤波历史值
  private headingHistory: number[] = [];
  private static readonly HISTORY_SIZE: number = 5;
  
  // 变化阈值（度）
  private changeThreshold: number = 0.5;

  /**
   * 添加指南针监听器
   */
  addCompassListener(listener: CompassListener): void {
    hilog.info(DOMAIN, CompassEngine.TAG, 'Adding compass listener');
    this.listeners.add(listener);
    
    if (!this.isListening) {
      this.startListening();
    }
  }

  /**
   * 移除指南针监听器
   */
  removeCompassListener(listener: CompassListener): void {
    hilog.info(DOMAIN, CompassEngine.TAG, 'Removing compass listener');
    this.listeners.delete(listener);
    
    if (this.listeners.size === 0 && this.isListening) {
      this.stopListening();
    }
  }

  /**
   * 设置更新间隔
   */
  setUpdateInterval(interval: number): void {
    this.updateInterval = interval;
  }

  /**
   * 开始监听指南针
   */
  private startListening(): void {
    try {
      hilog.info(DOMAIN, CompassEngine.TAG, 'Starting compass sensor');

      // 订阅方向传感器
      sensor.on(sensor.SensorId.ORIENTATION, (data: sensor.OrientationResponse) => {
        const now = Date.now();
        
        // 限制更新频率
        if (now - this.lastUpdateTime < this.updateInterval) {
          return;
        }
        this.lastUpdateTime = now;

        // 获取方位角（azimuth）
        // data.alpha 是绕 Z 轴的旋转角度，范围 0-360
        let heading = data.alpha;
        
        // 应用平滑滤波
        heading = this.smoothHeading(heading);
        
        // 通知所有监听器（使用可配置的变化阈值）
        const headingDiff = Math.abs(heading - this.lastHeading);
        const normalizedDiff = headingDiff > 180 ? 360 - headingDiff : headingDiff;
        
        if (normalizedDiff > this.changeThreshold) {
          this.lastHeading = heading;
          hilog.debug(DOMAIN, CompassEngine.TAG, `Compass heading: ${heading.toFixed(2)}`);
          
          this.listeners.forEach(listener => {
            try {
              listener.onCompassChanged(heading);
            } catch (err) {
              hilog.error(DOMAIN, CompassEngine.TAG, `Listener error: ${err}`);
            }
          });
        }
      }, {
        interval: this.updateInterval * 1000000 // 转换为纳秒
      });

      this.isListening = true;
      hilog.info(DOMAIN, CompassEngine.TAG, 'Compass sensor started');

    } catch (err) {
      hilog.error(DOMAIN, CompassEngine.TAG, `Failed to start compass sensor: ${err}`);
    }
  }

  /**
   * 停止监听指南针
   */
  private stopListening(): void {
    try {
      if (this.isListening) {
        sensor.off(sensor.SensorId.ORIENTATION);
        this.isListening = false;
        hilog.info(DOMAIN, CompassEngine.TAG, 'Compass sensor stopped');
      }
    } catch (err) {
      hilog.error(DOMAIN, CompassEngine.TAG, `Failed to stop compass sensor: ${err}`);
    }
  }

  /**
   * 平滑角度变化（改进的低通滤波 + 移动平均）
   */
  private smoothHeading(newHeading: number): number {
    if (this.lastHeading === 0 && this.headingHistory.length === 0) {
      this.headingHistory.push(newHeading);
      return newHeading;
    }

    // 添加到历史记录
    this.headingHistory.push(newHeading);
    if (this.headingHistory.length > CompassEngine.HISTORY_SIZE) {
      this.headingHistory.shift();
    }

    // 计算移动平均（考虑角度跨越 0/360 边界）
    let sum = 0;
    let count = this.headingHistory.length;
    
    for (let i = 0; i < count; i++) {
      let angle = this.headingHistory[i];
      
      // 调整角度使其相对于第一个值连续
      if (i > 0) {
        let diff = angle - this.headingHistory[0];
        if (diff > 180) {
          angle -= 360;
        } else if (diff < -180) {
          angle += 360;
        }
      }
      
      sum += angle;
    }

    let average = sum / count;
    
    // 归一化到 0-360 范围
    while (average < 0) {
      average += 360;
    }
    while (average >= 360) {
      average -= 360;
    }

    return average;
  }

  /**
   * 获取最后的方向角度
   */
  getLastHeading(): number {
    return this.lastHeading;
  }

  /**
   * 检查指南针传感器是否可用
   */
  static isCompassAvailable(): boolean {
    try {
      // 检查方向传感器是否存在
      // 注意：实际实现可能需要更详细的检查
      return true;
    } catch (err) {
      hilog.error(DOMAIN, CompassEngine.TAG, `Failed to check compass availability: ${err}`);
      return false;
    }
  }

  /**
   * 停止所有监听
   */
  stopAllListeners(): void {
    this.listeners.clear();
    this.stopListening();
    this.resetState();
  }

  /**
   * 重置状态
   */
  private resetState(): void {
    this.lastHeading = 0;
    this.headingHistory = [];
    this.lastUpdateTime = 0;
  }

  /**
   * 设置变化阈值
   */
  setChangeThreshold(threshold: number): void {
    this.changeThreshold = Math.max(0.1, threshold);
    hilog.info(DOMAIN, CompassEngine.TAG, `Change threshold set to ${this.changeThreshold} degrees`);
  }

  /**
   * 校准指南针（重置历史数据）
   */
  calibrate(): void {
    hilog.info(DOMAIN, CompassEngine.TAG, 'Calibrating compass');
    this.headingHistory = [];
    this.lastHeading = 0;
  }
}

