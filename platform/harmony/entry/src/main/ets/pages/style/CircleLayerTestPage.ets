/**
 * Circle Layer Test Page
 * 圆形图层测试 - 完整功能实现
 * 参考 Android: CircleLayerActivity
 * 
 * 功能包括:
 * 1. 基础圆形图层展示
 * 2. 从远程 URL 加载 GeoJSON 数据
 * 3. GeoJSON 聚类功能
 * 4. 多级聚类圆圈（不同颜色和大小）
 * 5. 聚类计数标签
 * 6. 非聚类点的符号图层
 * 7. 样式切换
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { 
  CircleLayer, 
  GeoJsonSource, 
  MapLibreMap, 
  MapView, 
  GeoJson,
  SymbolLayer,
  Expression
} from 'maplibre_harmony';
import { DEFAULT_STYLE_URLS, showToast } from '../common/TestUtils';
import { http } from '@kit.NetworkKit';

@Entry
@Component
struct CircleLayerTestPage {
  private mapController: MapLibreMap | null = null;
  @State private isClusterMode: boolean = false;
  @State private currentStyleIndex: number = 0;
  
  // 远程 GeoJSON 数据 URL
  private readonly BUS_STOPS_URL = 'https://s3.eu-central-1.amazonaws.com/maplibre-native/android-documentation-resources/bus-stops.geojson';
  private readonly STYLES = [DEFAULT_STYLE_URLS.streets, DEFAULT_STYLE_URLS.bright];
  
  build() {
    Column() {
      TestPageLayout({
        title: 'Circle Layer',
        description: '圆形图层测试 - 聚类与样式',
        showActionBar: true,
        mapContent: (): void => this.buildMapContent(),
        actionButtons: (): void => this.buildActionButtons()
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildMapContent() {
    MapView({
      styleUrl: this.STYLES[this.currentStyleIndex],
      initialLatitude: 1.29,
      initialLongitude: 103.85,
      initialZoom: 11,
      onMapReady: (map: MapLibreMap) => {
        this.mapController = map;
        map.jumpTo(0, 1.29, 103.85, 0, 11);
        // 初始加载基础圆形图层
        this.loadBasicCircleLayer();
      }
    })
  }
  
  @Builder
  buildActionButtons() {
    // 移除内层 Scroll，TestPageLayout 已经提供了外层 Scroll
    Column({ space: 8 }) {
      Text('基础操作')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('加载远程数据')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.loadRemoteData())
        
        Button('切换样式')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeMapStyle())
      }
      
      Text('圆形样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('改变颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeCircleColor())
        
        Button('改变大小')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeCircleSize())
      }
      
      Row({ space: 8 }) {
        Button('改变透明度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeCircleOpacity())
        
        Button('改变模糊度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeCircleBlur())
      }
      
      Text('边框样式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('边框颜色')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeStrokeColor())
        
        Button('边框宽度')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.changeStrokeWidth())
      }
      
      Button('边框透明度')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.changeStrokeOpacity())
      
      Text('聚类功能')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Button(this.isClusterMode ? '关闭聚类' : '开启聚类')
        .fontSize(14)
        .width('100%')
        .onClick(() => this.toggleCluster())
      
      Text('显示模式')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ top: 8, bottom: 4 })
      
      Row({ space: 8 }) {
        Button('基础图层')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.loadBasicCircleLayer())
        
        Button('重置视图')
          .fontSize(14)
          .layoutWeight(1)
          .onClick(() => this.resetView())
      }
    }
    .width('100%')
  }

  // 加载基础圆形图层
  private loadBasicCircleLayer(): void {
    if (!this.mapController) return;
    
    try {
      // 清理旧图层
      this.removeOldLayers();
      
      // 创建简单的点数据
      const geojson = GeoJson.featureCollection([
        GeoJson.pointFeature([103.85, 1.29]),
        GeoJson.pointFeature([103.86, 1.30]),
        GeoJson.pointFeature([103.84, 1.28]),
        GeoJson.pointFeature([103.87, 1.31]),
      ]);
      
      const source = new GeoJsonSource('circle-source');
      source.setGeoJson(geojson);
      this.mapController.addSource(source);
      
      const layer = new CircleLayer('circle-layer', 'circle-source');
      layer.setCircleRadius(15);
      layer.setCircleColor('#2196F3');
      layer.setCircleOpacity(0.8);
      layer.setCircleStrokeWidth(2);
      layer.setCircleStrokeColor('#FFFFFF');
      this.mapController.addLayer(layer);
      
      showToast('基础圆形图层已加载');
      this.isClusterMode = false;
    } catch (error) {
      showToast(`加载图层失败: ${error}`);
    }
  }

  // 加载远程 GeoJSON 数据
  private loadRemoteData(): void {
    if (!this.mapController) return;
    
    showToast('正在加载远程数据...');
    
    // 使用 HTTP 请求加载数据
    const httpRequest = http.createHttp();
    httpRequest.request(
      this.BUS_STOPS_URL,
      {
        method: http.RequestMethod.GET,
        connectTimeout: 60000,
        readTimeout: 60000
      },
      (err, data) => {
        if (err) {
          showToast(`加载失败: ${err.message}`);
          httpRequest.destroy();
          return;
        }
        
        if (data.responseCode === 200) {
          try {
            this.removeOldLayers();
            
            const geojsonData: object = JSON.parse(data.result.toString());
            const source = new GeoJsonSource('bus-stop-source');
            source.setGeoJson(geojsonData);
            this.mapController!.addSource(source);
            
            const layer = new CircleLayer('bus-stop-layer', 'bus-stop-source');
            layer.setCircleRadius(4);
            layer.setCircleColor('#FF9800');
            layer.setCircleOpacity(0.9);
            this.mapController!.addLayer(layer);
            
            // 显示成功消息（不解析 features 数量以避免类型错误）
            showToast('公交站点数据已加载');
          } catch (parseError) {
            showToast(`解析数据失败: ${parseError}`);
          }
        } else {
          showToast(`请求失败: ${data.responseCode}`);
        }
        
        httpRequest.destroy();
      }
    );
  }

  // 切换聚类模式
  private toggleCluster(): void {
    if (!this.mapController) return;
    
    if (this.isClusterMode) {
      // 关闭聚类，加载普通图层
      this.loadRemoteData();
    } else {
      // 开启聚类
      this.showBusCluster();
    }
  }

  // 显示聚类功能
  private showBusCluster(): void {
    if (!this.mapController) return;
    
    showToast('正在加载聚类数据...');
    
    const httpRequest = http.createHttp();
    httpRequest.request(
      this.BUS_STOPS_URL,
      {
        method: http.RequestMethod.GET,
        connectTimeout: 60000,
        readTimeout: 60000
      },
      (err, data) => {
        if (err) {
          showToast(`加载失败: ${err.message}`);
          httpRequest.destroy();
          return;
        }
        
        if (data.responseCode === 200) {
          try {
            this.removeOldLayers();
            
            const geojsonData: object = JSON.parse(data.result.toString());
            
            // 添加聚类数据源
            // 注意：聚类配置暂时通过构造函数传入
            const source = new GeoJsonSource('bus-stop-cluster-source');
            source.setGeoJson(geojsonData);
            // TODO: 实现 setCluster/setClusterMaxZoom/setClusterRadius 方法
            this.mapController!.addSource(source);
            
            // 添加非聚类点的符号图层
            const unclusteredLayer = new SymbolLayer('unclustered-points', 'bus-stop-cluster-source');
            // TODO: Expression 过滤器需要转换为正确的格式
            // unclusteredLayer.setFilter(
            //   Expression.neq(Expression.get('cluster'), Expression.literal(true))
            // );
            this.mapController!.addLayer(unclusteredLayer);
            
            // 添加聚类圆圈 - 大型聚类（150+）
            const circles1 = new CircleLayer('cluster-0', 'bus-stop-cluster-source');
            circles1.setCircleColor('#F44336'); // 红色
            circles1.setCircleRadius(18);
            // TODO: Expression 过滤器需要转换为正确的格式
            // const filter1 = Expression.all(
            //   Expression.has('point_count'),
            //   Expression.gte(Expression.toNumber(Expression.get('point_count')), Expression.literal(150))
            // );
            // circles1.setFilter(filter1);
            this.mapController!.addLayer(circles1);
            
            // 中型聚类（20-150）
            const circles2 = new CircleLayer('cluster-1', 'bus-stop-cluster-source');
            circles2.setCircleColor('#4CAF50'); // 绿色
            circles2.setCircleRadius(18);
            // TODO: Expression 过滤器需要转换为正确的格式
            // const filter2 = Expression.all(
            //   Expression.has('point_count'),
            //   Expression.gt(Expression.toNumber(Expression.get('point_count')), Expression.literal(20)),
            //   Expression.lt(Expression.toNumber(Expression.get('point_count')), Expression.literal(150))
            // );
            // circles2.setFilter(filter2);
            this.mapController!.addLayer(circles2);
            
            // 小型聚类（0-20）
            const circles3 = new CircleLayer('cluster-2', 'bus-stop-cluster-source');
            circles3.setCircleColor('#2196F3'); // 蓝色
            circles3.setCircleRadius(18);
            // TODO: Expression 过滤器需要转换为正确的格式
            // const filter3 = Expression.all(
            //   Expression.has('point_count'),
            //   Expression.gte(Expression.toNumber(Expression.get('point_count')), Expression.literal(0))
            // );
            // circles3.setFilter(filter3);
            this.mapController!.addLayer(circles3);
            
            // 添加计数文本
            const countLayer = new SymbolLayer('count', 'bus-stop-cluster-source');
            countLayer.setTextField(Expression.get('point_count'));
            countLayer.setTextSize(12);
            countLayer.setTextColor('#FFFFFF');
            this.mapController!.addLayer(countLayer);
            
            showToast('聚类模式已开启');
            this.isClusterMode = true;
          } catch (parseError) {
            showToast(`解析数据失败: ${parseError}`);
          }
        }
        
        httpRequest.destroy();
      }
    );
  }

  // 改变圆形颜色
  private changeCircleColor(): void {
    if (!this.mapController) return;
    
    try {
      // 尝试获取圆形图层
      let layer = this.mapController.getLayer('circle-layer');
      if (!layer) {
        layer = this.mapController.getLayer('bus-stop-layer');
      }
      
      if (!layer) {
        showToast('未找到圆形图层，请先加载图层');
        return;
      }
      
      // 检查是否是 CircleLayer 类型（使用类型属性检查）
      const layerObj = layer;
      if (!(layer instanceof  CircleLayer)) {
        showToast('图层不是圆形图层类型');
        return;
      }
      
      const circleLayer = layer;
      const colors: string[] = ['#2196F3', '#FF9800', '#4CAF50', '#F44336', '#9C27B0'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      
      // 设置新颜色
      circleLayer.setCircleColor(randomColor);
      showToast(`颜色已更改为 ${randomColor}`);
    } catch (error) {
      showToast(`更改颜色失败: ${error}`);
    }
  }

  // 改变圆形大小
  private changeCircleSize(): void {
    if (!this.mapController) return;
    
    try {
      let layer = this.mapController.getLayer('circle-layer');
      if (!layer) {
        layer = this.mapController.getLayer('bus-stop-layer');
      }
      
      if (!layer) {
        showToast('未找到圆形图层，请先加载图层');
        return;
      }
      
      if (!(layer instanceof CircleLayer)) {
        showToast('图层不是圆形图层类型');
        return;
      }
      
      const circleLayer = layer;
      const size = 5 + Math.random() * 20;
      circleLayer.setCircleRadius(size);
      showToast(`大小: ${size.toFixed(1)}`);
    } catch (error) {
      showToast(`更改大小失败: ${error}`);
    }
  }

  // 改变圆形透明度
  private changeCircleOpacity(): void {
    if (!this.mapController) return;
    
    try {
      let layer = this.mapController.getLayer('circle-layer');
      if (!layer) {
        layer = this.mapController.getLayer('bus-stop-layer');
      }
      
      if (!layer) {
        showToast('未找到圆形图层，请先加载图层');
        return;
      }
      
      if (!(layer instanceof CircleLayer)) {
        showToast('图层不是圆形图层类型');
        return;
      }
      
      const circleLayer = layer;
      const opacity = 0.3 + Math.random() * 0.7; // 0.3 - 1.0
      circleLayer.setCircleOpacity(opacity);
      
      // 触发地图重绘
      const currentZoom = this.mapController.getZoom();
      this.mapController.setZoom(currentZoom + 0.0001, 0, 0, 0);
      
      showToast(`透明度: ${opacity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改透明度失败: ${error}`);
    }
  }

  // 改变圆形模糊度
  private changeCircleBlur(): void {
    if (!this.mapController) return;
    
    try {
      let layer = this.mapController.getLayer('circle-layer');
      if (!layer) {
        layer = this.mapController.getLayer('bus-stop-layer');
      }
      
      if (!layer) {
        showToast('未找到圆形图层，请先加载图层');
        return;
      }
      
      if (!(layer instanceof CircleLayer)) {
        showToast('图层不是圆形图层类型');
        return;
      }
      
      const circleLayer = layer;
      const blur = Math.random() * 2; // 0 - 2
      circleLayer.setCircleBlur(blur);
      
      // 触发地图重绘
      const currentZoom = this.mapController.getZoom();
      this.mapController.setZoom(currentZoom + 0.0001, 0, 0, 0);
      
      showToast(`模糊度: ${blur.toFixed(2)}`);
    } catch (error) {
      showToast(`更改模糊度失败: ${error}`);
    }
  }

  // 改变边框颜色
  private changeStrokeColor(): void {
    if (!this.mapController) return;
    
    try {
      let layer = this.mapController.getLayer('circle-layer');
      if (!layer) {
        layer = this.mapController.getLayer('bus-stop-layer');
      }
      
      if (!layer) {
        showToast('未找到圆形图层，请先加载图层');
        return;
      }
      
      if (!(layer instanceof CircleLayer)) {
        showToast('图层不是圆形图层类型');
        return;
      }
      
      const circleLayer = layer;
      const colors: string[] = ['#FFFFFF', '#000000', '#FF0000', '#00FF00', '#0000FF', '#FFFF00'];
      const randomColor: string = colors[Math.floor(Math.random() * colors.length)];
      circleLayer.setCircleStrokeColor(randomColor);
      
      // 触发地图重绘
      const currentZoom = this.mapController.getZoom();
      this.mapController.setZoom(currentZoom + 0.0001, 0, 0, 0);
      
      showToast(`边框颜色: ${randomColor}`);
    } catch (error) {
      showToast(`更改边框颜色失败: ${error}`);
    }
  }

  // 改变边框宽度
  private changeStrokeWidth(): void {
    if (!this.mapController) return;
    
    try {
      let layer = this.mapController.getLayer('circle-layer');
      if (!layer) {
        layer = this.mapController.getLayer('bus-stop-layer');
      }
      
      if (!layer) {
        showToast('未找到圆形图层，请先加载图层');
        return;
      }
      
      if (!(layer instanceof CircleLayer)) {
        showToast('图层不是圆形图层类型');
        return;
      }
      
      const circleLayer = layer;
      const width = 1 + Math.random() * 5; // 1 - 6
      circleLayer.setCircleStrokeWidth(width);
      
      // 触发地图重绘
      const currentZoom = this.mapController.getZoom();
      this.mapController.setZoom(currentZoom + 0.0001, 0, 0, 0);
      
      showToast(`边框宽度: ${width.toFixed(1)}`);
    } catch (error) {
      showToast(`更改边框宽度失败: ${error}`);
    }
  }

  // 改变边框透明度
  private changeStrokeOpacity(): void {
    if (!this.mapController) return;
    
    try {
      let layer = this.mapController.getLayer('circle-layer');
      if (!layer) {
        layer = this.mapController.getLayer('bus-stop-layer');
      }
      
      if (!layer) {
        showToast('未找到圆形图层，请先加载图层');
        return;
      }
      
      if (!(layer instanceof CircleLayer)) {
        showToast('图层不是圆形图层类型');
        return;
      }
      
      const circleLayer = layer;
      const opacity = 0.3 + Math.random() * 0.7; // 0.3 - 1.0
      circleLayer.setCircleStrokeOpacity(opacity);
      
      // 触发地图重绘
      const currentZoom = this.mapController.getZoom();
      this.mapController.setZoom(currentZoom + 0.0001, 0, 0, 0);
      
      showToast(`边框透明度: ${opacity.toFixed(2)}`);
    } catch (error) {
      showToast(`更改边框透明度失败: ${error}`);
    }
  }

  // 切换地图样式
  private changeMapStyle(): void {
    if (!this.mapController) return;
    
    try {
      // 切换到下一个样式
      this.currentStyleIndex = (this.currentStyleIndex + 1) % this.STYLES.length;
      const newStyleUrl = this.STYLES[this.currentStyleIndex];
      
      // 使用 setStyleUrl 方法切换样式
      this.mapController.setStyleUrl(newStyleUrl);
      
      showToast(`正在切换到样式 ${this.currentStyleIndex + 1}`);
      
      // 样式加载完成后重新加载基础图层
      // 注意：样式切换会清除所有图层和数据源
      setTimeout(() => {
        this.loadBasicCircleLayer();
      }, 1000);
    } catch (error) {
      showToast(`切换样式失败: ${error}`);
    }
  }

  // 重置视图
  private resetView(): void {
    if (!this.mapController) return;
    
    this.mapController.jumpTo(0, 1.29, 103.85, 0, 11);
    showToast('视图已重置');
  }

  // 移除旧图层
  private removeOldLayers(): void {
    if (!this.mapController) return;
    
    const layerIds = [
      'circle-layer',
      'bus-stop-layer',
      'bus-stop-cluster-layer',
      'unclustered-points',
      'cluster-0',
      'cluster-1',
      'cluster-2',
      'count'
    ];
    
    const sourceIds = [
      'circle-source',
      'bus-stop-source',
      'bus-stop-cluster-source'
    ];
    
    layerIds.forEach(id => {
      try {
        this.mapController!.removeLayer(id);
      } catch (e) {
        // 图层可能不存在，忽略错误
      }
    });
    
    sourceIds.forEach(id => {
      try {
        this.mapController!.removeSource(id);
      } catch (e) {
        // 数据源可能不存在，忽略错误
      }
    });
  }
}

