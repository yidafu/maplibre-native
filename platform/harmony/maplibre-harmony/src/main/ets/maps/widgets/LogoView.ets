/**
 * LogoView - MapLibre logo component.
 *
 * Based on the Android and iOS LogoView implementations.
 * Displays the MapLibre brand logo.
 */

@Component
export struct LogoView {
  // Logo image resource.
  @Prop logoImage: Resource = $r('app.media.maplibre_logo_helmet');
  // Enable flag.
  @Prop logoEnabled: boolean = true;
  // Logo dimensions (auto by default).
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

