/**
 * Test Page Smoke UiTest
 *
 * Opens representative test pages purely through the launcher UI
 * (search + click) and asserts each page actually comes up, then returns
 * to Index. No direct API access — this is the same path a user takes.
 *
 * Add entries to SMOKE_TARGETS to widen coverage; keep queries unique
 * enough that the target is the first match in the filtered list.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  ensureAppFront,
  backFromTestPageAndClearSearch,
  openPageBySearch,
} from '../common/UiTestHelpers';

const TAG = 'PageSmokeUiTest';
const DOMAIN = 0xFF00;
const PAGE_OPEN_TIMEOUT = 15000;

interface SmokeTarget {
  title: string;
}

const SMOKE_TARGETS: SmokeTarget[] = [
  { title: 'Debug Mode' },
  { title: 'Map Padding' },
  { title: 'Camera Position' },
  { title: 'Zoom Controls' },
  { title: 'Circle Layer' },
];

export default function PageSmokeUiTest() {
  describe('UiTestPageSmoke', () => {
    let driver: Driver;

    beforeAll(async () => {
      driver = Driver.create();
      hilog.info(DOMAIN, TAG, 'suite start');
      const home = await ensureAppFront(driver);
      hilog.info(DOMAIN, TAG, 'on Index: %{public}s', String(home));
    });

    afterAll(async () => {
      await ensureAppFront(driver);
    });

    for (const target of SMOKE_TARGETS) {
      it('should open ' + target.title + ' from Index', 0, async () => {
        // Self-heal to Index first: a previous case may have left us
        // on a test page or with the keyboard up.
        await ensureAppFront(driver);
        const opened = await openPageBySearch(driver, target.title, PAGE_OPEN_TIMEOUT);
        hilog.info(DOMAIN, TAG, '%{public}s opened: %{public}s', target.title, String(opened));
        expect(opened).assertTrue();
        await backFromTestPageAndClearSearch(driver);
      });
    }
  });
}
