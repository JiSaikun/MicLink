export const initddk: () => number;
export const open: (deviceId: number, interfaceIndex: number) => number;
export const sendReport: (reportType: number, data: ArrayBuffer, length: number) => number;
export const read: (bufSize: number, timeout?: number) => {
  result: number;
  bytesRead: number;
  data: ArrayBuffer
};
export const closeHidDevice: () => number;