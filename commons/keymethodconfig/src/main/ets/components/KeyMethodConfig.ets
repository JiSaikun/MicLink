import {
  Communication,
  DeviceInfo,
  AudioFileManager,
  AudioWebSocketHandler,
  inputMessageModel,
  ConnectDevice,
  DPI_currInfoModel,
  KeyPressType,
} from 'mouse' //语音输入
import { WebSocket_serverUrl, getModelInfoModel, Languages } from 'config'; //语音输入
import window from '@ohos.window'; //一键回到桌面————应用最小化
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common'; //打开网页
import { Want } from '@kit.AbilityKit'; //打开网页

import { OpenLinkOptions } from '@kit.AbilityKit'; // 导入AbilityKit中的常用功能和打开链接选项
import { hilog } from '@kit.PerformanceAnalysisKit'; // 导入性能分析工具包中的日志功能
import { pasteboard } from '@kit.BasicServicesKit'; //划词翻译————剪切板
import { _translate, translate_Params, translate_Response } from 'mouse'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'; //读取剪切板————主动获取权限
import { Float_Window } from 'float_window'; //按键执行方法回调
import { OpenFileWithSystemApp } from 'api';
import { AudioWebSocketHandler_ble, BlueTooth_devices, DeviceArrayType_Ble } from 'bluetooth';
import { webview } from '@kit.ArkWeb';
import { promptAction } from '@kit.ArkUI';
import { Notification } from 'config';
import { notificationManager } from '@kit.NotificationKit';

const TAG: string = '[_KeyMethodConfig]';
const DOMAIN_NUMBER: number = 0xFF00;

async function getSlot(): Promise<boolean> { //用户已经开启了通知权限，检查用户是否开启了横屏通知
  return new Promise((resolve, reject) => {
    let getSlotCallback = (err: BusinessError, data: notificationManager.NotificationSlot): void => {
      if (err) {
        hilog.error(DOMAIN_NUMBER, TAG, `Failed to get slot. Code is ${err.code}, message is ${err.message}`);
      } else {
        hilog.info(DOMAIN_NUMBER, TAG, `Succeeded in getting slot.`);
        hilog.warn(DOMAIN_NUMBER, TAG, `slot enable status is ${JSON.stringify(data)}`);
        if (data != null) {
          hilog.warn(DOMAIN_NUMBER, TAG, `slot enable status is ${JSON.stringify(data)}`);
          hilog.info(DOMAIN_NUMBER, TAG, `slot enable status is ${JSON.stringify(data.level)}`);
          hilog.info(DOMAIN_NUMBER, TAG,
            `vibrationEnabled status is ${JSON.stringify(data.vibrationEnabled)}`);
          hilog.info(DOMAIN_NUMBER, TAG, `lightEnabled status is ${JSON.stringify(data.lightEnabled)}`);
          let a = (data as NotificationSlot).reminderMode
          if (a === 63 || (!data.sound && a === 63)) { //开启了横屏通知
            if (!Notification.state) {
              resolve(true)
            }
          } else { //没有开启横屏通知
            promptAction.showDialog({
              message: Languages.noLandscapeNotificationEnabled[AppStorage.get('languages') as string], // 你当前没有开启横屏通知!!!
              buttons: [{ text: Languages.goToEnable[AppStorage.get('languages') as string], color: '#007DFF' },
                { text: Languages.refuse[AppStorage.get('languages') as string], color: '#FF3B30' }]
            })
              .then((res: promptAction.ShowDialogSuccessResponse) => {
                if (res.index === 0) { //去开启横屏通知
                  notificationManager.openNotificationSettings(AppStorage.get('context') as common.UIAbilityContext)
                    .then(() => {
                      resolve(false)
                      hilog.info(DOMAIN_NUMBER, TAG, `[ANS] openNotificationSettings success`);
                    })
                    .catch((err: BusinessError) => {
                      hilog.error(DOMAIN_NUMBER, TAG,
                        `[ANS] openNotificationSettings failed, code is ${err.code}, message is ${err.message}`);
                    });
                } else {
                  resolve(true)
                  // AppStorage.setOrCreate('sdajfhjk', true)
                  // promptAction.showToast({ message: '开启语音翻译操作' })
                }
              })
          }
        }
      }
    }
    let slotType: notificationManager.SlotType = notificationManager.SlotType.SERVICE_INFORMATION;
    notificationManager.getSlot(slotType,
      getSlotCallback as (err: BusinessError, data: notificationManager.NotificationSlot) => void);
  })


}

async function LandscapeNotification(callBack: () => void): Promise<boolean> {
  return new Promise((resolve, reject) => {
    Notification.init()
      .then((initrequest) => {
        if (!initrequest) { //请求被拒绝
          promptAction.showDialog({
            // 你拒绝了通知弹窗的权限
            message: Languages.notificationPermissionDenied[AppStorage.get('languages') as string],
            buttons: [{ text: Languages.goToEnable[AppStorage.get('languages') as string], color: '#007DFF' },
              { text: Languages.refuse[AppStorage.get('languages') as string], color: '#FF3B30' }]
          })
            .then((res: promptAction.ShowDialogSuccessResponse) => {
              if (res.index === 0) {
                notificationManager.openNotificationSettings(AppStorage.get('context') as common.UIAbilityContext)
                  .then(() => {
                    hilog.info(DOMAIN_NUMBER, TAG, `[ANS] openNotificationSettings success`);
                    resolve(false)
                  })
                  .catch((err: BusinessError) => {
                    hilog.error(DOMAIN_NUMBER, TAG,
                      `[ANS] openNotificationSettings failed, code is ${err.code}, message is ${err.message}`);
                  });
              } else {
                // AppStorage.setOrCreate('sdajfhjk', true)
                // promptAction.showToast({ message: '开启语音翻译操作' })
                resolve(false)
              }
            })
        } else { //查看用户是否开启了横幅通知
          console.error('查看用户是否开启了横幅通知')

          resolve(true)

          // addSlot回调
          // let addSlotCallBack = (err: BusinessError): void => {
          //   if (err) {
          //     hilog.error(DOMAIN_NUMBER, TAG, `创建指定类型的通知渠道失败:addSlot failed, code is ${err.code}, message is ${err.message}`);
          //   } else {
          //     hilog.info(DOMAIN_NUMBER, TAG, `创建指定类型的通知渠道成功:addSlot success`);
          //     // getSlot回调
          //     getSlot()
          //       .then((getSoltRes) => {
          //         if (getSoltRes) {
          //           resolve(true)
          //         } else {
          //           LandscapeNotification(callBack)
          //         }
          //       })
          //   }
          // }
          // notificationManager.addSlot(notificationManager.SlotType.SERVICE_INFORMATION, addSlotCallBack);
        }
      })

  })
}

