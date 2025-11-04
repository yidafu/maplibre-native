#pragma once

#include <mbgl/style/layers/symbol_layer_properties.hpp>
#include <vector>
#include <string>

namespace mbgl {
namespace style {
namespace harmony {

/**
 * HarmonyOS 平台特定的 TextFont 默认值覆盖
 * 
 * 用途：
 * - 覆盖核心 TextFont::defaultValue() 返回 HarmonyOS 字体
 * - 使 SymbolLayer 默认使用 HarmonyOS Sans 而非 Open Sans
 * - 确保中文字符能通过 LocalGlyphRasterizer 本地渲染
 * 
 * 技术原理：
 * 1. 使用官方字体族名称 "HarmonyOS Sans"（带空格）
 * 2. LocalGlyphRasterizer 会自动将空格转换为下划线来查找文件
 * 3. 实际加载 /system/fonts/HarmonyOS_Sans.ttf 字体文件
 * 4. 本地渲染 CJK 字符，无需从服务器下载
 */
struct HarmonyTextFont : public TextFont {
    /**
     * HarmonyOS 优化的默认字体栈
     * 
     * ⚠️ 使用官方字体族名称（带空格），与系统字体规范一致
     * 
     * 鸿蒙系统字体（按优先级排序）：
     * 1. HarmonyOS Sans 系列（官方字体，可变字体支持所有字重）
     *    - 字体族: "HarmonyOS Sans" → 文件: HarmonyOS_Sans.ttf
     *    - 字体族: "HarmonyOS Sans SC" → 文件: HarmonyOS_Sans_SC.ttf
     * 2. Noto Sans 系列（Google 开源字体备选）
     *    - NotoSansCJK-Regular.ttc (CJK 统一字体)
     *    - NotoSans-Regular.ttf (基础字体)
     * 3. DroidSansFallback.ttf (最终备选)
     */
    static std::vector<std::string> defaultValue() { 
        return {
            {"HarmonyOS Sans"},        // HarmonyOS 官方默认字体（官方字体族名称）
            {"HarmonyOS Sans SC"},     // HarmonyOS 简体中文优化（官方字体族名称）
            {"Noto Sans CJK SC"},      // Noto Sans 简体中文
            {"Noto Sans"},             // Noto Sans 基础字体
            {"sans-serif"}             // 系统默认字体别名
        }; 
    }
};

/**
 * 获取 HarmonyOS 平台的默认 text-font
 * 
 * 使用示例（C++ 端）：
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

