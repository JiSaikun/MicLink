// // AudioWebSocketHandler.ets
// import { webSocket } from '@kit.NetworkKit';
// import { BusinessError } from '@kit.BasicServicesKit';
// import fileio from '@ohos.fileio';
// import { SmartMouseAudioProcessor } from 'mouse';
// import { Communication } from 'mouse';
// import { hilog } from '@kit.PerformanceAnalysisKit';
//
// // 音频数据类型枚举
// enum AudioDataType {
//   adpcmEncrypted, // ADPCM加密前（原始ADPCM）
//   adpcmDecrypted, // ADPCM解密后
//   pcmDecoded      // PCM解码后
// }
//
// export class AudioWebSocketHandler {
//   private webSocket: webSocket.WebSocket | null = null;
//   private audioProcessor: SmartMouseAudioProcessor = new SmartMouseAudioProcessor();
//   private enableAudioSave: boolean = false;
//   private audioSaveBasePath: string = '/data/storage/el2/base/files/audio/';
//   private adpcmEncryptedFile: fileio.File | null = null;
//   private adpcmDecryptedFile: fileio.File | null = null;
//   private pcmDecodedFile: fileio.File | null = null;
//   private audioFileTimestamp: string | null = null;
//
//   // 状态变量
//   private isRunning: boolean = false;
//   private sendCount: number = 0;
//   private processFrameCount: number = 0;
//   private pendingPcmData: Uint8Array = new Uint8Array(0);
//   private sendThreshold: number = 1024;
//   private clientId: string = "";
//   private language: string = "ZH_CN";
//   private ptt: string = "1";
//   private audioSampleRate: string = '16k';
//   private isFirstFrame: boolean = true;
//   private reconnectAttempts: number = 0;
//   private maxReconnectAttempts: number = 5;
//   private baseReconnectDelay: number = 2;
//   private reconnectTimer: number | null = null;
//   private currentUrl: string | null = null;
//
//   // 回调函数
//   public onMessageReceived: (message: Object) => void = () => {};
//   public onReceiveError: (error: string) => void = () => {};
//   public onDisconnected: (code: number | null, reason: string) => void = () => {};
//   public onConnected: () => void = () => {};
//
//   constructor(config: {
//     sendThreshold?: number;
//     serialNo: string;
//     apiKey: string;
//     deviceNo: string;
//     enableAudioSave?: boolean;
//   }) {
//     if (config.sendThreshold) {
//       this.sendThreshold = config.sendThreshold;
//     }
//
//     this.enableAudioSave = config.enableAudioSave || false;
//
//     if (this.enableAudioSave) {
//       this.initAudioSavePath();
//     }
//   }
//
//   // 初始化音频保存路径
//   private async initAudioSavePath(): Promise<void> {
//     try {
//       // 创建音频保存目录
//       await fileio.mkdir(this.audioSaveBasePath, 0o775);
//       hilog.info(0x0000, 'AudioWebSocket', '音频保存路径创建成功');
//     } catch (err) {
//       hilog.error(0x0000, 'AudioWebSocket', `音频保存路径创建失败: ${JSON.stringify(err)}`);
//       this.enableAudioSave = false;
//     }
//   }
//
//   // 初始化音频文件句柄
//   private async initAudioFileHandles(): Promise<void> {
//     if (!this.enableAudioSave) return;
//
//     try {
//       // 生成时间戳
//       const timestamp = new Date().toISOString().replace(/[:.-]/g, '_');
//       this.audioFileTimestamp = timestamp;
//
//       // 创建三个音频文件
//       this.adpcmEncryptedFile = await fileio.open(
//         `${this.audioSaveBasePath}${timestamp}_adpcm_encrypted.adpcm`,
//         fileio.O_CREAT | fileio.O_RDWR | fileio.O_TRUNC, 0o666
//       );
//
//       this.adpcmDecryptedFile = await fileio.open(
//         `${this.audioSaveBasePath}${timestamp}_adpcm_decrypted.adpcm`,
//         fileio.O_CREAT | fileio.O_RDWR | fileio.O_TRUNC, 0o666
//       );
//
//       this.pcmDecodedFile = await fileio.open(
//         `${this.audioSaveBasePath}${timestamp}_pcm_decoded.pcm`,
//         fileio.O_CREAT | fileio.O_RDWR | fileio.O_TRUNC, 0o666
//       );
//
//       hilog.info(0x0000, 'AudioWebSocket', '音频文件创建成功');
//     } catch (err) {
//       hilog.error(0x0000, 'AudioWebSocket', `音频文件初始化失败: ${JSON.stringify(err)}`);
//       await this.closeAudioFileHandles();
//     }
//   }
//
//   // 写入音频数据
//   private async writeAudioData(data: Uint8Array, dataType: AudioDataType): Promise<void> {
//     if (!this.enableAudioSave || data.length === 0) return;
//
//     try {
//       let file: fileio.File | null = null;
//       switch (dataType) {
//         case AudioDataType.adpcmEncrypted:
//           file = this.adpcmEncryptedFile;
//           break;
//         case AudioDataType.adpcmDecrypted:
//           file = this.adpcmDecryptedFile;
//           break;
//         case AudioDataType.pcmDecoded:
//           file = this.pcmDecodedFile;
//           break;
//       }
//
//       if (file) {
//         await fileio.write(file.fd, data);
//       }
//     } catch (err) {
//       hilog.error(0x0000, 'AudioWebSocket', `${AudioDataType[dataType]} 数据写入失败: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 关闭音频文件句柄
//   private async closeAudioFileHandles(): Promise<void> {
//     if (!this.enableAudioSave) return;
//
//     const closeFile = async (file: fileio.File | null) => {
//       if (file) {
//         try {
//           await fileio.close(file.fd);
//         } catch (err) {
//           hilog.error(0x0000, 'AudioWebSocket', `关闭文件失败: ${JSON.stringify(err)}`);
//         }
//       }
//     };
//
//     await closeFile(this.adpcmEncryptedFile);
//     await closeFile(this.adpcmDecryptedFile);
//     await closeFile(this.pcmDecodedFile);
//
//     this.adpcmEncryptedFile = null;
//     this.adpcmDecryptedFile = null;
//     this.pcmDecodedFile = null;
//
//     if (this.audioFileTimestamp) {
//       hilog.info(0x0000, 'AudioWebSocket', `音频文件保存完成: ${this.audioFileTimestamp}`);
//       this.audioFileTimestamp = null;
//     }
//   }
//
//   // 开始音频处理
//   async startAudio(config: {
//     language?: string;
//     ptt?: string;
//     clientId: string;
//     audioSampleRate?: number;
//   }): Promise<void> {
//     hilog.info(0x0000, 'AudioWebSocket',
//       `startAudio: clientId ${config.clientId}, language ${config.language}, ptt ${config.ptt}, audioSampleRate ${config.audioSampleRate}`);
//
//     this.isRunning = true;
//     this.sendCount = 0;
//     this.processFrameCount = 0;
//     this.clientId = config.clientId;
//     this.language = config.language || "ZH_CN";
//     this.ptt = config.ptt || "1";
//     this.isFirstFrame = true;
//
//     if (config.audioSampleRate === 1) {
//       this.audioSampleRate = '16k';
//     } else {
//       this.audioSampleRate = '8k';
//     }
//
//     // 初始化音频文件
//     if (this.enableAudioSave) {
//       await this.initAudioFileHandles();
//     }
//   }
//
//   // 处理音频帧
//   async processAudioFrame(rawData: Uint8Array, firmwareVersion: number): Promise<void> {
//     this.processFrameCount++;
//
//     if (!this.webSocket || !this.isConnected()) {
//       hilog.warn(0x0000, 'AudioWebSocket', 'WebSocket未连接，无法处理音频');
//       return;
//     }
//
//     // 保存原始ADPCM数据
//     const adpcmEncryptedData = rawData.slice(1);
//     await this.writeAudioData(adpcmEncryptedData, AudioDataType.adpcmEncrypted);
//
//     let pcmData: Int16Array | null = null;
//     let adpcmDecryptedData: Uint8Array;
//
//     if (firmwareVersion > 23) {
//       // 解密数据
//       adpcmDecryptedData = this.audioProcessor.miclinkDecrypt(adpcmEncryptedData);
//       await this.writeAudioData(adpcmDecryptedData, AudioDataType.adpcmDecrypted);
//
//       // 解码为PCM
//       pcmData = this.audioProcessor.processVoiceData(adpcmDecryptedData);
//     } else {
//       adpcmDecryptedData = adpcmEncryptedData;
//       pcmData = this.audioProcessor.processVoiceData(adpcmEncryptedData);
//     }
//
//     if (!pcmData) {
//       hilog.error(0x0000, 'AudioWebSocket', 'PCM数据解码失败');
//       return;
//     }
//
//     // 转换PCM为Uint8Array
//     const pcmBytes = this.audioProcessor.int16ArrayToBytes(pcmData);
//     await this.writeAudioData(pcmBytes, AudioDataType.pcmDecoded);
//
//     // 积累PCM数据
//     const newPendingData = new Uint8Array(this.pendingPcmData.length + pcmBytes.length);
//     newPendingData.set(this.pendingPcmData);
//     newPendingData.set(pcmBytes, this.pendingPcmData.length);
//     this.pendingPcmData = newPendingData;
//
//     // 达到阈值则发送
//     if (this.pendingPcmData.length >= this.sendThreshold) {
//       await this.sendToWebSocket(false);
//     }
//   }
//
//   // 停止音频处理
//   async stopAudio(): Promise<void> {
//     if (!this.isRunning) {
//       hilog.info(0x0000, 'AudioWebSocket', '音频已停止');
//       return;
//     }
//
//     this.isRunning = false;
//     hilog.info(0x0000, 'AudioWebSocket',
//       `计数器 - 发送次数: ${this.sendCount}, 处理帧次数: ${this.processFrameCount}`);
//
//     // 发送剩余PCM数据
//     if (this.pendingPcmData.length > 0) {
//       await this.sendToWebSocket(true);
//     } else {
//       await this.sendToWebSocket(true);
//     }
//
//     this.clientId = "";
//
//     // 关闭文件句柄
//     if (this.enableAudioSave) {
//       await this.closeAudioFileHandles();
//     }
//
//     hilog.info(0x0000, 'AudioWebSocket',
//       `音频停止 - 总发送次数: ${this.sendCount}, 总处理帧次数: ${this.processFrameCount}`);
//   }
//
//   // 连接到WebSocket服务器
//   async connect(url: string): Promise<void> {
//     this.currentUrl = url;
//     this.resetReconnectState();
//
//     return new Promise((resolve, reject) => {
//       try {
//         this.webSocket = webSocket.createWebSocket();
//
//         this.webSocket.on('open', () => {
//           hilog.info(0x0000, 'AudioWebSocket', 'WebSocket连接成功');
//           this.resetReconnectState();
//           this.onConnected();
//           resolve();
//         });
//
//         this.webSocket.on('message', (data: string | ArrayBuffer) => {
//           if (typeof data === 'string') {
//             this.handleTextMessage(data);
//           } else {
//             this.handleBinaryMessage(new Uint8Array(data));
//           }
//         });
//
//         this.webSocket.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
//           this.onDisconnected(value.code, value.reason);
//         });
//
//         this.webSocket.on('error', (err: BusinessError) => {
//           hilog.error(0x0000, 'AudioWebSocket', `WebSocket错误: ${JSON.stringify(err)}`);
//           if (!this.isConnected()) {
//             this.onDisconnected(null, err.message);
//           }
//           reject(err);
//         });
//
//         this.webSocket.connect(url, (err: BusinessError, value: boolean) => {
//           if (err) {
//             hilog.error(0x0000, 'AudioWebSocket', `连接失败: ${JSON.stringify(err)}`);
//             reject(err);
//           }
//         });
//       } catch (err) {
//         hilog.error(0x0000, 'AudioWebSocket', `创建WebSocket失败: ${JSON.stringify(err)}`);
//         reject(err);
//       }
//     });
//   }
//
//   // 断开连接
//   disconnect(): void {
//     this.resetReconnectState();
//     this.stopAudio();
//
//     if (this.webSocket) {
//       this.webSocket.close({
//         code: 1000,
//         reason: "客户端主动关闭"
//       });
//       this.webSocket = null;
//     }
//
//     // 确保文件句柄关闭
//     if (this.enableAudioSave) {
//       this.closeAudioFileHandles();
//     }
//
//     // 清空回调
//     this.onMessageReceived = () => {};
//     this.onReceiveError = () => {};
//     this.onDisconnected = () => {};
//     this.onConnected = () => {};
//   }
//
//   // 重连逻辑
//   async reconnect(): Promise<void> {
//     if (!this.currentUrl || this.reconnectAttempts >= this.maxReconnectAttempts) {
//       hilog.error(0x0000, 'AudioWebSocket', '重连失败：已达最大次数或URL为空');
//       this.resetReconnectState();
//       return;
//     }
//
//     if (this.reconnectTimer) {
//       return;
//     }
//
//     this.reconnectAttempts++;
//     const delay = this.baseReconnectDelay * Math.pow(2, this.reconnectAttempts - 1);
//
//     hilog.info(0x0000, 'AudioWebSocket', `第 ${this.reconnectAttempts} 次重连，延迟 ${delay} 秒...`);
//
//     this.reconnectTimer = setTimeout(async () => {
//       try {
//         await this.connect(this.currentUrl!);
//       } catch (err) {
//         hilog.error(0x0000, 'AudioWebSocket', `重连失败: ${JSON.stringify(err)}`);
//         await this.reconnect();
//       }
//     }, delay * 1000);
//   }
//
//   // 重置重连状态
//   private resetReconnectState(): void {
//     this.reconnectAttempts = 0;
//     if (this.reconnectTimer) {
//       clearTimeout(this.reconnectTimer);
//       this.reconnectTimer = null;
//     }
//   }
//
//   // 发送数据到WebSocket
//   private async sendToWebSocket(isLastFrame: boolean): Promise<void> {
//     if (!this.webSocket || !this.isConnected()) {
//       hilog.warn(0x0000, 'AudioWebSocket', 'WebSocket未连接，无法发送数据');
//       return;
//     }
//
//     this.sendCount++;
//
//     const message = {
//       "start": this.isFirstFrame,
//       "clientId": this.clientId,
//       "ptt": this.ptt,
//       "serialNo": Communication.deviceInfo.sn,
//       "phrases": "",
//       "format": "pcm",
//       "apiKey": "", // 需要从配置获取
//       "language": this.language,
//       "end": isLastFrame,
//       "rate": this.audioSampleRate,
//       "deviceNo": "", // 需要从配置获取
//       "content": this.arrayBufferToBase64(this.pendingPcmData.buffer),
//     };
//
//     try {
//       this.webSocket.send(JSON.stringify(message), (err: BusinessError, value: boolean) => {
//         if (err) {
//           hilog.error(0x0000, 'AudioWebSocket', `消息发送失败: ${JSON.stringify(err)}`);
//         }
//       });
//
//       this.pendingPcmData = new Uint8Array(0);
//       this.isFirstFrame = false;
//     } catch (err) {
//       hilog.error(0x0000, 'AudioWebSocket', `发送消息异常: ${JSON.stringify(err)}`);
//     }
//   }
//
//   // 处理文本消息
//   private handleTextMessage(text: string): void {
//     try {
//       const jsonMessage = JSON.parse(text);
//       this.onMessageReceived(jsonMessage);
//     } catch (err) {
//       const error = `接收消息解析失败: ${JSON.stringify(err)}`;
//       this.onReceiveError(error);
//     }
//   }
//
//   // 处理二进制消息
//   private handleBinaryMessage(data: Uint8Array): void {
//     const error = `暂不支持处理二进制消息，长度: ${data.length}`;
//     this.onReceiveError(error);
//   }
//
//   // 检查连接状态
//   isConnected(): boolean {
//     return this.webSocket !== null;
//   }
//
//   // ArrayBuffer转Base64
//   private arrayBufferToBase64(buffer: ArrayBuffer): string {
//     let binary = '';
//     const bytes = new Uint8Array(buffer);
//     const len = bytes.byteLength;
//
//     for (let i = 0; i < len; i++) {
//       binary += String.fromCharCode(bytes[i]);
//     }
//
//     return base64.encode(binary);
//   }
//
//   // 获取重连状态
//   isReconnecting(): boolean {
//     return this.reconnectAttempts > 0;
//   }
// }
//
// // Base64编码工具函数
// const base64 = {
//   encode: (str: string): string => {
//     // 简单的Base64编码实现
//     const base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
//     let result = '';
//     let i = 0;
//
//     while (i < str.length) {
//       const a = str.charCodeAt(i++);
//       const b = str.charCodeAt(i++);
//       const c = str.charCodeAt(i++);
//
//       const bits = (a << 16) | (b << 8) | c;
//
//       result += base64Chars.charAt((bits >> 18) & 0x3F) +
//       base64Chars.charAt((bits >> 12) & 0x3F) +
//       base64Chars.charAt((bits >> 6) & 0x3F) +
//       base64Chars.charAt(bits & 0x3F);
//     }
//
//     // 处理填充
//     const padding = str.length % 3;
//     if (padding > 0) {
//       result = result.slice(0, padding - 3) + (padding === 1 ? '==' : '=');
//     }
//
//     return result;
//   }
// };