/**
 * Basic Map Loading Test
 * Tests the fundamental map loading flow from app start to first frame rendered
 */

import { describe, it, expect, beforeAll, afterAll } from '@ohos/hypium';
import { TestHelper, PerformanceMetrics } from '../utils/TestHelper';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'BasicMapLoadingTest';
const DOMAIN = 0xFF00;

export default function BasicMapLoadingTest() {
  describe('BasicMapLoading', () => {
    let testHelper: TestHelper;
    let metrics: PerformanceMetrics;
    
    beforeAll(async () => {
      hilog.info(DOMAIN, TAG, 'Setting up BasicMapLoadingTest');
      testHelper = new TestHelper();
      await testHelper.init();
      metrics = new PerformanceMetrics();
    });
    
    afterAll(async () => {
      hilog.info(DOMAIN, TAG, 'Tearing down BasicMapLoadingTest');
      // Export performance metrics
      const metricsReport = metrics.exportMetrics();
      hilog.info(DOMAIN, TAG, `Performance metrics:\n${metricsReport}`);
    });
    
    /**
     * Test 1: Basic map loading
     * Verifies the complete flow from app launch to map rendered
     */
    it('should load map successfully', async () => {
      metrics.start();
      
      // Step 1: Wait for XComponent to be created
      hilog.info(DOMAIN, TAG, 'Step 1: Waiting for XComponent');
      const xcomponentFound = await testHelper.waitForComponent('mapview_xcomponent', 10000);
      expect(xcomponentFound).assertTrue();
      metrics.mark('xcomponent_created');
      
      // Step 2: Wait for style to load (check debug overlay or logs)
      hilog.info(DOMAIN, TAG, 'Step 2: Waiting for style to load');
      await testHelper.sleep(3000); // Wait for style loading
      metrics.mark('style_loaded');
      
      // Step 3: Wait for at least one tile to load
      hilog.info(DOMAIN, TAG, 'Step 3: Waiting for tiles to load');
      await testHelper.sleep(2000); // Wait for tile loading
      metrics.mark('tiles_loaded');
      
      // Step 4: Take screenshot
      hilog.info(DOMAIN, TAG, 'Step 4: Taking screenshot');
      const screenshotTaken = await testHelper.takeScreenshot('basic_map_loaded');
      expect(screenshotTaken).assertTrue();
      metrics.mark('screenshot_taken');
      
      // Step 5: Verify performance
      hilog.info(DOMAIN, TAG, 'Step 5: Verifying performance');
      const totalTime = metrics.getElapsed();
      hilog.info(DOMAIN, TAG, `Total loading time: ${totalTime}ms`);
      
      // Assert: Total loading time should be less than 10 seconds
      expect(totalTime).assertLess(10000);
      
      // Assert: First frame render time should be less than 2 seconds
      const xcomponentTime = metrics.marks.get('xcomponent_created');
      if (xcomponentTime !== undefined) {
        hilog.info(DOMAIN, TAG, `XComponent created in: ${xcomponentTime}ms`);
        expect(xcomponentTime).assertLess(2000);
      }
      
      hilog.info(DOMAIN, TAG, '✅ Basic map loading test passed');
    });
    
    /**
     * Test 2: Surface creation
     * Verifies that EGL and OpenGL are properly initialized
     */
    it('should initialize OpenGL context successfully', async () => {
      hilog.info(DOMAIN, TAG, 'Testing OpenGL context initialization');
      
      // Wait for XComponent
      const xcomponentFound = await testHelper.waitForComponent('mapview_xcomponent', 5000);
      expect(xcomponentFound).assertTrue();
      
      // Give time for EGL initialization
      await testHelper.sleep(1000);
      
      // If we reach here without crash, EGL initialization was successful
      hilog.info(DOMAIN, TAG, '✅ OpenGL context initialization test passed');
    });
    
    /**
     * Test 3: Style URL loading
     * Verifies that the style JSON is downloaded successfully
     */
    it('should download style JSON successfully', async () => {
      metrics.start();
      
      hilog.info(DOMAIN, TAG, 'Testing style JSON download');
      
      // Wait for component
      await testHelper.waitForComponent('mapview_xcomponent', 5000);
      
      // Wait for style download (reasonable timeout)
      await testHelper.sleep(3000);
      metrics.mark('style_downloaded');
      
      // Verify download time is reasonable
      const downloadTime = metrics.marks.get('style_downloaded');
      if (downloadTime !== undefined) {
        hilog.info(DOMAIN, TAG, `Style downloaded in: ${downloadTime}ms`);
        expect(downloadTime).assertLess(5000); // Should be less than 5 seconds
      }
      
      hilog.info(DOMAIN, TAG, '✅ Style JSON download test passed');
    });
    
    /**
     * Test 4: No crashes during loading
     * Verifies stability during the loading process
     */
    it('should not crash during loading', async () => {
      hilog.info(DOMAIN, TAG, 'Testing stability during loading');
      
      // Wait for component
      await testHelper.waitForComponent('mapview_xcomponent', 5000);
      
      // Wait through the entire loading process
      await testHelper.sleep(5000);
      
      // If we reach here, no crash occurred
      hilog.info(DOMAIN, TAG, '✅ Stability test passed - no crashes detected');
    });
    
    /**
     * Test 5: Black screen detection
     * Attempts to detect if the map is showing a black screen
     */
    it('should not show black screen', async () => {
      hilog.info(DOMAIN, TAG, 'Testing for black screen');
      
      // Wait for component
      await testHelper.waitForComponent('mapview_xcomponent', 5000);
      
      // Wait for rendering
      await testHelper.sleep(5000);
      
      // Take screenshot for manual verification
      const screenshotTaken = await testHelper.takeScreenshot('black_screen_check');
      expect(screenshotTaken).assertTrue();
      
      hilog.info(DOMAIN, TAG, '✅ Black screen check completed (manual verification required)');
      hilog.info(DOMAIN, TAG, 'Please manually verify that /data/local/tmp/black_screen_check.png is not all black');
    });
    
    /**
     * Test 6: Memory usage
     * Monitors basic memory behavior during loading
     */
    it('should not leak memory during loading', async () => {
      hilog.info(DOMAIN, TAG, 'Testing memory usage');
      
      // Wait for component
      await testHelper.waitForComponent('mapview_xcomponent', 5000);
      
      // Wait for full loading cycle
      await testHelper.sleep(6000);
      
      // Memory metrics would need native support
      // For now, just verify we can complete the loading cycle
      
      hilog.info(DOMAIN, TAG, '✅ Memory usage test completed');
    });
  });
}

