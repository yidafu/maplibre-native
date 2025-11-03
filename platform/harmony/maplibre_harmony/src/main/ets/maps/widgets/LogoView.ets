/**
 * LogoView - MapLibre Logo 组件
 *
 * 参考 Android LogoView 和 iOS LogoView 实现
 * 显示 MapLibre 品牌 Logo
 */

@Component
export struct LogoView {
  // Logo 图像资源
  @Prop logoImage: Resource = $r('app.media.maplibre_logo_helmet');
  // 是否启用
  @Prop logoEnabled: boolean = true;
  // Logo 尺寸（默认自适应）
  @Prop logoWidth: number | string = 'auto';
  @Prop logoHeight: number | string = 'auto';

  build() {
    if (this.logoEnabled) {
      Image(this.logoImage)
        .width(this.logoWidth === 'auto' ? 80 : this.logoWidth)
        .height(this.logoHeight === 'auto' ? 40 : this.logoHeight)
        .objectFit(ImageFit.Contain)
    }
  }
}

