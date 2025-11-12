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
 * Convert a char32_t Unicode code point into a UTF-8 string.
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
 * Render glyphs using the TextBlob approach (per the official documentation).
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
     * Render a glyph with TextBlob exactly as described in the documentation.
     */
    PremultipliedImage drawGlyphBitmap(char32_t codepoint, 
                                       const std::string& /* fontName */,
                                       bool bold) {
        constexpr uint32_t bitmapSize = 35;
        constexpr float fontSize = 24.0f;
        std::string text = codepointToUTF8(codepoint);
        
        // 1. Create the font object.
        OH_Drawing_Font* font = OH_Drawing_FontCreate();
        if (!font) {
            Log::Error(Event::General, "HarmonyOS: Failed to create font");
            return PremultipliedImage(Size(bitmapSize, bitmapSize));
        }
        
        // Configure font size.
        OH_Drawing_FontSetTextSize(font, fontSize);
        
        // Configure anti-aliasing and related properties.
        OH_Drawing_FontSetEdging(font, FONT_EDGING_ANTI_ALIAS);
        OH_Drawing_FontSetSubpixel(font, true);
        
        // Apply fake bold when requested.
        if (bold) {
            OH_Drawing_FontSetFakeBoldText(font, true);
        }
        
        // 2. Create the text blob as documented.
        OH_Drawing_TextBlob* textBlob = OH_Drawing_TextBlobCreateFromString(
            text.c_str(), 
            font, 
            TEXT_ENCODING_UTF8
        );
        
        if (!textBlob) {
            OH_Drawing_FontDestroy(font);
            return PremultipliedImage(Size(bitmapSize, bitmapSize));
        }
        
        // 3. Create the bitmap.
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
        
        // 4. Create the canvas.
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
        
        // 5. Create the brush (critical per the documentation).
        OH_Drawing_Brush* brush = OH_Drawing_BrushCreate();
        if (!brush) {
            OH_Drawing_CanvasDestroy(canvas);
            OH_Drawing_BitmapDestroy(bitmap);
            OH_Drawing_TextBlobDestroy(textBlob);
            OH_Drawing_FontDestroy(font);
            return PremultipliedImage(Size(bitmapSize, bitmapSize));
        }
        
        // Enable anti-aliasing on the brush.
        OH_Drawing_BrushSetAntiAlias(brush, true);
        // Paint in opaque black.
        OH_Drawing_BrushSetColor(brush, 0xFF000000);
        
        // 6. For Chinese glyphs, add a pen outline (per "Chinese text stroke").
        OH_Drawing_Pen* pen = OH_Drawing_PenCreate();
        if (pen) {
            OH_Drawing_PenSetAntiAlias(pen, true);
            OH_Drawing_PenSetWidth(pen, 0); // No stroke width.
            OH_Drawing_PenSetColor(pen, 0xFF000000);
        }
        
        // 7. Draw the text blob (follow the documented order).
        // For Chinese glyphs: stroke first, then fill.
        if (pen) {
            OH_Drawing_CanvasAttachPen(canvas, pen);
            OH_Drawing_CanvasDrawTextBlob(canvas, textBlob, 5.0f, 25.0f);
            OH_Drawing_CanvasDetachPen(canvas);
        }
        
        // Configure brush fill behavior.
        OH_Drawing_CanvasAttachBrush(canvas, brush);
        // Draw the text blob.
        OH_Drawing_CanvasDrawTextBlob(canvas, textBlob, 5.0f, 25.0f);
        
        // 8. Extract pixel data.
        void* pixels = OH_Drawing_BitmapGetPixels(bitmap);
        Size size(bitmapSize, bitmapSize);
        PremultipliedImage result(size);
        
        if (pixels) {
            std::memcpy(result.data.get(), pixels, bitmapSize * bitmapSize * 4);
        }
        
        // 9. Clean up objects in the documented order.
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
