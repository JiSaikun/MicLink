import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
import { TopTitle } from "../common/TopTitle"
import { LengthMetrics } from "@kit.ArkUI"

@Builder
export function SoundSettingBuilder() {
  SoundSetting()
}


@Component
struct SoundSetting {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        TopTitle({ title: '音色设置', isback: false })

      }.height('100%')

    }
    .padding({ left: 16, right: 16 })
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .backgroundImage($r('app.media.background_1'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}