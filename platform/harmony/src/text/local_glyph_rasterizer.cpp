#include <mbgl/text/local_glyph_rasterizer.hpp>
#include <mbgl/util/i18n.hpp>
#include <mbgl/util/platform.hpp>
#include <mbgl/util/constants.hpp>
#include <mbgl/util/logging.hpp>

#include <native_drawing/drawing_font_collection.h>
#include <native_drawing/drawing_canvas.h>
#include <native_drawing/drawing_bitmap.h>
#include <native_drawing/drawing_font.h>
#include <native_drawing/drawing_text_blob.h>
#include <native_drawing/drawing_typeface.h>
#include <native_drawing/drawing_brush.h>
#include <native_drawing/drawing_pen.h>

#include <memory>
#include <sstream>
#include <cmath>
#include <cstring>

namespace mbgl {

namespace {

/**
 * 将 char32_t Unicode 码点转换为 UTF-8 字符串
 */
std::string codepointToUTF8(char32_t codepoint) {
    std::string result;
    
    if (codepoint < 0x80) {
        result += static_cast<char>(codepoint);
    } else if (codepoint < 0x800) {
        result += static_cast<char>(0xC0 | (codepoint >> 6));
        result += static_cast<char>(0x80 | (codepoint & 0x3F));
    } else if (codepoint < 0x10000) {
        result += static_cast<char>(0xE0 | (codepoint >> 12));
        result += static_cast<char>(0x80 | ((codepoint >> 6) & 0x3F));
        result += static_cast<char>(0x80 | (codepoint & 0x3F));
    } else {
        result += static_cast<char>(0xF0 | (codepoint >> 18));
        result += static_cast<char>(0x80 | ((codepoint >> 12) & 0x3F));
        result += static_cast<char>(0x80 | ((codepoint >> 6) & 0x3F));
        result += static_cast<char>(0x80 | (codepoint & 0x3F));
    }
    
    return result;
}

} // namespace

/**
 * 使用 TextBlob 方式（参考官方文档）
 * https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/textblock-drawing-c
 */
class LocalGlyphRasterizer::Impl {
public:
    explicit Impl(const std::optional<std::string>& fontFamily_)
        : fontFamily(fontFamily_) {
        fontCollection = OH_Drawing_CreateSharedFontCollection();
    }
    
    ~Impl() {
        if (fontCollection) {
            OH_Drawing_DestroyFontCollection(fontCollection);
        }
    }
    
    bool isConfigured() const {
        return fontCollection != nullptr;
    }
    
