/**
 * MapLibre Native for HarmonyOS
 * 测试页面导航首页
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';

const DOMAIN = 0x0000;

// 测试页面配置
class TestPageItem {
  title: string = '';
  description: string = '';
  route: string = '';
  icon: string = '';
  
  constructor(title: string, description: string, route: string, icon: string) {
    this.title = title;
    this.description = description;
    this.route = route;
    this.icon = icon;
  }
}

@Entry
@Component
struct Index {
  // 测试页面列表
  private testPages: TestPageItem[] = [
    new TestPageItem(
      '基础地图测试',
      '测试地图渲染、标记添加、相机跳转等基础功能',
      'pages/BasicMapPage',
      '🗺️'
    ),
    new TestPageItem(
      '手势系统测试',
      '测试平移、缩放、旋转等手势功能和惯性动画',
      'pages/GestureTestPage',
      '👆'
    ),
    new TestPageItem(
      'Marker 功能测试',
      '测试 Marker 添加、删除、事件、动画、拖拽、InfoWindow 等完整功能',
      'pages/MarkerTestPage',
      '📍'
    ),
    new TestPageItem(
      'Style 样式测试',
      '测试地图样式切换、图层、数据源等 Style API 功能',
      'pages/StyleTestPage',
      '🎨'
    ),
  ];

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('MapLibre Native for HarmonyOS')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width('100%')
      .height(80)
      .backgroundColor('#2196F3')
      .justifyContent(FlexAlign.Center)
      .padding({ top: 20 })

      // 副标题
      Column() {
        Text('测试页面导航')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 10, bottom: 5 })

        Text('选择一个测试页面开始')
          .fontSize(14)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(15)

      // 测试页面列表
      List({ space: 15 }) {
        ForEach(this.testPages, (item: TestPageItem) => {
          ListItem() {
            this.buildTestPageCard(item)
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 15, right: 15 })

      // 底部信息
      Column() {
        Text('MapLibre Native v1.0.0')
          .fontSize(12)
          .fontColor('#999999')
          .margin({ bottom: 5 })

        Text('HarmonyOS 平台适配版本')
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  buildTestPageCard(item: TestPageItem) {
    Column() {
      Row() {
        // 图标
        Text(item.icon)
          .fontSize(32)
          .margin({ right: 15 })

        // 文字信息
        Column() {
          Text(item.title)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 5 })

          Text(item.description)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 箭头
        Text('›')
          .fontSize(28)
          .fontColor('#CCCCCC')
          .margin({ left: 10 })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .backgroundColor('#FAFAFA')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: 'rgba(0, 0, 0, 0.1)',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      this.navigateToPage(item.route);
    })
  }

  /**
   * 导航到指定页面
   */
  private navigateToPage(route: string): void {
    hilog.info(DOMAIN, 'Index', `Attempting to navigate to: ${route}`);
    
    // 直接使用 pushUrl，不使用命名路由
    router.pushUrl({
      url: route
    }).then(() => {
      hilog.info(DOMAIN, 'Index', `Successfully navigated to: ${route}`);
    }).catch((err: Error) => {
      hilog.error(DOMAIN, 'Index', `Navigation failed: ${err.message}`);
      console.error(`Navigation error: ${err.message}`);
    });
  }
}

