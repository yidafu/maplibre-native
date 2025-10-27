import { AbilityStage } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from './constants/HiLogConstants';

export default class MyAbilityStage extends AbilityStage {
  onCreate(): void {
    hilog.info(DOMAIN, 'MyAbilityStage', 'AbilityStage onCreate');
    
    // 初始化全局资源
    this.initializeGlobalResources();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'MyAbilityStage', 'AbilityStage onDestroy');
    
    // 清理全局资源
    this.cleanupGlobalResources();
  }

  private initializeGlobalResources(): void {
    try {
      hilog.info(DOMAIN, 'MyAbilityStage', 'Initializing global resources');
      
      // 初始化全局状态
      // 这里可以添加全局资源的初始化逻辑
      
    } catch (error) {
      hilog.error(DOMAIN, 'MyAbilityStage', 'Error initializing global resources: %{public}s', JSON.stringify(error));
    }
  }

  private cleanupGlobalResources(): void {
    try {
      hilog.info(DOMAIN, 'MyAbilityStage', 'Cleaning up global resources');
      
      // 清理全局状态
      // 这里可以添加全局资源的清理逻辑
      
    } catch (error) {
      hilog.error(DOMAIN, 'MyAbilityStage', 'Error cleaning up global resources: %{public}s', JSON.stringify(error));
    }
  }
}
