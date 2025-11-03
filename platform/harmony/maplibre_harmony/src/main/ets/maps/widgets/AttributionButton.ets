/**
 * AttributionButton - 版权归属按钮组件
 * 
 * 对应 Android 的 AttributionDialogManager 和 iOS 的 MLNAttributionButton
 * 显示地图数据来源和版权信息
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import promptAction from '@ohos.promptAction';

/**
 * 归属信息项
 */
export interface AttributionInfo {
  /**
   * 标题
   */
  title: string;
  
  /**
   * URL 链接（可选）
   */
  url?: string;
}

/**
 * AttributionButton 组件
 * 
 * 使用示例：
 * ```typescript
 * AttributionButton({
 *   isEnabled: true,
 *   tintColor: '#000000',
 *   attributions: [
 *     { title: '© MapLibre', url: 'https://maplibre.org' },
 *     { title: '© OpenStreetMap contributors', url: 'https://www.openstreetmap.org/copyright' }
 *   ],
 *   onAttributionClick: (attribution) => {
 *     // 处理点击事件
 *   }
 * })
 * ```
 */
@Component
export struct AttributionButton {
  /**
   * 是否启用
   */
  @Prop isEnabled: boolean = true;
  
  /**
   * 图标颜色
   */
  @Prop tintColor: string = '#000000';
  
  /**
   * 图标大小（vp）
   */
  @Prop iconSize: number = 24;
  
  /**
   * 归属信息列表
   */
  @Prop attributions: AttributionInfo[] = [
    { title: '© MapLibre', url: 'https://maplibre.org' },
    { title: '© OpenStreetMap contributors', url: 'https://www.openstreetmap.org/copyright' }
  ];
  
  /**
   * 点击归属信息的回调
   */
  onAttributionClick?: (attribution: AttributionInfo) => void;
  
  /**
   * 自定义点击处理
   * 如果提供，将覆盖默认行为
   */
  onButtonClick?: () => void;
  
  build() {
    // 使用 Stack 确保图标是圆形背景
    Stack() {
      if (this.isEnabled) {
        // 圆形背景
        Circle()
          .width(this.iconSize + 8)
          .height(this.iconSize + 8)
          .fill(Color.White)
          .opacity(0.8)
        
        // "i" 图标
        Text('i')
          .fontSize(this.iconSize - 6)
          .fontColor(this.tintColor)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.isEnabled ? this.iconSize + 8 : 0)
    .height(this.isEnabled ? this.iconSize + 8 : 0)
    .visibility(this.isEnabled ? Visibility.Visible : Visibility.None)
    .onClick(() => {
      if (this.isEnabled) {
        if (this.onButtonClick) {
          // 使用自定义点击处理
          this.onButtonClick();
        } else {
          // 默认行为：显示归属信息
          this.showAttributionDialog();
        }
      }
    })
  }
  
  /**
   * 显示归属信息对话框
   */
  private showAttributionDialog(): void {
    try {
      if (this.attributions.length === 0) {
        promptAction.showToast({
          message: 'No attribution information available',
          duration: 2000
        });
        return;
      }
      
      // 构建选项列表 (最多显示6个)
      const options = this.attributions.slice(0, 6).map(attr => attr.title);
      
      // 显示操作菜单
      const buttons: promptAction.Button[] = options.map((title) => {
        const button: promptAction.Button = {
          text: title,
          color: '#007AFF'
        };
        return button;
      });
      
      promptAction.showActionMenu({
        title: 'Map Attribution',
        buttons: buttons as [promptAction.Button, promptAction.Button?, promptAction.Button?, promptAction.Button?, promptAction.Button?, promptAction.Button?]
      }).then((result) => {
        if (result.index !== undefined && result.index >= 0) {
          const selectedAttribution = this.attributions[result.index];
          
          if (this.onAttributionClick) {
            // 调用外部回调
            this.onAttributionClick(selectedAttribution);
          } else {
            // 默认行为：如果有 URL，显示提示
            if (selectedAttribution.url) {
              promptAction.showToast({
                message: `Visit: ${selectedAttribution.url}`,
                duration: 3000
              });
            }
          }
        }
      }).catch((err: Error) => {
        hilog.error(DOMAIN, 'AttributionButton', `Failed to show action menu: ${err.message}`);
      });
      
    } catch (error) {
      hilog.error(DOMAIN, 'AttributionButton', `Error showing attribution dialog: ${error}`);
    }
  }
}

/**
 * 默认的归属信息
 */
export const DEFAULT_ATTRIBUTIONS: AttributionInfo[] = [
  {
    title: '© MapLibre',
    url: 'https://maplibre.org'
  },
  {
    title: '© OpenStreetMap contributors',
    url: 'https://www.openstreetmap.org/copyright'
  },
  {
    title: 'Improve this map',
    url: 'https://www.openstreetmap.org/fixthemap'
  }
];

