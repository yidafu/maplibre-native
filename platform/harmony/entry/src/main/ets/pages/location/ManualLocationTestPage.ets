/**
 * ManualLocationTestPage - Test programmatic location updates.
 *
 * Demonstrates forceLocationUpdate to set location without a real GPS engine.
 * Tests moving the location indicator to various preset coordinates.
 */
import { TestPageLayout } from '../common/TestPageLayout';
import { MapView, MapLibreMap } from 'maplibre_harmony';
import { LocationComponent, LocationComponentOptions, CameraMode, RenderMode } from 'maplibre_harmony';
import { LatLng } from 'maplibre_harmony';
import { TEST_LOCATIONS, showToast } from '../common/TestUtils';

@Entry
@Component
struct ManualLocationTestPage {
  private mapController: MapLibreMap | null = null;
  private locationComponent: LocationComponent | null = null;
  @State private isMapReady: boolean = false;
  @State private isActivated: boolean = false;
  @State private isEnabled: boolean = false;
  @State private statusMessage: string = 'Loading...';
  @State private currentLocation: string = 'Not set';
  @State private locationCount: number = 0;

  // List of test locations to cycle through
  private readonly locationList: LatLng[] = [
    TEST_LOCATIONS.beijing,
    TEST_LOCATIONS.shanghai,
    TEST_LOCATIONS.guangzhou,
    TEST_LOCATIONS.shenzhen,
    TEST_LOCATIONS.hangzhou,
    TEST_LOCATIONS.chengdu,
    TEST_LOCATIONS.xian,
    TEST_LOCATIONS.wuhan,
    TEST_LOCATIONS.london,
    TEST_LOCATIONS.nyc,
    TEST_LOCATIONS.sf,
    TEST_LOCATIONS.tokyo,
  ];

  aboutToDisappear() {
    this.mapController?.destroy();
    this.mapController = null;
  }

  private onMapReady = (map: MapLibreMap): void => {
    this.mapController = map;
    this.isMapReady = true;
    this.statusMessage = 'Map ready';
  };

  private activateAndEnable(): void {
    if (!this.mapController) {
      return;
    }
    this.mapController.addOnDidFinishLoadingStyleListener(() => {
      const lc = this.mapController!.getLocationComponent();
      if (!lc) {
        showToast('No LocationComponent');
        return;
      }
      this.locationComponent = lc;

      const options = new LocationComponentOptions();
      lc.activateLocationComponent(options).then(() => {
        this.isActivated = true;
        lc.setLocationComponentEnabled(true);
        this.isEnabled = true;
        this.statusMessage = 'Location active, use buttons to update';
        showToast('Location activated');
      }).catch((err: Error) => {
        this.statusMessage = 'Error: ' + err.message;
      });
    });
  }

  private setLocation(lat: number, lng: number, name: string): void {
    if (!this.locationComponent || !this.isActivated) {
      showToast('Activate location first');
      return;
    }
    this.locationComponent.forceLocationUpdate(lat, lng, 0, 100);
    this.currentLocation = name + ' (' + lat.toFixed(4) + ', ' + lng.toFixed(4) + ')';
    this.locationCount++;
    this.statusMessage = 'Location: ' + name;
    showToast('Moved to ' + name);
  }

  private cycleNextLocation(): void {
    if (this.locationList.length === 0) {
      return;
    }
    const idx = this.locationCount % this.locationList.length;
    const loc = this.locationList[idx];
    this.setLocation(loc.latitude, loc.longitude, 'Location #' + idx);

    // Also move camera to see the dot
    if (this.mapController) {
      this.mapController.easeTo(loc.latitude, loc.longitude, 0, 10, 1000);
    }
  }

  private setBearing(bearing: number): void {
    if (!this.locationComponent || !this.isActivated) {
      showToast('Activate first');
      return;
    }
    // Use current location with new bearing
    if (this.locationComponent.getLastKnownLocation()) {
      const loc = this.locationComponent.getLastKnownLocation()!;
      this.locationComponent.forceLocationUpdate(loc.latitude, loc.longitude, bearing, 100);
      this.statusMessage = 'Bearing set to ' + bearing + ' degrees';
      showToast('Bearing: ' + bearing + ' deg');
    } else {
      this.setLocation(TEST_LOCATIONS.hangzhou.latitude, TEST_LOCATIONS.hangzhou.longitude, 'Hangzhou');
      // Retry with bearing
      setTimeout(() => {
        const loc = this.locationComponent!.getLastKnownLocation();
        if (loc) {
          this.locationComponent!.forceLocationUpdate(loc.latitude, loc.longitude, bearing, 100);
          this.statusMessage = 'Bearing set to ' + bearing + ' degrees';
        }
      }, 100);
    }
  }

