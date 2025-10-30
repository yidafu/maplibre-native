/**
 * ScaleBarView - 比例尺组件
 * 
 * 参考 Android 和 iOS MLNScaleBar 实现
 * 根据缩放级别和纬度动态显示地图比例
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';

// 常量定义
const METERS_PER_FOOT = 0.3048;
const FEET_PER_METER = 3.28084;
const MIN_BAR_WIDTH_DP = 30;
const BAR_HEIGHT_DP = 4;

/**
 * 比例尺单位系统
 */
export enum ScaleBarUnit {
  Metric = 0,    // 公制（米/千米）
  Imperial = 1   // 英制（英尺/英里）
}

/**
 * 比例尺显示行配置
 */
interface ScaleBarRow {
  distance: number;      // 显示的距离
  numberOfBars: number;  // 条数
  label: string;         // 显示文本
}

@Component
export struct ScaleBarView {
  // 是否启用
  @Prop isEnabled: boolean = true;
  
  // 每个像素代表的米数（由外部传入）
  @Prop @Watch('onMetersPerPixelChanged') metersPerPixel: number = 0;
  
  // 单位系统
  @Prop unitSystem: ScaleBarUnit = ScaleBarUnit.Metric;
  
  // 是否使用深色样式
  @Prop useDarkStyles: boolean = false;
  
  // 主色和次色
  @Prop primaryColor: string = '#122D11';
  @Prop secondaryColor: string = '#F7F7F7';
  
  // 最大宽度（像素）
  @Prop maxWidth: number = 200;
  
  // 当前计算出的比例尺行
  @State private currentRow: ScaleBarRow | null = null;
  
  // 条形宽度
  @State private barWidth: number = 0;
  
  /**
   * 监听 metersPerPixel 变化
   */
  onMetersPerPixelChanged(): void {
    hilog.info(DOMAIN, 'ScaleBarView', `metersPerPixel changed: ${this.metersPerPixel}`);
    this.recalculate();
  }
  
  /**
   * 组件初始化
   */
  aboutToAppear(): void {
    hilog.info(DOMAIN, 'ScaleBarView', `Component initialized, isEnabled: ${this.isEnabled}, metersPerPixel: ${this.metersPerPixel}`);
    this.recalculate();
  }
  
  /**
   * 更新比例尺
   * @param metersPerPixel 每像素米数
   */
  update(metersPerPixel: number): void {
    this.metersPerPixel = metersPerPixel;
    this.recalculate();
  }
  
  /**
   * 重新计算比例尺
   */
  private recalculate(): void {
    hilog.info(DOMAIN, 'ScaleBarView', `recalculate: metersPerPixel=${this.metersPerPixel}, isEnabled=${this.isEnabled}`);
    
    if (this.metersPerPixel <= 0 || !this.isEnabled) {
      hilog.warn(DOMAIN, 'ScaleBarView', `recalculate: Cannot display - metersPerPixel=${this.metersPerPixel}, isEnabled=${this.isEnabled}`);
      this.currentRow = null;
      return;
    }
    
    const unitsPerPixel = this.unitSystem === ScaleBarUnit.Metric 
      ? this.metersPerPixel 
      : this.metersPerPixel * FEET_PER_METER;
    
    const maxDistance = this.maxWidth * unitsPerPixel;
    
    hilog.info(DOMAIN, 'ScaleBarView', `recalculate: unitsPerPixel=${unitsPerPixel}, maxDistance=${maxDistance}`);
    
    // 选择合适的比例尺行
    const row = this.selectPreferredRow(maxDistance);
    
    if (row) {
      // 计算实际宽度
      const actualWidth = row.distance / unitsPerPixel;
      
      hilog.info(DOMAIN, 'ScaleBarView', `recalculate: Selected row - distance=${row.distance}, bars=${row.numberOfBars}, actualWidth=${actualWidth}`);
      
      if (actualWidth >= MIN_BAR_WIDTH_DP) {
        this.currentRow = row;
        // 计算每个条的宽度
        this.barWidth = Math.floor(actualWidth / row.numberOfBars);
        hilog.info(DOMAIN, 'ScaleBarView', `recalculate: ✅ ScaleBar configured - barWidth=${this.barWidth}, label=${row.label}`);
      } else {
        hilog.warn(DOMAIN, 'ScaleBarView', `recalculate: actualWidth ${actualWidth} < MIN_BAR_WIDTH_DP ${MIN_BAR_WIDTH_DP}`);
        this.currentRow = null;
      }
    } else {
      hilog.warn(DOMAIN, 'ScaleBarView', `recalculate: No suitable row found for maxDistance=${maxDistance}`);
      this.currentRow = null;
    }
  }
  
  /**
   * 选择合适的比例尺行
   * @param maxDistance 最大距离
   */
  private selectPreferredRow(maxDistance: number): ScaleBarRow | null {
    const rows = this.getPredefinedRows();
    
    // 找到第一个小于等于最大距离的行
    for (const row of rows) {
      if (row.distance <= maxDistance) {
        return row;
      }
    }
    
    return null;
  }
  
