/**
 * MapLibre Debug Overlay Component
 * Displays real-time debugging information for map loading
 */

import { MapDebugState, StyleLoadingPhase, ResourceInfo, SourceInfo, LayerInfo, AlertInfo } from '../model/DebugState';

@Component
export struct MapDebugOverlay {
  @Link debugState: MapDebugState;
  @State showDetails: boolean = false;
  @State selectedTab: number = 0;
  
  build() {
    if (!this.debugState.enabled) {
      return;
    }
    
    Column() {
      // Header
      this.buildHeader();
      
      // Stats Summary
      this.buildStatsSummary();
      
      // Tab Bar
      if (this.showDetails) {
        this.buildTabBar();
        this.buildTabContent();
      }
    }
    .width('100%')
    .backgroundColor('#f0f0f0aa')
    .padding(8)
    .borderRadius(8)
    .position({ x: 0, y: 0 })
    .zIndex(1000)
  }
  
  @Builder
  buildHeader() {
    Row() {
      Text('MapLibre Debug')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .layoutWeight(1)
      
      Button(this.showDetails ? '▼' : '▶')
        .fontSize(12)
        .width(30)
        .height(30)
        .onClick(() => {
          this.showDetails = !this.showDetails;
        })
      
      Button('✕')
        .fontSize(12)
        .width(30)
        .height(30)
        .margin({ left: 4 })
        .onClick(() => {
          this.debugState.enabled = false;
        })
    }
    .width('100%')
    .padding(4)
  }
  
