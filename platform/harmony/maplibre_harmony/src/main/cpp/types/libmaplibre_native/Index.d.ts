
export type XComponentContextStatus = {
  hasDraw: boolean,
  hasChangeColor: boolean,
};

export const SetSurfaceId: (id: BigInt) => any;
export const ChangeSurface: (id: BigInt, w: number, h: number) => any;
export const DrawPattern: (id: BigInt) => any;
export const GetXComponentStatus: (id: BigInt) => XComponentContextStatus;
export const ChangeColor: (id: BigInt) => any;
export const DestroySurface: (id: BigInt) => any;

export const add: (a: number, b: number) => number;

export * from './NativeMapView'