  /**
   * 获取预定义的比例尺行
   */
  private getPredefinedRows(): ScaleBarRow[] {
    if (this.unitSystem === ScaleBarUnit.Metric) {
      // 公制（米/千米）
      return [
        // 千米级别
        { distance: 200000, numberOfBars: 4, label: '200 km' },
        { distance: 100000, numberOfBars: 4, label: '100 km' },
        { distance: 50000, numberOfBars: 5, label: '50 km' },
        { distance: 20000, numberOfBars: 4, label: '20 km' },
        { distance: 10000, numberOfBars: 4, label: '10 km' },
        { distance: 5000, numberOfBars: 5, label: '5 km' },
        { distance: 2000, numberOfBars: 4, label: '2 km' },
        { distance: 1000, numberOfBars: 4, label: '1 km' },
        // 米级别
        { distance: 500, numberOfBars: 5, label: '500 m' },
        { distance: 200, numberOfBars: 4, label: '200 m' },
        { distance: 100, numberOfBars: 4, label: '100 m' },
        { distance: 50, numberOfBars: 5, label: '50 m' },
        { distance: 20, numberOfBars: 4, label: '20 m' },
        { distance: 10, numberOfBars: 4, label: '10 m' },
        { distance: 5, numberOfBars: 5, label: '5 m' },
        { distance: 2, numberOfBars: 4, label: '2 m' },
        { distance: 1, numberOfBars: 4, label: '1 m' },
      ];
    } else {
      // 英制（英尺/英里）
      const FEET_PER_MILE = 5280;
      return [
        // 英里级别
        { distance: 100 * FEET_PER_MILE, numberOfBars: 4, label: '100 mi' },
        { distance: 50 * FEET_PER_MILE, numberOfBars: 5, label: '50 mi' },
        { distance: 20 * FEET_PER_MILE, numberOfBars: 4, label: '20 mi' },
        { distance: 10 * FEET_PER_MILE, numberOfBars: 4, label: '10 mi' },
        { distance: 5 * FEET_PER_MILE, numberOfBars: 5, label: '5 mi' },
        { distance: 2 * FEET_PER_MILE, numberOfBars: 4, label: '2 mi' },
        { distance: 1 * FEET_PER_MILE, numberOfBars: 4, label: '1 mi' },
        // 英尺级别
        { distance: 5000, numberOfBars: 5, label: '5000 ft' },
        { distance: 2000, numberOfBars: 4, label: '2000 ft' },
        { distance: 1000, numberOfBars: 4, label: '1000 ft' },
        { distance: 500, numberOfBars: 5, label: '500 ft' },
        { distance: 200, numberOfBars: 4, label: '200 ft' },
        { distance: 100, numberOfBars: 4, label: '100 ft' },
        { distance: 50, numberOfBars: 5, label: '50 ft' },
        { distance: 20, numberOfBars: 4, label: '20 ft' },
        { distance: 10, numberOfBars: 4, label: '10 ft' },
      ];
    }
  }
  
  /**
   * 获取条的颜色
   */
  private getBarColor(index: number): string {
    return index % 2 === 0 ? this.primaryColor : this.secondaryColor;
  }
  
  /**
   * 获取文本颜色（带描边效果）
   */
  private getTextColor(): string {
    return this.useDarkStyles ? '#FFFFFF' : '#000000';
  }
  
  /**
   * 获取文本描边颜色
   */
  private getTextStrokeColor(): string {
    return this.useDarkStyles ? '#000000' : '#FFFFFF';
  }
  
  build() {
    if (this.isEnabled && this.currentRow && this.barWidth > 0) {
      Column() {
        this.buildScaleBar()
      }
    } else {
      // 返回空容器，避免影响布局（不占空间）
      Column().width(0).height(0)
    }
  }

  @Builder
  buildScaleBar() {
    Column() {
      // 文本标签
      Row() {
        Text('0')
          .fontSize(8)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor())
          .textShadow({ radius: 2, color: this.getTextStrokeColor(), offsetX: 0, offsetY: 0 })
          .width(this.barWidth)
          .textAlign(TextAlign.Start)
        
        // 中间空白
        Row().layoutWeight(1)
        
        Text(this.currentRow!.label)
          .fontSize(8)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor())
          .textShadow({ radius: 2, color: this.getTextStrokeColor(), offsetX: 0, offsetY: 0 })
          .width(this.barWidth)
          .textAlign(TextAlign.End)
      }
      .width(this.barWidth * this.currentRow!.numberOfBars + this.barWidth)  // 额外宽度用于标签
      .height(12)
      .margin({ bottom: 2 })
      
      // 比例尺条
      Stack() {
        Row() {
          ForEach(
            Array.from({ length: this.currentRow!.numberOfBars }, (_v: undefined, i: number): number => i), 
            (index: number) => {
              Row()
                .width(this.barWidth)
                .height(BAR_HEIGHT_DP)
                .backgroundColor(this.getBarColor(index))
            }, 
            (index: number) => index.toString()
          )
        }
        .width(this.barWidth * this.currentRow!.numberOfBars)
        .height(BAR_HEIGHT_DP)
      }
      .width(this.barWidth * this.currentRow!.numberOfBars)
      .height(BAR_HEIGHT_DP)
      .backgroundColor(this.secondaryColor)
      .borderWidth(1)
      .borderColor(this.primaryColor)
      .borderRadius(BAR_HEIGHT_DP / 2)
      .clip(true)
    }
    .padding({ left: 10, top: 2, right: 10, bottom: 2 })
  }
}
