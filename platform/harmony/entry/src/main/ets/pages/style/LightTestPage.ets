import { maplibre, MapLibreMap, MapView , NativeMapView} from 'maplibre_harmony';
/**
 * LightTestPage - 光照系统测试页面
 * 
 * 测试接口：
 * - getLight() - 获取光照配置
 */

import { TestPageLayout } from '../common/TestPageLayout';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

@Entry
@Component
struct LightTestPage {
  private scroller: Scroller = new Scroller();
  @State statusMessage: string = '等待操作...';
  @State mapReady: boolean = false;
  @State lightInfo: string = '';
  
  private mapView: NativeMapView | null = null;

  /**
   * 地图区域构建器
   */
  @Builder
  buildMapContent() {
    MapView({
      styleUrl: 'https://demotiles.maplibre.org/style.json',
      initialLatitude: 39.9,
      initialLongitude: 116.4,
      initialZoom: 5,
      initialBearing: 0,
      initialPitch: 0, // 设置倾斜角以更好地观察光照效果
      onMapReady: (map: MapLibreMap) => {
        this.onMapReady(map);
      }
    })
  }

  /**
   * 控制区域构建器
   */
  @Builder
  buildActionButtons() {
    Scroll(this.scroller) {
      Column({ space: 8 }) {
      // 状态信息
          Text(this.statusMessage)
      .fontSize(14)
      .width('100%')
      .padding(12)
      .backgroundColor('#F8F8F8')
      .borderRadius(4)
    
          // 光照信息显示
          if (this.lightInfo) {
      Text(this.lightInfo)
        .fontSize(12)
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF3E0')
        .borderRadius(4)
        .fontColor('#E65100')
        .maxLines(15)
          }
    
          // 光照测试
          Text('光照系统测试')
      .fontSize(16)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
          Button('获取光照信息')
      .width('100%')
      .onClick(() => {
        this.getLightInfo();
      })
      .enabled(this.mapReady)
    
          Button('刷新光照配置')
      .width('100%')
      .onClick(() => {
        this.refreshLight();
      })
      .enabled(this.mapReady)
    
          Divider()
    
          // 功能说明
          Text('功能说明')
      .fontSize(14)
      .fontWeight(FontWeight.Bold)
      .width('100%')
    
          Text('光照系统控制3D建筑和地形的光照效果：\n\n' +
      '• Anchor: 光照参照系（视口/地图）\n' +
      '• Position: 光照位置（方位角、极角、距离）\n' +
      '• Color: 光照颜色\n' +
      '• Intensity: 光照强度')
      .fontSize(12)
      .width('100%')
      .fontColor('#666666')
      }
      .width('100%')
      .padding(8)
    }
    .scrollBar(BarState.Auto)
    .scrollable(ScrollDirection.Vertical)
  
  }

  build() {
    Column() {
      TestPageLayout({
        showActionBar: true,
        title: '光照系统测试',
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 地图就绪回调
   */
  private onMapReady(map?: MapLibreMap): void {
    if (this.mapView) {
      this.mapView = this.mapView;
      this.mapReady = true;
      this.statusMessage = '✅ 地图加载成功';
      // 自动获取光照信息
      setTimeout(() => {
        this.getLightInfo();
      }, 1000);
      hilog.info(DOMAIN, 'LightTestPage', 'Map ready');
    }
  }

  /**
   * 获取光照信息
   */
  private getLightInfo(): void {
    if (!this.mapView) return;
    
    try {
      const light: Record<string, Object> = this.mapView.getLight() as Record<string, Object>;
      
      if (light) {
        // 解析光照属性
        let info = '光照配置信息:\n\n';
        
        // Anchor（参照系）
        const anchor = light.anchor as string | undefined;
        if (anchor !== undefined) {
          info += `Anchor: ${anchor}\n`;
          info += `  (${anchor === 'map' ? '地图' : '视口'}参照系)\n\n`;
        }
        
        // Position（位置）
        const position = light.position as number[] | undefined;
        if (position) {
          info += `Position:\n`;
          if (Array.isArray(position) && position.length >= 3) {
            info += `  方位角: ${position[0]}°\n`;
            info += `  极角: ${position[1]}°\n`;
            info += `  距离: ${position[2]}\n\n`;
          } else {
            info += `  ${JSON.stringify(position)}\n\n`;
          }
        }
        
        // Color（颜色）
        const color = light.color as string | undefined;
        if (color !== undefined) {
          info += `Color: ${color}\n\n`;
        }
        
        // Intensity（强度）
        const intensity = light.intensity as number | undefined;
        if (intensity !== undefined) {
          info += `Intensity: ${intensity}\n\n`;
        }
        
        // 其他属性
        const otherProps = Object.keys(light).filter(
          key => !['anchor', 'position', 'color', 'intensity'].includes(key)
        );
        
        if (otherProps.length > 0) {
          info += '其他属性:\n';
          otherProps.forEach((key: string) => {
            const value: Object = light[key] as Object;
            info += `  ${key}: ${JSON.stringify(value)}\n`;
          });
        }
        
        this.lightInfo = info;
        this.statusMessage = '✅ 已获取光照信息';
        
        hilog.info(DOMAIN, 'LightTestPage', `Light info: ${JSON.stringify(light)}`);
      } else {
        this.lightInfo = '⚠️ 当前样式没有光照配置';
        this.statusMessage = '获取完成（无光照配置）';
      }
    } catch (error) {
      this.statusMessage = `❌ 获取失败: ${error.message}`;
      hilog.error(DOMAIN, 'LightTestPage', `Failed to get light: ${error.message}`);
    }
  }

  /**
   * 刷新光照配置
   */
  private refreshLight(): void {
    if (!this.mapView) return;
    
    try {
      // 触发重绘
      this.mapView.triggerRepaint();
      
      // 延迟重新获取
      setTimeout(() => {
        this.getLightInfo();
      }, 300);
      
      this.statusMessage = '🔄 正在刷新光照配置...';
      
      hilog.info(DOMAIN, 'LightTestPage', 'Refreshing light configuration');
    } catch (error) {
      this.statusMessage = `❌ 刷新失败: ${error.message}`;
      hilog.error(DOMAIN, 'LightTestPage', `Failed to refresh: ${error.message}`);
    }
  }
}

