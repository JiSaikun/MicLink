import { webSocket } from '@kit.NetworkKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
// import { inputMethodEngine } from '@kit.IMEKit';
import { getModelInfoModel, Languages } from 'config'
import { Communication, ConnectDevice } from './Communication'
import { _translate } from '../viewmodel/UserViewModel'
import { translate_Params, translate_Response } from '../model/MouseInfoModel'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import { promptAction } from '@kit.ArkUI';
import { Float_Window } from 'float_window';
import { webview } from '@kit.ArkWeb';
import { Notification } from 'config';
import { common, Want } from '@kit.AbilityKit';

interface sendQueueType {
  chunk: Int16Array,
  start: boolean
}

// 定义日志消息接口
interface logMessageModel {
  "start": boolean,
  "clientId": string,
  "ptt": string,
  "serialNo": string,
  "phrases": string,
  "format": string,
  "apiKey": string,
  "language": string,
  "end": boolean,
  "rate": string,
  "deviceNo": string,
  "content": string
}

export interface inputMessageModel {
  start: boolean
  "clientId": string,
  "ptt": string,
  "serialNo": string,
  "phrases": string,
  "format": string,
  "apiKey": string,
  "language": string,
  "end": boolean,
  "rate": string,
  "deviceNo": string,
  content: string
}

interface res_moudel {
  "data": res_data_moudel
  "message": string,
  "status": number
}

interface res_data_moudel {
  "btype": boolean,
  "clientId": string
  "sn": string
  "text": string
  "type": string
}

// 性能指标接口
interface MetricsModel {
  totalChunksSent: number;
  totalBytesSent: number;
  failedChunks: number;
  sessionStartTime: number;
  lastChunkTime: number;
}

// 扩展性能指标接口（用于getMetrics返回值）
interface ExtendedMetricsModel {
  totalChunksSent: number;
  totalBytesSent: number;
  failedChunks: number;
  sessionStartTime: number;
  lastChunkTime: number;
  sessionDuration: number;
  failedChunksCount: number;
  currentBufferFrames: number;
  totalSamplesCached: number;
  isConnected: boolean;
}

export class AudioWebSocketHandler {
  public isConnected: boolean = false;
  private ws: webSocket.WebSocket | null = null;
  private serverUrl: string = "ws://asr.miclink.net/ws";
  private audioData: Int16Array[] = []
  private state: number = 0 //0:语音输入
  private wending: boolean = false //语音数据不再变化
  private inputMessage: inputMessageModel = {
    start: false,
    "clientId": '',
    "ptt": '',
    "serialNo": '',
    "phrases": '',
    "format": '',
    "apiKey": '',
    "language": '',
    "end": false,
    "rate": '',
    "deviceNo": '',
    content: ''
  }
  private sendIntervalId: number | null = null;
  private isSending: boolean = false;
  private pendingChunks: Int16Array[][] = [];
  private completionCheckId: number | null = null;
  private pendingInitTimerId: number | null = null; // 初始化延迟定时器
  private isClosing: boolean = false; // 新增：标记是否正在关闭
  private noDataTimeoutId: number | null = null; // 音频数据超时定时器
  private readonly NO_DATA_TIMEOUT_MS = 30000; // 30秒无数据超时
  private hasSentStart: boolean = false; // 标记是否已经发送过start消息
  private hasSentEnd: boolean = false; // 标记是否已经发送过end消息
  private FINText: string = ''
  // 性能优化：增量计算总采样点，避免重复遍历
  private totalSamplesCache: number = 0;
  private readonly MAX_BUFFER_FRAMES = 150; // 最大缓冲帧数，防止内存泄漏
  private readonly FRAMES_TO_KEEP = 30; // 清理后保留的帧数

  // 网络重试机制
  private readonly MAX_SEND_RETRIES = 3; // 最大重试次数
  private failedChunksCount: number = 0; // 失败分片计数

  // 心跳机制
  private heartbeatIntervalId: number | null = null;
  private lastHeartbeatTime: number = 0;
  private readonly HEARTBEAT_INTERVAL_MS = 5000; // 5秒心跳间隔
  private readonly HEARTBEAT_TIMEOUT_MS = 15000; // 15秒心跳超时

  // 性能指标
  private metrics: MetricsModel = {
    totalChunksSent: 0,
    totalBytesSent: 0,
    failedChunks: 0,
    sessionStartTime: 0,
    lastChunkTime: 0
  };
  // 优化配置 - 1024字节分片
  private readonly CHUNK_SIZE_BYTES = 1024; // 目标分片大小
  private readonly SAMPLES_PER_CHUNK = 512; // 1024字节 / 2字节每采样点 = 512个采样点
  private readonly SEND_INTERVAL_MS = 0; // 发送间隔（立即发送）
  private readonly CHECK_INTERVAL_MS = 20; // 检查间隔（从3ms增加到20ms，减少检测频率）
  private readonly COMPLETION_CHECK_MS = 100; // 完成检查间隔
  private readonly MAX_BUFFER_SIZE = 50; // 最大缓冲分片数
  private readonly MIN_SAMPLES_FOR_COMPLETION = 1024; // 最小采样点数才开始检测完成（约0.064秒@16kHz）
  private webViewController: webview.WebviewController | null = null

  // 新增优化相关属性（简化为类似蓝牙的实时发送模式）
  private lastSentSampleIndex: number = 0; // 采样点索引（仿蓝牙模式）
  private lastSendTime: number = 0; // 记录上次发送时间
  private readonly MIN_SEND_INTERVAL: number = 10; // 最小发送间隔10ms，保持响应性
  private cachedTotalSamples: number = 0; // 缓存总采样点数
  private lastCacheUpdateTime: number = 0; // 缓存更新时间
  private sessionStartTime: number = 0; // 会话开始时间
  private readonly MAX_SESSION_DURATION: number = Number.MAX_SAFE_INTEGER; // 禁用会话超时，支持长时语音传输
  private completionDetectionStartTime: number = 0; // 完成检测开始时间
  private readonly MAX_NO_DATA_TIMEOUT: number = 10000; // 10秒内没有数据则超时

