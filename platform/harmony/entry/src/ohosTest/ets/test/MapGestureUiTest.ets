/**
 * Map Gesture UiTest
 *
 * Drives the real map on AutomationTestPage with UiDriver touch injections
 * (swipe / doubleClick / click / longClick) and asserts the camera actually
 * reacted. This exercises the full gesture pipeline end to end:
 * UiTest event injection → ArkUI gesture recognizers → C++
 * NativeGestureManager → mbgl camera.
 *
 * Camera assertions read the page's camera readout Text
 * (id: automation_camera_text) instead of holding a MapLibreMap — the
 * ohosTest module compiles its own copy of shared singletons, so the test
 * module can never observe TestMapAccessor state set by the entry page.
 *
 * Requires a device/emulator where the map renders (an emulator with a
 * black map will not receive gestures and these tests fail there).
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  sleep,
  find,
  waitFor,
  ensureAppFront,
  openPageBySearch,
  backFromTestPageAndClearSearch,
  AUTOMATION_ANCHOR_TEXT,
} from '../common/UiTestHelpers';

const TAG = 'MapGestureUiTest';
const DOMAIN = 0xFF00;
const CAMERA_TEXT_ID = 'automation_camera_text';
const MAP_OPEN_TIMEOUT = 15000;
const CAMERA_READY_TIMEOUT = 20000;

interface CameraState {
  lat: number;
  lng: number;
  zoom: number;
}

/** Read the page's camera readout; null while unavailable/unparsable. */
async function readCamera(driver: Driver): Promise<CameraState | null> {
  const comp = await find(driver, ON.id(CAMERA_TEXT_ID));
  if (comp === null) {
    return null;
  }
  let text = '';
  try {
    text = await comp.getText();
  } catch (e) {
    return null;
  }
  const parts = text.split('|');
  if (parts.length !== 4 || parts[0] !== 'cam') {
    return null;
  }
  const state: CameraState = {
    lat: parseFloat(parts[1]),
    lng: parseFloat(parts[2]),
    zoom: parseFloat(parts[3]),
  };
  if (Number.isNaN(state.lat) || Number.isNaN(state.lng) || Number.isNaN(state.zoom)) {
    return null;
  }
  return state;
}

async function waitForCamera(driver: Driver, timeoutMs: number): Promise<CameraState | null> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    const state = await readCamera(driver);
    if (state !== null) {
      return state;
    }
    await sleep(300);
  }
  return null;
}

export default function MapGestureUiTest() {
  describe('UiTestMapGestures', () => {
    let driver: Driver;
    let camera: CameraState | null = null;
    let screenW = 0;
    let screenH = 0;

    beforeAll(async () => {
      driver = Driver.create();
      hilog.info(DOMAIN, TAG, 'suite start');
      await ensureAppFront(driver);
      // AutomationTestPage has no TestPageLayout title bar; verify the
      // navigation landed via its anchor text instead.
      const opened = await openPageBySearch(driver, 'Auto Test', MAP_OPEN_TIMEOUT, false);
      const anchorVisible = await waitFor(driver, ON.text(AUTOMATION_ANCHOR_TEXT), 10000);
      hilog.info(DOMAIN, TAG, 'AutomationTestPage open %{public}s / anchor %{public}s',
        String(opened), String(anchorVisible));
      // The readout only reports once the native map is up — this is the
      // UI-visible "map ready" signal.
      camera = await waitForCamera(driver, CAMERA_READY_TIMEOUT);
      const size = await driver.getDisplaySize();
      screenW = size.x;
      screenH = size.y;
      hilog.info(DOMAIN, TAG, 'screen %{public}s, camera %{public}s',
        screenW + 'x' + screenH, JSON.stringify(camera));
      // The search box may have left the soft keyboard open; tapping the map
      // (harmless single tap) dismisses it so later gestures land on the map.
      if (camera !== null) {
        await driver.click(Math.round(screenW / 2), Math.round(screenH * 0.15));
        await sleep(500);
      }
    });

    afterAll(async () => {
      await backFromTestPageAndClearSearch(driver);
    });

    it('should have map UI reporting camera state', 0, () => {
      expect(camera !== null).assertTrue();
    });

    it('should pan the map with a swipe', 0, async () => {
      if (camera === null) { return; }
      const before = await readCamera(driver);
      if (before === null) {
        expect(false).assertTrue();
        return;
      }
      const cx = Math.round(screenW / 2);
      const cy = Math.round(screenH / 2);
      await driver.swipe(cx + 150, cy + 150, cx - 150, cy - 150, 400);
      await sleep(800);
      const after = await readCamera(driver);
      hilog.info(DOMAIN, TAG, 'pan: %{public}s -> %{public}s',
        JSON.stringify(before), JSON.stringify(after));
      if (after === null) {
        expect(false).assertTrue();
        return;
      }
      const dLat = Math.abs(after.lat - before.lat);
      const dLng = Math.abs(after.lng - before.lng);
      expect(dLat > 0.001 || dLng > 0.001).assertTrue();
    });

    it('should zoom in on double click', 0, async () => {
      if (camera === null) { return; }
      const before = await readCamera(driver);
      if (before === null) {
        expect(false).assertTrue();
        return;
      }
      await driver.doubleClick(Math.round(screenW / 2), Math.round(screenH / 2));
      await sleep(1500);
      const after = await readCamera(driver);
      hilog.info(DOMAIN, TAG, 'double click zoom: %{public}s -> %{public}s',
        String(before.zoom), JSON.stringify(after));
      if (after === null) {
        expect(false).assertTrue();
        return;
      }
      expect(after.zoom).assertClose(before.zoom + 1.0, 0.5);
    });

    it('should survive a single click', 0, async () => {
      if (camera === null) { return; }
      await driver.click(Math.round(screenW / 2), Math.round(screenH / 2));
      await sleep(500);
      expect(await readCamera(driver) !== null).assertTrue();
    });

    it('should survive a long press', 0, async () => {
      if (camera === null) { return; }
      await driver.longClick(Math.round(screenW / 2), Math.round(screenH / 2));
      await sleep(500);
      expect(await readCamera(driver) !== null).assertTrue();
    });

    it('should still pan after click gestures', 0, async () => {
      if (camera === null) { return; }
      const before = await readCamera(driver);
      if (before === null) {
        expect(false).assertTrue();
        return;
      }
      await driver.swipe(Math.round(screenW / 2) - 120, Math.round(screenH / 2),
        Math.round(screenW / 2) + 120, Math.round(screenH / 2), 400);
      await sleep(800);
      const after = await readCamera(driver);
      if (after === null) {
        expect(false).assertTrue();
        return;
      }
      const dLat = Math.abs(after.lat - before.lat);
      const dLng = Math.abs(after.lng - before.lng);
      expect(dLat > 0.001 || dLng > 0.001).assertTrue();
    });
  });
}
