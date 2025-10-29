/**
 * OfflineCacheTestPage - 离线缓存管理测试页面
 * 
 * 测试 OfflineManager 的缓存管理功能：
 * - 环境缓存清理和失效
 * - 数据库维护
 */
import { OfflineManager } from 'maplibre_harmony/src/main/ets/maps/offline';
import common from '@ohos.app.ability.common';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct OfflineCacheTestPage {
  @State private title: string = '离线缓存管理测试';
  @State private statusMessage: string = '就绪';
  @State private lastOperationResult: string = '';
  @State private cacheSizeInput: string = '50';
  @State private tileCountLimitInput: string = '6000';
  @State private autoPackEnabled: boolean = false;
  
  private context: common.UIAbilityContext | null = null;
  private offlineManager: OfflineManager | null = null;

  aboutToAppear() {
    try {
      // 获取上下文
      this.context = getContext(this) as common.UIAbilityContext;
      // 获取 OfflineManager 实例
      this.offlineManager = OfflineManager.getInstance(this.context);
      this.statusMessage = '✅ OfflineManager 已初始化';
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.statusMessage = `❌ 初始化失败: ${errorMsg}`;
      this.showToast(`初始化失败: ${errorMsg}`);
    }
  }

  /**
   * 清除环境缓存
   */
  private async clearAmbientCache() {
    if (!this.offlineManager) return;
    
    this.statusMessage = '正在清除环境缓存...';
    this.lastOperationResult = '';
    
    try {
      await this.offlineManager.clearAmbientCache();
      this.statusMessage = '操作成功';
      this.lastOperationResult = '✅ 环境缓存已清除';
      this.showToast('环境缓存已清除');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.statusMessage = '操作失败';
      this.lastOperationResult = `❌ 清除失败: ${errorMsg}`;
      this.showToast(`清除失败: ${errorMsg}`);
    }
  }
  
  /**
   * 使缓存失效
   */
  private async invalidateAmbientCache() {
    if (!this.offlineManager) return;
    
    this.statusMessage = '正在使缓存失效...';
    this.lastOperationResult = '';
    
    try {
      await this.offlineManager.invalidateAmbientCache();
      this.statusMessage = '操作成功';
      this.lastOperationResult = '✅ 缓存已标记为失效';
      this.showToast('缓存已失效');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.statusMessage = '操作失败';
      this.lastOperationResult = `❌ 操作失败: ${errorMsg}`;
      this.showToast(`失败: ${errorMsg}`);
    }
  }
  
  /**
   * 重置数据库（危险操作，需要确认）
   */
  private resetDatabase() {
    // 显示确认对话框
    promptAction.showDialog({
      title: '⚠️ 危险操作',
      message: '重置数据库将删除所有离线区域和缓存数据，此操作不可撤销。确定要继续吗？',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '确定重置', color: '#ff0000' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.performReset();
      }
    }).catch(() => {
      // 用户取消或对话框错误
    });
  }
  
  /**
   * 执行重置操作
   */
  private async performReset() {
    if (!this.offlineManager) return;
    
    this.statusMessage = '正在重置数据库...';
    this.lastOperationResult = '';
    
    try {
      await this.offlineManager.resetDatabase();
      this.statusMessage = '操作成功';
      this.lastOperationResult = '✅ 数据库已重置';
      this.showToast('数据库已重置');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.statusMessage = '操作失败';
      this.lastOperationResult = `❌ 重置失败: ${errorMsg}`;
      this.showToast(`重置失败: ${errorMsg}`);
    }
  }
  
  /**
   * 显示提示消息
   */
  public showToast(message: string) {
    promptAction.showToast({
      message: message,
      duration: 2000
    });
  }
  
  build() {
    Scroll() {
      Column() {
        // 标题栏
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })
        
        // 状态信息显示区
        Column() {
          Text('状态')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 5 })
          
          Text(this.statusMessage)
            .fontSize(14)
            .fontColor('#666')
            .padding(10)
            .width('100%')
            .backgroundColor('#f5f5f5')
            .borderRadius(5)
          
          if (this.lastOperationResult) {
            Text(this.lastOperationResult)
              .fontSize(13)
              .fontColor(this.lastOperationResult.startsWith('✅') ? '#4CAF50' : '#f44336')
              .padding(10)
              .width('100%')
              .backgroundColor(this.lastOperationResult.startsWith('✅') ? '#E8F5E9' : '#FFEBEE')
              .borderRadius(5)
              .margin({ top: 10 })
          }
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 环境缓存管理区
        Column() {
          Text('🗂️ 环境缓存管理')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 10 })
          
          Row() {
            Button('清除环境缓存')
              .onClick(() => this.clearAmbientCache())
              .margin({ right: 10 })
              .layoutWeight(1)
            
            Button('使缓存失效')
              .onClick(() => this.invalidateAmbientCache())
              .layoutWeight(1)
          }
          .width('100%')
          .margin({ bottom: 10 })
        }
        .width('90%')
        .backgroundColor('#fff')
        .padding(15)
        .borderRadius(10)
        .margin({ bottom: 15 })
        
        // 数据库维护区
        Column() {
          Text('💾 数据库维护')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 10 })
          
          Button('重置数据库（危险）')
            .onClick(() => this.resetDatabase())
            .width('100%')
            .backgroundColor('#ff0000')
        }
        .width('90%')
        .backgroundColor('#fff')
        .padding(15)
        .borderRadius(10)
        .margin({ bottom: 15 })
        
        // 返回按钮
        Button('返回')
          .onClick(() => {
            router.back();
          })
          .width('90%')
          .margin({ top: 20, bottom: 40 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f0f0f0')
  }
}
