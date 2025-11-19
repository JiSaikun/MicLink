import { CommonConfig } from "../common/CommonConfig"
import { TopTitle } from "../common/TopTitle"

@Builder
export function PersonalProfileBuilder() {
  PersonalProfile()
}

@Component
struct PersonalProfile {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'

  build() {
    NavDestination() {
      TopTitle({ title: '编辑个人资料' })
        .margin({ bottom: 12 })
    }
    .padding(16)
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}