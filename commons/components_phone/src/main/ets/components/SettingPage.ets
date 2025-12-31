import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"

@Builder
export function SettingPageBuilder() {
  SettingPage()
}

@Component
struct SettingPage {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @StorageLink('Backgrounding') Backgrounding: boolean = false//手机专属标记
  dialogController: CustomDialogController | null = new CustomDialogController({
    builder: LogOut({
      cancel: () => {
        this.onCancel();
      },
      confirm: () => {
        this.onAccept();
      }
    }),
    cancel: this.exitApp,
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -20 },
    gridCount: 4,
    customStyle: false,
    cornerRadius: 16
  })

  onCancel() {
    console.info('单击第一个按钮时回调');
    this.pageInfo.pushPath({ "name": 'login&phone' })
    AppStorage.setOrCreate('login', false)
    AppStorage.setOrCreate('userLoginInfo', null)
  }

  onAccept() {
    console.info('点击第二个按钮时回调');
  }

  // 在自定义组件即将析构销毁时将dialogController置空
  aboutToDisappear() {
    this.dialogController = null; // 将dialogController置空
  }

  exitApp() {
    console.info('单击空白区域中的回拨');
  }






  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        TopTitle({ title: Languages.setting[this.languages] })
          .margin({ bottom: 12 })
        Column() {
          Row() {
            Text(Languages.colorTheme[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Image($r('app.media.Arrow_to_the_right'))
              .width(16)
              .height(16)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.pageInfo.pushPath({ "name": 'ColorTheme' })
          })

          Row() {
            Text(Languages.interfaceLanguage[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Image($r('app.media.Arrow_to_the_right'))
              .width(16)
              .height(16)
          }
          .border({ width: { top: 1, bottom: 1 }, color: CommonConfig.commonBackgroundColor })
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
          .onClick(() => {
            this.pageInfo.pushPath({ "name": 'InterfaceLanguage' })
          })

          Row() {
            Text(Languages.keepRunningInBackground[this.languages])
              .fontSize(CommonConfig.fontSize_14)
              .fontColor(CommonConfig.hintTextColor_select)
              .fontWeight(CommonConfig.fontWeight_400)
            Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.Backgrounding }).onChange((value: boolean) => {
              // 处理开关逻辑
              this.Backgrounding=value
            })
              .selectedColor(this.paletteTheme)
              .height(22)
              .width(44)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ top: 12, bottom: 12 })
        }
        .padding({ left: 12, right: 12 })
        .borderRadius(12)
        .backgroundColor(Color.White)

        Blank()
        Row() {
          Text(Languages.logout[this.languages])
            .fontSize(CommonConfig.fontSize_14)
            .fontWeight(CommonConfig.fontWeight_400)
            .fontColor('#FF3B30')
            .width('100%')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              if (this.dialogController != null) {
                this.dialogController.open();
              }
            })
        }
        .padding({ top: 12, bottom: 12 })
        .borderRadius(8)
        .backgroundColor(Color.White)
        .width('100%')
      }
      .width('100%')
      .height('100%')
    }
    .padding(16)
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}
@CustomDialog
@Component
struct LogOut {
  // 若尝试在CustomDialog中传入多个其他的Controller，以实现在CustomDialog中打开另一个或另一些CustomDialog，那么此处需要将指向自己的controller放在所有controller的后面
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }
  controller?: CustomDialogController;
  @StorageLink('languages') languages: string = 'ZH_CN'

  build() {
    Column() {
      Text(Languages.confirmLogout[this.languages])
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_16)
        .fontWeight(CommonConfig.fontWeight_400)
        .margin({ bottom: 16 })
      Text(Languages.confirmLogoutMessage[this.languages])
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_14)
        .fontWeight(CommonConfig.fontWeight_400)
        .margin({ bottom: 16 })
      Text(Languages.confirm[this.languages])
        .backgroundColor(Color.White)
        .fontSize(CommonConfig.fontSize_16)
        .fontColor('#FF0509')
        .fontWeight(CommonConfig.fontWeight_400)
        .width('100%')
        .borderRadius(8)
        .textAlign(TextAlign.Center)
        .padding(12)
        .margin({ bottom: 8 })
        .onClick(() => {
          this.cancel()
          this.controller?.close()
        })
      Text(Languages.cancel[this.languages])
        .backgroundColor(Color.White)
        .fontSize(CommonConfig.fontSize_16)
        .fontColor(CommonConfig.hintTextColor_select)
        .fontWeight(CommonConfig.fontWeight_400)
        .width('100%')
        .borderRadius(8)
        .textAlign(TextAlign.Center)
        .padding(12)
        .onClick(()=> this.controller?.close())

    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(CommonConfig.commonBorderColor)
    .borderRadius({topLeft:16,topRight:16})
    .padding(16)
  }
}