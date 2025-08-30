import {LeftBar,Topbar,Content,paramModel} from 'common'
PersistentStorage.persistProp("login", false)
@Builder function IndexPageBuilder(){
  IndexPage()
}
@Component
struct IndexPage {
  @StorageLink("login") login: boolean = true
  @Consume('pageInfo') pageInfo:NavPathStack
  @State web: string = 'https://asrai.miclink.net/'
  @State currentIndex: number = 0
  @State bottomCurrIndex: number = 10000
  @State extend:boolean=true //状态栏延申
  @State width_length:number=248
  aboutToAppear(): void {
    if (!this.login) {
      this.pageInfo.pushPath({'name':'login'})
    }
    // console.log('=================================进入测试机')
    // console.log('+',JSON.stringify(this.pageInfo.getParamByName("indexPage")))
    this.web=(this.pageInfo.getParamByName("indexPage")[0] as paramModel).web
    this.currentIndex=(this.pageInfo.getParamByName("indexPage")[0] as paramModel).currentIndex
    this.bottomCurrIndex=(this.pageInfo.getParamByName("indexPage")[0] as paramModel).bottomCurrIndex
    this.extend=(this.pageInfo.getParamByName("indexPage")[0] as paramModel).extend
    this.width_length=(this.pageInfo.getParamByName("indexPage")[0] as paramModel).width_length
    // console.log(JSON.stringify(this.pageInfo.getParamByName("indexPage")[0]))
  }
  build() {
    Column(){
        NavDestination(){
        Row(){
          LeftBar({currentIndex:this.currentIndex,web:this.web,bottomCurrIndex:this.bottomCurrIndex,extend:this.extend
          ,width_length:this.width_length})
          Stack(){
            Topbar()
              .zIndex(100)
            Content({web:this.web})
          }
          // .border({width:1})
          .align(Alignment.TopStart)
          .height('100%')
          .layoutWeight(1)
        }
        // .backgroundColor(Color.Blue)
        .width('100%')
        .height('100%')
      }
      .hideToolBar(true)
      .hideTitleBar(true)

    }




  }
}