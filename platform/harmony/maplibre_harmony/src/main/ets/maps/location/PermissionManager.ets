import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import bundleManager from '@ohos.bundle.bundleManager';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * Location permission manager.
 * Provides helpers for checking, requesting, and tracking permission state.
 */
export class PermissionManager {
  private static readonly TAG: string = 'PermissionManager';
  // Location permission list
  private static readonly LOCATION_PERMISSIONS: Permissions[] = [
    'ohos.permission.APPROXIMATELY_LOCATION' as Permissions,
    'ohos.permission.LOCATION' as Permissions
  ];

  /**
   * Check whether location permissions are granted.
   */
  static async checkLocationPermission(context: Context): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const tokenID = bundleInfo.appInfo.accessTokenId;

      // Verify each required permission
      for (const permission of PermissionManager.LOCATION_PERMISSIONS) {
        const grantStatus = await atManager.checkAccessToken(tokenID, permission);
        if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          return true;
        }
      }

      hilog.warn(DOMAIN, PermissionManager.TAG, 'Location permissions not granted');
      return false;
    } catch (err) {
      hilog.error(DOMAIN, PermissionManager.TAG, `Failed to check permissions: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /**
   * Request location permissions.
   */
  static async requestLocationPermission(context: Context): Promise<PermissionRequestResult> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();

      const requestResult = await atManager.requestPermissionsFromUser(
        context,
        PermissionManager.LOCATION_PERMISSIONS
      );

      const result: PermissionRequestResult = {
        granted: false,
        deniedPermissions: [],
        permanentlyDenied: false
      };

      // Inspect grant results
      if (requestResult && requestResult.permissions && requestResult.authResults) {
        for (let i = 0; i < requestResult.permissions.length; i++) {
          const permission = requestResult.permissions[i];
          const authResult = requestResult.authResults[i];

          if (authResult === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
            result.granted = true;
          } else {
            result.deniedPermissions.push(permission as Permissions);
            hilog.warn(DOMAIN, PermissionManager.TAG, `Permission denied: ${permission}`);
          }
        }
      }

      // Evaluate potential permanent denial
      if (result.deniedPermissions.length > 0) {
        result.permanentlyDenied = await PermissionManager.isPermanentlyDenied(context, result.deniedPermissions[0]);
      }

      return result;
    } catch (err) {
      hilog.error(DOMAIN, PermissionManager.TAG, `Failed to request permissions: ${JSON.stringify(err)}`);
      return {
        granted: false,
        deniedPermissions: PermissionManager.LOCATION_PERMISSIONS,
        permanentlyDenied: false,
        error: err as BusinessError
      };
    }
  }

  /**
   * Determine whether a permission has been permanently denied.
   */
  private static async isPermanentlyDenied(context: Context, permission: Permissions): Promise<boolean> {
    try {
      // Re-check the permission state
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const tokenID = bundleInfo.appInfo.accessTokenId;

      const grantStatus = await atManager.checkAccessToken(tokenID, permission);

      // Treat PERMISSION_DENIED as potentially permanent
      // Note: HarmonyOS does not expose a strict "permanent denial" concept; simplified handling
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    } catch (err) {
      hilog.error(DOMAIN, PermissionManager.TAG, `Failed to check permanent denial: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /**
   * Get the rationale message shown before requesting permission.
   */
  static getPermissionRationale(): string {
    return 'Location permission lets the map display your current position and improves the overall experience.';
  }

  /**
   * Get the message displayed after a permanent denial.
   */
  static getPermanentlyDeniedMessage(): string {
    return 'Location permission was denied. Please grant it manually in system settings.';
  }

  /**
   * Check whether location services are enabled.
   */
  static async isLocationServiceEnabled(): Promise<boolean> {
    try {
      // Note: production code should verify the system location service state
      // Simplified for now—always returns true
      return true;
    } catch (err) {
      hilog.error(DOMAIN, PermissionManager.TAG, `Failed to check location service: ${JSON.stringify(err)}`);
      return false;
    }
  }
}

/**
 * Result of a permission request.
 */
export interface PermissionRequestResult {
  // Whether any permission was granted
  granted: boolean;

  // List of denied permissions
  deniedPermissions: Array<Permissions>;

  // Whether the permission is permanently denied
  permanentlyDenied: boolean;

  // Optional error information
  error?: BusinessError;
}