export class _KeyMethodConfig {
  /**
   * 语音输入--语音翻译
   * 0：语音输入
   * 1：语音翻译
   */
  static async voiceInput(state: number = 0, isAI_assistant: boolean = false) {
    AppStorage.setOrCreate('isAI_assistant', isAI_assistant)

    if (!(AppStorage.get('device_isBle') ?
    (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
      0].BlueTooth_devices.audioDataState :
    ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState
    )) {
      // if (!AppStorage.get('sdajfhjk')) {
      if (AppStorage.get('flax')) {
        if (state) { //语音翻译
          if (AppStorage.get('isAutoCloseVoiceTransPop')) {
            if (await LandscapeNotification(() => {
            })) {
              if (!Notification.state) {
                Notification.state = true
                Notification.setOrCreate(Languages.voiceTranslation[AppStorage.get('languages') as string],
                  Languages.pleaseSpeak[AppStorage.get('languages') as string])
              }
            } else {
              return
            }
          }
        } else {
          if (await LandscapeNotification(() => {
          })) {
            if (!Notification.state) {
              Notification.state = true

              Notification.setOrCreate(isAI_assistant ?
              Languages.voiceAssistant[AppStorage.get('languages') as string] :
              Languages.voiceInput[AppStorage.get('languages') as string],
                Languages.pleaseSpeak[AppStorage.get('languages') as string])
            }
          } else {
            return
          }

        }
      }
      // }
      if (AppStorage.get('device_isBle')) {
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.send([0x62])
          .then(() => {
            BlueTooth_devices.audioData = [];
            (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
              0].BlueTooth_devices.audioDataState =
              !(AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
                0].BlueTooth_devices.audioDataState

            //WebSocket  语音数据处理
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608" + new Date().toString(),
              "ptt": (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number].isPunctuationRecognition ?
                '1' : '0',
              "serialNo": (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
                0].BlueTooth_devices.deviceInfo.sn,
              "phrases": "",
              "format": "pcm",
              "apiKey": (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_show_currIndex') as number].getModelInfo?.appkey as string,
              "language": state ? AppStorage.get('from_languages') as string : AppStorage.get('speech_Recognition_languages') as string,
              "end": false,
              "rate": (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_show_currIndex') as number].BlueTooth_devices.deviceInfo.sampleRate ?
                "16k" : "8k",
              "deviceNo": "6c:b1:33:9f:b9:8b",
              content: ''
            }
            console.log(`创建蓝牙WebSocket时，BlueTooth_devices.audioData长度: ${BlueTooth_devices.audioData.length}`);
            let audioToText: AudioWebSocketHandler_ble =
              new AudioWebSocketHandler_ble(WebSocket_serverUrl.audioToText, BlueTooth_devices.audioData, state,
                inputMessage) //语音转文字 websocket  //0：语音输入
            audioToText.connect()
          })
      } else {
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x62])
          .then(() => {
            Communication.audioData = []
            ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState =
              !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState
            //WebSocket  语音数据处理
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608" + new Date().toString(),
              "ptt": ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].isPunctuationRecognition ?
                '1' : '0',
              "serialNo": ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
                0].Communication.deviceInfo.sn,
              "phrases": "",
              "format": "pcm",
              "apiKey": ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
                0].getModelInfo?.appkey as string,
              "language": state ? AppStorage.get('from_languages') as string :AppStorage.get('speech_Recognition_languages') as string,
              "end": false,
              "rate": ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.deviceInfo.sampleRate ?
                "16k" : "8k",
              "deviceNo": "6c:b1:33:9f:b9:8b",
              content: ''
            }
            console.log(`创建2.4G WebSocket时，Communication.audioData长度: ${Communication.audioData.length}`);
            let audioToText: AudioWebSocketHandler =
              new AudioWebSocketHandler(WebSocket_serverUrl.audioToText, Communication.audioData, state,
                inputMessage) //语音转文字 websocket  //0：语音输入
            audioToText.connect()
          })
      }

      if (state) {
        AppStorage.setOrCreate('editCompleted', false)
        AppStorage.setOrCreate('voiceTranslationText', {
          transText: '',
          text: ''
        })
        if (!AppStorage.get('voiceOrText')) {
          AppStorage.setOrCreate('voiceTranslationText', [])
        }
        AppStorage.setOrCreate('voiceOrText', true)
        if (Float_Window.windowClass) {
          Float_Window.minimize_float_window()
        }
        if (!Float_Window.showVoiceTranslation) {
          Float_Window.showVoiceTranslation = true
          Float_Window.creat_VoiceTranslation()
        }
        if (AppStorage.get('flax') && !AppStorage.get('isAutoCloseVoiceTransPop')) {
          const pageInfo = AppStorage.get('pageInfo') as NavPathStack
          let pages = pageInfo.getAllPathName()
          if (pages[pages.length-1] !== 'VoiceTranslation') {
            pageInfo.pushPath({ "name": 'VoiceTranslation' })
          }
        }
        // else {  //窗口无法置顶
        //   Float_Window.show_float_window(Float_Window.window_VoiceTranslation)
        // }
      } else {
        // if (!Float_Window.showVoiceInput) { //窗口没有显示时创建窗口
        Float_Window.creat()
        // } else {
        //   Float_Window.show_float_window()
        // }
        Float_Window.showVoiceInput += 1
      }

    } else {
      Notification.state = false
      // setTimeout(()=>{
      //   Notification.clear()
      // },2000)
      if (AppStorage.get('device_isBle')) {
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.send([0x63])
          .then(() => {
            (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
              0].BlueTooth_devices.audioDataState =
              !(AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
                0].BlueTooth_devices.audioDataState
            // /**
            //  * 语音数据处理
            //  */
            // // 保存本地PCM文件
            // const context = AppStorage.get('context') as common.UIAbilityContext;
            //   let a: AudioFileManager = new AudioFileManager(BlueTooth_devices.audioData, context)
            //   console.log(BlueTooth_devices.audioData.length.toString(), '语音数据结束*****模拟')
          })
      } else {
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x63])
          .then(() => {
            ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState =
              !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState
            /**
             * 语音数据处理
             */
            // // 保存本地PCM文件
            // const context = AppStorage.get('context') as common.UIAbilityContext;
            // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
            // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')
          })
      }
      if (!state) {
        let flax = Float_Window.showVoiceInput
        setTimeout(() => {
          if (Float_Window.showVoiceInput === flax) {
            // Float_Window.showVoiceInput = 0
            Float_Window.minimize_float_window()
            // Float_Window.destroyWindow() //在悬浮窗关闭后清空语音输入文本状态变量，文本显示：如果文本变量不为空，在后面拼接，如果为空则直接将新数据赋值即可
          }
        }, 2000)
      }


    }
    if (state) {
      if (AppStorage.get('voiceInputState')) {
        AppStorage.setOrCreate('voiceInputState', false) //语音状态
      }
      if (AppStorage.get('device_isBle')) {
        AppStorage.setOrCreate('voiceTranslationState',
          !(AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
            0].BlueTooth_devices.audioDataState)
      } else {
        AppStorage.setOrCreate('voiceTranslationState',
          !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
            0].Communication.audioDataState)
      } //语音状态
    } else {
      if (AppStorage.get('voiceTranslationState')) {
        AppStorage.setOrCreate('voiceTranslationState', false) //语音状态
      }


      AppStorage.setOrCreate('voiceInputState', AppStorage.get('device_isBle') ?
        !(AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.audioDataState :
        !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
          0].Communication.audioDataState) //语音状态
    }
  }

  /**
   * 语音输入_长按按下
   */
  static async voiceInput_long(state: number = 0, isAI_assistant: boolean = false) {
    AppStorage.setOrCreate('isAI_assistant', isAI_assistant)
    // if (!AppStorage.get('sdajfhjk')) {
    if (AppStorage.get('flax')) {
      if (state) { //语音翻译
        if (AppStorage.get('isAutoCloseVoiceTransPop')) {
          if (await LandscapeNotification(() => {
          })) {
            if (!Notification.state) {
              Notification.state = true
              Notification.setOrCreate(Languages.voiceTranslation[AppStorage.get('languages') as string],
                Languages.pleaseSpeak[AppStorage.get('languages') as string])
            }
          } else {
            return
          }
        }
      } else {
        if (await LandscapeNotification(() => {
        })) {
          if (!Notification.state) {
            console.warn('警告1')
            Notification.state = true
            Notification.setOrCreate(isAI_assistant ? Languages.voiceAssistant[AppStorage.get('languages') as string] :
            Languages.voiceInput[AppStorage.get('languages') as string],
              Languages.pleaseSpeak[AppStorage.get('languages') as string])
          }
        } else {
          console.warn('警告2')
          return
        }

      }
    }
    // }
    console.log('[语音调试] voiceInput_long 开始，state:', state, 'isAI_assistant:', isAI_assistant);
    if (AppStorage.get('device_isBle')) {
      BlueTooth_devices.audioData = []
      console.log('[语音调试] 清空蓝牙音频数据');
    } else {
      Communication.audioData = []
      console.log('[语音调试] 清空2.4G音频数据');
    }
    /**
     * 语音数据处理
     */
    //保存本地PCM文件
    // const context = AppStorage.get('context') as common.UIAbilityContext;
    // let a: AudioFileManager = new AudioFileManager(Communication.audioData, context)
    // console.log(Communication.audioData.length.toString(), '语音数据结束*****模拟')
    if (AppStorage.get('device_isBle')) {
      //WebSocket  语音数据处理
      let inputMessage: inputMessageModel = {
        start: false,
        "clientId": "clientId1751968608" + new Date().toString(),
        "ptt": (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number].isPunctuationRecognition ?
          '1' :
          '0',
        "serialNo": (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.deviceInfo.sn,
        "phrases": "",
        "format": "pcm",
        "apiKey": (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_show_currIndex') as number].getModelInfo?.appkey as string,
        "language": state ? AppStorage.get('from_languages') as string : AppStorage.get('speech_Recognition_languages') as string,
        "end": false,
        "rate": (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_show_currIndex') as number].BlueTooth_devices.deviceInfo.sampleRate ?
          "16k" : "8k",
        "deviceNo": "6c:b1:33:9f:b9:8b",
        content: ''
      }
      let audioToText: AudioWebSocketHandler_ble =
        new AudioWebSocketHandler_ble(WebSocket_serverUrl.audioToText, BlueTooth_devices.audioData, state,
          inputMessage) //语音转文字 websocket
      audioToText.connect()
    } else {
      //WebSocket  语音数据处理
      let inputMessage: inputMessageModel = {
        start: false,
        "clientId": "clientId1751968608" + new Date().toString(),
        "ptt": ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].isPunctuationRecognition ?
          '1' :
          '0',
        "serialNo": ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
          0].Communication.deviceInfo.sn,
        "phrases": "",
        "format": "pcm",
        "apiKey": ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].getModelInfo?.appkey as string,
        "language": state ? AppStorage.get('from_languages') as string :AppStorage.get('speech_Recognition_languages') as string,
        "end": false,
        "rate": ConnectDevice.Communication[AppStorage.get('device_show_currIndex') as number].Communication.deviceInfo.sampleRate ?
          "16k" : "8k",
        "deviceNo": "6c:b1:33:9f:b9:8b",
        content: ''
      }
      let audioToText: AudioWebSocketHandler =
        new AudioWebSocketHandler(WebSocket_serverUrl.audioToText, Communication.audioData, state,
          inputMessage) //语音转文字 websocket
      audioToText.connect()
    }
    if (AppStorage.get('device_isBle')) {
      if ((AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.audioDataState) { //若开始长按时，有通过0x62命令开启的语音输入等，先进行关闭 ...否则改变audioDataState 采集状态，确保1b数据被放到语音数据里
        // ——————手动发起0x62收集录音数据
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.send([0x62])
      } else {
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.audioDataState =
          !(AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
            0].BlueTooth_devices.audioDataState
      }
    } else {
      const currentState =
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState;
      console.log('[语音调试] 当前2.4G audioDataState状态:', currentState);

      if (currentState) { //若开始长按时，有通过0x62命令开启的语音输入等，先进行关闭 ...否则改变audioDataState 采集状态，确保1b数据被放到语音数据里 ——————手动发起0x62收集录音数据
        console.log('[语音调试] audioDataState为true，先发送0x62命令停止当前语音输入');
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x62])
      } else {
        console.log('[语音调试] audioDataState为false，翻转状态开始音频采集');
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState =
          !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState;
        console.log('[语音调试] 新的audioDataState状态:',
          ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState);
      }
    }
    if (state) {
      AppStorage.setOrCreate('editCompleted', false)
      AppStorage.setOrCreate('voiceTranslationText', {
        transText: '',
        text: ''
      })
      AppStorage.setOrCreate('voiceOrText', true)
      if (Float_Window.windowClass) {
        Float_Window.minimize_float_window()
      }
      if (!Float_Window.showVoiceTranslation) {
        Float_Window.showVoiceTranslation = true
        Float_Window.creat_VoiceTranslation()
      }
      if (AppStorage.get('flax') && !AppStorage.get('isAutoCloseVoiceTransPop')) {
        const pageInfo = AppStorage.get('pageInfo') as NavPathStack
        let pages = pageInfo.getAllPathName()
        if (pages[pages.length-1] !== 'VoiceTranslation') {
          pageInfo.pushPath({ "name": 'VoiceTranslation' })
        }
      }
      if (AppStorage.get('voiceInputState')) {
        AppStorage.setOrCreate('voiceInputState', false) //语音状态
      }
      if (AppStorage.get('device_isBle')) {
        AppStorage.setOrCreate('voiceTranslationState',
          (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
            0].BlueTooth_devices.audioDataState)
      } else {
        AppStorage.setOrCreate('voiceTranslationState',
          ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
            0].Communication.audioDataState)
      } //语音状态
    } else {
      AppStorage.setOrCreate('isAI_assistant', isAI_assistant)
      // if (!Float_Window.showVoiceInput) { //窗口没有显示时创建窗口
      Float_Window.creat()
      // } else {
      //   Float_Window.show_float_window()
      // }
      Float_Window.showVoiceInput += 1
      if (AppStorage.get('voiceTranslationState')) {
        AppStorage.setOrCreate('voiceTranslationState', false) //语音状态
      }
      if (AppStorage.get('device_isBle')) {
        AppStorage.setOrCreate('voiceInputState',
          (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
            0].BlueTooth_devices.audioDataState
        ) //语音状态
      } else {
        AppStorage.setOrCreate('voiceInputState',
          ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
            0].Communication.audioDataState)
      } //语音状态
    }
  }

  /**
   * 语音输入_长按抬起
   */
  static endvoiceInput_long(state: number = 0) {
    Notification.state = false
    // setTimeout(()=>{
    //   Notification.clear()
    // },2000)
    console.log('[语音调试] endvoiceInput_long 开始，state:', state);
    if (AppStorage.get('device_isBle')) {
      console.log('[语音调试] 结束蓝牙语音输入');
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.audioDataState =
        !(AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
          0].BlueTooth_devices.audioDataState;
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x63])
    } else {
      console.log('[语音调试] 结束2.4G语音输入');
      const oldState =
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState;
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState =
        !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState;
      console.log('[语音调试] audioDataState从', oldState, '翻转为',
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState);
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x63])
    }
    if (!state) {
      let flax = Float_Window.showVoiceInput
      setTimeout(() => {
        if (Float_Window.showVoiceInput === flax) { //说明在60s内没有再进行过语音输入功能
          // Float_Window.showVoiceInput = 0
          Float_Window.destroyWindow()
          // Float_Window.destroyWindow() //在悬浮窗关闭后清空语音输入文本状态变量，文本显示：如果文本变量不为空，在后面拼接，如果为空则直接将新数据赋值即可
        }
      }, 2000)
    }

    if (state) {
      if (AppStorage.get('voiceInputState')) {
        AppStorage.setOrCreate('voiceInputState', false) //语音状态
      }
      if (AppStorage.get('device_isBle')) {
        AppStorage.setOrCreate('voiceTranslationState',
          (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
            0].BlueTooth_devices.audioDataState) //语音状态
      } else {
        AppStorage.setOrCreate('voiceTranslationState',
          ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
            0].Communication.audioDataState)
      } //语音状态
    } else {
      if (AppStorage.get('voiceTranslationState')) {
        AppStorage.setOrCreate('voiceTranslationState', false) //语音状态
      }
      if (AppStorage.get('device_isBle')) {
        AppStorage.setOrCreate('voiceInputState',
          (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
            0].BlueTooth_devices.audioDataState)
      } else {
        AppStorage.setOrCreate('voiceInputState',
          ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
            0].Communication.audioDataState)
      } //语音状态
    }
  }

  /**
   *回车/发送
   */
  static entry() {
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0,
        0x28])
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20, 0,
        0x28])
    }
  }

  /**
   *删除
   */
  static delete() {
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0,
        0x2A])
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20, 0,
        0x2A])
    }
  }

  /**
   *打开网页 __百度
   */
  static openTheWebpage() {
    if (!AppStorage.get('webUrlToOpen')) {
      return;
    }

    const context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext;
    const storedUrl: string = AppStorage.get('webUrlToOpen') as string;
    const defaultUrl: string = 'https://www.baidu.com/';

    // 最简单的验证：只要以 http:// 或 https:// 开头就认为是有效 URL
    let finalUrl: string = defaultUrl;
    if (storedUrl &&
      storedUrl.trim() !== '' &&
      (storedUrl.startsWith('http://') || storedUrl.startsWith('https://'))) {
      finalUrl = storedUrl;
    }

    console.error('最终打开的网址:', finalUrl);

    const want: Want = {
      action: 'ohos.want.action.viewData',
      entities: ['entity.system.browsable'],
      uri: finalUrl
    };

    context.startAbility(want);
  }


  /**
   *ChatGPT
   */
  static openChatGPT() {
    let currpageIsAI: boolean = AppStorage.get('currpageIsAI') as boolean
    switch (AppStorage.get('mouse_KeyPressType') as KeyPressType) {
      case KeyPressType.WORK_SUMMARY_CLICK: //工作总结键-单击
        AppStorage.setOrCreate('chatIeUrl', 'og8n92sxc6jd_v1')
        break
      case KeyPressType.WORK_SUMMARY_LONG_PRESS_DOWN: //工作总结键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'og8n92sxc6jd_v1')
        break
      case KeyPressType.TEMPLATE_DOWNLOAD_CLICK: //模版下载键-单击
        AppStorage.setOrCreate('chatIeUrl', 'template')
        break
      case KeyPressType.TEMPLATE_DOWNLOAD_LONG_PRESS_DOWN: //模版下载键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'template')
        break
      case KeyPressType.MIND_MAP_CLICK: //思维导图键-单击
        AppStorage.setOrCreate('chatIeUrl', 'xml')
        break
      case KeyPressType.MIND_MAP_LONG_PRESS_DOWN: //思维导图键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'xml')
        break
      case KeyPressType.READING_COMPREHENSION_CLICK: //阅读理解键-单击
        AppStorage.setOrCreate('chatIeUrl', 'aiReading')
        break
      case KeyPressType.READING_COMPREHENSION_LONG_PRESS_DOWN: //阅读理解键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'aiReading')
        break
      case KeyPressType.DOCUMENT_CONVERSION_CLICK: //文档转换键-单击
        AppStorage.setOrCreate('chatIeUrl', 'fileChange')
        break
      case KeyPressType.DOCUMENT_CONVERSION_LONG_PRESS_DOWN: //文档转换键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'fileChange')
        break
      case KeyPressType.WRITING_CLICK: //写作键-单击
        AppStorage.setOrCreate('chatIeUrl', '61l7lnzu9kot_v1')
        break
      case KeyPressType.WRITING_LONG_PRESS_DOWN: //写作键-长按按下
        AppStorage.setOrCreate('chatIeUrl', '61l7lnzu9kot_v1')
        break
      case KeyPressType.TABLE_CLICK: //表格键-单击
        AppStorage.setOrCreate('chatIeUrl', 'table')
        break
      case KeyPressType.TABLE_LONG_PRESS_DOWN: //表格键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'table')
        break
      case KeyPressType.SPEECH_CLICK: //演讲稿键-单击
        AppStorage.setOrCreate('chatIeUrl', '1ajruc2aglo3_v1')
        break
      case KeyPressType.SPEECH_LONG_PRESS_DOWN: //演讲稿键-长按按下
        AppStorage.setOrCreate('chatIeUrl', '1ajruc2aglo3_v1')
        break
      case KeyPressType.AI_PAINTING_CLICK: //AI绘画键-单击
        AppStorage.setOrCreate('chatIeUrl', 'aiImg')
        break
      case KeyPressType.AI_PAINTING_LONG_PRESS_DOWN: //AI绘画键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'aiImg')
        break
      case KeyPressType.CODE_CLICK: //代码键-单击
        AppStorage.setOrCreate('chatIeUrl', 'g5wrtd2jx1s1_v1')
        break
      case KeyPressType.CODE_LONG_PRESS_DOWN: //代码键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'g5wrtd2jx1s1_v1')
        break
      case KeyPressType.PPT_CLICK: //PPT键-单击
        AppStorage.setOrCreate('chatIeUrl', 'ppt')
        break
      case KeyPressType.PPT_LONG_PRESS_DOWN: //PPT键-长按按下
        AppStorage.setOrCreate('chatIeUrl', 'ppt')
        break
      default:
        AppStorage.setOrCreate('chatIeUrl', 'ai')
    }
    if (currpageIsAI) {
      let pageInfo: NavPathStack = AppStorage.get('pageInfo') as NavPathStack
      pageInfo.clear()
      pageInfo.pushPath({ name: 'aipage' })
      AppStorage.set('currpageIsAI', false)
    }
  }

  /**
   *回到桌面
   */
  static desktop() {
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0x08, 0x07])
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20,
        0x08, 0x07])
    }
  }

  /**
   *快捷按键
   */
  static triggerShortcut() {
    console.log(JSON.stringify(AppStorage.get('custom_shortcut')))
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send((AppStorage.get('custom_shortcut') as shortcutType).pressedKeys)
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
        0].Communication.getDeviceInfo((AppStorage.get('custom_shortcut') as shortcutType).pressedKeys)
    }
  }

  /**
   *前进
   */
  static forward() {
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0x04, 0x4F])
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20,
        0x04, 0x4F])
    }
  }

  /**
   *复制
   */
  static copyContent() {
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0x01, 0x06])
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20,
        0x01, 0x06])
    }
  }

  /**
   *粘贴
   */
  static pasteTarget() {
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0x01, 0x19])
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20,
        0x01, 0x19])
    }
  }

  // /**
  //  *AI智能创作
  //  */
  // static aiGeneratedText() {
  //   // Communication.getDeviceInfo([0x20, 0x04, 0x4F])
  // }
  /**
   *后退
   */
  static back() {
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0x04, 0x50])
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20,
        0x04, 0x50])
    }
  }

  /**
   *一键锁屏
   */
  static lockNow() {
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0x08, 0x0F])
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20,
        0x08, 0x0F])
    }
  }

  /**
   *划词翻译
   */
  static word_SelectedTranslation() {
    AppStorage.setOrCreate('editCompleted', false)
    if (!AppStorage.get('isWordScan_Translation')) {
      return
    }
    if (Float_Window.windowClass) {
      Float_Window.minimize_float_window()
    }
    let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard(); //获取系统剪贴板对象。
    systemPasteboard.clearData() //清空剪贴板
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x20, 0x01, 0x06]) //Ctrl+C
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x20,
        0x01, 0x06]) //Ctrl+C
    }
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      // 向用户申请读取剪贴板的权限
      atManager.requestPermissionsFromUser(AppStorage.get('context'), ['ohos.permission.READ_PASTEBOARD'])
        .then((data) => {
          console.info("权限申请结果: " + JSON.stringify(data));
        })
        .catch((err: BusinessError) => {
          console.error("权限申请失败: " + err.message);
        });
    } catch (err) {
      console.error(`权限申请捕获异常: ${err.code}, ${err.message}`);
    }
    setTimeout(() => {
      systemPasteboard.getData().then((pasteData: pasteboard.PasteData) => {
        console.error(JSON.stringify(pasteData.getRecordCount()))
        let text: string = pasteData.getPrimaryText();
        console.log('111111111111111', text)
        if (text) {
          AppStorage.setOrCreate('voiceTranslationText', {
            transText: '',
            text: ''
          })
          AppStorage.setOrCreate('voiceOrText', false)
          let params: translate_Params = {
            appkey: AppStorage.get('device_isBle') ?
            ((AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
              0].getModelInfo as getModelInfoModel).appkey :
            (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
              0].getModelInfo as getModelInfoModel).appkey, //获取用户按键模式详情中得到
            from: AppStorage.get('wordScan_from_languages') ? AppStorage.get('wordScan_from_languages') as string :
              'ZH_CN', //源语言___后面配置
            productCode: AppStorage.get('device_isBle') ?
            (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
              0].BlueTooth_devices.deviceInfo.productType.toString() :
            ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
              0].Communication.deviceInfo.productType.toString(), //产品编码
            sno: AppStorage.get('device_isBle') ?
            (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
              0].BlueTooth_devices.deviceInfo.sn :
            ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
              0].Communication.deviceInfo.sn, //设备号
            text: text, //翻译内容
            to: AppStorage.get('wordScan_to_languages') ? AppStorage.get('wordScan_to_languages') as string :
              'EN_US' //翻译语言___后面配置
          }
          if (!Float_Window.showVoiceTranslation) {
            Float_Window.showVoiceTranslation = true
            Float_Window.creat_VoiceTranslation()
          }
          if (AppStorage.get('flax')) {
            const pageInfo = AppStorage.get('pageInfo') as NavPathStack
            let pages = pageInfo.getAllPathName()
            if (pages[pages.length-1] !== 'VoiceTranslation') {
              pageInfo.pushPath({ "name": 'VoiceTranslation' })
            }
          }
          _translate(params).then((res) => {
            console.log('翻译请求成功————翻译结果：' + res.data?.transText)
            systemPasteboard.clearData() //清空剪贴板
            if (res.data) {
              let dataArray = AppStorage.get('voiceTranslationText') as translate_Response
              dataArray = {
                transText: res.data?.transText as string,
                text: res.data?.text as string,
              }
              AppStorage.setOrCreate('voiceTranslationText', dataArray)
            } else {
              AppStorage.setOrCreate('flax_yuyinfanyi_chazhaobudaoyuyan',
                !AppStorage.get('flax_yuyinfanyi_chazhaobudaoyuyan'))
            }

          })

        } else {
          AppStorage.setOrCreate('flax_huacifanyi',
            !AppStorage.get('flax_huacifanyi'))
        }

        // setTimeout(() => { //移除一条条目
        //   pasteData.removeRecord(0)
        //   // let isRemove: boolean = pasteData.removeRecordAt(0);
        //   // console.error(JSON.stringify(isRemove))
        // }, 10)
      }
      )
        .catch((err: BusinessError) => {
          console.error('Failed to get PasteData. Cause: ' + err.message);
        });
    }, 200)
  }

  /**
   *DPI切换
   */
  static DPI_Switch() {
    let DPI_currInfo: DPI_currInfoModel = AppStorage.get('device_isBle') ?
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].DPI_currInfo as DPI_currInfoModel :
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].DPI_currInfo as DPI_currInfoModel
    console.log(JSON.stringify(DPI_currInfo))
    if (DPI_currInfo.curr === DPI_currInfo.length - 1) {
      DPI_currInfo.curr = 1
    } else {
      DPI_currInfo.curr += 2
    }
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
        0].BlueTooth_devices.send([0x68, DPI_currInfo.curr])
      // AppStorage.setOrCreate('DPI_currInfo', DPI_currInfo)
        .then(() => {
          (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].mouseconfig as DeviceInfo).dpiLevel =
            DPI_currInfo.curr === 1 ? DPI_currInfo.curr : DPI_currInfo.curr
        })
    } else {
      // AppStorage.setOrCreate('DPI_currInfo', DPI_currInfo)
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].Communication.getDeviceInfo([0x68,
        DPI_currInfo.curr]).then(() => {
        (ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].mouseconfig as DeviceInfo).dpiLevel =
          DPI_currInfo.curr === 1 ? DPI_currInfo.curr : DPI_currInfo.curr
      })
    }

    DPI_currInfo.curr -= 1
    AppStorage.setOrCreate('DPI_currInfo', DPI_currInfo)
    AppStorage.setOrCreate('DPI_currIndex', DPI_currInfo.curr)
    if (AppStorage.get('device_isBle')) {
      (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number].DPI_currInfo =
        DPI_currInfo
    } else {
      ConnectDevice.Communication[AppStorage.get('device_currIndex') as number].DPI_currInfo = DPI_currInfo
    }
    // if (AppStorage.get('flax_DPI')) {
    //   AppStorage.setOrCreate('flax_DPI',false)
    //   setTimeout(()=>AppStorage.setOrCreate('flax_DPI',true),500)
    // }
  }

  /**
   *打开文件夹
   */
  static explorer() {
    const TAG: string = '[UIAbilityComponentsOpenLink]'; // 定义日志标签
    const DOMAIN_NUMBER: number = 0xFF00; // 定义日志域编号
    let context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext; // 获取当前UIAbility上下文
    let link: string = 'filemanager://openDirectory'; // 定义要打开的链接，这里是文件管理的URI
    let openLinkOptions: OpenLinkOptions = {
      // 配置打开链接的选项
      parameters: {
        // 参数设置
        'fileUri': AppStorage.get('folderPath') as string // 文件URI参数，这里为空
        // 'fileUri': 'file://docs/storage/Users/currentUser/Desktop/%E6%96%B0%E5%BB%BA%20DWG%20%E6%96%87%E4%BB%B6.dwg' // 文件URI参数，这里为空
        // 'fileUri': 'file://docs/storage/Users/currentUser/Documents/test.txt' // 文件URI参数，这里为空
      }
    };
    try { // 异常处理
      context.openLink(link, openLinkOptions) // 调用打开链接方法
        .then(() => { // 成功回调
          hilog.info(DOMAIN_NUMBER, TAG, 'open link success.'); // 记录成功日志
        }).catch((err: BusinessError) => { // 失败回调
        hilog.error(DOMAIN_NUMBER, TAG,
          `open link failed. Code is ${err.code}, message is ${err.message}`); // 记录错误日志
      });
    } catch (paramError) { // 捕获参数错误
      hilog.error(DOMAIN_NUMBER, TAG,
        `Failed to start link. Code is ${paramError.code}, message is ${paramError.message}`); // 记录参数错误日志
    }
    // const TAG: string = '[UIAbilityComponentsOpenLink]'; // 定义日志标签
    // const DOMAIN_NUMBER: number = 0xFF00; // 定义日志域编号
    // let context: common.UIAbilityContext = AppStorage.get('context') as common.UIAbilityContext; // 获取当前UIAbility上下文
    // let link: string = 'filemanager://openDirectory'; // 定义要打开的链接，这里是文件管理的URI
    // let openLinkOptions: OpenLinkOptions = {
    //   // 配置打开链接的选项
    //   parameters: {
    //     // 参数设置
    //     'fileUri': '' // 文件URI参数，这里为空
    //     // 'fileUri': 'file://docs/storage/Users/currentUser/Desktop/%E6%96%B0%E5%BB%BA%20DWG%20%E6%96%87%E4%BB%B6.dwg' // 文件URI参数，这里为空
    //     // 'fileUri': 'file://docs/storage/Users/currentUser/Documents/test.txt' // 文件URI参数，这里为空
    //   }
    // };
    // try { // 异常处理
    //   context.openLink(link, openLinkOptions) // 调用打开链接方法
    //     .then(() => { // 成功回调
    //       hilog.info(DOMAIN_NUMBER, TAG, 'open link success.'); // 记录成功日志
    //     }).catch((err: BusinessError) => { // 失败回调
    //     hilog.error(DOMAIN_NUMBER, TAG,
    //       `open link failed. Code is ${err.code}, message is ${err.message}`); // 记录错误日志
    //   });
    // } catch (paramError) { // 捕获参数错误
    //   hilog.error(DOMAIN_NUMBER, TAG,
    //     `Failed to start link. Code is ${paramError.code}, message is ${paramError.message}`); // 记录参数错误日志
    // }
  }


  /**
   * 一键最小化
   */
  static onMinimizeClick() {
    // 获取当前应用的最后窗口
    window.getLastWindow(AppStorage.get('context') as common.UIAbilityContext).then((windowClass: window.Window) => {
      // 调用最小化方法
      windowClass.minimize((err: BusinessError) => {
        if (err) {
          console.error(`最小化窗口失败，错误码: ${err.code}, 信息: ${err.message}`);
          return;
        }
        console.info('窗口最小化成功');
      });
    }).catch((err: BusinessError) => {
      console.error(`获取窗口失败: ${err.message}`);
    });
  }

  /**
   * 打开文件
   */
  static async openFileWithSystemApp() {
    try {
      const mimeType: string =
        OpenFileWithSystemApp.getMimeType(OpenFileWithSystemApp.getFileNameFromUri(AppStorage.get('foldPath') as string));
      const want: Want = {
        action: 'ohos.want.action.view',
        uri: AppStorage.get('foldPath'),
        type: mimeType
      };
      await OpenFileWithSystemApp.context.startAbility(want);
      hilog.info(0x0000, 'FileOpener', 'System app launch request sent.');
    } catch (error) { // 修复错误1：明确指定error类型
      const err: BusinessError = error as BusinessError;
      hilog.error(0x0000, 'FileOpener', 'Failed to open file: code=%{public}d, message=%{public}s', err.code,
        err.message);
    } finally {
      OpenFileWithSystemApp.isProcessing = false;
    }
  }

  /**
   * 固定文本
   */
  static inputFixedText() {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, AppStorage.get('fixedText'));
      let systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard(); //获取系统剪贴板对象。
      // systemPasteboard.setAppShareOptions(pasteboard.ShareOption.INAPP);
      systemPasteboard.setData(pasteData)
        .then(() => {
          // console.info('文本已复制到剪贴板: ' + audioToText_res);
          if (AppStorage.get('device_isBle')) {
            (AppStorage.get('devices') as DeviceArrayType_Ble[])[AppStorage.get('device_currIndex') as number||
              0].BlueTooth_devices.send([0x20, 0x01, 0x19]) //Ctrl+V
          } else {
            ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||
              0].Communication.getDeviceInfo([0x20, 0x01, 0x19]) //Ctrl+V
          }

          setTimeout(() =>
          systemPasteboard.clearData() //清空剪贴板
            , 2000)
        })
        .catch((err: BusinessError) => {
          console.error('复制失败: ' + err.message);
        });
    } catch (error) {
      console.error('复制操作异常: ' + error.message);
    }

  }

  static async voiceInput_AICon(WebviewController: webview.WebviewController, language: string,
    voiceInput_AICon: boolean = true) {

    if (!((AppStorage.get('devices') as DeviceArrayType_Ble[]).length ?
    (AppStorage.get('devices') as DeviceArrayType_Ble[])[
    0].BlueTooth_devices.audioDataState :
    ConnectDevice.Communication[0].Communication.audioDataState)
    ) {

      if ((AppStorage.get('devices') as DeviceArrayType_Ble[]).length) {
        if (voiceInput_AICon) {
          // 显示录音提示框
          promptAction.showDialog({
            title: `${Languages.deviceRecordingPrompt[AppStorage.get('languages') as string]}`,
            message: `${Languages.hardwareRecordingNotice[AppStorage.get('languages') as string]}\n\n1. ${Languages.prohibitVoiceOperation[AppStorage.get('languages') as string]}\n2. ${Languages.prohibitLongPressButton[AppStorage.get('languages') as string]}\n3. ${Languages.operationInterruptRecording[AppStorage.get('languages') as string]}`,
            buttons: [
              {
                text: `${Languages.closeReminder[AppStorage.get('languages') as string]}`,
                color: '#FF3B30'
              }
            ]
          });
          (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.send([0x62])
            .then(() => {
              BlueTooth_devices.audioData = [];
              (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.audioDataState =
                !(AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.audioDataState
              //WebSocket  语音数据处理
              let inputMessage: inputMessageModel = {
                start: false,
                "clientId": "clientId1751968608" + new Date().toString(),
                "ptt": (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].isPunctuationRecognition ?
                  '1' :
                  '0',
                "serialNo": (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.deviceInfo.sn,
                "phrases": "",
                "format": "pcm",
                "apiKey": (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].getModelInfo?.appkey as string,
                "language": language,
                "end": false,
                "rate": (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.deviceInfo.sampleRate ?
                  "16k" : "8k",
                "deviceNo": "6c:b1:33:9f:b9:8b",
                content: ''
              }
              let audioToText: AudioWebSocketHandler_ble =
                new AudioWebSocketHandler_ble(WebSocket_serverUrl.audioToText, BlueTooth_devices.audioData, 0,
                  inputMessage, WebviewController) //语音转文字 websocket
              audioToText.connect()
            })
        }
      } else {
        if (voiceInput_AICon) {
          // 显示录音提示框
          promptAction.showDialog({
            title: `${Languages.deviceRecordingPrompt[AppStorage.get('languages') as string]}`,
            message: `${Languages.hardwareRecordingNotice[AppStorage.get('languages') as string]}\n\n1. ${Languages.prohibitVoiceOperation[AppStorage.get('languages') as string]}\n2. ${Languages.prohibitLongPressButton[AppStorage.get('languages') as string]}\n3. ${Languages.operationInterruptRecording[AppStorage.get('languages') as string]}`,
            buttons: [
              {
                text: `${Languages.closeReminder[AppStorage.get('languages') as string]}`,
                color: '#FF3B30'
              }
            ]
          });
          ConnectDevice.Communication[0].Communication.getDeviceInfo([0x62])
            .then(() => {
              Communication.audioData = []
              ConnectDevice.Communication[0].Communication.audioDataState =
                !ConnectDevice.Communication[0].Communication.audioDataState
              //WebSocket  语音数据处理
              let inputMessage: inputMessageModel = {
                start: false,
                "clientId": "clientId1751968608" + new Date().toString(),
                "ptt": ConnectDevice.Communication[0].isPunctuationRecognition ?
                  '1' :
                  '0',
                "serialNo": ConnectDevice.Communication[0].Communication.deviceInfo.sn,
                "phrases": "",
                "format": "pcm",
                "apiKey": ConnectDevice.Communication[0].getModelInfo?.appkey as string,
                "language": language,
                "end": false,
                "rate": ConnectDevice.Communication[0].Communication.deviceInfo.sampleRate ?
                  "16k" : "8k",
                "deviceNo": "6c:b1:33:9f:b9:8b",
                content: ''
              }
              let audioToText: AudioWebSocketHandler =
                new AudioWebSocketHandler(WebSocket_serverUrl.audioToText, Communication.audioData, 0,
                  inputMessage, WebviewController) //语音转文字 websocket
              audioToText.connect()
            })
        }

      }

    } else {
      if ((AppStorage.get('devices') as DeviceArrayType_Ble[]).length) {
        (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.send([0x63])
          .then(() => {
            (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.audioDataState =
              !(AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.audioDataState
            if (voiceInput_AICon) {
              _KeyMethodConfig.voiceInput_AICon(WebviewController, language)
              if (Float_Window.windowClass) {
                Float_Window.minimize_float_window()
              }
              return
            }
            //WebSocket  语音数据处理
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608" + new Date().toString(),
              "ptt": (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].isPunctuationRecognition ?
                '1' :
                '0',
              "serialNo": (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.deviceInfo.sn,
              "phrases": "",
              "format": "pcm",
              "apiKey": (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].getModelInfo?.appkey as string,
              "language": language,
              "end": false,
              "rate": (AppStorage.get('devices') as DeviceArrayType_Ble[])[0].BlueTooth_devices.deviceInfo.sampleRate ?
                "16k" : "8k",
              "deviceNo": "6c:b1:33:9f:b9:8b",
              content: ''
            }
            /**
             * 语音数据处理
             */
            // 保存本地PCM文件
            const context = AppStorage.get('context') as common.UIAbilityContext;
            new AudioFileManager(BlueTooth_devices.audioData, context, WebviewController, inputMessage)
          })
      } else {
        ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.getDeviceInfo([0x63])
          .then(() => {
            ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState =
              !ConnectDevice.Communication[AppStorage.get('device_currIndex') as number||0].Communication.audioDataState
            if (voiceInput_AICon) {
              _KeyMethodConfig.voiceInput_AICon(WebviewController, language)
              if (Float_Window.windowClass) {
                Float_Window.minimize_float_window()
              }
              return
            }
            let inputMessage: inputMessageModel = {
              start: false,
              "clientId": "clientId1751968608" + new Date().toString(),
              "ptt": ConnectDevice.Communication[0].isPunctuationRecognition ?
                '1' :
                '0',
              "serialNo": ConnectDevice.Communication[0].Communication.deviceInfo.sn,
              "phrases": "",
              "format": "pcm",
              "apiKey": ConnectDevice.Communication[0].getModelInfo?.appkey as string,
              "language": language,
              "end": false,
              "rate": ConnectDevice.Communication[0].Communication.deviceInfo.sampleRate ?
                "16k" : "8k",
              "deviceNo": "6c:b1:33:9f:b9:8b",
              content: ''
            }
            /**
             * 语音数据处理
             */
            // 保存本地PCM文件
            const context = AppStorage.get('context') as common.UIAbilityContext;
            new AudioFileManager(Communication.audioData, context, WebviewController, inputMessage)
          })
      }

    }

  }
}

interface shortcutType {
  keyPreview: string
  pressedKeys: number[]
}

interface NotificationSlot {
  "type": number,
  "notificationType": number,
  "level": number,
  "desc": string,
  "badgeFlag": boolean,
  "bypassDnd": boolean,
  "lockscreenVisibility": number,
  "vibrationEnabled": boolean,
  "sound": string,
  "lightEnabled": boolean,
  "lightColor": number,
  "vibrationValues": number[],
  "enabled": boolean,
  "authorizedStatus": number,
  "reminderMode": number
}