  // Base64编码表
  private base64Chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  constructor(serverUrl: string, audioData: Int16Array[], state: number, inputMessage: inputMessageModel,
    webViewController?: webview.WebviewController) {
    this.serverUrl = serverUrl;
    this.audioData = audioData;
    this.state = state;
    this.inputMessage = inputMessage;
    if (webViewController) {
      this.webViewController = webViewController
    }
    if (state) {
      AppStorage.setOrCreate('voiceTranslationText', {
        transText: '',
        text: ''
      })
      AppStorage.setOrCreate('changeText', false)
    } else {
      AppStorage.setOrCreate('voiceInputText', '')
      AppStorage.setOrCreate('linshi', '')
    }
    this.wending = false
    this.FINText = ''
    this.isSending = false;
    this.isClosing = false;
    this.hasSentStart = false;
    this.hasSentEnd = false;
    this.totalSamplesCache = 0;
    this.failedChunksCount = 0;
    this.metrics.sessionStartTime = Date.now();

    // 新增初始化
    this.lastSentSampleIndex = 0;
    this.cachedTotalSamples = 0;
    this.lastCacheUpdateTime = Date.now();
    this.sessionStartTime = Date.now();
  }

  public connect(): void {
    try {
      // 添加连接状态检查
      if (this.ws && this.isConnected) {
        console.warn('WebSocket已经连接');
        return;
      }

      console.log('*************************进入webSocket连接************************');
      console.log(`🔍 连接前会话状态: hasSentStart=${this.hasSentStart}, hasSentEnd=${this.hasSentEnd}`);

      // 保存当前start标志状态（用于重连场景）
      const preserveStartFlag = this.hasSentStart;

      // 清理之前的连接
      this.cleanupConnection();

      // 恢复start标志（避免重连时重复发送start）
      // 注意：hasSentEnd不保存，每次连接都应该能够发送新的结束标记
      this.hasSentStart = preserveStartFlag;
      this.hasSentEnd = false; // 重置结束标志，允许发送新的结束标记

      console.log(`🔍 连接后会话状态: hasSentStart=${this.hasSentStart}, hasSentEnd=${this.hasSentEnd}`);

      this.ws = webSocket.createWebSocket();

      this.ws.on('open', (err: BusinessError, value: Object) => {
        if (!err) {
          this.isConnected = true;
          this.isClosing = false;
          console.log("连接已打开，状态:" + JSON.stringify(value));
          console.log('*******************************语音数据长度：', this.audioData.length);

          // 启动心跳机制
          this.setupHeartbeat();

          // 使用优化的实时发送方式（仿蓝牙模式）
          this.startRealTimeAudioSending();
        } else {
          console.error("连接错误:" + JSON.stringify(err));
          this.isConnected = false;
        }
      });

      this.ws.on('message', (err: BusinessError, value: string | ArrayBuffer) => {
        if (!err) {
          let message: string;
          if (typeof value === 'string') {
            message = value;
          } else {
            message = this.arrayBufferToString(value);
          }
          console.error("收到消息，内容:" + message);
          this.handleWebSocketMessage(message);
        } else {
          console.error("消息错误:" + JSON.stringify(err));
        }
      });

      this.ws.on('close', (err: BusinessError, value: webSocket.CloseResult) => {
        this.isConnected = false;
        this.isClosing = false;
        this.cleanupIntervals();
        console.log(`连接已关闭，状态码: ${value.code}, 原因: ${value.reason}`);
      });

      this.ws.on('error', (err: BusinessError) => {
        console.error("发生错误: " + err.message);
        this.cleanupIntervals();
        this.isConnected = false;
      });

      console.warn('正在连接到服务器...')
      this.ws.connect(this.serverUrl, (err: BusinessError, value: boolean) => {
        if (!err) {
          console.warn("连接成功");
        } else {
          console.error("连接失败。错误信息:" + err.message);
          this.cleanupIntervals();
          this.isConnected = false;
        }
      });
    } catch (error) {
      console.error('连接异常:', error);
      this.cleanupIntervals();
      this.isConnected = false;
    }
  }

