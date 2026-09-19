/**
 * UiTestHelpers - shared helpers for UiTest (UiDriver)-driven integration suites.
 *
 * These suites exercise the app purely through the UI, unlike the
 * TestMapAccessor-based suites that drive the MapLibreMap API directly.
 *
 * Conventions:
 * - Navigation between pages is done by clicking visible list items.
 * - A test page is considered "open" once its title bar back arrow (←)
 *   appears — the only shared anchor across all TestPageLayout pages.
 * - All waits are bounded polling loops (hypium 1.0.24 has no per-case
 *   timeout), so no helper can hang the whole run.
 */
import { Driver, ON, On, Component } from '@ohos.UiTest';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { abilityDelegatorRegistry } from '@kit.TestKit';

const TAG = 'UiTestHelpers';
const DOMAIN = 0xFF00;
const APP_BUNDLE = 'org.maplibre.harmony';
const APP_ABILITY = 'EntryAbility';

/** Index page header text — used to detect that we are back on the launcher. */
export const INDEX_HEADER_TEXT = 'MapLibre Native';

/** Back-arrow caption in the shared TestPageLayout title bar. */
export const BACK_ARROW_TEXT = '←';

export async function sleep(ms: number): Promise<void> {
  return new Promise<void>(resolve => setTimeout(resolve, ms));
}

/**
 * Make sure AutomationTestPage is on screen, reusing an already-open one.
 *
 * API suites call this in beforeAll and do NOT navigate back in afterAll:
 * one map instance is shared across all of them. Repeated map
 * create/destroy cycles trip an intermittent CURL/libuv event-loop
 * teardown crash (OnlineFileSource thread, SIGSEGV in uv__async_io), so
 * the page is popped only once — by the first later suite that needs the
 * Index (ensureAppFront).
 */
export async function ensureAutomationPage(driver: Driver): Promise<boolean> {
  if (await exists(driver, ON.text(AUTOMATION_ANCHOR_TEXT))) {
    return true;
  }
  const onIndex = await ensureAppFront(driver);
  if (!onIndex) {
    hilog.error(DOMAIN, TAG, 'ensureAutomationPage: Index not reachable');
    return false;
  }
  // AutomationTestPage has no TestPageLayout title bar; openPageBySearch's
  // arrow check must be off.
  return await openPageBySearch(driver, 'Auto Test', 15000, false);
}

/**
 * Find a component; resolves null when nothing matches.
 * NOTE: driver.findComponent resolves to null (does not reject) on this
 * API version, so every caller must null-check before using the result.
 */
export async function find(driver: Driver, on: On): Promise<Component | null> {
  try {
    const comp: Component | null = await driver.findComponent(on);
    if (comp === null || comp === undefined) {
      return null;
    }
    return comp;
  } catch (e) {
    return null;
  }
}

/**
 * True if a component matching `on` is currently findable in the visible tree.
 */
export async function exists(driver: Driver, on: On): Promise<boolean> {
  return await find(driver, on) !== null;
}

/** Bounded wait until the component appears; returns false on timeout. */
export async function waitFor(driver: Driver, on: On, timeoutMs: number): Promise<boolean> {
  const start = Date.now();
  while (Date.now() - start < timeoutMs) {
    if (await exists(driver, on)) {
      return true;
    }
    await sleep(200);
  }
  return false;
}

/** AutomationTestPage anchor text (rendered behind the map). */
export const AUTOMATION_ANCHOR_TEXT = 'AUTOMATION_PAGE_ANCHOR';

/**
 * Best-effort clear of the Index search box. API suites search for
 * 'Auto Test' and never clean up, so a stale query would leave the list
 * filtered for every later suite.
 */
async function clearIndexSearchQuiet(driver: Driver): Promise<void> {
  try {
    const input = await find(driver, ON.type('TextInput'));
    if (input === null) {
      return;
    }
    const text = await input.getText();
    if (text !== undefined && text.length > 0) {
      await input.clearText();
      await sleep(300);
    }
  } catch (e) {
    // best effort
  }
}

/**
 * Bring the main app (EntryAbility) to the foreground and land on Index.
 *
 * `aa test` starts the generated TestAbility whose page is a blank
 * "Hello World" scaffold — the app's real Index is never loaded by the
 * test harness itself. Every suite must call this first, otherwise the
 * UiDriver only sees the scaffold page (and the API suites silently
 * no-op with map === null).
 *
 * Safe to call repeatedly: no-op when Index is already visible. `aa start`
 * does not reset a running app's router stack, so back out of pushed pages
 * before deciding the app needs (re)launching.
 */
export async function ensureAppFront(driver: Driver): Promise<boolean> {
  const onIndex = await ensureAppFrontInner(driver);
  if (onIndex) {
    await clearIndexSearchQuiet(driver);
  }
  return onIndex;
}