  @Builder
  buildStatsSummary() {
    Column() {
      // Phase indicator
      Row() {
        Text('Status:')
          .fontSize(12)
          .margin({ right: 8 })
        
        Text(this.debugState.getPhaseString())
          .fontSize(12)
          .fontColor(this.debugState.getStateColor())
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .margin({ top: 8 })
      
      // Progress bar
      if (this.debugState.styleStats) {
        Row() {
          Text(`Progress: ${(this.debugState.styleStats.progress * 100).toFixed(1)}%`)
            .fontSize(12)
            .width('100%')
        }
        .margin({ top: 4 })
        
        Progress({
          value: this.debugState.styleStats.loadedResources,
          total: this.debugState.styleStats.totalResources,
          type: ProgressType.Linear
        })
        .width('100%')
        .color(this.debugState.getStateColor())
        .margin({ top: 4 })
      }
      
      // Quick stats
      if (this.debugState.httpStats || this.debugState.styleStats) {
        Row() {
          if (this.debugState.styleStats) {
            this.buildQuickStat('Resources', 
              `${this.debugState.styleStats.loadedResources}/${this.debugState.styleStats.totalResources}`);
          }
          
          if (this.debugState.httpStats) {
            this.buildQuickStat('HTTP', 
              `${this.debugState.httpStats.successRequests}/${this.debugState.httpStats.totalRequests}`);
            this.buildQuickStat('Success Rate', 
              `${(this.debugState.httpStats.successRate * 100).toFixed(1)}%`);
          }
          
          if (this.debugState.cacheStats) {
            this.buildQuickStat('Cache Hit', 
              `${(this.debugState.cacheStats.hitRate * 100).toFixed(1)}%`);
          }
        }
        .width('100%')
        .margin({ top: 8 })
        .justifyContent(FlexAlign.SpaceAround)
      }
    }
    .width('100%')
    .padding(8)
    .backgroundColor(Color.White)
    .borderRadius(4)
    .margin({ top: 8 })
  }
  
  @Builder
  buildQuickStat(label: string, value: string) {
    Column() {
      Text(label)
        .fontSize(10)
        .fontColor('#666666')
      
      Text(value)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 2 })
    }
  }
  
  @Builder
  buildTabBar() {
    Row() {
      this.buildTab('Resources', 0);
      this.buildTab('Sources', 1);
      this.buildTab('Layers', 2);
      this.buildTab('Alerts', 3);
    }
    .width('100%')
    .margin({ top: 8 })
  }
  
  @Builder
  buildTab(title: string, index: number) {
    Text(title)
      .fontSize(12)
      .padding(8)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.selectedTab === index ? Color.White : Color.Transparent)
      .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Normal)
      .borderRadius(4)
      .onClick(() => {
        this.selectedTab = index;
      })
  }
  
  @Builder
  buildTabContent() {
    Column() {
      if (this.selectedTab === 0) {
        this.buildResourcesTab();
      } else if (this.selectedTab === 1) {
        this.buildSourcesTab();
      } else if (this.selectedTab === 2) {
        this.buildLayersTab();
      } else if (this.selectedTab === 3) {
        this.buildAlertsTab();
      }
    }
    .width('100%')
    .height(200)
    .backgroundColor(Color.White)
    .borderRadius(4)
    .margin({ top: 4 })
    .padding(8)
  }
  
  @Builder
  buildResourcesTab() {
    if (this.debugState.resources.length === 0) {
      Text('No resources loaded yet')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 20 })
        .width('100%')
        .textAlign(TextAlign.Center)
    } else {
      List({ space: 4 }) {
        ForEach(this.debugState.resources, (resource: ResourceInfo, index: number) => {
          ListItem() {
            this.buildResourceItem(resource);
          }
        })
      }
      .width('100%')
      .height('100%')
    }
  }
  
  @Builder
  buildResourceItem(resource: ResourceInfo) {
    Column() {
      Row() {
        Text(resource.type)
          .fontSize(10)
          .fontColor(Color.White)
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .backgroundColor('#1890ff')
          .borderRadius(2)
        
        Text(this.getResourceStateText(resource.state))
          .fontSize(10)
          .fontColor(Color.White)
          .padding({ left: 4, right: 4, top: 2, bottom: 2 })
          .backgroundColor(this.getResourceStateColor(resource.state))
          .borderRadius(2)
          .margin({ left: 4 })
        
        Blank()
        
        if (resource.state === 2) { // Success
          Text(`${(resource.dataSize / 1024).toFixed(1)} KB`)
            .fontSize(10)
            .fontColor('#666666')
          
          Text(`${resource.duration.toFixed(0)} ms`)
            .fontSize(10)
            .fontColor('#666666')
            .margin({ left: 8 })
        }
      }
      .width('100%')
      
      Text(this.getShortUrl(resource.url))
        .fontSize(11)
        .fontColor('#333333')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 4 })
      
      if (resource.error) {
        Text(`Error: ${resource.error}`)
          .fontSize(10)
          .fontColor('#ff4d4f')
          .margin({ top: 2 })
      }
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#f5f5f5')
    .borderRadius(4)
  }
  
  @Builder
  buildSourcesTab() {
    if (this.debugState.sources.length === 0) {
      Text('No sources created yet')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 20 })
        .width('100%')
        .textAlign(TextAlign.Center)
    } else {
      List({ space: 4 }) {
        ForEach(this.debugState.sources, (source: SourceInfo, index: number) => {
          ListItem() {
            this.buildSourceItem(source);
          }
        })
      }
      .width('100%')
      .height('100%')
    }
  }
  
  @Builder
  buildSourceItem(source: SourceInfo) {
    Row() {
      Column() {
        Text(source.id)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
        
        Text(`Type: ${source.type}`)
          .fontSize(10)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      if (source.initialized) {
        Column() {
          Text('Tiles')
            .fontSize(10)
            .fontColor('#666666')
          
          Text(`${source.loadedTiles}/${source.tileCount}`)
            .fontSize(11)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 2 })
        }
      }
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#f5f5f5')
    .borderRadius(4)
  }
  
  @Builder
  buildLayersTab() {
    if (this.debugState.layers.length === 0) {
      Text('No layers created yet')
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 20 })
        .width('100%')
        .textAlign(TextAlign.Center)
    } else {
      List({ space: 4 }) {
        ForEach(this.debugState.layers, (layer: LayerInfo, index: number) => {
          ListItem() {
            this.buildLayerItem(layer);
          }
        })
      }
      .width('100%')
      .height('100%')
    }
  }
  
  @Builder
  buildLayerItem(layer: LayerInfo) {
    Row() {
      Column() {
        Text(layer.id)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
        
        Text(`Type: ${layer.type} | Source: ${layer.sourceId}`)
          .fontSize(10)
          .fontColor('#666666')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      Text(layer.visible ? '👁' : '👁‍🗨')
        .fontSize(16)
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#f5f5f5')
    .borderRadius(4)
  }
  
  @Builder
  buildAlertsTab() {
    if (this.debugState.alerts.length === 0) {
      Text('No alerts')
        .fontSize(12)
        .fontColor('#52c41a')
        .margin({ top: 20 })
        .width('100%')
        .textAlign(TextAlign.Center)
    } else {
      List({ space: 4 }) {
        ForEach(this.debugState.alerts, (alert: AlertInfo, index: number) => {
          ListItem() {
            this.buildAlertItem(alert);
          }
        })
      }
      .width('100%')
      .height('100%')
    }
  }
  
  @Builder
  buildAlertItem(alert: AlertInfo) {
    Column() {
      Row() {
        Text('⚠️')
          .fontSize(14)
        
        Text(alert.type)
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 4 })
      }
      .width('100%')
      
      Text(alert.message)
        .fontSize(10)
        .fontColor('#666666')
        .margin({ top: 4 })
    }
    .width('100%')
    .padding(8)
    .backgroundColor('#fff7e6')
    .borderRadius(4)
    .border({ width: 1, color: '#ffa940' })
  }
  
  private getShortUrl(url: string): string {
    if (url.length <= 50) return url;
    return '...' + url.substring(url.length - 47);
  }
  
  private getResourceStateText(state: number): string {
    switch (state) {
      case 0: return 'Pending';
      case 1: return 'Loading';
      case 2: return 'Success';
      case 3: return 'Failed';
      default: return 'Unknown';
    }
  }
  
  private getResourceStateColor(state: number): string {
    switch (state) {
      case 0: return '#999999';
      case 1: return '#1890ff';
      case 2: return '#52c41a';
      case 3: return '#ff4d4f';
      default: return '#999999';
    }
  }
}

