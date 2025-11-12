/**
 * ViewCallback - view callback interface.
 */
export interface ViewCallback {
  onMapReady(): void;

  onMapLoaded(): void;

  onMapError(error: string): void;

  onCameraWillChange(): void;

  onCameraIsChanging(): void;

  onCameraDidChange(): void;

  onWillStartLoadingMap(): void;

  onDidFinishLoadingMap(): void;

  onDidFailLoadingMap(error: string): void;

  onWillStartRenderingFrame(): void;

  onDidFinishRenderingFrame(): void;

  onWillStartRenderingMap(): void;

  onDidFinishRenderingMap(): void;

  onDidBecomeIdle(): void;

  onDidFinishLoadingStyle(): void;

  onSourceChanged(sourceId: string): void;

  onStyleImageMissing(imageId: string): void;

  onCanRemoveUnusedStyleImage(imageId: string): boolean;
}
