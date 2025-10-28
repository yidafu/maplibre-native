/**
 * OfflineCacheTestPage - 离线缓存管理测试页面
 * 
 * 测试 OfflineManager 的缓存管理功能：
 * - 环境缓存清理和失效
 * - 数据库维护和压缩
 * - 缓存大小限制配置
 */
import { OfflineManager, getOfflineManager, FileSourceCallback } from '../maps/offline';
import common from '@ohos.app.ability.common';
import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

// FileSourceCallback 实现类
class ClearCacheCallback implements FileSourceCallback {
  private page: OfflineCacheTestPage;
  
  constructor(page: OfflineCacheTestPage) {
    this.page = page;
  }
  
  onSuccess(): void {
    this.page.statusMessage = '操作成功';
    this.page.lastOperationResult = '✅ 环境缓存已清除';
    this.page.showToast('环境缓存已清除');
  }
  
  onError(error: string): void {
    this.page.statusMessage = '操作失败';
    this.page.lastOperationResult = `❌ 清除失败: ${error}`;
    this.page.showToast(`清除失败: ${error}`);
  }
}

class InvalidateCacheCallback implements FileSourceCallback {
  private page: OfflineCacheTestPage;
  
  constructor(page: OfflineCacheTestPage) {
    this.page = page;
  }
  
  onSuccess(): void {
    this.page.statusMessage = '操作成功';
    this.page.lastOperationResult = '✅ 缓存已标记为失效';
    this.page.showToast('缓存已失效');
  }
  
  onError(error: string): void {
    this.page.statusMessage = '操作失败';
    this.page.lastOperationResult = `❌ 操作失败: ${error}`;
    this.page.showToast(`操作失败: ${error}`);
  }
}

class SetCacheSizeCallback implements FileSourceCallback {
  private page: OfflineCacheTestPage;
  private sizeMB: number;
  
  constructor(page: OfflineCacheTestPage, sizeMB: number) {
    this.page = page;
    this.sizeMB = sizeMB;
  }
  
  onSuccess(): void {
    this.page.statusMessage = '操作成功';
    this.page.lastOperationResult = `✅ 最大缓存大小已设置为 ${this.sizeMB}MB`;
    this.page.showToast('缓存大小已设置');
  }
  
  onError(error: string): void {
    this.page.statusMessage = '操作失败';
    this.page.lastOperationResult = `❌ 设置失败: ${error}`;
    this.page.showToast(`设置失败: ${error}`);
  }
}

class PackDatabaseCallback implements FileSourceCallback {
  private page: OfflineCacheTestPage;
  
  constructor(page: OfflineCacheTestPage) {
    this.page = page;
  }
  
  onSuccess(): void {
    this.page.statusMessage = '操作成功';
    this.page.lastOperationResult = '✅ 数据库已压缩，空间已回收';
    this.page.showToast('数据库已压缩');
  }
  
  onError(error: string): void {
    this.page.statusMessage = '操作失败';
    this.page.lastOperationResult = `❌ 压缩失败: ${error}`;
    this.page.showToast(`压缩失败: ${error}`);
  }
}

class ResetDatabaseCallback implements FileSourceCallback {
  private page: OfflineCacheTestPage;
  
  constructor(page: OfflineCacheTestPage) {
    this.page = page;
  }
  
  onSuccess(): void {
    this.page.statusMessage = '操作成功';
    this.page.lastOperationResult = '✅ 数据库已重置，所有数据已清除';
    this.page.showToast('数据库已重置');
  }
  
  onError(error: string): void {
    this.page.statusMessage = '操作失败';
    this.page.lastOperationResult = `❌ 重置失败: ${error}`;
    this.page.showToast(`重置失败: ${error}`);
  }
}

@Entry
@Component
struct OfflineCacheTestPage {
  @State title: string = '离线缓存管理测试';
  @State statusMessage: string = '准备就绪';
  @State lastOperationResult: string = '';
  @State cacheSizeInput: string = '50'; // MB
  @State tileCountLimitInput: string = '6000';
  @State autoPackEnabled: boolean = true;
  
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private offlineManager: OfflineManager | null = null;
  
  aboutToAppear() {
    // 初始化离线管理器
    this.offlineManager = getOfflineManager(this.context);
    this.statusMessage = '离线管理器已初始化';
  }
  
  /**
   * 清除环境缓存
   */
  private clearAmbientCache() {
    if (!this.offlineManager) return;
    
    this.statusMessage = '正在清除环境缓存...';
    this.lastOperationResult = '';
    
    const callback = new ClearCacheCallback(this);
    this.offlineManager.clearAmbientCache(callback);
  }
  
  /**
   * 使缓存失效
   */
  private invalidateAmbientCache() {
    if (!this.offlineManager) return;
    
    this.statusMessage = '正在使缓存失效...';
    this.lastOperationResult = '';
    
    const callback = new InvalidateCacheCallback(this);
    this.offlineManager.invalidateAmbientCache(callback);
  }
  
  /**
   * 设置最大缓存大小
   */
  private setMaximumCacheSize() {
    if (!this.offlineManager) return;
    
    const sizeMB = parseInt(this.cacheSizeInput);
    if (isNaN(sizeMB) || sizeMB <= 0) {
      this.showToast('请输入有效的缓存大小（MB）');
      return;
    }
    
    const sizeBytes = sizeMB * 1024 * 1024;
    this.statusMessage = `正在设置最大缓存大小为 ${sizeMB}MB...`;
    this.lastOperationResult = '';
    
    const callback = new SetCacheSizeCallback(this, sizeMB);
    this.offlineManager.setMaximumAmbientCacheSize(sizeBytes, callback);
  }
  
