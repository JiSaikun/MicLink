@Component
export struct  Topbar {
  @State isDown:boolean=false
  @Consume('pageInfo') pageInfo:NavPathStack
  @Styles textStyle(){
  .height(40)
  }
  build() {
      Row(){
        RelativeContainer(){
          Row(){
            Image($r('app.media.avatar'))
              .width(32)
              .margin({right:10})
            Text('迷人的Justin')
              .fontSize(14)
              .fontWeight(400)
              .lineHeight(14)
              .fontColor('#31373d')
            Image($r('app.media.downward_arrow'))
              .width(16)
              .rotate({
                angle:this.isDown?180:0,
                centerZ:180
              })
          }
          .alignRules({
            middle: { anchor: '__container__', align: HorizontalAlign.Center },
            center: { anchor: '__container__', align: VerticalAlign.Center },
          })
          .onClick(()=>{
            this.isDown=!this.isDown
          })
          Column(){
            Text('个人中心')
              .textStyle()
            Text('修改密码')
              .textStyle()
            Divider()
              .width('100%')
              .height(1)
            Text('退出登录')
              .textStyle()
              .onClick(()=>{
                AppStorage.setOrCreate("login",false)
                this.pageInfo.pushPath({"name":'login'})
              })
          }
          .visibility(this.isDown?Visibility.Visible:Visibility.None)
          .width('100%')
          .height(130)
          .backgroundColor('#fff')
          .shadow({radius:10,color:'#e9e9eb'})
          // .backgroundColor(Color.Red)
          .borderRadius(4)
          .alignRules({
            middle: { anchor: '__container__', align: HorizontalAlign.Center },
            top: { anchor: '__container__', align: VerticalAlign.Bottom },
          })
        }
        .width(142)
        .margin({right:20})
        // Image($r('app.media.Frame_11'))
        //   .width(44)
        // Image($r('app.media.Frame_10'))
        //   .width(44)
        // Image($r('app.media.Frame_12'))
        //   .width(44)
        //   .margin({right:10})
      }
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Center)
      // .backgroundColor(Color.Blue)
      .height(64)
      .width('100%')
      .border({width:{bottom:2},color:'#f8f8f8'})
  }
}