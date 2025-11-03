#include <mbgl/text/local_glyph_rasterizer.hpp>
#include <mbgl/util/i18n.hpp>
#include <mbgl/util/platform.hpp>
#include <mbgl/util/constants.hpp>
#include <mbgl/util/logging.hpp>

#ifdef MLN_TEXT_SHAPING_HARFBUZZ
#include <mbgl/text/freetype.hpp>
#endif

#include <filesystem>
#include <map>
#include <memory>
#include <sstream>

namespace mbgl {

namespace {

// 列出目录下的所有文件（用于调试）
void listDirectoryContents(const std::string& dirPath) {
    try {
        if (!std::filesystem::exists(dirPath)) {
            Log::Info(Event::General, "Directory does not exist: " + dirPath);
            return;
        }
        
        Log::Info(Event::General, "Listing contents of: " + dirPath);
        int fileCount = 0;
        for (const auto& entry : std::filesystem::directory_iterator(dirPath)) {
            if (entry.is_regular_file()) {
                Log::Info(Event::General, "  - " + entry.path().filename().string());
                fileCount++;
            }
        }
        Log::Info(Event::General, "Total files found: " + std::to_string(fileCount));
    } catch (const std::exception& e) {
        Log::Warning(Event::General, "Failed to list directory " + dirPath + ": " + e.what());
    }
}

// 获取鸿蒙系统字体路径
std::string getSystemFontPath(const std::string& fontFamily, bool bold) {
    // 鸿蒙系统字体目录
    const std::vector<std::string> fontPaths = {
        "/system/fonts/",
        "/data/fonts/",
    };
    
    // 第一次调用时列出系统字体目录内容（用于调试）
    static bool firstCall = true;
    if (firstCall) {
        firstCall = false;
        Log::Info(Event::General, "=== Font Path Discovery Started ===");
        for (const auto& path : fontPaths) {
            listDirectoryContents(path);
        }
        Log::Info(Event::General, "=== Font Path Discovery Completed ===");
    }
    
    Log::Info(Event::General, "Searching font for family: " + fontFamily + 
              (bold ? " (bold)" : " (regular)"));
    
    // 字体文件名映射
    std::vector<std::string> candidateFiles;
    
    if (fontFamily == "HarmonyOS_Sans" || fontFamily == "sans-serif" || fontFamily.empty()) {
        // HarmonyOS Sans 是默认字体（可变字体，包含所有字重）
        // 根据实际系统字体文件名
        candidateFiles = {
            // HarmonyOS Sans 系列（实际存在的文件）
            "HarmonyOS_Sans.ttf",           // 默认可变字体，支持所有字重
            "HarmonyOS_Sans_SC.ttf",        // 简体中文优化版本
            "HarmonyOS_Sans_TC.ttf",        // 繁体中文版本
            // Noto Sans CJK 备选（.ttc 格式，TrueType Collection）
            "NotoSansCJK-Regular.ttc",
            "NotoSans-Regular.ttf",
            "NotoSans[wdth,wght].ttf",      // 可变字体
            // 最终备选
            "DroidSansFallback.ttf",
        };
    } else {
        // 尝试直接使用提供的字体名
        candidateFiles.push_back(fontFamily + (bold ? "_Bold.ttf" : "_Regular.ttf"));
        candidateFiles.push_back(fontFamily + (bold ? "-Bold.ttf" : "-Regular.ttf"));
        candidateFiles.push_back(fontFamily + (bold ? "_Bold.otf" : "_Regular.otf"));
        candidateFiles.push_back(fontFamily + (bold ? "-Bold.otf" : "-Regular.otf"));
        candidateFiles.push_back(fontFamily + ".ttf");
        candidateFiles.push_back(fontFamily + ".otf");
    }
    
    // 查找第一个存在的字体文件
    for (const auto& basePath : fontPaths) {
        for (const auto& filename : candidateFiles) {
            std::string fullPath = basePath + filename;
            Log::Info(Event::General, "Trying: " + fullPath);
            if (std::filesystem::exists(fullPath)) {
                Log::Info(Event::General, "✓ Found font: " + fullPath);
                return fullPath;
            }
        }
    }
    
    Log::Warning(Event::General, "No suitable font found for: " + fontFamily + 
                 (bold ? " (bold)" : " (regular)"));
    return "";
}

} // namespace

#ifdef MLN_TEXT_SHAPING_HARFBUZZ

class LocalGlyphRasterizer::Impl {
public:
    Impl(const std::optional<std::string>& fontFamily_)
        : fontFamily(fontFamily_),
          freeTypeLib(std::make_unique<FreeTypeLibrary>()) {
        if (fontFamily) {
            Log::Info(Event::General, "LocalGlyphRasterizer initialized with font family: " + *fontFamily);
        } else {
            Log::Info(Event::General, "LocalGlyphRasterizer initialized with default system font");
        }
    }

    bool isConfigured() const {
        // 即使没有指定字体族，也尝试使用系统默认字体
        return true;
    }

