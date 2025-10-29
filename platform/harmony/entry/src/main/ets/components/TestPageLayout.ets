/**
 * TestPageLayout - 统一的测试页面布局组件
 *
 * 提供标准化的测试页面布局：
 * - 顶部标题栏（返回按钮 + 标题）
 * - 地图显示区域（60%高度）
 * - 底部控制区域（40%高度，可滚动）
 * - 统一的布局样式
 *
 * 使用方式：
 * ```ets
 * TestPageLayout({ title: '我的测试页面' }) {
 *   mapArea: this.MapAreaBuilder
 *   controlArea: this.ControlAreaBuilder
 * }
 * ```
 */

import { router } from '@kit.ArkUI';

/**
 * 测试页面布局组件
 */
@Component
export struct TestPageLayout {
  /** 页面标题 */
   title: ResourceStr = '测试页面';
  /** 自定义返回逻辑（可选） */
   onBack?: () => void;
  /** 地图区域内容（由外部传入） */
  @BuilderParam mapArea?: () => void;
  /** 控制区域内容（由外部传入） */
  @BuilderParam controlArea?: () => void;

  aboutToAppear() {
    // 组件初始化逻辑
  }

  build() {
    Column() {
      // 标题栏
      this.TitleBar()

      // 地图区域（60%）
      Stack() {
        if (this.mapArea) {
          this.mapArea()
        }
      }
      .width('100%')
      .layoutWeight(0.6) // 占剩余空间的 60%
      .backgroundColor('#F0F0F0') // 添加默认背景色

      // 控制区（40%，可滚动）
      Scroll() {
        Column({ space: 12 }) {
          if (this.controlArea) {
            this.controlArea()
          }
        }
        .padding({
          left: 12,
          right: 12,
          top: 8,
          bottom: 12
        })
        .width('100%')
      }
      .width('100%')
      .layoutWeight(0.4) // 占剩余空间的 40%
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 标题栏 Builder
   */
  @Builder
  TitleBar() {
    Row() {
      Button('返回', { type: ButtonType.Normal })
        .fontSize(16)
        .backgroundColor(Color.Transparent)
        .fontColor('#2196F3')
        .borderRadius(0)
        .onClick(() => {
          if (this.onBack) {
            this.onBack();
          } else {
            router.back();
          }
        })
        .margin({ left: 12 })

      Text(this.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .margin({ right: 60 })
    }
    .width('100%')
    .height(56)
    .backgroundColor('#F5F5F5')
    .alignItems(VerticalAlign.Center)
  }
}

/**
 * 标准按钮行组件（两个按钮，各48%宽度）
 * 用于在控制区域中快速创建按钮行
 */
@Component
export struct ButtonRow {
  @BuilderParam button1: () => void;
  @BuilderParam button2?: () => void;

  build() {
    Row() {
      if (this.button1) {
        this.button1()
      }

      if (this.button2) {
        this.button2()
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }
}

/**
 * 标准按钮组件（48%宽度）
 * 用于快速创建符合规范的按钮
 */
@Component
export struct StandardButton {
  text: string = '按钮';
  buttonType?: ButtonType = ButtonType.Normal;
  bgColor?: ResourceColor = '#4CAF50';
  textColor?: ResourceColor = Color.White;
  textSize?: number = 16;
  isEnabled?: boolean = true;
  clickHandler?: () => void;
  addLeftMargin?: boolean = false;

  build() {
    Button(this.text)
      .type(this.buttonType)
      .backgroundColor(this.bgColor)
      .fontColor(this.textColor)
      .fontSize(this.textSize)
      .enabled(this.isEnabled)
      .width('48%')
      .margin({ left: this.addLeftMargin ? 8 : 0 })
      .onClick(() => {
        if (this.clickHandler) {
          this.clickHandler();
        }
      })
  }
}

