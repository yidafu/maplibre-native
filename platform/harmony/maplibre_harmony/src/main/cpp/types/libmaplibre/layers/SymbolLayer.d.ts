/**
 * SymbolLayer Type Definitions
 * 符号图层类型定义
 */

declare namespace maplibre {
    /**
     * SymbolLayer - 符号图层
     * 
     * 用于显示图标和文本标签
     */
    export class SymbolLayer {
        /**
         * 创建 SymbolLayer
         * @param layerId 图层ID
         * @param sourceId 数据源ID
         */
        constructor(layerId: string, sourceId: string);
        
        // ==================== 基本方法 ====================
        
        /**
         * 获取图层ID
         */
        getId(): string;
        
        /**
         * 获取图层类型
         */
        getType(): string;
        
        /**
         * 获取数据源ID
         */
        getSourceId(): string;
        
        /**
         * 设置源图层
         * @param sourceLayer 源图层名称
         */
        setSourceLayer(sourceLayer: string): void;
        
        /**
         * 获取源图层
         */
        getSourceLayer(): string;
        
        /**
         * 设置最小缩放级别
         * @param minZoom 最小缩放级别
         */
        setMinZoom(minZoom: number): void;
        
        /**
         * 获取最小缩放级别
         */
        getMinZoom(): number;
        
        /**
         * 设置最大缩放级别
         * @param maxZoom 最大缩放级别
         */
        setMaxZoom(maxZoom: number): void;
        
        /**
         * 获取最大缩放级别
         */
        getMaxZoom(): number;
        
        // ==================== 图标布局属性 ====================
        
        /**
         * 设置图标图片
         * @param iconImage 图片名称
         */
        setIconImage(iconImage: string): void;
        
        /**
         * 获取图标图片
         */
        getIconImage(): string;
        
        /**
         * 设置图标大小
         * @param size 大小比例
         */
        setIconSize(size: number): void;
        
        /**
         * 获取图标大小
         */
        getIconSize(): number;
        
        /**
         * 设置图标旋转角度
         * @param rotate 旋转角度（度）
         */
        setIconRotate(rotate: number): void;
        
        /**
         * 获取图标旋转角度
         */
        getIconRotate(): number;
        
        /**
         * 设置图标偏移
         * @param offsetX X方向偏移
         * @param offsetY Y方向偏移
         */
        setIconOffset(offsetX: number, offsetY: number): void;
        
        /**
         * 获取图标偏移
         */
        getIconOffset(): number[];
        
        /**
         * 设置图标锚点
         * @param anchor 锚点位置
         */
        setIconAnchor(anchor: string): void;
        
        /**
         * 获取图标锚点
         */
        getIconAnchor(): string;
        
        /**
         * 设置图标是否允许重叠
         * @param allow 是否允许
         */
        setIconAllowOverlap(allow: boolean): void;
        
        /**
         * 获取图标是否允许重叠
         */
        getIconAllowOverlap(): boolean;
        
        // ==================== 文本布局属性 ====================
        
        /**
         * 设置文本内容
         * @param text 文本内容
         */
        setTextField(text: string): void;
        
        /**
         * 获取文本内容
         */
        getTextField(): string;
        
        /**
         * 设置文本字体
         * @param font 字体名称
         */
        setTextFont(font: string): void;
        
        /**
         * 获取文本字体
         */
        getTextFont(): string[];
        
        /**
         * 设置文本大小
         * @param size 字体大小
         */
        setTextSize(size: number): void;
        
        /**
         * 获取文本大小
         */
        getTextSize(): number;
        
        /**
         * 设置文本最大宽度
         * @param maxWidth 最大宽度
         */
        setTextMaxWidth(maxWidth: number): void;
        
        /**
         * 获取文本最大宽度
         */
        getTextMaxWidth(): number;
        
