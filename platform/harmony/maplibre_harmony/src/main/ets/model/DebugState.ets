/**
 * Debug state model for MapLibre debugging overlay
 */

export enum StyleLoadingPhase {
  NotStarted = 0,
  DownloadingStyle = 1,
  ParsingStyle = 2,
  LoadingSources = 3,
  LoadingLayers = 4,
  LoadingSprites = 5,
  LoadingGlyphs = 6,
  LoadingTiles = 7,
  Completed = 8,
  Failed = 9
}

export enum ResourceLoadState {
  Pending = 0,
  Loading = 1,
  Success = 2,
  Failed = 3
}

export interface ResourceInfo {
  url: string;
  type: string;
  state: ResourceLoadState;
  dataSize: number;
  duration: number;
  error: string;
}

export interface SourceInfo {
  id: string;
  type: string;
  initialized: boolean;
  tileCount: number;
  loadedTiles: number;
}

export interface LayerInfo {
  id: string;
  type: string;
  sourceId: string;
  visible: boolean;
}

export interface StyleLoadingStats {
  currentPhase: StyleLoadingPhase;
  totalResources: number;
  loadedResources: number;
  failedResources: number;
  progress: number;
  totalLoadTime: number;
  averageLoadTime: number;
}

export interface HttpStats {
  totalRequests: number;
  successRequests: number;
  failedRequests: number;
  pendingRequests: number;
  successRate: number;
  totalBytes: number;
  avgDuration: number;
  maxDuration: number;
}

export interface CacheStats {
  totalQueries: number;
  cacheHits: number;
  cacheMisses: number;
  hitRate: number;
  cacheSize: number;
  maxCacheSize: number;
}

export interface AlertInfo {
  type: string;
  message: string;
  timestamp: number;
  details: Record<string, string>;
}

@Observed
export class MapDebugState {
  public enabled: boolean = false;
  public styleStats: StyleLoadingStats | null = null;
  public httpStats: HttpStats | null = null;
  public cacheStats: CacheStats | null = null;
  public resources: ResourceInfo[] = [];
  public sources: SourceInfo[] = [];
  public layers: LayerInfo[] = [];
  public alerts: AlertInfo[] = [];
  
  constructor() {
  }
  
  public reset(): void {
    this.styleStats = null;
    this.httpStats = null;
    this.cacheStats = null;
    this.resources = [];
    this.sources = [];
    this.layers = [];
    this.alerts = [];
  }
  
  public getPhaseString(): string {
    if (!this.styleStats) return 'Not Started';
    
    switch (this.styleStats.currentPhase) {
      case StyleLoadingPhase.NotStarted: return 'Not Started';
      case StyleLoadingPhase.DownloadingStyle: return 'Downloading Style';
      case StyleLoadingPhase.ParsingStyle: return 'Parsing Style';
      case StyleLoadingPhase.LoadingSources: return 'Loading Sources';
      case StyleLoadingPhase.LoadingLayers: return 'Loading Layers';
      case StyleLoadingPhase.LoadingSprites: return 'Loading Sprites';
      case StyleLoadingPhase.LoadingGlyphs: return 'Loading Glyphs';
      case StyleLoadingPhase.LoadingTiles: return 'Loading Tiles';
      case StyleLoadingPhase.Completed: return 'Completed';
      case StyleLoadingPhase.Failed: return 'Failed';
      default: return 'Unknown';
    }
  }
  
  public getStateColor(): string {
    if (!this.styleStats) return '#999999';
    
    switch (this.styleStats.currentPhase) {
      case StyleLoadingPhase.Completed: return '#52c41a';
      case StyleLoadingPhase.Failed: return '#ff4d4f';
      case StyleLoadingPhase.NotStarted: return '#999999';
      default: return '#1890ff';
    }
  }
}