  @Builder
  mapContent() {
    MapView({
      onMapReady: this.onMapReady,
    })
      .width('100%')
      .height('100%')
  }

  @Builder
  controlPanel() {
    Column() {
      Text(this.statusMessage)
        .fontSize(14)
        .fontColor(this.isMapReady ? '#4CAF50' : '#FF9800')
        .width('100%')
        .padding(12)
        .backgroundColor('#F5F5F5')
        .borderRadius(6)
        .margin({ bottom: 8 })

      Row() {
        Text('Current: ')
          .fontSize(12)
        Text(this.currentLocation)
          .fontSize(12)
          .fontColor('#2196F3')
      }
      .width('100%')

      if (!this.isActivated) {
        Button('Activate & Enable')
          .width('100%')
          .margin({ top: 8 })
          .enabled(this.isMapReady)
          .onClick(() => this.activateAndEnable())
      } else {
        // En/disable
        Button(this.isEnabled ? 'Disable' : 'Enable')
          .width('100%')
          .backgroundColor(this.isEnabled ? '#FF5722' : '#4CAF50')
          .onClick(() => {
            this.isEnabled = !this.isEnabled;
            this.locationComponent!.setLocationComponentEnabled(this.isEnabled);
            this.statusMessage = this.isEnabled ? 'Enabled' : 'Disabled';
          })

        Divider().height(1).margin({ top: 12, bottom: 8 })

        Text('Preset Locations').fontSize(15).fontWeight(FontWeight.Bold).width('100%')

        // City buttons in a grid
        Grid() {
          ForEach(this.locationList, (loc: LatLng, index: number) => {
            GridItem() {
              Button(this.locationList[index].latitude.toFixed(1) + ', ' + this.locationList[index].longitude.toFixed(1))
                .width('100%')
                .fontSize(11)
                .height(36)
                .onClick(() => {
                  const names = ['Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen', 'Hangzhou', 'Chengdu',
                    'Xian', 'Wuhan', 'London', 'NYC', 'SF', 'Tokyo'];
                  if (index >= this.locationCount) {
                    this.locationCount = index + 1;
                  }
                  this.mapController!.easeTo(loc.latitude, loc.longitude, 0, 10, 800);
                  this.setLocation(loc.latitude, loc.longitude, names[index] || 'Loc ' + index);
                })
                .enabled(this.isActivated)
            }
          }, (loc: LatLng, index: number) => String(index))
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(6)
        .rowsGap(6)
        .width('100%')
        .margin({ top: 4 })

        Divider().height(1).margin({ top: 12, bottom: 8 })

        Text('Bearing Control').fontSize(15).fontWeight(FontWeight.Bold).width('100%')

        Row() {
          Button('0 deg')
            .width('30%')
            .fontSize(12)
            .onClick(() => this.setBearing(0))
          Button('90 deg')
            .width('30%')
            .fontSize(12)
            .margin({ left: '5%' })
            .onClick(() => this.setBearing(90))
          Button('180 deg')
            .width('30%')
            .fontSize(12)
            .margin({ left: '5%' })
            .onClick(() => this.setBearing(180))
        }
        .width('100%')
        .margin({ top: 4 })

        Button('Cycle Next Location + Camera')
          .width('100%')
          .margin({ top: 8 })
          .backgroundColor('#2196F3')
          .enabled(this.isActivated)
          .onClick(() => this.cycleNextLocation())

        Text('Total updates: ' + this.locationCount)
          .fontSize(12)
          .fontColor('#666')
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ top: 8 })
      }
    }
    .width('100%')
  }

  build() {
    Column() {
      TestPageLayout({
      title: 'Manual Location',
      subtitle: 'Programmatic location updates',
      mapContent: (): void => this.mapContent(),
      controlPanel: (): void => this.controlPanel(),
      })
    }
    .width('100%')
    .height('100%')
  }
}
