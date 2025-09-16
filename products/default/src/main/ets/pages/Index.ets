import { fileIo, WriteOptions } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  aboutToAppear(): void {
    let context = getContext(this); // 沙箱路径
    let filePath = context.filesDir + '/test.txt';
    let file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE);
    let arrayBuffer = new ArrayBuffer(4096);
    fileIo.read(file.fd, arrayBuffer).then((readLen: number) => {
      console.info(readLen.toString());
      let str: string = 'hello, world';
      let options: WriteOptions = { offset: readLen };
      let writeLen = fileIo.writeSync(file.fd, str, options);
      console.info('write data to file succeed and size is:' + writeLen);
    }).catch((err: BusinessError) => {
      console.error('read file data failed with error message: ' + err.message + ', error code: ' + err.code);
    }).finally(() => {
      fileIo.closeSync(file);
    });
  }

  build() {
    RelativeContainer() {
      Text(this.message)
        .id('WriteHelloWorld')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
    }
    .height('100%')
    .width('100%')
  }
}