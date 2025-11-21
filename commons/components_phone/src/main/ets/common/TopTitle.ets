import { CommonConfig } from "./CommonConfig";

@Component
export struct TopTitle {
  @Consume('pageInfo') pageInfo: NavPathStack
  @Prop title: string = ''
  @Prop isback: boolean = true

  build() {
    Row() {
      Image($r('app.media.page_back_icon'))
        .width(32)
        .height(32)
        .onClick(() => {
          this.pageInfo.pop()
        })
      Text(this.title)
        .fontWeight(CommonConfig.fontWeight_700)
        .fontSize(CommonConfig.fontSize_16)
        .fontColor(CommonConfig.hintTextColor_select)

      Image('')
        .width(32)
        .height(32)
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .backgroundColor(this.isback?CommonConfig.commonBackgroundColor:'')
  }
}