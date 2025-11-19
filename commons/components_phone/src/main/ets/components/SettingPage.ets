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
            Toggle({ type: ToggleType.Switch, isOn: true }).onChange((value: boolean) => {
              // 处理开关逻辑
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

  getConfirmLogoutText(): string {
    switch (this.languages) {
      case 'ZH_CN': return Languages.confirmLogout.ZH_CN;
      case 'EN_US': return Languages.confirmLogout.EN_US;
      case 'ZH_TW': return Languages.confirmLogout.ZH_TW;
      case 'JA_JP': return Languages.confirmLogout.JA_JP;
      case 'VI_VN': return Languages.confirmLogout.VI_VN;
      case 'KO_KR': return Languages.confirmLogout.KO_KR;
      case 'ID_ID': return Languages.confirmLogout.ID_ID;
      case 'TH_TH': return Languages.confirmLogout.TH_TH;
      case 'FIL_PH': return Languages.confirmLogout.FIL_PH;
      case 'MAY_MAY': return Languages.confirmLogout.MAY_MAY;
      case 'RU_RU': return Languages.confirmLogout.RU_RU;
      case 'TR_TR': return Languages.confirmLogout.TR_TR;
      case 'FR_FR': return Languages.confirmLogout.FR_FR;
      case 'DE_DE': return Languages.confirmLogout.DE_DE;
      case 'IT_IT': return Languages.confirmLogout.IT_IT;
      case 'ES_ES': return Languages.confirmLogout.ES_ES;
      case 'MN_MN': return Languages.confirmLogout.MN_MN;
      case 'AR_SA': return Languages.confirmLogout.AR_SA;
      case 'KA_KA': return Languages.confirmLogout.KA_KA;
      case 'UYGUR': return Languages.confirmLogout.UYGUR;
      default: return 'Confirm logout?';
    }
  }

  getConfirmLogoutMessageText(): string {
    switch (this.languages) {
      case 'ZH_CN': return Languages.confirmLogoutMessage.ZH_CN;
      case 'EN_US': return Languages.confirmLogoutMessage.EN_US;
      case 'ZH_TW': return Languages.confirmLogoutMessage.ZH_TW;
      case 'JA_JP': return Languages.confirmLogoutMessage.JA_JP;
      case 'VI_VN': return Languages.confirmLogoutMessage.VI_VN;
      case 'KO_KR': return Languages.confirmLogoutMessage.KO_KR;
      case 'ID_ID': return Languages.confirmLogoutMessage.ID_ID;
      case 'TH_TH': return Languages.confirmLogoutMessage.TH_TH;
      case 'FIL_PH': return Languages.confirmLogoutMessage.FIL_PH;
      case 'MAY_MAY': return Languages.confirmLogoutMessage.MAY_MAY;
      case 'RU_RU': return Languages.confirmLogoutMessage.RU_RU;
      case 'TR_TR': return Languages.confirmLogoutMessage.TR_TR;
      case 'FR_FR': return Languages.confirmLogoutMessage.FR_FR;
      case 'DE_DE': return Languages.confirmLogoutMessage.DE_DE;
      case 'IT_IT': return Languages.confirmLogoutMessage.IT_IT;
      case 'ES_ES': return Languages.confirmLogoutMessage.ES_ES;
      case 'MN_MN': return Languages.confirmLogoutMessage.MN_MN;
      case 'AR_SA': return Languages.confirmLogoutMessage.AR_SA;
      case 'KA_KA': return Languages.confirmLogoutMessage.KA_KA;
      case 'UYGUR': return Languages.confirmLogoutMessage.UYGUR;
      default: return 'Do you want to log out of the current account?';
    }
  }

  getConfirmText(): string {
    switch (this.languages) {
      case 'ZH_CN': return Languages.confirm.ZH_CN;
      case 'EN_US': return Languages.confirm.EN_US;
      case 'ZH_TW': return Languages.confirm.ZH_TW;
      case 'JA_JP': return Languages.confirm.JA_JP;
      case 'VI_VN': return Languages.confirm.VI_VN;
      case 'KO_KR': return Languages.confirm.KO_KR;
      case 'ID_ID': return Languages.confirm.ID_ID;
      case 'TH_TH': return Languages.confirm.TH_TH;
      case 'FIL_PH': return Languages.confirm.FIL_PH;
      case 'MAY_MAY': return Languages.confirm.MAY_MAY;
      case 'RU_RU': return Languages.confirm.RU_RU;
      case 'TR_TR': return Languages.confirm.TR_TR;
      case 'FR_FR': return Languages.confirm.FR_FR;
      case 'DE_DE': return Languages.confirm.DE_DE;
      case 'IT_IT': return Languages.confirm.IT_IT;
      case 'ES_ES': return Languages.confirm.ES_ES;
      case 'MN_MN': return Languages.confirm.MN_MN;
      case 'AR_SA': return Languages.confirm.AR_SA;
      case 'KA_KA': return Languages.confirm.KA_KA;
      case 'UYGUR': return Languages.confirm.UYGUR;
      default: return 'Confirm';
    }
  }

  getCancelText(): string {
    switch (this.languages) {
      case 'ZH_CN': return Languages.cancel.ZH_CN;
      case 'EN_US': return Languages.cancel.EN_US;
      case 'ZH_TW': return Languages.cancel.ZH_TW;
      case 'JA_JP': return Languages.cancel.JA_JP;
      case 'VI_VN': return Languages.cancel.VI_VN;
      case 'KO_KR': return Languages.cancel.KO_KR;
      case 'ID_ID': return Languages.cancel.ID_ID;
      case 'TH_TH': return Languages.cancel.TH_TH;
      case 'FIL_PH': return Languages.cancel.FIL_PH;
      case 'MAY_MAY': return Languages.cancel.MAY_MAY;
      case 'RU_RU': return Languages.cancel.RU_RU;
      case 'TR_TR': return Languages.cancel.TR_TR;
      case 'FR_FR': return Languages.cancel.FR_FR;
      case 'DE_DE': return Languages.cancel.DE_DE;
      case 'IT_IT': return Languages.cancel.IT_IT;
      case 'ES_ES': return Languages.cancel.ES_ES;
      case 'MN_MN': return Languages.cancel.MN_MN;
      case 'AR_SA': return Languages.cancel.AR_SA;
      case 'KA_KA': return Languages.cancel.KA_KA;
      case 'UYGUR': return Languages.cancel.UYGUR;
      default: return 'Cancel';
    }
  }

  build() {
    Column() {
      Text(this.getConfirmLogoutText())
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_16)
        .fontWeight(CommonConfig.fontWeight_400)
        .margin({ bottom: 16 })
      Text(this.getConfirmLogoutMessageText())
        .fontColor(CommonConfig.hintTextColor_select)
        .fontSize(CommonConfig.fontSize_14)
        .fontWeight(CommonConfig.fontWeight_400)
        .margin({ bottom: 16 })
      Text(this.getConfirmText())
        .backgroundColor('#EAEAEA')
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
      Text(this.getCancelText())
        .backgroundColor('#EAEAEA')
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
    .borderRadius(16)
    .padding(16)
  }
}