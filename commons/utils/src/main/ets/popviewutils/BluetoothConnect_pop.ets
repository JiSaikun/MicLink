import { Languages } from "config"
import { CursorController } from "@kit.ArkUI"
import { pointer } from "@kit.InputKit"

@Component
export struct BluetoothConnect_pop {
  @StorageLink('languages') languages: string = 'ZH_CN'
  @Link isShow_bluetoothConnect_pop: boolean
  @Prop isBluetoothConnect_state: boolean //蓝牙检索状态
  cursorCustom: CursorController = this.getUIContext().getCursorController();

  build() {
    Stack() {
      Stack() {
        Row() {
          // Text('连接设备')
          Text(Languages.connectDevice[this.languages])
            .fontSize(18)
            .fontWeight(500)
            .fontColor('#31373d')
          Blank()
          Image($r('app.media.pop_down'))
            .height(44)
            .width(44)
            .onClick(() => {
              this.isShow_bluetoothConnect_pop = false
            })
            .onHover((flag) => {
              if (flag) {
                this.cursorCustom.setCursor(pointer.PointerStyle.HAND_POINTING);
              } else {
                console.info("restoreDefault");
                this.cursorCustom.restoreDefault();
              }
            })

        }
        .border({ width: 1, color: '#f8f8f8' })
        .width(622)
        .height(64)
        .borderRadius(8)
        .padding({ left: 24, right: 24 })
        .zIndex(10)

        Column({ space: 24 }) {
          Image(this.isBluetoothConnect_state ? $r('app.media.Frame_2161') : $r('app.media.Ellipse_45'))
            .width(164)
          // Text(this.isBluetoothConnect_state?'连接成功':'正在连接设备')
          Text(this.isBluetoothConnect_state?Languages.connectSuccess[this.languages]:Languages.connectingDevice[this.languages])
            .fontSize(18)
            .fontWeight(500)
            .fontColor('#31373d')
          // Text(this.isBluetoothConnect_state?'已连接成功，可关闭弹窗。':'确认设备是否开启配对模式，并检查电脑蓝牙是否开启。')
          Text(this.isBluetoothConnect_state?Languages.connectedClosePopup[this.languages]:Languages.checkPairingAndBluetooth[this.languages])
            .fontSize(14)
            .fontWeight(400)
            .fontColor('#A4AAB2')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .shadow({ radius: 10, color: '#e9e9eb' })
        .width(622)
        .borderRadius(8)
        .backgroundColor('#fff')
        .padding(105)
      }
      .align(Alignment.TopStart)
      .backgroundColor('#fff')
      .borderRadius(8)
      .zIndex(10)


      Column() {

      }
      .width('100%')
      .height('100%')
      .backgroundColor('#000')
      .opacity(0.2)
    }
    .width('100%')
    .height('100%')

  }
}