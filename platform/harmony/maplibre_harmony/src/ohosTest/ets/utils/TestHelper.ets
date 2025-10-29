/**
 * Test helper utilities for MapLibre Harmony tests
 */

import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'MapLibreTestHelper';
const DOMAIN = 0xFF00;

export class TestHelper {
  private driver: Driver | null = null;
  
  /**
   * Initialize test helper
   */
  async init(): Promise<void> {
    try {
      this.driver = Driver.create();
      hilog.info(DOMAIN, TAG, 'Test helper initialized');
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to initialize: ${error}`);
      throw error;
    }
  }
  
  /**
   * Wait for component to appear
   */
  async waitForComponent(componentId: string, timeout: number = 10000): Promise<boolean> {
    if (!this.driver) {
      throw new Error('Driver not initialized');
    }
    
    const startTime = Date.now();
    while (Date.now() - startTime < timeout) {
      try {
        const component = await this.driver.findComponent(ON.id(componentId));
        if (component) {
          hilog.info(DOMAIN, TAG, `Component found: ${componentId}`);
          return true;
        }
      } catch (error) {
        // Component not found yet, continue waiting
      }
      
      await this.sleep(100);
    }
    
    hilog.error(DOMAIN, TAG, `Component not found within timeout: ${componentId}`);
    return false;
  }
  
  /**
   * Wait for text to appear
   */
  async waitForText(text: string, timeout: number = 10000): Promise<boolean> {
    if (!this.driver) {
      throw new Error('Driver not initialized');
    }
    
    const startTime = Date.now();
    while (Date.now() - startTime < timeout) {
      try {
        const component = await this.driver.findComponent(ON.text(text));
        if (component) {
          hilog.info(DOMAIN, TAG, `Text found: ${text}`);
          return true;
        }
      } catch (error) {
        // Text not found yet, continue waiting
      }
      
      await this.sleep(100);
    }
    
    hilog.error(DOMAIN, TAG, `Text not found within timeout: ${text}`);
    return false;
  }
  
  /**
   * Click on component
   */
  async clickComponent(componentId: string): Promise<boolean> {
    if (!this.driver) {
      throw new Error('Driver not initialized');
    }
    
    try {
      const component = await this.driver.findComponent(ON.id(componentId));
      if (component) {
        await component.click();
        hilog.info(DOMAIN, TAG, `Clicked component: ${componentId}`);
        return true;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to click component: ${error}`);
    }
    
    return false;
  }
  
  /**
   * Take screenshot
   */
  async takeScreenshot(filename: string): Promise<boolean> {
    if (!this.driver) {
      throw new Error('Driver not initialized');
    }
    
    try {
      await this.driver.screenCap(`/data/local/tmp/${filename}.png`);
      hilog.info(DOMAIN, TAG, `Screenshot saved: ${filename}.png`);
      return true;
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to take screenshot: ${error}`);
      return false;
    }
  }
  
  /**
   * Get component text
   */
  async getComponentText(componentId: string): Promise<string | null> {
    if (!this.driver) {
      throw new Error('Driver not initialized');
    }
    
    try {
      const component = await this.driver.findComponent(ON.id(componentId));
      if (component) {
        const text = await component.getText();
        return text;
      }
    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to get component text: ${error}`);
    }
    
    return null;
  }
  
  /**
   * Assert condition with timeout
   */
  async assertWithTimeout(
    condition: () => Promise<boolean>,
    message: string,
    timeout: number = 5000
  ): Promise<void> {
    const startTime = Date.now();
    while (Date.now() - startTime < timeout) {
      if (await condition()) {
        hilog.info(DOMAIN, TAG, `Assertion passed: ${message}`);
        return;
      }
      await this.sleep(100);
    }
    
    throw new Error(`Assertion failed: ${message}`);
  }
  
  /**
   * Sleep for specified milliseconds
   */
  async sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  
  /**
   * Log info message
   */
  logInfo(message: string): void {
    hilog.info(DOMAIN, TAG, message);
  }
  
  /**
   * Log error message
   */
  logError(message: string): void {
    hilog.error(DOMAIN, TAG, message);
  }
}

/**
 * Performance metrics collector
 */
export class PerformanceMetrics {
  private startTime: number = 0;
  private marks: Map<string, number> = new Map();
  
  /**
   * Start timing
   */
  start(): void {
    this.startTime = Date.now();
    this.marks.clear();
    hilog.info(DOMAIN, TAG, 'Performance metrics started');
  }
  
  /**
   * Mark a milestone
   */
  mark(name: string): void {
    const elapsed = Date.now() - this.startTime;
    this.marks.set(name, elapsed);
    hilog.info(DOMAIN, TAG, `Mark: ${name} at ${elapsed}ms`);
  }
  
  /**
   * Get elapsed time since start
   */
  getElapsed(): number {
    return Date.now() - this.startTime;
  }
  
  /**
   * Get time between two marks
   */
  getDuration(startMark: string, endMark: string): number | null {
    const start = this.marks.get(startMark);
    const end = this.marks.get(endMark);
    
    if (start !== undefined && end !== undefined) {
      return end - start;
    }
    
    return null;
  }
  
  /**
   * Export metrics as JSON
   */
  exportMetrics(): string {
    const metrics: Record<string, number> = {
      totalTime: this.getElapsed()
    };
    
    this.marks.forEach((time, name) => {
      metrics[name] = time;
    });
    
    return JSON.stringify(metrics, null, 2);
  }
  
  /**
   * Assert performance requirement
   */
  assertPerformance(mark: string, maxTime: number): void {
    const time = this.marks.get(mark);
    if (time === undefined) {
      throw new Error(`Mark not found: ${mark}`);
    }
    
    if (time > maxTime) {
      throw new Error(
        `Performance assertion failed: ${mark} took ${time}ms, expected < ${maxTime}ms`
      );
    }
    
    hilog.info(DOMAIN, TAG, `Performance OK: ${mark} = ${time}ms < ${maxTime}ms`);
  }
}

