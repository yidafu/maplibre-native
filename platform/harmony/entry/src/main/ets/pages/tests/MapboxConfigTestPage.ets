/**
 * Mapbox 配置测试页面
 * 
 * 测试 Mapbox 配置和 mapbox:// URL 支持
 */
import { MapView, MapLibreMap, MapLibre } from 'maplibre_harmony';
import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { MapboxToken } from '../../entryability/token';

// 定义样式接口
interface MapStyle {
  name: string;
  url: string;
}

@Entry
@Component
struct MapboxConfigTestPage {
  private map: MapLibreMap | null = null;
  @State isMapReady: boolean = false;
  @State currentStyle: string = 'streets-v11';
  @State hasToken: boolean = false;
  @State errorMessage: string = '';

  // Mapbox 样式列表
  private mapboxStyles: MapStyle[] = [
    { name: 'Streets', url: 'mapbox://styles/mapbox/streets-v11' },
    { name: 'Outdoors', url: 'mapbox://styles/mapbox/outdoors-v11' },
    { name: 'Light', url: 'mapbox://styles/mapbox/light-v10' },
    { name: 'Dark', url: 'mapbox://styles/mapbox/dark-v10' },
    { name: 'Satellite', url: 'mapbox://styles/mapbox/satellite-v9' },
    { name: 'Satellite Streets', url: 'mapbox://styles/mapbox/satellite-streets-v11' }
  ];

  aboutToAppear(): void {
    // 检查是否已配置 Mapbox
    try {
      const token: string = MapLibre.getAccessToken();
      const baseUrl: string = MapLibre.getApiBaseURL();
      
      // 检查当前配置是否为 Mapbox
      if (baseUrl.includes('mapbox.com') || baseUrl.includes('mapbox.cn')) {
        if (token && token.length > 0) {
          this.hasToken = true;
          console.info(`✅ Mapbox 已配置 - BaseURL: ${baseUrl}, Token: ${token.substring(0, 10)}...`);
        } else {
          this.errorMessage = '⚠️ Mapbox 已配置但缺少 Access Token';
          console.warn('Mapbox Access Token 未设置');
        }
      } else {
        // 当前不是 Mapbox 配置，自动切换
        console.info(`当前配置: ${baseUrl}，正在切换到 Mapbox...`);
        
        // 切换到 Mapbox 配置
        MapLibre.useMapbox();
        
        // 设置 token（如果有）
        if (MapboxToken && MapboxToken.length > 0) {
          MapLibre.setAccessToken(MapboxToken);
          this.hasToken = true;
          this.errorMessage = `✅ 已切换到 Mapbox 配置 - BaseURL: ${MapLibre.getApiBaseURL()}`;
          console.info('✅ Mapbox 配置完成');
        } else {
          this.errorMessage = '⚠️ 需要在 entry/src/main/ets/entryability/token.ets 中配置 Mapbox Access Token';
          console.warn('Mapbox Token 未配置，请编辑 token.ets 文件');
        }
      }
    } catch (error) {
      const err = error as BusinessError;
      this.errorMessage = `配置检查失败: ${err.message}`;
      console.error('检查 Mapbox 配置失败:', error);
    }
  }

  private switchStyle(styleUrl: string, styleName: string): void {
    if (!this.map || !this.isMapReady) {
      console.warn('地图未就绪');
      return;
    }

    try {
      console.info(`切换样式到: ${styleName} (${styleUrl})`);
      this.map.setStyleUrl(styleUrl);
      this.currentStyle = styleName;
      this.errorMessage = '';
    } catch (error) {
      const err = error as BusinessError;
      this.errorMessage = `切换样式失败: ${err.message}`;
      console.error('切换样式失败:', error);
    }
  }

  private addTerrainDEM(): void {
    if (!this.map || !this.isMapReady) {
      console.warn('地图未就绪');
      return;
    }

    try {
      // 注意：当前版本暂时简化地形功能演示
      // 实际使用时需要通过 Style API 添加 RasterDemSource
      console.info('地形 DEM 功能演示');
      this.errorMessage = '地形 DEM 功能需要通过 RasterDemSource 实现，请参考文档';
    } catch (error) {
      const err = error as BusinessError;
      this.errorMessage = `添加地形失败: ${err.message}`;
      console.error('添加地形 DEM 失败:', error);
    }
  }

  build() {
    Column() {
      // 顶部标题栏
      Row() {
        Button('返回')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 10 })
        
        Text('Mapbox 配置测试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Text('   ') // 占位，保持居中
          .width(60)
      }
      .width('100%')
      .height(50)
      .backgroundColor('#f0f0f0')
      .justifyContent(FlexAlign.SpaceBetween)

      // 配置状态显示
      Column() {
        if (this.hasToken) {
          Row() {
            Text('✅ Mapbox 已配置')
              .fontSize(14)
              .fontColor(Color.Green)
            
            Text(`BaseURL: ${MapLibre.getApiBaseURL()}`)
              .fontSize(12)
              .fontColor(Color.Gray)
              .margin({ left: 10 })
          }
          .padding(10)
        } else {
          Text('⚠️ ' + this.errorMessage)
            .fontSize(14)
            .fontColor(Color.Orange)
            .padding(10)
        }

        if (this.errorMessage && this.hasToken) {
          Text(this.errorMessage)
            .fontSize(12)
            .fontColor(Color.Red)
            .padding({ left: 10, right: 10 })
        }
      }
      .width('100%')
      .backgroundColor('#fff')

      // 地图视图
      MapView({
        styleUrl: 'mapbox://styles/mapbox/streets-v11',
        initialZoom: 6,
        onMapReady: (map: MapLibreMap) => {
          console.info('地图就绪');
          this.map = map;
          this.isMapReady = true;
          
          // 设置初始位置（北京）
          map.setLatLng(39.9042, 116.4074);
          // map.setZoom(10);
        }
      })
        .layoutWeight(1)

      // 底部控制栏
      Column() {
        // 样式选择
        Text('切换样式：')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10, bottom: 5 })
        
        Grid() {
          ForEach(this.mapboxStyles, (style: MapStyle) => {
            GridItem() {
              Button(style.name)
                .fontSize(12)
                .padding({ left: 5, right: 5, top: 5, bottom: 5 })
                .backgroundColor(this.currentStyle === style.name ? Color.Blue : Color.Gray)
                .onClick(() => {
                  this.switchStyle(style.url, style.name);
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(5)
        .columnsGap(5)
        .height(150)
        .padding({ left: 10, right: 10 })

        // 地形测试
        Button('添加地形 DEM')
          .fontSize(14)
          .margin({ top: 10 })
          .onClick(() => {
            this.addTerrainDEM();
          })
          .enabled(this.isMapReady && this.hasToken)
        
        Text('说明：点击按钮测试 mapbox://mapbox.mapbox-terrain-dem-v1')
          .fontSize(10)
          .fontColor(Color.Gray)
          .margin({ top: 5, bottom: 10 })
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#f8f8f8')
    }
    .width('100%')
    .height('100%')
  }

  aboutToDisappear() {
    if (this.map) {
      this.map.destroy();
      this.map = null;
    }
  }
}