    /**
     * 使用 TextBlob 渲染字形（按照官方文档正确实现）
     */
    PremultipliedImage drawGlyphBitmap(char32_t codepoint, 
                                       const std::string& /* fontName */,
                                       bool bold) {
        constexpr uint32_t bitmapSize = 35;
        constexpr float fontSize = 24.0f;
        std::string text = codepointToUTF8(codepoint);
        
        // 1. 创建字体对象
        OH_Drawing_Font* font = OH_Drawing_FontCreate();
        if (!font) {
            Log::Error(Event::General, "HarmonyOS: Failed to create font");
            return PremultipliedImage(Size(bitmapSize, bitmapSize));
        }
        
        // 设置字体大小
        OH_Drawing_FontSetTextSize(font, fontSize);
        
        // 设置抗锯齿和其他属性
        OH_Drawing_FontSetEdging(font, FONT_EDGING_ANTI_ALIAS);
        OH_Drawing_FontSetSubpixel(font, true);
        
        // 设置粗体
        if (bold) {
            OH_Drawing_FontSetFakeBoldText(font, true);
        }
        
        // 2. 创建字块对象（按照官方文档）
        OH_Drawing_TextBlob* textBlob = OH_Drawing_TextBlobCreateFromString(
            text.c_str(), 
            font, 
            TEXT_ENCODING_UTF8
        );
        
        if (!textBlob) {
            OH_Drawing_FontDestroy(font);
            return PremultipliedImage(Size(bitmapSize, bitmapSize));
        }
        
        // 3. 创建 Bitmap
        OH_Drawing_Bitmap* bitmap = OH_Drawing_BitmapCreate();
        if (!bitmap) {
            Log::Error(Event::General, "HarmonyOS: Failed to create bitmap");
            OH_Drawing_TextBlobDestroy(textBlob);
            OH_Drawing_FontDestroy(font);
            return PremultipliedImage(Size(bitmapSize, bitmapSize));
        }
        
        OH_Drawing_BitmapFormat format;
        format.colorFormat = COLOR_FORMAT_RGBA_8888;
        format.alphaFormat = ALPHA_FORMAT_PREMUL;
        OH_Drawing_BitmapBuild(bitmap, bitmapSize, bitmapSize, &format);
        
        // 4. 创建 Canvas
        OH_Drawing_Canvas* canvas = OH_Drawing_CanvasCreate();
        if (!canvas) {
            Log::Error(Event::General, "HarmonyOS: Failed to create canvas");
            OH_Drawing_BitmapDestroy(bitmap);
            OH_Drawing_TextBlobDestroy(textBlob);
            OH_Drawing_FontDestroy(font);
            return PremultipliedImage(Size(bitmapSize, bitmapSize));
        }
        
        OH_Drawing_CanvasBind(canvas, bitmap);
        OH_Drawing_CanvasClear(canvas, 0xFFFFFFFF);
        
        // 5. 创建画刷（关键！按照官方文档）
        OH_Drawing_Brush* brush = OH_Drawing_BrushCreate();
        if (!brush) {
            OH_Drawing_CanvasDestroy(canvas);
            OH_Drawing_BitmapDestroy(bitmap);
            OH_Drawing_TextBlobDestroy(textBlob);
            OH_Drawing_FontDestroy(font);
            return PremultipliedImage(Size(bitmapSize, bitmapSize));
        }
        
        // 设置画刷抗锯齿
        OH_Drawing_BrushSetAntiAlias(brush, true);
        // 设置画刷颜色为黑色
        OH_Drawing_BrushSetColor(brush, 0xFF000000);
        
        // 6. 对于中文，还需要画笔描边（参考官方文档"中文文字描边"）
        OH_Drawing_Pen* pen = OH_Drawing_PenCreate();
        if (pen) {
            OH_Drawing_PenSetAntiAlias(pen, true);
            OH_Drawing_PenSetWidth(pen, 0); // 无描边
            OH_Drawing_PenSetColor(pen, 0xFF000000);
        }
        
        // 7. 绘制字块（按照官方文档顺序）
        // 对于中文：先描边，再填充
        if (pen) {
            OH_Drawing_CanvasAttachPen(canvas, pen);
            OH_Drawing_CanvasDrawTextBlob(canvas, textBlob, 5.0f, 25.0f);
            OH_Drawing_CanvasDetachPen(canvas);
        }
        
        // 设置画刷填充效果
        OH_Drawing_CanvasAttachBrush(canvas, brush);
        // 绘制字块
        OH_Drawing_CanvasDrawTextBlob(canvas, textBlob, 5.0f, 25.0f);
        
        // 8. 提取像素
        void* pixels = OH_Drawing_BitmapGetPixels(bitmap);
        Size size(bitmapSize, bitmapSize);
        PremultipliedImage result(size);
        
        if (pixels) {
            std::memcpy(result.data.get(), pixels, bitmapSize * bitmapSize * 4);
        }
        
        // 9. 清理（按照官方文档顺序）
        OH_Drawing_CanvasDetachBrush(canvas);
        if (pen) {
            OH_Drawing_PenDestroy(pen);
        }
        OH_Drawing_BrushDestroy(brush);
        OH_Drawing_CanvasDestroy(canvas);
        OH_Drawing_BitmapDestroy(bitmap);
        OH_Drawing_TextBlobDestroy(textBlob);
        OH_Drawing_FontDestroy(font);
        
        return result;
    }
    
private:
    std::optional<std::string> fontFamily;
    OH_Drawing_FontCollection* fontCollection = nullptr;
};

LocalGlyphRasterizer::LocalGlyphRasterizer(const std::optional<std::string>& fontFamily)
    : impl(std::make_unique<Impl>(fontFamily)) {}

LocalGlyphRasterizer::~LocalGlyphRasterizer() = default;

bool LocalGlyphRasterizer::canRasterizeGlyph(const FontStack&, GlyphID glyphID) {
    return util::i18n::allowsFixedWidthGlyphGeneration(glyphID) && impl->isConfigured();
}

Glyph LocalGlyphRasterizer::rasterizeGlyph(const FontStack& fontStack, GlyphID glyphID) {
    Glyph glyph;
    glyph.id = glyphID;
    
    if (!impl->isConfigured()) {
        return glyph;
    }

    std::string fontName = "HarmonyOS Sans";
    if (!fontStack.empty()) {
        const auto& firstFont = fontStack.front();
        if (firstFont != util::LAST_RESORT_ALPHABETIC_FONT && 
            firstFont != util::LAST_RESORT_PAN_UNICODE_FONT) {
            fontName = firstFont;
        }
    }

    bool bold = false;
    for (const auto& font : fontStack) {
        std::string lowercaseFont = platform::lowercase(font);
        if (lowercaseFont.find("bold") != std::string::npos && 
            lowercaseFont.find("semibold") == std::string::npos) {
            bold = true;
            break;
        }
    }

    PremultipliedImage rgbaBitmap = impl->drawGlyphBitmap(glyphID, fontName, bold);

    constexpr uint32_t bitmapSize = 35;
    Size size(bitmapSize, bitmapSize);
    
    glyph.metrics.width = bitmapSize;
    glyph.metrics.height = bitmapSize;
    glyph.metrics.left = -2;
    glyph.metrics.top = -5;
    glyph.metrics.advance = 24;

    glyph.bitmap = AlphaImage(size);
    for (uint32_t i = 0; i < size.width * size.height; i++) {
        glyph.bitmap.data[i] = 0xff - static_cast<uint8_t>(
            std::round(0.2126 * rgbaBitmap.data[4 * i] + 
                      0.7152 * rgbaBitmap.data[4 * i + 1] +
                      0.0722 * rgbaBitmap.data[4 * i + 2])
        );
    }

    return glyph;
}

} // namespace mbgl