async function ensureAppFrontInner(driver: Driver): Promise<boolean> {
  if (await exists(driver, ON.text(INDEX_HEADER_TEXT))) {
    return true;
  }
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  try {
    await delegator.executeShellCommand(
      'aa start -b ' + APP_BUNDLE + ' -a ' + APP_ABILITY, 15);
  } catch (e) {
    hilog.warn(DOMAIN, TAG, 'aa start failed: %{public}s', String(e));
  }
  // Cold start lands on Index; a running app on a pushed page stays there.
  if (await waitFor(driver, ON.text(INDEX_HEADER_TEXT), 5000)) {
    return true;
  }
  if (await backToFrontIndex(driver)) {
    return true;
  }
  try {
    await delegator.executeShellCommand(
      'aa start -b ' + APP_BUNDLE + ' -a ' + APP_ABILITY, 15);
  } catch (e) {
    hilog.warn(DOMAIN, TAG, 'aa start retry failed: %{public}s', String(e));
  }
  return await waitFor(driver, ON.text(INDEX_HEADER_TEXT), 15000);
}

/**
 * Find a component that is actually on screen. The unfiltered Index list
 * builds every item (plain ForEach), so findComponent happily returns
 * stale OFFSCREEN nodes right after filtering — clicking those silently
 * does nothing. Bounds-check against the display to reject them.
 */
export async function findVisible(driver: Driver, on: On): Promise<Component | null> {
  const comp = await find(driver, on);
  if (comp === null) {
    return null;
  }
  try {
    const rect = await comp.getBounds();
    const size = await driver.getDisplaySize();
    if (rect.right <= 0 || rect.bottom <= 0 || rect.left >= size.x || rect.top >= size.y) {
      return null;
    }
  } catch (e) {
    return null;
  }
  return comp;
}

/**
 * Press system back until the Index page is visible again (bounded).
 * Checks for Index first so we never back out of the app itself.
 */
export async function backToFrontIndex(driver: Driver): Promise<boolean> {
  for (let i = 0; i < 6; i++) {
    if (await exists(driver, ON.text(INDEX_HEADER_TEXT))) {
      return true;
    }
    try {
      await driver.pressBack();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'pressBack failed: %{public}s', String(e));
    }
    await sleep(800);
  }
  return await exists(driver, ON.text(INDEX_HEADER_TEXT));
}

/**
 * Filter the Index list through the search box and click the item whose
 * title equals `title`. Searching avoids scrolling the long page list:
 * filtered results are anchored right below the search bar.
 *
 * `expectBackArrow` should be false for pages not built on TestPageLayout
 * (e.g. AutomationTestPage has no title bar).
 *
 * Returns false if the item could not be clicked or the page did not come up.
 */
export async function openPageBySearch(driver: Driver, title: string,
  timeoutMs: number, expectBackArrow: boolean = true): Promise<boolean> {
  const input = await findVisible(driver, ON.type('TextInput'));
  if (input === null) {
    hilog.error(DOMAIN, TAG, 'search box not found (not on Index?) for %{public}s', title);
    return false;
  }
  try {
    await input.click();
    await input.clearText();
    await input.inputText(title.toLowerCase());
  } catch (e) {
    hilog.error(DOMAIN, TAG, 'search input failed for %{public}s: %{public}s', title, String(e));
    return false;
  }
  if (!await waitFor(driver, ON.text(title), timeoutMs)) {
    hilog.error(DOMAIN, TAG, 'item %{public}s not visible after search', title);
    return false;
  }
  // The unfiltered list builds all items (plain ForEach), so right after
  // filtering findComponent may still return the stale offscreen node —
  // retry until the re-rendered (visible) node can be clicked.
  let clicked = false;
  for (let attempt = 0; attempt < 4 && !clicked; attempt++) {
    const item = await findVisible(driver, ON.text(title));
    if (item === null) {
      await sleep(400);
      continue;
    }
    try {
      await item.click();
      clicked = true;
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'click %{public}s attempt %{public}d failed: %{public}s', title, attempt, String(e));
      await sleep(400);
    }
  }
  if (!clicked) {
    return false;
  }
  if (!expectBackArrow) {
    return true;
  }
  return await waitFor(driver, ON.text(BACK_ARROW_TEXT), timeoutMs);
}

/**
 * Leave the current test page (back to Index) and clear the search box so
 * the next search starts from the full list.
 */
/**
 * Leave the current test page (back to Index) and clear the search box so
 * the next search starts from the full list.
 *
 * Uses the page's own ← button rather than system back: a pressBack can be
 * consumed by the soft keyboard (opened by the search box) instead of
 * navigating, which would strand us on the test page.
 */
export async function backFromTestPageAndClearSearch(driver: Driver): Promise<void> {
  const backBtn = await find(driver, ON.text(BACK_ARROW_TEXT));
  if (backBtn !== null) {
    try {
      await backBtn.click();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'back button click failed: %{public}s', String(e));
      await driver.pressBack();
    }
  } else {
    await driver.pressBack();
  }
  await waitFor(driver, ON.text(INDEX_HEADER_TEXT), 10000);
  const input = await find(driver, ON.type('TextInput'));
  if (input !== null) {
    try {
      await input.clearText();
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'clear search failed: %{public}s', String(e));
    }
  }
  await sleep(300);
}
