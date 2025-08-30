import {LeftBar,Topbar,Content} from 'common'
PersistentStorage.persistProp("login", false)
@Entry
@Component
struct Index {
  @StorageLink("login") login: boolean = true
  @Provide('pageInfo') pageInfo:NavPathStack=new NavPathStack()
  @State web: string = 'https://asrai.miclink.net/?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/temLibrary'
  aboutToAppear(): void {
    this.pageInfo.disableAnimation(true)
    // console.log(JSON.stringify(this.login))
    if (!this.login) {
      this.pageInfo.pushPath({'name':'login'})
    }
  }

  build() {
    Column(){
        Navigation(this.pageInfo){
        Row(){
          LeftBar({web:this.web})
          Stack(){
            Topbar()
              .zIndex(100)
            if (this.web){
              Content({web:this.web})
            }else {

            }
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
      .mode(NavigationMode.Stack)

    }




  }
}