        /**
         * 设置文本偏移
         * @param offsetX X方向偏移
         * @param offsetY Y方向偏移
         */
        setTextOffset(offsetX: number, offsetY: number): void;
        
        /**
         * 获取文本偏移
         */
        getTextOffset(): number[];
        
        /**
         * 设置文本锚点
         * @param anchor 锚点位置
         */
        setTextAnchor(anchor: string): void;
        
        /**
         * 获取文本锚点
         */
        getTextAnchor(): string;
        
        /**
         * 设置文本是否允许重叠
         * @param allow 是否允许
         */
        setTextAllowOverlap(allow: boolean): void;
        
        /**
         * 获取文本是否允许重叠
         */
        getTextAllowOverlap(): boolean;
        
        // ==================== 图标绘制属性 ====================
        
        /**
         * 设置图标不透明度
         * @param opacity 不透明度 (0-1)
         */
        setIconOpacity(opacity: number): void;
        
        /**
         * 获取图标不透明度
         */
        getIconOpacity(): number;
        
        /**
         * 设置图标颜色
         * @param color 颜色值
         */
        setIconColor(color: string): void;
        
        /**
         * 获取图标颜色
         */
        getIconColor(): string;
        
        /**
         * 设置图标光晕颜色
         * @param color 颜色值
         */
        setIconHaloColor(color: string): void;
        
        /**
         * 获取图标光晕颜色
         */
        getIconHaloColor(): string;
        
        /**
         * 设置图标光晕宽度
         * @param width 宽度
         */
        setIconHaloWidth(width: number): void;
        
        /**
         * 获取图标光晕宽度
         */
        getIconHaloWidth(): number;
        
        // ==================== 文本绘制属性 ====================
        
        /**
         * 设置文本不透明度
         * @param opacity 不透明度 (0-1)
         */
        setTextOpacity(opacity: number): void;
        
        /**
         * 获取文本不透明度
         */
        getTextOpacity(): number;
        
        /**
         * 设置文本颜色
         * @param color 颜色值
         */
        setTextColor(color: string): void;
        
        /**
         * 获取文本颜色
         */
        getTextColor(): string;
        
        /**
         * 设置文本光晕颜色
         * @param color 颜色值
         */
        setTextHaloColor(color: string): void;
        
        /**
         * 获取文本光晕颜色
         */
        getTextHaloColor(): string;
        
        /**
         * 设置文本光晕宽度
         * @param width 宽度
         */
        setTextHaloWidth(width: number): void;
        
        /**
         * 获取文本光晕宽度
         */
        getTextHaloWidth(): number;
        
        // ==================== 新增图标布局属性 ====================
        
        /**
         * 设置图标忽略放置
         */
        setIconIgnorePlacement(ignore: boolean): void;
        getIconIgnorePlacement(): boolean;
        
        /**
         * 设置图标可选
         */
        setIconOptional(optional: boolean): void;
        getIconOptional(): boolean;
        
        /**
         * 设置图标填充
         */
        setIconPadding(padding: number): void;
        getIconPadding(): number;
        
        /**
         * 设置防止图标上下颠倒
         */
        setIconKeepUpright(keep: boolean): void;
        getIconKeepUpright(): boolean;
        
        /**
         * 设置图标倾斜对齐
         */
        setIconPitchAlignment(alignment: string): void;
        getIconPitchAlignment(): string;
        
        /**
         * 设置图标旋转对齐
         */
        setIconRotationAlignment(alignment: string): void;
        getIconRotationAlignment(): string;
        
        /**
         * 设置图标文本适配
         */
        setIconTextFit(fit: string): void;
        getIconTextFit(): string;
        
        /**
         * 设置图标文本适配填充
         */
        setIconTextFitPadding(padding: number[]): void;
        getIconTextFitPadding(): number[];
        
        /**
         * 设置图标平移
         */
        setIconTranslate(translate: number[]): void;
        getIconTranslate(): number[];
        
