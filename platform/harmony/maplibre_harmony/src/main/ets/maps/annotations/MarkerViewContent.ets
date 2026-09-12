import { ComponentContent } from '@kit.ArkUI';
import type { UIContext } from '@kit.ArkUI';

/**
 * Marker custom-view content bridge.
 *
 * AnnotationViewDelegate.viewForAnnotation hands back a raw `contentBuilder`
 * closure, while the ViewAnnotation rendering pipeline only consumes
 * `ComponentContent` (BuilderNode based). This module bridges the two: a
 * module-level host @Builder renders a lightweight host component whose
 * @BuilderParam invokes the stored closure — the same invocation model the
 * deprecated AnnotationView used inside its build().
 */
class MarkerViewContentParams {
  builder: (() => void) | undefined = undefined;
}

@Component
struct MarkerViewHost {
  @BuilderParam contentBuilder?: () => void;

  build() {
    Column() {
      if (this.contentBuilder) {
        this.contentBuilder()
      }
    }
  }
}

/**
 * Host builder executed by the ComponentContent pipeline. Instantiates the
 * host component so the delegate's builder DSL runs inside a component
 * render context.
 */
@Builder
function markerViewContentHost(params: MarkerViewContentParams) {
  MarkerViewHost({ contentBuilder: params.builder })
}

/**
 * Wrap a delegate contentBuilder closure into a ComponentContent for the
 * ViewAnnotation pipeline. Returns null when no UIContext is available yet;
 * callers are expected to retry once the UIContext has been propagated.
 */
export function createMarkerViewContent(
  uiContext: UIContext | null,
  builder: (() => void)
): ComponentContent<Object> | null {
  if (!uiContext) {
    return null;
  }
  const params = new MarkerViewContentParams();
  params.builder = builder;
  return new ComponentContent<MarkerViewContentParams>(
    uiContext,
    wrapBuilder<[MarkerViewContentParams]>(markerViewContentHost),
    params
  );
}
