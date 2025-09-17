import { LeftBar, Topbar, Content, paramModel } from 'common'
import Content_Ai from 'command_ai/src/main/ets/components/Command_Ai'
import {DeviceSettings} from '../components/DeviceSettings'
import {CreateNewInstruction_pop}from 'command_ai/src/main/ets/components/CreateNewInstruction_pop'

// PersistentStorage.persistProp("login", false)

@Builder
function IndexPageBuilder() {
  IndexPage()
}

@Component
struct IndexPage {
  @StorageLink("login") login: boolean = true
  @Consume('pageInfo') pageInfo: NavPathStack
  @State web: string = 'https://asrai.miclink.net/'
  @State currentIndex: number = 0
  @State bottomCurrIndex: number = 10000
  @State extend: boolean = true //状态栏延申
  @State width_length: number = 248
  @State isShow_CreateNewInstruction_pop: boolean = false
  @State isShow_EditInstruction_pop: boolean = false
  @State EditInstruction_pop_currIndex:number=0
  aboutToAppear(): void {
    if (!this.login) {
      this.pageInfo.pushPath({ 'name': 'login' })
    }
    // console.log('=================================进入测试机')
    // console.log('+',JSON.stringify(this.pageInfo.getParamByName("indexPage")))
    this.web = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).web
    this.currentIndex = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).currentIndex
    this.bottomCurrIndex = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).bottomCurrIndex
    this.extend = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).extend
    this.width_length = (this.pageInfo.getParamByName("indexPage")[0] as paramModel).width_length
    // console.log(JSON.stringify(this.pageInfo.getParamByName("indexPage")[0]))
  }

  build() {
      Column() {
        NavDestination() {
          Stack(){
            Row() {
              LeftBar({
                currentIndex: this.currentIndex,
                web: this.web,
                bottomCurrIndex: this.bottomCurrIndex,
                extend: this.extend
              ,
                width_length: this.width_length
              })
              Stack() {
                Topbar()
                  .zIndex(100)
                if (this.web) {
                  if (this.web === 'Command_Ai') {
                    Content_Ai({isShow_CreateNewInstruction_pop:this.isShow_CreateNewInstruction_pop,isShow_EditInstruction_pop:this.isShow_EditInstruction_pop,EditInstruction_pop_currIndex:this.EditInstruction_pop_currIndex}) //AI--指令
                  } else if (this.web === 'DeviceSettings') {
                    /*
                      设备设置
                     */
                    DeviceSettings()
                  } else {
                    Content({ web: this.web })
                  }
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
            if (this.isShow_CreateNewInstruction_pop){
              CreateNewInstruction_pop({isShow_CreateNewInstruction_pop:this.isShow_CreateNewInstruction_pop,isShow_EditInstruction_pop:this.isShow_EditInstruction_pop})
            }
            if (this.isShow_EditInstruction_pop){
              CreateNewInstruction_pop({isShow_CreateNewInstruction_pop:this.isShow_CreateNewInstruction_pop,isShow_EditInstruction_pop:this.isShow_EditInstruction_pop,isParam:true,currIndexParam:this.EditInstruction_pop_currIndex})
            }

          }
          .width('100%')
          .height('100%')

        }
        .hideToolBar(true)
        .hideTitleBar(true)

      }


  }
}