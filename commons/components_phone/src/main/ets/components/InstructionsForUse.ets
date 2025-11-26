import { DeviceArrayType_Ble } from "bluetooth"
import { getModelInfoModel } from "config"
import { ConnectDevice } from "mouse"
import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { Languages_params } from "../view/SmartSettings"

@Builder
export function InstructionsForUseBuilder() {
  InstructionsForUse()
}

@Component
struct InstructionsForUse{
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'


  build() {
    NavDestination() {
      // TopTitle({ title: Languages.editProfile[this.languages] })
      TopTitle({ title:"使用说明"  })
        .margin({ bottom: 12 })


    }
    .padding({ left: 16, right: 16, bottom: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}