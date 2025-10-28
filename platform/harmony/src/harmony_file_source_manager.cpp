#include "harmony_main_resource_loader.hpp"

// FileSource manager
#include <mbgl/storage/file_source_manager.hpp>
#include <mbgl/storage/resource_options.hpp>
#include <mbgl/util/logging.hpp>

// FileSource implementations - now accessible via CMAKE include paths
#include <mbgl/storage/asset_file_source.hpp>
#include <mbgl/storage/database_file_source.hpp>
#include <mbgl/storage/local_file_source.hpp>
#include <mbgl/storage/online_file_source.hpp>
#include <mbgl/storage/mbtiles_file_source.hpp>
#include <mbgl/storage/pmtiles_file_source.hpp>

namespace mbgl {

/**
 * @brief Harmony 平台专用的 FileSourceManager 实现
 * 
 * 这个实现使用 HarmonyMainResourceLoader 代替默认的 MainResourceLoader，
 * 修复了 Actor invoke 失败的问题。
 */
class HarmonyFileSourceManagerImpl final : public FileSourceManager {
public:
    HarmonyFileSourceManagerImpl() {
        mbgl::Log::Info(mbgl::Event::General, "[Harmony] Registering HarmonyMainResourceLoader");
        
        // 🔧 FIX: 使用 HarmonyMainResourceLoader 代替默认的 MainResourceLoader
        registerFileSourceFactory(FileSourceType::ResourceLoader,
                                  [](const ResourceOptions& resourceOptions, const ClientOptions& clientOptions) {
                                      mbgl::Log::Info(mbgl::Event::General, 
                                                     "[Harmony] Creating HarmonyMainResourceLoader instance");
                                      return std::make_unique<HarmonyMainResourceLoader>(resourceOptions, clientOptions);
                                  });

        registerFileSourceFactory(FileSourceType::Asset,
                                  [](const ResourceOptions& resourceOptions, const ClientOptions& clientOptions) {
                                      return std::make_unique<AssetFileSource>(resourceOptions, clientOptions);
                                  });

        registerFileSourceFactory(FileSourceType::Database,
                                  [](const ResourceOptions& resourceOptions, const ClientOptions& clientOptions) {
                                      return std::make_unique<DatabaseFileSource>(resourceOptions, clientOptions);
                                  });

        registerFileSourceFactory(FileSourceType::FileSystem,
                                  [](const ResourceOptions& resourceOptions, const ClientOptions& clientOptions) {
                                      return std::make_unique<LocalFileSource>(resourceOptions, clientOptions);
                                  });

        registerFileSourceFactory(FileSourceType::Mbtiles,
                                  [](const ResourceOptions& resourceOptions, const ClientOptions& clientOptions) {
                                      return std::make_unique<MBTilesFileSource>(resourceOptions, clientOptions);
                                  });

        registerFileSourceFactory(FileSourceType::Pmtiles,
                                  [](const ResourceOptions& resourceOptions, const ClientOptions& clientOptions) {
                                      return std::make_unique<PMTilesFileSource>(resourceOptions, clientOptions);
                                  });

        registerFileSourceFactory(FileSourceType::Network,
                                  [](const ResourceOptions& resourceOptions, const ClientOptions& clientOptions) {
                                      return std::make_unique<OnlineFileSource>(resourceOptions, clientOptions);
                                  });
        
        mbgl::Log::Info(mbgl::Event::General, 
                       "[Harmony] HarmonyFileSourceManagerImpl initialized successfully");
    }
};

FileSourceManager* FileSourceManager::get() noexcept {
    static HarmonyFileSourceManagerImpl instance;
    mbgl::Log::Info(mbgl::Event::General, 
                   "[Harmony] FileSourceManager::get() called, using Harmony implementation");
    return &instance;
}

} // namespace mbgl

