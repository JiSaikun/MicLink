import { promptAction, screenshot } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { _ocr } from '../viewmodel/UserViewModel';
import { ocr_Params } from '../model/UserModel';


// 手动实现base64编码
function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  const base64Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  let result = '';
  let i = 0;

  while (i < bytes.length) {
    const byte1 = bytes[i];
    const byte2 = i + 1 < bytes.length ? bytes[i + 1] : 0;
    const byte3 = i + 2 < bytes.length ? bytes[i + 2] : 0;

    // 将3个字节转换为4个6位值
    const char1 = byte1 >> 2;
    const char2 = ((byte1 & 3) << 4) | (byte2 >> 4);
    const char3 = ((byte2 & 15) << 2) | (byte3 >> 6);
    const char4 = byte3 & 63;

    // 使用字符串方法而不是索引访问
    result += getBase64Char(base64Chars, char1) +
    getBase64Char(base64Chars, char2) +
      (i + 1 < bytes.length ? getBase64Char(base64Chars, char3) : '=') +
      (i + 2 < bytes.length ? getBase64Char(base64Chars, char4) : '=');

    i += 3;
  }

  return result;
}

// 辅助函数：安全获取base64字符
function getBase64Char(base64Chars: string, index: number): string {
  return base64Chars.substring(index, index + 1);
}

//获取已配对的蓝牙连接列表


@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State permissions: Array<Permissions> = ['ohos.permission.CUSTOM_SCREEN_CAPTURE'];

  getPairedDevices() {
    let captureOption: screenshot.CaptureOption = {
      "displayId": 0
    };
    try {
      let promise = screenshot.capture(captureOption);
      promise.then((pixelMap: image.PixelMap) => {
        console.info('Succeeded in saving screenshot. Pixel bytes number: ' + pixelMap.getPixelBytesNumber());
        const readBuffer: ArrayBuffer = new ArrayBuffer(pixelMap.getPixelBytesNumber())
        if (pixelMap != undefined) {
          pixelMap.readPixelsToBuffer(readBuffer, (error: BusinessError, res: void) => {
            if (error) {
              console.error(`Failed to read image pixel data. code is ${error.code}, message is ${error.message}`); // 不符合条件则进入。
              return;
            } else {
              console.info('Succeeded in reading image pixel data.'); // 符合条件则进入。
              console.error('截图结果', readBuffer.byteLength)

              // 将readBuffer转换为base64字符串
              this.message = arrayBufferToBase64(readBuffer);
              console.info('Base64 content:', this.message);
              let params: ocr_Params = {
                content: this.message,
                language: "ZH_CN"
              }
              _ocr(params).then((res) => {
                console.log('数据响应：', JSON.stringify(res))
              }).catch(()=>{
                console.log('请求失败：', JSON.stringify(res))
              })

            }
          })
        }
        // pixelMap.release(); // PixelMap使用完后及时释放内存
      }).catch((err: BusinessError) => {
        console.error(`Failed to save screenshot1. Code: ${err.code}, message: ${err.message}`);
      });
    } catch (exception) {
      console.error(`Failed to save screenshot. Code: ${exception.code}, message: ${exception.message}`);
    }
    ;
  }

  // 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
  reqPermissionsFromUser(permissions: Array<Permissions>, context: common.UIAbilityContext): void {
    let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗。
    atManager.requestPermissionsFromUser(context, permissions).then((data) => {
      let grantStatus: Array<number> = data.authResults;
      let length: number = grantStatus.length;
      for (let i = 0; i < length; i++) {
        if (grantStatus[i] === 0) {
          // 用户授权，可以继续访问目标操作。
          this.getPairedDevices()
        } else {
          // 当用户拒绝授权时，系统应提示用户必须授予相应权限才能使用当前页面的功能，并指导用户前往系统设置开启所需权限。
          promptAction.showToast({ message: '请打开蓝牙设备获取权限', duration: 2000 })
          return;
        }
      }
      // 授权成功
    }).catch((err: BusinessError) => {
      console.error(`Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
    })
  }

  build() {
    Scroll() {
      Column() {
        TextArea({ text: this.message })
          .id('HelloWorld')
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
        Button('ajsdbkjsakldjklasjkld')
          .onClick(() => {
            // 使用UIExtensionAbility：将common.UIAbilityContext 替换为common.UIExtensionContext
            const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
            this.reqPermissionsFromUser(this.permissions, context);
          })
      }

    }
    .align(Alignment.TopStart)
    .height('100%')
    .width('100%')
  }
}