    FreeTypeFace* getFontFace(const FontStack& fontStack, bool bold) {
        // 确定字体名称，默认使用 HarmonyOS_Sans
        std::string fontName = fontFamily.value_or("HarmonyOS_Sans");
        
        // 如果 fontStack 不为空，尝试使用第一个字体
        if (!fontStack.empty()) {
            const auto& firstFont = fontStack.front();
            // 跳过 MapLibre 的 last resort 字体
            if (firstFont != util::LAST_RESORT_ALPHABETIC_FONT && 
                firstFont != util::LAST_RESORT_PAN_UNICODE_FONT) {
                fontName = firstFont;
            }
        }
        
        // 生成缓存键
        std::string cacheKey = fontName + (bold ? ":bold" : ":regular");
        
        // 检查缓存
        auto it = fontCache.find(cacheKey);
        if (it != fontCache.end() && it->second && it->second->isValid()) {
            return it->second.get();
        }
        
        // 加载字体文件
        std::string fontPath = getSystemFontPath(fontName, bold);
        if (fontPath.empty()) {
            Log::Warning(Event::General, "Failed to find font file for: " + cacheKey);
            return nullptr;
        }
        
        // 创建 FreeTypeFace
        auto face = std::make_unique<FreeTypeFace>(fontPath, *freeTypeLib);
        if (!face->isValid()) {
            Log::Error(Event::General, "Failed to load font: " + fontPath);
            return nullptr;
        }
        
        Log::Info(Event::General, "Loaded font: " + fontPath);
        auto* facePtr = face.get();
        fontCache[cacheKey] = std::move(face);
        return facePtr;
    }

private:
    std::optional<std::string> fontFamily;
    std::unique_ptr<FreeTypeLibrary> freeTypeLib;
    std::map<std::string, std::unique_ptr<FreeTypeFace>> fontCache;
};

#else // !MLN_TEXT_SHAPING_HARFBUZZ

// Stub implementation when FreeType is not available
class LocalGlyphRasterizer::Impl {
public:
    Impl(const std::optional<std::string>&) {
        Log::Warning(Event::General, 
            "LocalGlyphRasterizer: FreeType not available, local glyph rendering disabled");
    }
    bool isConfigured() const { return false; }
};

#endif // MLN_TEXT_SHAPING_HARFBUZZ

LocalGlyphRasterizer::LocalGlyphRasterizer(const std::optional<std::string>& fontFamily)
    : impl(std::make_unique<Impl>(fontFamily)) {}

LocalGlyphRasterizer::~LocalGlyphRasterizer() = default;

bool LocalGlyphRasterizer::canRasterizeGlyph(const FontStack&, GlyphID glyphID) {
#ifdef MLN_TEXT_SHAPING_HARFBUZZ
    // 只处理 CJK 字符
    bool canRasterize = util::i18n::allowsFixedWidthGlyphGeneration(glyphID) && impl->isConfigured();
    if (canRasterize) {
        std::ostringstream oss;
        oss << "canRasterizeGlyph: YES for glyphID=" << static_cast<uint32_t>(glyphID);
        Log::Info(Event::General, oss.str());
    }
    return canRasterize;
#else
    (void)glyphID; // Suppress unused warning
    return false;
#endif
}

Glyph LocalGlyphRasterizer::rasterizeGlyph(const FontStack& fontStack, GlyphID glyphID) {
#ifdef MLN_TEXT_SHAPING_HARFBUZZ
    Glyph glyph;
    glyph.id = glyphID;
    
    // 记录 glyph 渲染请求
    std::ostringstream oss;
    oss << "rasterizeGlyph called: glyphID=" << static_cast<uint32_t>(glyphID) << ", fontStack=[";
    for (size_t i = 0; i < fontStack.size(); ++i) {
        if (i > 0) oss << ", ";
        oss << fontStack[i];
    }
    oss << "]";
    Log::Info(Event::General, oss.str());

    if (!impl->isConfigured()) {
        Log::Warning(Event::General, "LocalGlyphRasterizer not configured");
        return glyph;
    }

    // 检测是否需要粗体
    bool bold = false;
    for (const auto& font : fontStack) {
        std::string lowercaseFont = platform::lowercase(font);
        // 检查 "bold" 但排除 "semibold"
        if (lowercaseFont.find("bold") != std::string::npos && 
            lowercaseFont.find("semibold") == std::string::npos) {
            bold = true;
            break;
        }
    }

    // 获取字体
    FreeTypeFace* face = impl->getFontFace(fontStack, bold);
    if (!face) {
        Log::Warning(Event::General, "Failed to get font face for glyph rendering");
        return glyph;
    }

    // 使用 FreeType 渲染字形
    try {
        glyph = face->rasterizeGlyph(glyphID);
        std::ostringstream successOss;
        successOss << "✅ Glyph rasterized successfully: glyphID=" << static_cast<uint32_t>(glyphID);
        Log::Info(Event::General, successOss.str());
    } catch (const std::exception& e) {
        Log::Error(Event::General, "Failed to rasterize glyph: " + std::string(e.what()));
    }

    return glyph;
#else
    (void)fontStack; // Suppress unused warnings
    (void)glyphID;
    return Glyph();
#endif
}

} // namespace mbgl