  private handleWebSocketMessage(message: string): void {
    try {
      // 更新心跳时间
      this.updateHeartbeat();

      let res: res_moudel = JSON.parse(message);
      /**
       * 语音转录优化
       */
      if (res.data.type === 'LAST' || res.data.type === "FIN") {
        if (res.data.type === 'LAST') {
          if (this.FINText === '') {
            this.FINText += res.data.text
            res.data.text = this.FINText
          } else {
            res.data.text = this.FINText + res.data.text
          }
        } else {
          this.FINText += res.data.text
          res.data.text = this.FINText
        }
      } else {
        res.data.text = this.FINText + res.data.text
      }
      if ((AppStorage.get('flax') && !this.state && !this.wending) && !this.webViewController) {
        if (AppStorage.get('isAI_assistant')) {
          Notification.setOrCreate(Languages.voiceAssistant[AppStorage.get('languages') as string], res.data.text)
        } else {
          Notification.setOrCreate(Languages.voiceInput[AppStorage.get('languages') as string], res.data.text)
        }
      }
      if (this.webViewController && !this.wending) {
        // 构建JS代码字符串
        const jsCode = `getRecordingText('${res.data.text}', '中间过度')`;
        AppStorage.setOrCreate('getRecordingText', res.data.text)
        console.error("执行JS代码: " + jsCode);
        this.webViewController.runJavaScript(jsCode).then((result: string) => {
          console.error("JS执行成功，返回值: " + result);
        }).catch((error: Error) => {
          console.error("JS执行失败: " + error.message);
        });
        return
      } else {
        this.webViewController = null
      }

      if (res.status === 200 && this.state === 0) {
        if (AppStorage.get('isAI_assistant')) {
          if (this.wending && (res.data.type === 'LAST' || res.data.type === "FIN")) {
            AppStorage.setOrCreate('voiceInputText', res.data.text);
            if (AppStorage.get('flax') && !this.state) {
              Notification.clear()
              Notification.state = false

              /**
               * 网页搜索 - 修复数组类型错误
               */
              if (res.data.text === '') {
                return
              }
              const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
              const encodedKeyword = encodeURIComponent(res.data.text);
              let uri: string = '';

              const searchEngine = AppStorage.get('EnhancedBrowserSearch') as number || 0;

              // 修复错误3、4、5：明确指定数组类型
              const searchEngines: SearchEngineConfig[] = [
                { name: '百度', url: `https://www.baidu.com/s?wd=${encodedKeyword}` } as SearchEngineConfig,
                { name: '谷歌', url: `https://www.google.com/search?q=${encodedKeyword}` } as SearchEngineConfig
              ];

              if (searchEngine >= 0 && searchEngine < searchEngines.length) {
                uri = searchEngines[searchEngine].url;
                console.log(`使用${searchEngines[searchEngine].name}搜索: ${res.data.text}`);
              } else {
                uri = searchEngines[0].url;
                console.log(`使用默认搜索引擎搜索: ${res.data.text}`);
              }

              const want: Want = {
                action: 'ohos.want.action.viewData',
                entities: ['entity.system.browsable'],
                uri: uri
              };

              context.startAbility(want).catch((err: BusinessError) => {
                console.error('搜索失败:', err.message);
              });
            }
            return;
          } else {
            AppStorage.setOrCreate('linshi', res.data.text);
          }
        } else {
          if (res.data.text.length > (AppStorage.get('voiceInputText') as string).length) {
            AppStorage.setOrCreate('voiceInputText', res.data.text);
          }
        }
      }

      if (res.status === 200) {
        let audioToText_res: string = res.data.text;
        if (!audioToText_res) {
          return;
        }
        if (this.state) {
          if (this.wending) {
            if (res.data.type === 'LAST' || res.data.type === "FIN") {
              this.handleTextResult(audioToText_res, res.data.type);
            }
            return
          }
          this.handleTextResult(audioToText_res, res.data.type);
        } else {
          if (!AppStorage.get('isAI_assistant')) {
            this.handleTextResult(audioToText_res, res.data.type);
          }
        }

      } else {
        console.error('响应异常:', res.message);
      }
    } catch (error) {
      console.error('处理WebSocket消息异常:', error);
    }
  }

