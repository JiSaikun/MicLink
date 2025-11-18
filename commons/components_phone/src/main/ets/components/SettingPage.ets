import { CommonConfig } from "../common/CommonConfig"
import { TopTitle } from "../common/TopTitle"

@Builder
export function SettingPageBuilder() {
  SettingPage()
}

@Component
struct SettingPage {
  build() {
    NavDestination() {
      Flex({ direction: FlexDirection.Column }) {
        TopTitle({ title: '设置' })
      }
      .width('100%')
    }
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}