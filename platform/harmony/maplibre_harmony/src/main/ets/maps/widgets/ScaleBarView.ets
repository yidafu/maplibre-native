/**
 * ScaleBarView - scale bar component.
 *
 * Inspired by Android and iOS MLNScaleBar implementations.
 * Dynamically displays map scale based on zoom level and latitude.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
// Constants.
const METERS_PER_FOOT = 0.3048;
const FEET_PER_METER = 3.28084;
const MIN_BAR_WIDTH_DP = 30;
const BAR_HEIGHT_DP = 4;

/**
 * Scale bar unit system.
 */
export enum ScaleBarUnit {
  Metric = 0, // Metric (meters/kilometers).
  Imperial = 1 // Imperial (feet/miles).
}

/**
 * Scale bar row configuration.
 */
interface ScaleBarRow {
  distance: number; // Displayed distance.
  numberOfBars: number; // Number of segments.
  label: string; // Label text.
}

@Component
export struct ScaleBarView {
  // Whether the scale bar is enabled.
  @Prop isEnabled: boolean = true;
  // Meters represented per pixel (provided externally).
  @Prop @Watch('onMetersPerPixelChanged') metersPerPixel: number = 0;
  // Unit system.
  @Prop unitSystem: ScaleBarUnit = ScaleBarUnit.Metric;
  // Whether to use dark styling.
  @Prop useDarkStyles: boolean = false;
  // Primary and secondary colors.
  @Prop primaryColor: string = '#122D11';
  @Prop secondaryColor: string = '#F7F7F7';
  // Maximum width (pixels).
  @Prop maxWidth: number = 200;
  // Currently selected scale bar row.
  @State private currentRow: ScaleBarRow | null = null;
  // Width of each bar segment.
  @State private barWidth: number = 0;

  /**
   * Watch for metersPerPixel changes.
   */
  onMetersPerPixelChanged(): void {
    this.recalculate();
  }

  /**
   * Component initialization.
   */
  aboutToAppear(): void {
    this.recalculate();
  }

  /**
   * Update the scale bar.
   * @param metersPerPixel Meters per pixel.
   */
  update(metersPerPixel: number): void {
    this.metersPerPixel = metersPerPixel;
    this.recalculate();
  }

  /**
   * Recalculate the scale bar.
   */
  private recalculate(): void {

    if (this.metersPerPixel <= 0 || !this.isEnabled) {
      hilog.warn(DOMAIN, 'ScaleBarView',
        `recalculate: Cannot display - metersPerPixel=${this.metersPerPixel}, isEnabled=${this.isEnabled}`);
      this.currentRow = null;
      return;
    }

    const unitsPerPixel = this.unitSystem === ScaleBarUnit.Metric
      ? this.metersPerPixel
      : this.metersPerPixel * FEET_PER_METER;

    const maxDistance = this.maxWidth * unitsPerPixel;

    // Select a suitable scale bar row.
    const row = this.selectPreferredRow(maxDistance);

    if (row) {
      // Compute the actual width.
      const actualWidth = row.distance / unitsPerPixel;

      if (actualWidth >= MIN_BAR_WIDTH_DP) {
        this.currentRow = row;
        // Compute the width of each segment.
        this.barWidth = Math.floor(actualWidth / row.numberOfBars);
      } else {
        hilog.warn(DOMAIN, 'ScaleBarView',
          `recalculate: actualWidth ${actualWidth} < MIN_BAR_WIDTH_DP ${MIN_BAR_WIDTH_DP}`);
        this.currentRow = null;
      }
    } else {
      hilog.warn(DOMAIN, 'ScaleBarView', `recalculate: No suitable row found for maxDistance=${maxDistance}`);
      this.currentRow = null;
    }
  }

  /**
   * Select a suitable scale bar row.
   * @param maxDistance Maximum distance.
   */
  private selectPreferredRow(maxDistance: number): ScaleBarRow | null {
    const rows = this.getPredefinedRows();

    // Find the first row that does not exceed the maximum distance.
    for (const row of rows) {
      if (row.distance <= maxDistance) {
        return row;
      }
    }

    return null;
  }

  /**
   * Retrieve predefined scale bar rows.
   */
  private getPredefinedRows(): ScaleBarRow[] {
    if (this.unitSystem === ScaleBarUnit.Metric) {
      // Metric (meters/kilometers).
      return [
        // Kilometer scale.
        { distance: 200000, numberOfBars: 4, label: '200 km' },
        { distance: 100000, numberOfBars: 4, label: '100 km' },
        { distance: 50000, numberOfBars: 5, label: '50 km' },
        { distance: 20000, numberOfBars: 4, label: '20 km' },
        { distance: 10000, numberOfBars: 4, label: '10 km' },
        { distance: 5000, numberOfBars: 5, label: '5 km' },
        { distance: 2000, numberOfBars: 4, label: '2 km' },
        { distance: 1000, numberOfBars: 4, label: '1 km' },
        // Meter scale.
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
      // Imperial (feet/miles).
      const FEET_PER_MILE = 5280;
      return [
        // Mile scale.
        { distance: 100 * FEET_PER_MILE, numberOfBars: 4, label: '100 mi' },
        { distance: 50 * FEET_PER_MILE, numberOfBars: 5, label: '50 mi' },
        { distance: 20 * FEET_PER_MILE, numberOfBars: 4, label: '20 mi' },
        { distance: 10 * FEET_PER_MILE, numberOfBars: 4, label: '10 mi' },
        { distance: 5 * FEET_PER_MILE, numberOfBars: 5, label: '5 mi' },
        { distance: 2 * FEET_PER_MILE, numberOfBars: 4, label: '2 mi' },
        { distance: 1 * FEET_PER_MILE, numberOfBars: 4, label: '1 mi' },
        // Foot scale.
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
   * Determine the color of a segment.
   */
  private getBarColor(index: number): string {
    return index % 2 === 0 ? this.primaryColor : this.secondaryColor;
  }

  /**
   * Determine the text color (with stroke effect).
   */
  private getTextColor(): string {
    return this.useDarkStyles ? '#FFFFFF' : '#000000';
  }

  /**
   * Determine the text stroke color.
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
      // Return an empty container to avoid affecting layout.
      Column().width(0).height(0)
    }
  }

  @Builder
  buildScaleBar() {
    Column() {
      // Text labels.
      Row() {
        Text('0')
          .fontSize(8)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor())
          .textShadow({
            radius: 2,
            color: this.getTextStrokeColor(),
            offsetX: 0,
            offsetY: 0
          })
          .width(this.barWidth)
          .textAlign(TextAlign.Start)

        // Middle spacer.
        Row().layoutWeight(1)

        Text(this.currentRow!.label)
          .fontSize(8)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextColor())
          .textShadow({
            radius: 2,
            color: this.getTextStrokeColor(),
            offsetX: 0,
            offsetY: 0
          })
          .width(this.barWidth)
          .textAlign(TextAlign.End)
      }
      .width(this.barWidth * this.currentRow!.numberOfBars + this.barWidth) // Extra width reserved for labels.
      .height(12)
      .margin({ bottom: 2 })

      // Scale bar segments.
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
    .padding({
      left: 10,
      top: 2,
      right: 10,
      bottom: 2
    })
  }
}
