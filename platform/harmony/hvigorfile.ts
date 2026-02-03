import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { updateAbcVersionPlugin, updateHarAbcVersionPlugin } from './plugin.ts';

process.env.CURL_MODE = 'poll'; // Force CURL to run in event-driven mode

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins:[updateAbcVersionPlugin(), updateHarAbcVersionPlugin()]         /* Custom plugin to extend the functionality of Hvigor. */
}