  /**
   * 压缩数据库
   */
  private packDatabase() {
    if (!this.offlineManager) return;
    
    this.statusMessage = '正在压缩数据库（可能需要较长时间）...';
    this.lastOperationResult = '';
    
    const callback = new PackDatabaseCallback(this);
    this.offlineManager.packDatabase(callback);
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
  private performReset() {
    if (!this.offlineManager) return;
    
    this.statusMessage = '正在重置数据库...';
    this.lastOperationResult = '';
    
    const callback = new ResetDatabaseCallback(this);
    this.offlineManager.resetDatabase(callback);
  }
  
  /**
   * 切换自动压缩开关
   */
  private toggleAutoPack(enabled: boolean) {
    if (!this.offlineManager) return;
    
    this.autoPackEnabled = enabled;
    this.offlineManager.runPackDatabaseAutomatically(enabled);
    this.lastOperationResult = enabled 
      ? '✅ 已启用自动数据库压缩' 
      : '⚠️ 已禁用自动数据库压缩';
    this.showToast(enabled ? '已启用自动压缩' : '已禁用自动压缩');
  }
  
  /**
   * 设置离线瓦片数量限制
   */
  private setTileCountLimit() {
    if (!this.offlineManager) return;
    
    const limit = parseInt(this.tileCountLimitInput);
    if (isNaN(limit) || limit <= 0) {
      this.showToast('请输入有效的瓦片数量限制');
      return;
    }
    
    this.offlineManager.setOfflineMapboxTileCountLimit(limit);
    this.lastOperationResult = `✅ 离线瓦片数量限制已设置为 ${limit}`;
    this.showToast('瓦片限制已设置');
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
          
          // 设置缓存大小
          Row() {
            TextInput({ placeholder: '缓存大小 (MB)', text: this.cacheSizeInput })
              .type(InputType.Number)
              .layoutWeight(1)
              .margin({ right: 10 })
              .onChange((value: string) => {
                this.cacheSizeInput = value;
              })
            
            Button('设置大小')
              .onClick(() => this.setMaximumCacheSize())
              .width(100)
          }
          .width('100%')
        }
        .width('100%')
        .padding(15)
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .margin({ bottom: 15 })
        
        // 数据库管理区
        Column() {
          Text('💾 数据库管理')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 10 })
          
          Button('压缩数据库')
            .onClick(() => this.packDatabase())
            .width('100%')
            .margin({ bottom: 10 })
            .backgroundColor('#2196F3')
          
          Button('重置数据库（危险）')
            .onClick(() => this.resetDatabase())
            .width('100%')
            .margin({ bottom: 10 })
            .backgroundColor('#f44336')
            .fontColor('#ffffff')
          
          // 自动压缩开关
          Row() {
            Text('自动压缩数据库')
              .fontSize(14)
              .layoutWeight(1)
            
            Toggle({ type: ToggleType.Switch, isOn: this.autoPackEnabled })
              .onChange((isOn: boolean) => {
                this.toggleAutoPack(isOn);
              })
          }
          .width('100%')
          .padding(10)
          .backgroundColor('#f5f5f5')
          .borderRadius(5)
        }
        .width('100%')
        .padding(15)
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .margin({ bottom: 15 })
        
        // 高级配置区
        Column() {
          Text('⚙️ 高级配置')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 10 })
          
          Row() {
            TextInput({ placeholder: '瓦片数量限制', text: this.tileCountLimitInput })
              .type(InputType.Number)
              .layoutWeight(1)
              .margin({ right: 10 })
              .onChange((value: string) => {
                this.tileCountLimitInput = value;
              })
            
            Button('设置限制')
              .onClick(() => this.setTileCountLimit())
              .width(100)
          }
          .width('100%')
          
          Text('说明: 限制单个离线区域可下载的最大瓦片数量')
            .fontSize(12)
            .fontColor('#999')
            .margin({ top: 5 })
        }
        .width('100%')
        .padding(15)
        .backgroundColor('#ffffff')
        .borderRadius(8)
        .margin({ bottom: 15 })
        
        // 使用说明
        Column() {
          Text('📖 功能说明')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 10 })
          
          Text('• 清除环境缓存: 删除所有非离线区域的缓存资源\n' +
            '• 使缓存失效: 标记缓存为过期，下次使用时重新验证\n' +
            '• 压缩数据库: 回收已删除数据占用的空间\n' +
            '• 重置数据库: 删除所有数据（包括离线区域）\n' +
            '• 自动压缩: 系统自动执行数据库压缩优化')
            .fontSize(12)
            .fontColor('#666')
            .lineHeight(20)
        }
        .width('100%')
        .padding(15)
        .backgroundColor('#FFF9C4')
        .borderRadius(8)
        .margin({ bottom: 15 })
        
        // 返回按钮
        Button('返回')
          .onClick(() => {
            router.back();
          })
          .width('100%')
          .margin({ top: 10, bottom: 20 })
      }
      .width('90%')
      .margin({ left: '5%', right: '5%' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f0f0f0')
  }
}