  private handleTextResult(text: string, type: string): void {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();

      systemPasteboard.setData(pasteData)
        .then(() => {
          console.error('文本已复制到剪贴板: ' + text);
          this.processClipboardText(text, systemPasteboard, type);
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
        });
    } catch (error) {
      console.error('复制操作异常: ' + error);
    }
  }

  private processClipboardText(text: string, systemPasteboard: pasteboard.SystemPasteboard, type: string): void {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      atManager.requestPermissionsFromUser(AppStorage.get('context'), ['ohos.permission.READ_PASTEBOARD']);
    } catch (err) {
      console.error(`权限申请失败: ${err.code}, ${err.message}`);
    }

    systemPasteboard.getData().then((pasteData: pasteboard.PasteData) => {
      console.log('剪贴板记录数量:', pasteData.getRecordCount());
      let clipboardText: string = pasteData.getPrimaryText();

      if (this.state === 0 && this.wending && !AppStorage.get('isAI_assistant')) {
        this.wending = false
        // 语音输入模式
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number || 0].Communication.getDeviceInfo([0x20,
          0x01, 0x19])
          .then(() => {
            if (AppStorage.get('flax') && !this.state && !this.wending) {
              Notification.clear()
              Notification.state = false
            }
            setTimeout(() => {
              systemPasteboard.clearData();
            }, 2000);
          });
        return;
      }

      if (this.state === 1) {
        // 语音翻译模式
        this.handleTranslation(clipboardText, systemPasteboard, type);
      }
    })
      .catch((err: BusinessError) => {
        console.error('获取剪贴板数据失败: ' + err.message);
      });
  }

  private handleTranslation(text: string, systemPasteboard: pasteboard.SystemPasteboard, type: string): void {
    let params: translate_Params = {
      appkey: (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number ||
        0].getModelInfo as getModelInfoModel).appkey,
      from: AppStorage.get('from_languages') ? AppStorage.get('from_languages') as string : 'ZH_CN',
      productCode: ConnectDevice.Communication[AppStorage.get('device_currIndex') as number ||
        0].Communication.deviceInfo.productType.toString(),
      sno: ConnectDevice.Communication[AppStorage.get('device_currIndex') as number || 0].Communication.deviceInfo.sn,
      text: text,
      to: AppStorage.get('to_languages') ? AppStorage.get('to_languages') as string : 'EN_US'
    };

    _translate(params).then((res) => {
      console.log('翻译请求成功————翻译结果：' + res.data?.transText, type);
      if (res.data) {
        let dataArray: translate_Response = {
          transText: res.data?.transText as string,
          text: res.data?.text as string,
        };
        AppStorage.setOrCreate('voiceTranslationText', dataArray);
        if (AppStorage.get('flax') && AppStorage.get('isAutoCloseVoiceTransPop')) {
          Notification.setOrCreate(Languages.voiceTranslation[AppStorage.get('languages') as string], res.data?.transText)
        }
        if (this.wending) {
          setTimeout(() => {
            AppStorage.setOrCreate('changeText', true)
          }, 2000)
        }
        systemPasteboard.clearData();
        // console.error('翻译文本已复制到剪贴板: ' + dataArray);
        // console.error('翻译文本已复制到剪贴板: ' + AppStorage.get('isAutoCloseVoiceTransPop')+(type === 'LAST' || type === "FIN"));
        if (AppStorage.get('isAutoCloseVoiceTransPop') && (type === 'LAST' || type === "FIN")) {
          // console.error('翻译文本已复制到剪贴板1: ' + dataArray.transText);
          try {
            const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, dataArray.transText);
            systemPasteboard.setData(pasteData)
              .then(() => {
                console.error('翻译文本已复制到剪贴板: ' + dataArray.transText);
                this.wending = false
                Float_Window.destroyWindow(Float_Window.window_VoiceTranslation)
                setTimeout(() => {
                  // 语音输入模式
                  ConnectDevice.Communication[AppStorage.get('device_currIndex') as number ||
                    0].Communication.getDeviceInfo([0x20,
                    0x01, 0x19])
                    .then(() => {
                      if (AppStorage.get('flax') && AppStorage.get('isAutoCloseVoiceTransPop')) {
                        Notification.clear()
                        Notification.state = false
                      }
                      console.error('执行粘贴操作: ' + dataArray.transText);
                      Float_Window.showVoiceTranslation = false
                      if (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number ||
                        0].Communication.audioDataState) {
                        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number ||
                          0].Communication.getDeviceInfo([0x63])
                        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number ||
                          0].Communication.audioDataState =
                          !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number ||
                            0].Communication.audioDataState
                      }
                      setTimeout(() => {
                        systemPasteboard.clearData();
                      }, 2000);
                    });
                }, 50);
              })
              .catch((err: BusinessError) => {
                console.error('翻译文本复制失败: ' + err.message);
              });
          } catch (error) {
            console.error('复制操作异常: ' + error);
          }
        }

      } else {
        AppStorage.setOrCreate('flax_yuyinfanyi_chachaobudaoyuyan',
          !AppStorage.get('flax_yuyinfanyi_chachaobudaoyuyan'));
      }
    })
      .catch(() => {
      });
  }

  /**
   * 清理WebSocket连接但保持会话状态（用于重连）
   */
  private cleanupConnection(): void {
    console.log('清理WebSocket连接资源');

    this.cleanupIntervals();
    this.isSending = false;

    if (this.ws) {
      try {
        if (this.isConnected) {
          this.ws.close({ code: 1000, reason: "准备重连" });
        }
      } catch (error) {
        console.error('清理连接异常:', error);
      }
      this.ws = null;
    }

    this.isConnected = false;
    this.isClosing = false;
  }

  public disconnect(): void {
    console.log('开始断开WebSocket连接');

    if (this.ws && this.isConnected) {
      try {
        console.log('正在关闭WebSocket连接...');

        // 先发送结束标记（在设置isClosing之前）
        this.sendEndMarker();

        // 然后清理定时器和状态
        this.cleanupIntervals();
        this.isSending = false;
        this.isClosing = true;

        // 延迟一段时间确保结束标记发送完成
        setTimeout(() => {
          this.ws!.close({
            code: 1000,
            reason: "客户端主动关闭"
          }, (err: BusinessError, value: boolean) => {
            if (!err) {
              console.log("连接已成功关闭");
            } else {
              console.error("关闭连接失败。错误信息: " + JSON.stringify(err));
            }
            this.ws = null;
            this.isConnected = false;
            this.isClosing = false;
          });
        }, 100);

      } catch (error) {
        console.error('断开连接异常:', error);
        this.ws = null;
        this.isConnected = false;
        this.isClosing = false;
      }
    } else {
      console.log('WebSocket实例不存在或未连接，直接清理');
      this.ws = null;
      this.isConnected = false;
      this.isClosing = false;
    }
  }

  // 强制断开连接（用于超时等情况）
  private forceDisconnect(): void {
    console.log('强制断开WebSocket连接');
    this.cleanupIntervals();
    this.isSending = false;
    this.isConnected = false;
    this.isClosing = false;

    if (this.ws) {
      try {
        this.ws.close({
          code: 1000,
          reason: "强制关闭"
        });
      } catch (error) {
        console.error('强制关闭异常:', error);
      } finally {
        this.ws = null;
      }
    }
  }

  // 异步断开连接方法
  public async disconnectAsync(): Promise<void> {
    return new Promise((resolve) => {
      console.log('开始异步断开WebSocket连接');

      this.cleanupIntervals();
      this.isSending = false;
      this.isClosing = true;

      if (!this.ws || !this.isConnected) {
        console.log('WebSocket未连接，直接完成');
        this.isConnected = false;
        this.isClosing = false;
        resolve();
        return;
      }

      // 设置超时保护
      const timeoutId = setTimeout(() => {
        console.warn('WebSocket关闭超时，强制断开');
        this.forceDisconnect();
        resolve();
      }, 5000);

      try {
        // 发送结束标记
        this.sendEndMarker();

        setTimeout(() => {
          this.ws!.close({
            code: 1000,
            reason: "客户端主动关闭"
          }, (err: BusinessError, value: boolean) => {
            clearTimeout(timeoutId);
            if (!err) {
              console.log("连接已成功关闭");
            } else {
              console.error("关闭连接失败。错误信息: " + JSON.stringify(err));
            }
            this.ws = null;
            this.isConnected = false;
            this.isClosing = false;
            resolve();
          });
        }, 100);

      } catch (error) {
        console.error('断开连接异常:', error);
        clearTimeout(timeoutId);
        this.forceDisconnect();
        resolve();
      }
    });
  }

  private cleanupIntervals(): void {
    if (this.sendIntervalId !== null) {
      clearInterval(this.sendIntervalId);
      this.sendIntervalId = null;
    }
    if (this.completionCheckId !== null) {
      clearInterval(this.completionCheckId);
      this.completionCheckId = null;
    }
    if (this.pendingInitTimerId !== null) {
      clearTimeout(this.pendingInitTimerId);
      this.pendingInitTimerId = null;
    }
    if (this.noDataTimeoutId !== null) {
      clearTimeout(this.noDataTimeoutId);
      this.noDataTimeoutId = null;
    }
    if (this.heartbeatIntervalId !== null) {
      clearInterval(this.heartbeatIntervalId);
      this.heartbeatIntervalId = null;
    }
  }

  private cleanupOldAudioData(): void {
    if (this.audioData.length > this.MAX_BUFFER_FRAMES) {
      const framesToRemove = this.audioData.length - this.FRAMES_TO_KEEP;
      for (let i = 0; i < framesToRemove; i++) {
        this.totalSamplesCache -= this.audioData[i].length;
      }
      this.audioData.splice(0, framesToRemove);
      console.log(`🧹 内存清理：删除${framesToRemove}帧旧数据`);
    }
  }

  public addAudioFrame(frame: Int16Array): void {
    this.audioData.push(frame);
    this.totalSamplesCache += frame.length;
    if (this.audioData.length % 50 === 0) {
      this.cleanupOldAudioData();
    }
  }

  private getTotalSamples(): number {
    return this.totalSamplesCache;
  }

  private setupHeartbeat(): void {
    this.lastHeartbeatTime = Date.now();
    this.heartbeatIntervalId = setInterval(() => {
      if (!this.isConnected || this.isClosing) {
        return;
      }
      const now = Date.now();
      const timeSinceLastHeartbeat = now - this.lastHeartbeatTime;
      if (timeSinceLastHeartbeat > this.HEARTBEAT_TIMEOUT_MS) {
        console.warn(`💔 心跳超时(${timeSinceLastHeartbeat}ms)，尝试重连`);
        this.reconnect();
        return;
      }
      if (timeSinceLastHeartbeat > this.HEARTBEAT_INTERVAL_MS) {
        console.log('💓 发送心跳');
        this.lastHeartbeatTime = now;
      }
    }, this.HEARTBEAT_INTERVAL_MS) as number;
  }

  private updateHeartbeat(): void {
    this.lastHeartbeatTime = Date.now();
  }

  private async reconnect(): Promise<void> {
    console.log('🔄 开始重连WebSocket...（保持start状态，重置end状态）');
    try {
      // 使用cleanupConnection而不是disconnect，避免发送结束标记
      this.cleanupConnection();
      await this.delay(1000);
      // connect()会保留hasSentStart并重置hasSentEnd，确保重连后可以发送新的结束标记
      this.connect();
      console.log(`🔄 重连完成，会话状态: start=${this.hasSentStart}, end=${this.hasSentEnd}`);
    } catch (error) {
      console.error('重连失败:', error);
    }
  }

  private sendMessageWithRetry(
    inputMessage: inputMessageModel,
    retries: number = this.MAX_SEND_RETRIES
  ): boolean {
    for (let attempt = 0; attempt < retries; attempt++) {
      const success = this.sendMessage(inputMessage);
      if (success) {
        return true;
      }
      // 同步重试（简化版本，避免async问题）
      if (attempt < retries - 1) {
        console.warn(`发送失败，立即重试 (${attempt + 1}/${retries})`);
      }
    }
    console.error(`✖️ 消息发送失败，已重试${retries}次`);
    this.failedChunksCount++;
    this.metrics.failedChunks++;
    return false;
  }

  /**
   * 获取性能指标
   */
  public getMetrics(): ExtendedMetricsModel {
    const result: ExtendedMetricsModel = {
      totalChunksSent: this.metrics.totalChunksSent,
      totalBytesSent: this.metrics.totalBytesSent,
      failedChunks: this.metrics.failedChunks,
      sessionStartTime: this.metrics.sessionStartTime,
      lastChunkTime: this.metrics.lastChunkTime,
      sessionDuration: Date.now() - this.metrics.sessionStartTime,
      failedChunksCount: this.failedChunksCount,
      currentBufferFrames: this.audioData.length,
      totalSamplesCached: this.totalSamplesCache,
      isConnected: this.isConnected
    };
    return result;
  }

  public sendMessage(inputMessage: inputMessageModel): boolean {
    if (!this.isConnected || !this.ws || this.isClosing) {
      console.error("未连接到服务器或正在关闭，无法发送消息");
      return false;
    }

    if (!inputMessage.content.trim() && !inputMessage.end) {
      console.error("消息不能为空");
      return false;
    }

    try {
      this.ws.send(JSON.stringify(inputMessage), (err: BusinessError, value: boolean) => {
        if (err) {
          console.error("消息发送失败: " + err.message);
        } else {
          console.log("消息发送成功");
        }
      });
      return true;
    } catch (error) {
      console.error("发送消息未知错误：", error);
      return false;
    }
  }

  private arrayBufferToString(buffer: ArrayBuffer): string {
    try {
      const uint8Array: Uint8Array = new Uint8Array(buffer);
      let result: string = "";

      for (let i = 0; i < uint8Array.length; i++) {
        result += String.fromCharCode(uint8Array[i]);
      }

      return result;
    } catch (error) {
      console.error('ArrayBuffer转换字符串失败:', error);
      return '';
    }
  }

  // Base64编码实现
  private base64Encode(uint8Array: Uint8Array): string {
    if (!uint8Array || uint8Array.length === 0) {
      return '';
    }

    const outputLength = Math.ceil(uint8Array.length / 3) * 4;
    const output = new Array<string>(outputLength);
    let outputIndex = 0;

    try {
      for (let i = 0; i < uint8Array.length; i += 3) {
        const byte1 = uint8Array[i];
        const byte2 = i + 1 < uint8Array.length ? uint8Array[i + 1] : 0;
        const byte3 = i + 2 < uint8Array.length ? uint8Array[i + 2] : 0;

        const enc1 = byte1 >> 2;
        const enc2 = ((byte1 & 0x3) << 4) | (byte2 >> 4);
        const enc3 = ((byte2 & 0xf) << 2) | (byte3 >> 6);
        const enc4 = byte3 & 0x3f;

        output[outputIndex++] = this.base64Chars.charAt(enc1);
        output[outputIndex++] = this.base64Chars.charAt(enc2);
        output[outputIndex++] = i + 1 < uint8Array.length ? this.base64Chars.charAt(enc3) : '=';
        output[outputIndex++] = i + 2 < uint8Array.length ? this.base64Chars.charAt(enc4) : '=';
      }

      return output.join('');
    } catch (error) {
      console.error('Base64编码错误:', error);
      return '';
    }
  }

  // 将Int16Array转换为Base64编码
  private int16ToBase64(int16Array: Int16Array): string {
    const byteArray = new Uint8Array(int16Array.length * 2);

    for (let i = 0; i < int16Array.length; i++) {
      const value = int16Array[i];
      byteArray[i * 2] = value & 0xFF;
      byteArray[i * 2 + 1] = (value >> 8) & 0xFF;
    }

    return this.base64Encode(byteArray);
  }

  // ========== 优化的实时音频发送方法（仿蓝牙模式）==========

  private startRealTimeAudioSending(): void {
    console.log('开始实时音频发送 - 仿蓝牙实时模式');

    // 重置发送相关状态
    this.lastSentSampleIndex = 0;
    this.lastSendTime = Date.now();
    this.cachedTotalSamples = 0;
    this.lastCacheUpdateTime = Date.now();
    this.sessionStartTime = Date.now();

    // 延迟一小段时间，让音频数据有时间积累
    this.pendingInitTimerId = setTimeout(() => {
      if (this.isClosing || !this.ws) {
        return;
      }

      // 1. 发送初始数据（如果有）
      this.sendExistingDataImmediately();

      // 2. 设置实时监听新数据（仿蓝牙模式）
      this.setupRealTimeListenerBluetoothStyle();

      // 3. 设置完成检测
      this.setupCompletionDetection();

      // 4. 设置无数据超时检测
      this.setupNoDataTimeout();
    }, 100) as number; // 缩短延迟到100ms
  }

  private async sendExistingDataImmediately(): Promise<void> {
    if (this.audioData.length === 0) {
      return;
    }

    console.log(`立即发送现有数据: ${this.audioData.length} 帧`);

    try {
      this.isSending = true;

      // 使用连续分片获取新数据（仿蓝牙模式）
      const chunks = this.getContinuousAudioChunksFromStart();

      if (chunks.length > 0) {
        console.log(`生成 ${chunks.length} 个连续1024字节分片`);

        for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
          if (this.isClosing) {
            break;
          }

          const chunk = chunks[chunkIndex];
          await this.sendAudioChunkImmediately(chunk, chunkIndex, chunks.length);

          // 更新采样点索引
          this.lastSentSampleIndex += chunk.length;

          // 立即发送，不延迟
        }
      }

      console.log(`现有数据发送完成，最后发送采样点位置: ${this.lastSentSampleIndex}`);

    } catch (error) {
      console.error('发送现有数据错误:', error);
    } finally {
      this.isSending = false;
    }
  }

  private setupRealTimeListenerBluetoothStyle(): void {
    console.log('设置实时监听器（仿蓝牙模式）');

    // 清理旧的定时器
    if (this.sendIntervalId !== null) {
      clearInterval(this.sendIntervalId);
      this.sendIntervalId = null;
    }

    // 设置新的定时器，使用20ms检查间隔（与蓝牙一致）
    this.sendIntervalId = setInterval(() => {
      try {
        // 检查对象是否仍然有效（防止GC后的访问）
        if (!this || this.isClosing || !this.ws) {
          return;
        }

        if (this.isSending) {
          return;
        }

        // 添加节流控制：确保最小发送间隔
        const currentTime = Date.now();
        if (currentTime - this.lastSendTime < this.MIN_SEND_INTERVAL) {
          return;
        }

        // 检查是否有新数据（基于采样点总数）
        const totalSamples = this.calculateTotalSamplesCached();

        if (totalSamples > this.lastSentSampleIndex) {
          this.lastSendTime = currentTime;
          this.processNewDataImmediately();
        }
      } catch (error) {
        console.error('2.4G实时监听器回调异常:', error);
        // 如果出现异常，清理定时器
        if (this && this.cleanupIntervals) {
          this.cleanupIntervals();
        }
      }
    }, this.CHECK_INTERVAL_MS) as number; // 使用20ms检查间隔，与蓝牙一致
  }

  private async processNewDataImmediately(): Promise<void> {
    // 计算总采样点数来检查是否有新数据
    const totalSamples = this.calculateTotalSamplesCached();

    if (totalSamples <= this.lastSentSampleIndex || this.isSending || this.isClosing) {
      return;
    }

    try {
      this.isSending = true;

      // 使用连续分片获取新数据
      const chunks = this.getContinuousAudioChunks();

      if (chunks.length > 0) {
        console.log(`发送 ${chunks.length} 个新数据连续分片`);

        for (let chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
          if (this.isClosing) {
            break;
          }

          const chunk = chunks[chunkIndex];
          await this.sendAudioChunkImmediately(chunk, chunkIndex, chunks.length);

          // 更新全局采样点位置
          this.lastSentSampleIndex += chunk.length;

          // 立即发送，不延迟
        }
      }

      console.log(`新数据发送完成，当前采样点位置: ${this.lastSentSampleIndex}`);

    } catch (error) {
      console.error('发送新数据错误:', error);
    } finally {
      this.isSending = false;
    }
  }

  private async sendAudioChunkImmediately(chunk: Int16Array, chunkIndex: number, totalChunks: number): Promise<void> {
    try {
      if (this.isClosing) {
        return;
      }

      if (!chunk || chunk.length === 0) {
        return;
      }

      // 添加超时控制，防止长时间阻塞
      const timeoutPromise = new Promise<never>((_, reject) => {
        setTimeout(() => reject(new Error('发送音频分片超时')), 2000);
      });

      const sendPromise = new Promise<void>((resolve) => {
        try {
          const base64Audio = this.int16ToBase64(chunk);

          if (!base64Audio) {
            resolve();
            return;
          }

          // 减少日志输出频率，避免阻塞
          if (chunkIndex % 10 === 0 || chunkIndex < 3) {
            console.log(`2.4G分片 ${chunkIndex}/${totalChunks} Base64长度: ${base64Audio.length}`);
          }

          // 确保整个会话只发送一次start=true
          // 只依赖hasSentStart标志，不依赖chunkIndex（因为chunkIndex在不同方法中会重置）
          const isStart = !this.hasSentStart;
          if (isStart) {
            this.hasSentStart = true;
            console.log('🎤 2.4G发送开始标志 start=true，当前采样点位置:', this.lastSentSampleIndex);
          }
          const isEnd = false;

          const inputMessage: inputMessageModel = {
            "start": isStart,
            "clientId": this.inputMessage.clientId,
            "ptt": this.inputMessage.ptt,
            "serialNo": this.inputMessage.serialNo,
            "phrases": this.inputMessage.phrases,
            "format": this.inputMessage.format || "pcm",
            "apiKey": this.inputMessage.apiKey,
            "language": this.inputMessage.language,
            "end": isEnd,
            "rate": this.inputMessage.rate,
            "deviceNo": this.inputMessage.deviceNo,
            "content": base64Audio
          };

          const success = this.sendMessage(inputMessage);
          if (!success) {
            console.error('发送音频数据失败');
          }

          // 更新性能指标
          this.metrics.totalChunksSent++;
          this.metrics.totalBytesSent += chunk.length * 2;
          this.metrics.lastChunkTime = Date.now();

          resolve();
        } catch (error) {
          console.error(`音频分片处理错误:`, error);
          resolve(); // 继续执行，不中断整个流程
        }
      });

      await Promise.race([sendPromise, timeoutPromise]);

    } catch (error) {
      console.error(`发送音频分片错误:`, error);
      // 如果是超时错误，标记为需要重试或跳过
      if (error.message && error.message.includes('超时')) {
        console.warn('音频分片发送超时，跳过此分片');
        this.metrics.failedChunks++;
      }
    }
  }

  // 获取连续的音频分片，从全局采样点位置开始
  private getContinuousAudioChunks(): Int16Array[] {
    const chunks: Int16Array[] = [];

    // 计算总采样点数
    const totalSamples = this.calculateTotalSamplesCached();

    // 如果没有新数据，返回空数组
    if (totalSamples <= this.lastSentSampleIndex) {
      return chunks;
    }

    // 创建合并的数据缓冲区
    const combinedData = new Int16Array(totalSamples);
    let offset = 0;
    for (const frame of this.audioData) {
      combinedData.set(frame, offset);
      offset += frame.length;
    }

    // 从上次发送的位置开始连续分片
    for (let i = this.lastSentSampleIndex; i < combinedData.length; i += this.SAMPLES_PER_CHUNK) {
      const endIndex = Math.min(i + this.SAMPLES_PER_CHUNK, combinedData.length);
      const chunk = combinedData.slice(i, endIndex);
      chunks.push(chunk);
      console.log(`2.4G连续分片 ${chunks.length}: 从采样点${i}到${endIndex - 1}, 大小: ${chunk.length}采样点`);
    }

    console.log(`2.4G连续分片总共生成 ${chunks.length} 个分片，从全局采样点${this.lastSentSampleIndex}开始`);
    return chunks;
  }

  private getContinuousAudioChunksFromStart(): Int16Array[] {
    const chunks: Int16Array[] = [];

    // 计算总采样点数
    let totalSamples = 0;
    for (let i = 0; i < this.audioData.length; i++) {
      totalSamples += this.audioData[i].length;
    }

    if (totalSamples <= 0) {
      return chunks;
    }

    // 创建合并的数据缓冲区
    const combinedData = new Int16Array(totalSamples);
    let offset = 0;
    for (const frame of this.audioData) {
      combinedData.set(frame, offset);
      offset += frame.length;
    }

    // 从0开始连续分片
    for (let i = 0; i < combinedData.length; i += this.SAMPLES_PER_CHUNK) {
      const endIndex = Math.min(i + this.SAMPLES_PER_CHUNK, combinedData.length);
      const chunk = combinedData.slice(i, endIndex);
      chunks.push(chunk);
    }

    return chunks;
  }

  // 获取总采样点数（带缓存优化）- 仿蓝牙版本
  private calculateTotalSamplesCached(): number {
    const currentTime = Date.now();
    // 缓存100ms内的计算结果，避免频繁计算，减少主线程开销
    if (currentTime - this.lastCacheUpdateTime < 100) {
      return this.cachedTotalSamples;
    }

    let totalSamples = 0;
    const length = this.audioData.length;
    // 批量计算，减少循环开销
    for (let i = 0; i < length; i++) {
      totalSamples += this.audioData[i].length;
    }

    this.cachedTotalSamples = totalSamples;
    this.lastCacheUpdateTime = currentTime;
    return totalSamples;
  }

  // ========== 完成检测和无数据超时 ==========

  private setupCompletionDetection(): void {
    console.log('2.4G设置完成检测');

    let lastDataLength = this.audioData.length;
    let stableCount = 0;
    this.completionDetectionStartTime = Date.now(); // 记录开始检测的时间

    this.completionCheckId = setInterval(() => {
      try {
        // 检查对象是否仍然有效（防止GC后的访问）
        if (!this || this.isClosing) {
          if (this && this.cleanupIntervals) {
            this.cleanupIntervals();
          }
          return;
        }

        // 检查当前数组长度
        const currentLength = this.audioData.length;

        // 计算总采样点数，用于最小数据量检查
        const currentTotalSamples = this.calculateTotalSamplesCached();

        // 只有在至少有最小数据量后才开始检测完成，避免误判
        if (currentTotalSamples < this.MIN_SAMPLES_FOR_COMPLETION) {
          // 检查是否超时（10秒内没有数据）
          const elapsedTime = Date.now() - this.completionDetectionStartTime;
          if (elapsedTime > this.MAX_NO_DATA_TIMEOUT) {
            console.warn(`2.4G设备${this.MAX_NO_DATA_TIMEOUT / 1000}秒内未收到音频数据，停止检测并清理资源`);
            this.cleanupIntervals();
            return;
          }

          if (stableCount % 50 === 0) { // 减少日志频率
            console.log(`2.4G采样点不足(${currentTotalSamples}/${this.MIN_SAMPLES_FOR_COMPLETION})，继续等待...（已等待${Math.floor(elapsedTime / 1000)}秒）`);
          }
          stableCount++;
          return;
        }

        // 检查音频采集是否已停止（关键修复）
        const audioDataState = ConnectDevice.Communication[AppStorage.get('device_currIndex') as number ||
          0]?.Communication?.audioDataState || false;

        if (stableCount % 50 === 0) { // 每秒输出一次状态
          console.log(`2.4G完成检测状态 - 数组长度: ${currentLength}, audioDataState: ${audioDataState}, 稳定计数: ${stableCount}`);
        }

        if (currentLength === lastDataLength) {
          stableCount++;

          if (stableCount % 25 === 0 || stableCount >= 50) { // 减少日志频率
            console.log(`2.4G数据稳定计数: ${stableCount}/50 (${stableCount * this.CHECK_INTERVAL_MS}ms), audioDataState: ${audioDataState}`);
          }

          // 如果数据稳定超过阈值，发送结束标记
          if (stableCount >= 50) {
            console.log(`2.4G数据稳定超过${50 * this.CHECK_INTERVAL_MS}ms（1秒），发送结束标记`);
            this.sendEndMarker();
            this.cleanupIntervals();
          }
        } else {
          if (stableCount > 0 && stableCount % 10 === 0) { // 减少日志频率
            console.log(`2.4G接收到新数据，重置稳定计数 (之前: ${stableCount})，当前数组长度: ${currentLength}`);
          }
          stableCount = 0;
          lastDataLength = currentLength;
        }
      } catch (error) {
        console.error('2.4G完成检测回调异常:', error);
        // 如果出现异常，清理定时器
        if (this && this.cleanupIntervals) {
          this.cleanupIntervals();
        }
      }
    }, this.CHECK_INTERVAL_MS) as number;
  }

  private setupNoDataTimeout(): void {
    console.log(`设置无数据超时检测: ${this.NO_DATA_TIMEOUT_MS}ms`);

    this.noDataTimeoutId = setTimeout(() => {
      try {
        // 检查对象是否仍然有效（防止GC后的访问）
        if (!this || this.isClosing) {
          return;
        }

        console.warn(`2.4G音频数据超时: ${this.NO_DATA_TIMEOUT_MS}ms内未收到任何音频数据`);
        console.log(`当前音频数据状态: 帧数=${this.audioData.length}, 已发送索引=${this.lastSentSampleIndex}`);

        // 发送结束标记并停止语音输入
        this.sendEndMarker();
        this.cleanupIntervals();

      } catch (error) {
        console.error('无数据超时处理异常:', error);
        if (this && this.cleanupIntervals) {
          this.cleanupIntervals();
        }
      }
    }, this.NO_DATA_TIMEOUT_MS) as number;
  }

  private sendEndMarker(): void {
    // 防止重复发送结束标记
    if (this.hasSentEnd) {
      console.log('结束标记已发送，跳过重复发送');
      return;
    }

    console.log('发送结束标记');
    this.hasSentEnd = true;

    const endMessage: inputMessageModel = {
      "start": false,
      "clientId": this.inputMessage.clientId,
      "ptt": this.inputMessage.ptt,
      "serialNo": this.inputMessage.serialNo,
      "phrases": this.inputMessage.phrases,
      "format": this.inputMessage.format || "pcm",
      "apiKey": this.inputMessage.apiKey,
      "language": this.inputMessage.language,
      "end": true,
      "rate": this.inputMessage.rate,
      "deviceNo": this.inputMessage.deviceNo,
      "content": ""
    };

    this.sendMessage(endMessage);
    this.wending = true;
    console.error(this.wending + '\t' + '发送结束标记', JSON.stringify(endMessage.rate));
  }

  // 延迟函数
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  // 清理资源
  public destroy(): void {
    console.log('开始销毁AudioWebSocketHandler');

    // 立即标记对象为无效状态，防止定时器回调继续执行
    this.isClosing = true;
    this.hasSentStart = false; // 重置start标志，为下次会话做准备
    this.hasSentEnd = false; // 重置end标志，为下次会话做准备

    // 立即清理所有定时器，防止SIGSEGV
    this.cleanupIntervals();

    this.disconnectAsync().then(() => {
      // 清理音频数据
      this.audioData = [];
      this.pendingChunks = [];
      this.isSending = false;
      this.ws = null;
      this.lastSentSampleIndex = 0;
      console.log('AudioWebSocketHandler资源已完全清理');
    });
  }
}
// 定义搜索引擎配置接口
interface SearchEngineConfig {
  name: string;
  url: string;
}