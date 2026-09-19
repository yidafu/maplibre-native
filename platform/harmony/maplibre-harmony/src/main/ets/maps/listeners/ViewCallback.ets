import { StateCallback } from './StateCallback';

/**
 * ViewCallback - view callback interface.
 *
 * 方法集与 StateCallback 完全一致，历史上是整份复制出来的。改为空继承以
 * 消除两份副本各自漂移的风险；两个类型名都继续对外导出（外部实现的
 * implements 与参数注解不受影响），未来 ViewCallback 也可在此之上追加
 * view 专属方法而不影响 StateCallback。
 */
export interface ViewCallback extends StateCallback {
}
