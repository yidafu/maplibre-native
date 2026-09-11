/**
 * TestPageLayout - Unified test page layout component.
 *
 * Provides a consistent structure for all test pages:
 * - Title bar with back button
 * - Map content area (full remaining space)
 * - Optional floating control panel
 * - Optional control footer at the bottom
 */

import { router } from '@kit.ArkUI';

@Component
export struct TestPageLayout {
  // Page title displayed in the header bar
  @Prop title: string = 'Test Page';

  // Optional subtitle displayed below the title
  @Prop subtitle: string = '';

  // Show the control footer area at the bottom
  @Prop showControlFooter: boolean = false;

  // Map content builder (required)
  @BuilderParam mapContent: () => void = this.defaultMapContent;

  // Floating control panel builder (optional, shown on top of map)
  @BuilderParam controlPanel?: () => void;

  // Control footer builder (optional, shown at bottom)
  @BuilderParam controlFooter?: () => void;

  // Control panel visibility state
  @State private isControlPanelVisible: boolean = true;

  @Builder
  defaultMapContent() {
    Column() {
      Text('Map content area')
        .fontSize(14)
        .fontColor('#999')
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F0F0F0')
  }

  build() {
    Column() {
      // ===== Title Bar =====
      Row() {
        // Back button
        Button({ type: ButtonType.Normal }) {
          Text('←')
            .fontSize(22)
            .fontColor(Color.White)
        }
        .backgroundColor(Color.Transparent)
        .width(44)
        .height(44)
        .onClick(() => {
          router.back();
        })

        Column() {
          Text(this.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .lineHeight(22)

          if (this.subtitle) {
            Text(this.subtitle)
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.8)')
              .margin({ top: 1 })
              .lineHeight(16)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        .margin({ left: 4 })

        // Toggle control panel button
        if (this.controlPanel) {
          Button({ type: ButtonType.Normal }) {
            Text(this.isControlPanelVisible ? '▼' : '▲')
              .fontSize(18)
              .fontColor(Color.White)
          }
          .backgroundColor(Color.Transparent)
          .width(44)
          .height(44)
          .onClick(() => {
            this.isControlPanelVisible = !this.isControlPanelVisible;
          })
        }
      }
      .width('100%')
      .height(56)
      .backgroundColor('#2196F3')
      .padding({ left: 4, right: 4 })

      // ===== Main Content Area =====
      Stack({ alignContent: Alignment.TopStart }) {
        // Map content fills the entire area
        Column() {
          this.mapContent();
        }
        .width('100%')
        .height('100%')

        // Floating control panel overlay
        if (this.controlPanel && this.isControlPanelVisible) {
          Column() {
            Blank()
              .layoutWeight(1)

            Scroll() {
              Column() {
                this.controlPanel();
              }
              .width('100%')
            }
            .backgroundColor(Color.White)
            .borderRadius({ topLeft: 12, topRight: 12 })
            .shadow({
              radius: 12,
              color: 'rgba(0, 0, 0, 0.15)',
              offsetX: 0,
              offsetY: -2,
            })
            .padding(16)
            .scrollBar(BarState.Auto)
            .constraintSize({ maxHeight: '60%' })
          }
          .width('100%')
          .height('100%')
          .padding({ bottom: 16 })
          .hitTestBehavior(HitTestMode.Transparent)
        }
      }
      .layoutWeight(1)

      // ===== Control Footer =====
      if (this.showControlFooter) {
        Scroll() {
          Column() {
            if (this.controlFooter) {
              this.controlFooter();
            }
          }
          .width('100%')
          .padding(12)
        }
        .width('100%')
        .constraintSize({ maxHeight: '35%' })
        .backgroundColor('#F8F8F8')
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
