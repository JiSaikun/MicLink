// import { hilog } from '@kit.PerformanceAnalysisKit';
// import testNapi from 'libhid_usb.so'; // 注意这里的库名，去掉lib前缀和.so后缀
//
// const DOMAIN = 0x0000;
//
// @Entry
// @Component
// struct Index {
//   @State message: string = 'Hello World';
//   @State deviceInfo: string = '';
//
//   build() {
//     Row() {
//       Column() {
//         Text(this.message)
//           .fontSize(30)
//           .fontWeight(FontWeight.Bold)
//           .onClick(() => {
//             this.connectDevice();
//           })
//
//         Text(this.deviceInfo)
//           .fontSize(16)
//           .margin({ top: 20 })
//           .width('90%')
//           .textAlign(TextAlign.Start)
//       }
//       .width('100%')
//     }
//     .height('100%')
//   }
//
//   // 封装设备连接逻辑，添加错误处理
//   connectDevice() {
//     // 先检查testNapi是否加载成功
//     if (typeof testNapi === 'undefined') {
//       this.message = 'Failed to load native module';
//       this.deviceInfo = 'Native module "hid_usb" is undefined';
//       hilog.error(DOMAIN, 'testTag', 'Native module is undefined');
//       return;
//     }
//
//     try {
//       this.message = 'Connecting...';
//       // 调用原生方法前先检查是否存在
//       if (typeof testNapi.initddk !== 'function') {
//         throw new Error('initddk method not found in native module');
//       }
//
//       // 尝试调用initddk方法
//       const result = testNapi.initddk(110, 200);
//       this.message = result.success ? 'Connected' : 'Connection failed';
//       this.deviceInfo = JSON.stringify(result, null, 2);
//       hilog.info(DOMAIN, 'testTag', 'initddk result: %{public}s', JSON.stringify(result));
//     } catch (e) {
//       this.message = 'Error occurred';
//       this.deviceInfo = `Error: ${e.message}`;
//       hilog.error(DOMAIN, 'testTag', 'Error: %{public}s', e.message);
//     }
//   }
// }