        /**
         * 设置图标平移锚点
         */
        setIconTranslateAnchor(anchor: string): void;
        getIconTranslateAnchor(): string;
        
        /**
         * 设置图标光晕模糊
         */
        setIconHaloBlur(blur: number): void;
        getIconHaloBlur(): number;
        
        // ==================== 新增文本布局属性 ====================
        
        /**
         * 设置文本字母间距
         */
        setTextLetterSpacing(spacing: number): void;
        getTextLetterSpacing(): number;
        
        /**
         * 设置文本对齐方式
         */
        setTextJustify(justify: string): void;
        getTextJustify(): string;
        
        /**
         * 设置文本径向偏移
         */
        setTextRadialOffset(offset: number): void;
        getTextRadialOffset(): number;
        
        /**
         * 设置文本可变锚点
         */
        setTextVariableAnchor(anchors: string[]): void;
        getTextVariableAnchor(): string[];
        
        /**
         * 设置文本可变锚点偏移
         */
        setTextVariableAnchorOffset(offset: number[]): void;
        getTextVariableAnchorOffset(): number[];
        
        /**
         * 设置文本旋转角度
         */
        setTextRotate(rotate: number): void;
        getTextRotate(): number;
        
        /**
         * 设置文本填充
         */
        setTextPadding(padding: number): void;
        getTextPadding(): number;
        
        /**
         * 设置防止文本上下颠倒
         */
        setTextKeepUpright(keep: boolean): void;
        getTextKeepUpright(): boolean;
        
        /**
         * 设置文本转换
         */
        setTextTransform(transform: string): void;
        getTextTransform(): string;
        
        /**
         * 设置文本最大角度
         */
        setTextMaxAngle(angle: number): void;
        getTextMaxAngle(): number;
        
        /**
         * 设置文本旋转对齐
         */
        setTextRotationAlignment(alignment: string): void;
        getTextRotationAlignment(): string;
        
        /**
         * 设置文本倾斜对齐
         */
        setTextPitchAlignment(alignment: string): void;
        getTextPitchAlignment(): string;
        
        /**
         * 设置文本行高
         */
        setTextLineHeight(lineHeight: number): void;
        getTextLineHeight(): number;
        
        /**
         * 设置文本书写模式
         */
        setTextWritingMode(mode: string[]): void;
        getTextWritingMode(): string[];
        
        /**
         * 设置文本忽略放置
         */
        setTextIgnorePlacement(ignore: boolean): void;
        getTextIgnorePlacement(): boolean;
        
        /**
         * 设置文本可选
         */
        setTextOptional(optional: boolean): void;
        getTextOptional(): boolean;
        
        // ==================== 新增文本绘制属性 ====================
        
        /**
         * 设置文本光晕模糊
         */
        setTextHaloBlur(blur: number): void;
        getTextHaloBlur(): number;
        
        /**
         * 设置文本平移
         */
        setTextTranslate(translate: number[]): void;
        getTextTranslate(): number[];
        
        /**
         * 设置文本平移锚点
         */
        setTextTranslateAnchor(anchor: string): void;
        getTextTranslateAnchor(): string;
        
        // ==================== 符号通用属性 ====================
        
        /**
         * 设置符号放置方式
         */
        setSymbolPlacement(placement: string): void;
        getSymbolPlacement(): string;
        
        /**
         * 设置符号间距
         */
        setSymbolSpacing(spacing: number): void;
        getSymbolSpacing(): number;
        
        /**
         * 设置符号避免边缘
         */
        setSymbolAvoidEdges(avoid: boolean): void;
        getSymbolAvoidEdges(): boolean;
        
        /**
         * 设置符号排序键
         */
        setSymbolSortKey(sortKey: number): void;
        getSymbolSortKey(): number;
        
        /**
         * 设置符号Z顺序
         */
        setSymbolZOrder(zOrder: string): void;
        getSymbolZOrder(): string;
    }
}

export = maplibre;
