/**
 * 测试页面统一布局组件
 * 提供标题栏、返回按钮、操作按钮区等公共 UI 元素
 */
import { router } from '@kit.ArkUI';

@Component
export struct TestPageLayout {
  // 页面标题
  @Prop title: string = '测试页面';
  
  // 页面描述（可选）
  @Prop description: string = '';
  
  // 是否显示操作按钮区
  @Prop showActionBar: boolean = false;
  
  // 操作按钮内容构建器
  @BuilderParam actionButtons?: () => void;
  
  // 地图区域内容构建器
  @BuilderParam mapContent: () => void;
  
  // 控制面板内容构建器（可选）
  @BuilderParam controlPanel?: () => void;
  
  // 控制面板显示状态
  @State isControlPanelVisible: boolean = true;

  @Builder
  defaultActionButtons() {
    // 默认无操作按钮
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        // 返回按钮
        Button({ type: ButtonType.Normal }) {
          Text('←')
            .fontSize(24)
            .fontColor(Color.White)
        }
        .backgroundColor(Color.Transparent)
        .width(48)
        .height(48)
        .onClick(() => {
          router.back();
        })
        
        // 标题和描述
        Column() {
          Text(this.title)
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          
          if (this.description) {
            Text(this.description)
              .fontSize(12)
              .fontColor('#E0E0E0')
              .margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 8 })
        
        // 控制面板切换按钮（仅在有控制面板时显示）
        if (this.controlPanel) {
          Button({ type: ButtonType.Normal }) {
            Text(this.isControlPanelVisible ? '▼' : '▲')
              .fontSize(20)
              .fontColor(Color.White)
          }
          .backgroundColor(Color.Transparent)
          .width(40)
          .height(40)
          .onClick(() => {
            this.isControlPanelVisible = !this.isControlPanelVisible;
          })
        }

      }
      .width('100%')
      .height(60)
      .backgroundColor('#2196F3')
      .padding({ left: 8, right: 8, top: 10 })
      
      // 主内容区
      Stack() {
        // 地图内容（全屏）
        Column() {
          this.mapContent();
        }
        .width('100%')
        .height('100%')
        
        // 控制面板（浮动在地图上，支持滚动）
        if (this.controlPanel && this.isControlPanelVisible) {
          Scroll() {
            Column() {
              this.controlPanel();
            }
            .width('100%')
          }
          .width('100%')
          .height('70%') // 限制高度，避免遮挡整个地图
          .backgroundColor(Color.White)
          .borderRadius(8)
          .shadow({
            radius: 8,
            color: 'rgba(0, 0, 0, 0.2)',
            offsetX: 0,
            offsetY: 2
          })
          .padding(12)
          .margin(16)
          .scrollBar(BarState.Auto) // 有内容溢出时自动显示滚动条
        }
      }
      .layoutWeight(1)
      
      // 操作按钮区（可选，支持滚动）
      if (this.actionButtons) {
        Scroll() {
          Column() {
            this.actionButtons();
          }
          .width('100%')
          .padding(12)
        }
        .width('100%')
        .layoutWeight(0.4)
        .backgroundColor('#F5F5F5')
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}

