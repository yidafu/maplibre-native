/**
 * AttributionButton - attribution button component.
 *
 * Mirrors Android AttributionDialogManager and iOS MLNAttributionButton.
 * Displays map data sources and copyright information.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { DOMAIN } from '../../constants/HiLogConstants';
import { promptAction } from '@kit.ArkUI';
/**
 * Attribution entry.
 */
export interface AttributionInfo {
  /**
   * Title.
   */
  title: string;

  /**
   * URL link (optional).
   */
  url?: string;
}

/**
 * AttributionButton component.
 *
 * Usage example:
 * ```typescript
 * AttributionButton({
 *   isEnabled: true,
 *   tintColor: '#000000',
 *   attributions: [
 *     { title: '© MapLibre', url: 'https://maplibre.org' },
 *     { title: '© OpenStreetMap contributors', url: 'https://www.openstreetmap.org/copyright' }
 *   ],
 *   onAttributionClick: (attribution) => {
 *     // Handle click events.
 *   }
 * })
 * ```
 */
@Component
export struct AttributionButton {
  /**
   * Whether the button is enabled.
   */
  @Prop isEnabled: boolean = true;
  /**
   * Icon color.
   */
  @Prop tintColor: string = '#000000';
  /**
   * Icon size (vp).
   */
  @Prop iconSize: number = 24;
  /**
   * Attribution list.
   */
  @Prop attributions: AttributionInfo[] = [
    { title: '© MapLibre', url: 'https://maplibre.org' },
    { title: '© OpenStreetMap contributors', url: 'https://www.openstreetmap.org/copyright' }
  ];
  /**
   * Callback for attribution item clicks.
   */
  onAttributionClick?: (attribution: AttributionInfo) => void;
  /**
   * Custom click handler.
   * Overrides the default behavior when provided.
   */
  onButtonClick?: () => void;

  build() {
    // Use Stack to ensure the icon has a circular background.
    Stack() {
      if (this.isEnabled) {
        // Circular background.
        Circle()
          .width(this.iconSize + 8)
          .height(this.iconSize + 8)
          .fill(Color.White)
          .opacity(0.8)

        // "i" icon.
        Text('i')
          .fontSize(this.iconSize - 6)
          .fontColor(this.tintColor)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.isEnabled ? this.iconSize + 8 : 0)
    .height(this.isEnabled ? this.iconSize + 8 : 0)
    .visibility(this.isEnabled ? Visibility.Visible : Visibility.None)
    .onClick(() => {
      if (this.isEnabled) {
        if (this.onButtonClick) {
          // Use the custom click handler.
          this.onButtonClick();
        } else {
          // Default behavior: display attribution details.
          this.showAttributionDialog();
        }
      }
    })
  }

  /**
   * Display the attribution dialog.
   */
  private showAttributionDialog(): void {
    try {
      if (this.attributions.length === 0) {
        promptAction.showToast({
          message: 'No attribution information available',
          duration: 2000,
          bottom: 100
        });
        return;
      }

      // Build the options list (show up to six entries).
      const options = this.attributions.slice(0, 6).map(attr => attr.title);

      // Present the action menu.
      const buttons: promptAction.Button[] = options.map((title) => {
        const button: promptAction.Button = {
          text: title,
          color: '#007AFF'
        };
        return button;
      });

      const dialogButtons: promptAction.Button[] = buttons.map(btn => {
        const button: promptAction.Button = { text: btn.text, color: btn.color };
        return button;
      });
      promptAction.showDialog({
        title: 'Map Attribution',
        message: options.join('\n'),
        buttons: dialogButtons
      }).then((result) => {
        if (result.index !== undefined && result.index >= 0) {
          const selectedAttribution = this.attributions[result.index];

          if (this.onAttributionClick) {
            // Invoke the external callback.
            this.onAttributionClick(selectedAttribution);
          } else {
            // Default behavior: show a prompt when a URL is available.
            if (selectedAttribution.url) {
              promptAction.showToast({
                message: `Visit: ${selectedAttribution.url}`,
                duration: 3000,
                bottom: 100
              });
            }
          }
        }
      }).catch((err: Error) => {
        hilog.error(DOMAIN, 'AttributionButton', `Failed to show action menu: ${err.message}`);
      });

    } catch (error) {
      hilog.error(DOMAIN, 'AttributionButton', `Error showing attribution dialog: ${error}`);
    }
  }
}

/**
 * Default attribution entries.
 */
export const DEFAULT_ATTRIBUTIONS: AttributionInfo[] = [
  {
    title: '© MapLibre',
    url: 'https://maplibre.org'
  },
  {
    title: '© OpenStreetMap contributors',
    url: 'https://www.openstreetmap.org/copyright'
  },
  {
    title: 'Improve this map',
    url: 'https://www.openstreetmap.org/fixthemap'
  }
];

