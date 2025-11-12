import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { updateAbcVersionPlugin, updateHarAbcVersionPlugin } from './plugin.ts';

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins:[updateAbcVersionPlugin(), updateHarAbcVersionPlugin()]         /* Custom plugin to extend the functionality of Hvigor. */
}