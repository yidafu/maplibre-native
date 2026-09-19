/**
 * Index Page UiTest
 *
 * Pure UI-level tests for the test-page launcher (Index), driven entirely
 * through UiTest (UiDriver): rendering, search filtering, section
 * collapse/expand and navigation into a test page. No MapLibreMap API is
 * touched — the assertions are on the visible component tree.
 */
import { describe, beforeAll, afterAll, it, expect } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import {
  sleep,
  find,
  exists,
  waitFor,
  ensureAppFront,
  backToFrontIndex,
  backFromTestPageAndClearSearch,
  INDEX_HEADER_TEXT,
} from '../common/UiTestHelpers';

const TAG = 'IndexUiTest';
const DOMAIN = 0xFF00;
const SHORT_TIMEOUT = 10000;

export default function IndexUiTest() {
  describe('UiTestIndexPage', () => {
    let driver: Driver;

    beforeAll(async () => {
      driver = Driver.create();
      hilog.info(DOMAIN, TAG, 'suite start');
      const home = await ensureAppFront(driver);
      hilog.info(DOMAIN, TAG, 'on Index: %{public}s', String(home));
    });

    afterAll(async () => {
      await backToFrontIndex(driver);
    });

    it('should render header, search bar and page list', 0, async () => {
      // Poll instead of one-shot checks: right after the app foregrounds the
      // list items can lag the header by a few hundred ms.
      const home = await ensureAppFront(driver);
      const header = await waitFor(driver, ON.text(INDEX_HEADER_TEXT), SHORT_TIMEOUT);
      const input = await waitFor(driver, ON.type('TextInput'), SHORT_TIMEOUT);
      const firstItem = await waitFor(driver, ON.text('Simple Map'), SHORT_TIMEOUT);
      hilog.info(DOMAIN, TAG, 'render: home=%{public}s header=%{public}s input=%{public}s firstItem=%{public}s',
        String(home), String(header), String(input), String(firstItem));
      expect(header && input && firstItem).assertTrue();
    });

    it('should filter pages by search query', 0, async () => {
      const input = await find(driver, ON.type('TextInput'));
      if (input === null) {
        expect(false).assertTrue();
        return;
      }
      await input.click();
      await input.inputText('camera');
      await sleep(600);
      // Camera pages remain, everything else is gone from the tree.
      expect(await exists(driver, ON.text('Camera Position'))).assertTrue();
      expect(await exists(driver, ON.text('Simple Map'))).assertFalse();
      await input.clearText();
      await sleep(600);
      expect(await waitFor(driver, ON.text('Simple Map'), SHORT_TIMEOUT)).assertTrue();
    });

    it('should collapse and expand a section', 0, async () => {
      const header = await find(driver, ON.text('Basic'));
      if (header === null) {
        expect(false).assertTrue();
        return;
      }
      await header.click();
      await sleep(600);
      // Collapsed: items are removed from the tree.
      expect(await exists(driver, ON.text('Simple Map'))).assertFalse();
      const headerAgain = await find(driver, ON.text('Basic'));
      if (headerAgain === null) {
        expect(false).assertTrue();
        return;
      }
      await headerAgain.click();
      await sleep(600);
      expect(await exists(driver, ON.text('Simple Map'))).assertTrue();
    });

    it('should navigate to Simple Map page and back', 0, async () => {
      const item = await find(driver, ON.text('Simple Map'));
      if (item === null) {
        expect(false).assertTrue();
        return;
      }
      await item.click();
      // SimpleMapTestPage control panel heading; renders without map load.
      const opened = await waitFor(driver, ON.text('Map Controls'), SHORT_TIMEOUT);
      expect(opened).assertTrue();
      // Use the page's own ← button: system back may be consumed by the
      // soft keyboard left over from the search test.
      await backFromTestPageAndClearSearch(driver);
      const backHome = await exists(driver, ON.text(INDEX_HEADER_TEXT));
      expect(backHome).assertTrue();
    });
  });
}
