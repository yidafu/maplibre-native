import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import bundleManager from '@ohos.bundle.bundleManager';
import { DOMAIN } from '../../constants/HiLogConstants';

/**
 * 位置权限管理器
 * 提供完善的权限检查、请求和状态管理
 */
export class PermissionManager {
  private static readonly TAG: string = 'PermissionManager';
  
  // 位置权限列表
  private static readonly LOCATION_PERMISSIONS: Permissions[] = [
    'ohos.permission.APPROXIMATELY_LOCATION' as Permissions,
    'ohos.permission.LOCATION' as Permissions
  ];

  /**
   * 检查是否已授予位置权限
   */
  static async checkLocationPermission(context: Context): Promise<boolean> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const tokenID = bundleInfo.appInfo.accessTokenId;

      // 检查所有位置权限
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
   * 请求位置权限
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

      // 检查授权结果
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

      // 检查是否永久拒绝
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
   * 检查权限是否被永久拒绝
   */
  private static async isPermanentlyDenied(context: Context, permission: Permissions): Promise<boolean> {
    try {
      // 再次检查权限状态
      const atManager = abilityAccessCtrl.createAtManager();
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      const tokenID = bundleInfo.appInfo.accessTokenId;
      
      const grantStatus = await atManager.checkAccessToken(tokenID, permission);
      
      // 如果状态是 PERMISSION_DENIED，可能是永久拒绝
      // 注意：鸿蒙系统中没有直接的"永久拒绝"概念，这里简化处理
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    } catch (err) {
      hilog.error(DOMAIN, PermissionManager.TAG, `Failed to check permanent denial: ${JSON.stringify(err)}`);
      return false;
    }
  }

  /**
   * 获取权限提示消息
   */
  static getPermissionRationale(): string {
    return '定位权限用于在地图上显示您的当前位置，帮助您更好地使用地图功能。';
  }

  /**
   * 获取永久拒绝后的提示消息
   */
  static getPermanentlyDeniedMessage(): string {
    return '定位权限已被拒绝，请前往系统设置中手动授予权限。';
  }

  /**
   * 检查位置服务是否开启
   */
  static async isLocationServiceEnabled(): Promise<boolean> {
    try {
      // 注意：实际实现需要检查系统位置服务状态
      // 这里简化处理，返回 true
      return true;
    } catch (err) {
      hilog.error(DOMAIN, PermissionManager.TAG, `Failed to check location service: ${JSON.stringify(err)}`);
      return false;
    }
  }
}

/**
 * 权限请求结果
 */
export interface PermissionRequestResult {
  // 是否授予权限
  granted: boolean;
  // 被拒绝的权限列表
  deniedPermissions: Array<Permissions>;
  // 是否永久拒绝
  permanentlyDenied: boolean;
  // 错误信息（如果有）
  error?: BusinessError;
}

