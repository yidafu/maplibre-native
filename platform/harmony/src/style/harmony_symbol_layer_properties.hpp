#pragma once

#include <mbgl/style/layers/symbol_layer_properties.hpp>
#include <vector>
#include <string>

namespace mbgl {
namespace style {
namespace harmony {

/**
 * HarmonyOS-specific override for the TextFont default value.
 *
 * Use cases:
 * - Override `TextFont::defaultValue()` to return HarmonyOS fonts.
 * - Make `SymbolLayer` use HarmonyOS Sans instead of Open Sans by default.
 * - Ensure Chinese characters render locally via `LocalGlyphRasterizer`.
 *
 * Technical details:
 * 1. Use the official family name "HarmonyOS Sans" (note the space).
 * 2. `LocalGlyphRasterizer` replaces spaces with underscores when locating files.
 * 3. The actual file loaded is `/system/fonts/HarmonyOS_Sans.ttf`.
 * 4. Enables local rendering of CJK glyphs without downloading from a server.
 */
struct HarmonyTextFont : public TextFont {
    /**
     * Default font stack optimized for HarmonyOS.
     *
     * Use the official family names (with spaces) to match system conventions.
     *
     * Harmony font priority:
     * 1. HarmonyOS Sans family (official variable font covering all weights)
     *    - Family: "HarmonyOS Sans" -> File: HarmonyOS_Sans.ttf
     *    - Family: "HarmonyOS Sans SC" -> File: HarmonyOS_Sans_SC.ttf
     * 2. Noto Sans family (Google open-source fallback)
     *    - NotoSansCJK-Regular.ttc (CJK unified glyphs)
     *    - NotoSans-Regular.ttf (base Latin font)
     * 3. DroidSansFallback.ttf (final fallback)
     */
    static std::vector<std::string> defaultValue() { 
        return {
            {"HarmonyOS Sans"},        // HarmonyOS official default family name.
            {"HarmonyOS Sans SC"},     // Simplified Chinese optimized family.
            {"Noto Sans CJK SC"},      // Noto Sans CJK Simplified Chinese.
            {"Noto Sans"},             // Noto Sans base Latin font.
            {"sans-serif"}             // Generic system fallback.
        }; 
    }
};

/**
 * Get the default HarmonyOS text-font stack.
 *
 * Example (C++):
 * ```cpp
 * auto defaultFonts = harmony::getDefaultTextFont();
 * layer->setTextFont(PropertyValue<std::vector<std::string>>(defaultFonts));
 * ```
 */
inline std::vector<std::string> getDefaultTextFont() {
    return HarmonyTextFont::defaultValue();
}

} // namespace harmony
} // namespace style
} // namespace mbgl

