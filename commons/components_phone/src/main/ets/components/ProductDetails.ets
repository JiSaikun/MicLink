import { CommonConfig } from "../common/CommonConfig"
import { Languages } from "../common/Languages"
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

  aboutToAppear(): void {
    this.productName = this.pageInfo.getParamByName('ProductDetails')[0] as string
  }

  build() {
    NavDestination() {
      Column() {
        TopTitle({ title: Languages.membershipPackage[this.languages],isback:false })
          .margin({ bottom: 12 })
      }
      .width('100%')
      .height('100%')

    }
    .padding({left:16,right:16})
    .backgroundColor(CommonConfig.commonBackgroundColor)
    .backgroundImage($r('app.media.background_1'))
    .backgroundImageSize({ width: '100%', height: '100%' })
    .hideTitleBar(true)
    .hideToolBar(true)
  }
}