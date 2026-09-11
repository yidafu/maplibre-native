import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DOMAIN } from '../constants/HiLogConstants';

export default class EntryAbility extends UIAbility {
  private isDestroyed: boolean = false;
  private pendingLaunchWant?: Want;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    this.isDestroyed = false;
    this.pendingLaunchWant = want;
    
    // 清理可能残留的全局状态
    this.cleanupGlobalState();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    this.isDestroyed = true;
    
    // 确保所有资源都被正确清理
    this.cleanupAllResources();
  }

  private cleanupGlobalState(): void {
    try {
      // 清理可能残留的NAPI引用
      hilog.info(DOMAIN, 'testTag', 'Cleaning up global state');
      
      // 重置FileSourceManager状态
      // 这里可以添加更多全局状态清理逻辑
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Error cleaning up global state: %{public}s', JSON.stringify(error));
    }
  }

  private cleanupAllResources(): void {
    try {
      hilog.info(DOMAIN, 'testTag', 'Cleaning up all resources');
      
      // 清理EGL上下文
      // 清理OpenGL资源
      // 停止所有后台线程
      // 释放NAPI引用
      
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Error cleaning up resources: %{public}s', JSON.stringify(error));
    }
  }

  private windowStage: window.WindowStage | null = null;

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 保存窗口引用
    this.windowStage = windowStage;

    // Support launching a specific test page via Want parameter.
    // Used by ohosTest to load the automation test page directly.
    let startPage: string = 'pages/Index';
    try {
      const wantParamPage = this.pendingLaunchWant?.parameters?.['startPage'] as string;
      if (wantParamPage && typeof wantParamPage === 'string' && wantParamPage.length > 0) {
        startPage = wantParamPage;
        hilog.info(DOMAIN, 'testTag', 'Loading custom start page: %{public}s', startPage);
      }
    } catch (error) {
      hilog.warn(DOMAIN, 'testTag', 'Failed to read startPage parameter: %{public}s', JSON.stringify(error));
    }

    windowStage.loadContent(startPage, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
    
    // 清理窗口相关资源
    if (this.windowStage) {
      try {
        // 确保窗口资源被正确释放
        this.windowStage = null;
        hilog.info(DOMAIN, 'testTag', 'Window stage resources cleaned up');
      } catch (error) {
        hilog.error(DOMAIN, 'testTag', 'Error cleaning up window stage: %{public}s', JSON.stringify(error));
      }
    }
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    
    // 检查窗口状态
    if (!this.windowStage) {
      hilog.warn(DOMAIN, 'testTag', 'Window stage is null in onForeground');
    }
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    
    // 暂停非必要的操作
    this.pauseNonEssentialOperations();
  }

  private pauseNonEssentialOperations(): void {
    try {
      hilog.info(DOMAIN, 'testTag', 'Pausing non-essential operations');
      
      // 暂停地图渲染
      // 暂停网络请求
      // 其他非必要操作
      
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Error pausing operations: %{public}s', JSON.stringify(error));
    }
  }
}
