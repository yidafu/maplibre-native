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

namespace mbgl {

namespace {

// 获取鸿蒙系统字体路径
std::string getSystemFontPath(const std::string& fontFamily, bool bold) {
    // 鸿蒙系统字体目录
    const std::vector<std::string> fontPaths = {
        "/system/fonts/",
        "/data/fonts/",
    };
    
    // 字体文件名映射
    std::vector<std::string> candidateFiles;
    
    if (fontFamily == "sans-serif" || fontFamily.empty()) {
        if (bold) {
            candidateFiles = {
                "HarmonyOS_Sans_SC_Bold.ttf",
                "HarmonyOS_Sans_Bold.ttf",
                "NotoSansCJK-Bold.ttf",
                "NotoSansSC-Bold.ttf",
                "DroidSansFallback.ttf",  // Fallback
            };
        } else {
            candidateFiles = {
                "HarmonyOS_Sans_SC_Regular.ttf",
                "HarmonyOS_Sans_Regular.ttf",
                "NotoSansCJK-Regular.ttf",
                "NotoSansSC-Regular.ttf",
                "DroidSansFallback.ttf",  // Fallback
            };
        }
    } else {
        // 尝试直接使用提供的字体名
        candidateFiles.push_back(fontFamily + (bold ? "-Bold.ttf" : "-Regular.ttf"));
        candidateFiles.push_back(fontFamily + (bold ? "_Bold.ttf" : "_Regular.ttf"));
        candidateFiles.push_back(fontFamily + ".ttf");
    }
    
    // 查找第一个存在的字体文件
    for (const auto& basePath : fontPaths) {
        for (const auto& filename : candidateFiles) {
            std::string fullPath = basePath + filename;
            if (std::filesystem::exists(fullPath)) {
                Log::Info(Event::General, "Found font: " + fullPath);
                return fullPath;
            }
        }
    }
    
    Log::Warning(Event::General, "No suitable font found for: " + fontFamily + (bold ? " (bold)" : ""));
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
        // 确定字体名称
        std::string fontName = fontFamily.value_or("sans-serif");
        
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
    return util::i18n::allowsFixedWidthGlyphGeneration(glyphID) && impl->isConfigured();
#else
    (void)glyphID; // Suppress unused warning
    return false;
#endif
}

Glyph LocalGlyphRasterizer::rasterizeGlyph(const FontStack& fontStack, GlyphID glyphID) {
#ifdef MLN_TEXT_SHAPING_HARFBUZZ
    Glyph glyph;
    glyph.id = glyphID;

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

