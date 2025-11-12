import {OhosPluginId, Target} from '@ohos/hvigor-ohos-plugin';
import {hvigor, HvigorNode, HvigorPlugin} from '@ohos/hvigor';
import path from "path";
import fs from "fs";


function getLoaderJsonPath(target: Target) {
  return path.resolve(target.getBuildTargetOutputPath(), `../../intermediates/loader/${target.getTargetName()}/loader.json`);
}


function getPkgContextInfoPath(target: Target) {
  return path.resolve(target.getBuildTargetOutputPath(), `../../intermediates/loader/${target.getTargetName()}/pkgContextInfo.json`);
}


function deleteLoaderJson(target: Target) {
  const loaderJsonPath = getLoaderJsonPath(target);
  if (fs.existsSync(loaderJsonPath)) {
    fs.rmSync(loaderJsonPath);
  }
}


function deletePkgContextInfo(target: Target) {
  const pkgContextInfoPath = getPkgContextInfoPath(target);
  if (fs.existsSync(pkgContextInfoPath)) {
    fs.rmSync(pkgContextInfoPath);
  }
}


function deleteRollupCache(target: Target, buildMode: string) {
  const arkTSCompileCachePath = path.resolve(target.getBuildTargetOutputPath(),
    `../../cache/${target.getTargetName()}/${target.getTargetName()}@HarCompileArkTS/esmodule/${buildMode}/compiler.cache`);
  if (fs.existsSync(arkTSCompileCachePath)) {
    fs.rmSync(arkTSCompileCachePath, { recursive: true });
  }
}


function updateHapHspAbcVersion(subNode: HvigorNode, target: Target) {
  const task = subNode.getTaskByName(`${target.getTargetName()}@GenerateLoaderJson`);
  if (!task) {
    console.log('GenerateLoaderJson not found.');
    return;
  }
  deleteLoaderJson(target);
  deletePkgContextInfo(target);
  task.afterRun(() => {
    const pkgContextInfoPath = getPkgContextInfoPath(target);
    if (!fs.existsSync(pkgContextInfoPath)) {
      console.log('pkgContextInfo not found.');
      return;
    }
    const pkgContextInfoObj = JSON.parse(fs.readFileSync(pkgContextInfoPath).toString());
    if (!pkgContextInfoObj) {
      console.log('pkgContextInfo parse failed.');
      return;
    }
    const loaderJsonPath = getLoaderJsonPath(target);
    if (!fs.existsSync(loaderJsonPath)) {
      console.log('loaderJson not found.');
      return;
    }
    const loaderJsonObj = JSON.parse(fs.readFileSync(loaderJsonPath).toString());
    if (!loaderJsonObj) {
      console.log('loaderJson parse failed.');
      return;
    }
    for (const [key, value] of Object.entries(pkgContextInfoObj)) {
      if (!value?.version) {
        continue;
      }
      if (!loaderJsonObj.updateVersionInfo[key]) {
        loaderJsonObj.updateVersionInfo[key] = {};
      }
      loaderJsonObj.updateVersionInfo[key][key] = value.version;
    }
    fs.writeFileSync(loaderJsonPath, JSON.stringify(loaderJsonObj));
  });
}


function updateHarAbcVersion(target: Target) {
  deleteLoaderJson(target);
  deleteRollupCache(target, 'debug');
  deleteRollupCache(target, 'release');
}


// The user of bytecode har can use this plugin to correctly modify the version number of ohmurl in abc when integrating bytecode har, ensuring no crashes during runtime
export function updateAbcVersionPlugin(): HvigorPlugin {
  return {
    pluginId: 'updateAbcVersionPlugin',
    apply(node: HvigorNode) {
      hvigor.nodesEvaluated(() => {
        hvigor.getRootNode().subNodes(subNode => {
          let context = subNode.getContext(OhosPluginId.OHOS_HAP_PLUGIN);
          if (!context) {
            context = subNode.getContext(OhosPluginId.OHOS_HSP_PLUGIN);
          }
          if (!context) {
            return;
          }
          context.targets(target => {
            updateHapHspAbcVersion(subNode, target);
          });
        });
      });
    }
  };
}


// The generator of bytecode har uses this plugin to incrementally build ohmurl with the correct bytecode har after modifying the version number
export function updateHarAbcVersionPlugin(): HvigorPlugin {
  return {
    pluginId: 'updateHarAbcVersionPlugin',
    apply(node: HvigorNode) {
      hvigor.nodesEvaluated(() => {
        hvigor.getRootNode().subNodes(subNode => {
          const context = subNode.getContext(OhosPluginId.OHOS_HAR_PLUGIN);
          if (!context) {
            return;
          }
          context.targets(target => {
            updateHarAbcVersion(target);
          });
        });
      });
    }
  };
}