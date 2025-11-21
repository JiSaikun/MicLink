import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"
import { UserLoginInfo } from "common"
import { UpdatePhone_PHONE } from "./UpdatePhone_PHONE"
import { UpdatePhone_EMAIL } from "./UpdatePhone_EMAIL"

@Builder
export function UpdatePhoneBuilder() {
  UpdatePhone()
}


@Component
struct UpdatePhone {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State userLoginInfo: UserLoginInfo = AppStorage.get('userLoginInfo') as UserLoginInfo
  @State isEMAIL: boolean = false

  aboutToAppear(): void {
    if (this.userLoginInfo?.type === 'EMAIL') {
      this.isEMAIL = true
    }
  }

  build() {
    NavDestination() {
      TopTitle({ title: '', isback: false })
      Stack() {
        UpdatePhone_EMAIL()
          .margin({ top: 76 })

        if (!this.isEMAIL) { //手机号
          UpdatePhone_PHONE({isEMAIL:this.isEMAIL})
        }
      }
      .align(Alignment.TopStart)
      .width('100%')
      .layoutWeight(1)

    }
    .padding({ left:16,right:16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}