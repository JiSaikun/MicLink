import { CommonConfig } from "../common/CommonConfig"
import { TopTitle } from "../common/TopTitle"

@Builder
export function ProductDetailsBuilder() {
  ProductDetails()
}

@Component
struct ProductDetails {
  @StorageLink("paletteTheme") paletteTheme: string = CommonConfig.PaletteTheme
  @Consume('pageInfo') pageInfo: NavPathStack
  @StorageLink('languages') languages: string = 'ZH_CN'
  @State productName: string = ''

  build() {
    NavDestination() {
      TopTitle({ title: '会员套餐' })
        .margin({ bottom: 12 })
    }
    .padding(16)
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}