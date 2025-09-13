import { Communication, DeviceInfo, MouseICType } from 'mouse'
import { LengthMetrics } from '@kit.ArkUI'
PersistentStorage.persistProp("lowPowerAlertEnabled", true)
/**
 * 设备设置
 */
@Component
export struct ConfigPage3 {
  @StorageLink("mouseconfig") mouseconfig: DeviceInfo | null = null //鼠标信息
  @StorageLink("lowPowerAlertEnabled") lowPowerAlertEnabled: boolean = true //是否开启低电量提醒
  @State reportRate: SelectOption[] = [{ value: '125' }, { value: '250' }, { value: '500' }, { value: '1000' }]
  @Prop currportRate: number
  @Watch('change_LEDstate')@State currLED: boolean = true
  @Watch('change_reportRate') @State reportRate_currIndex: number = 0
  @State DPI_currIndex: number = 0

  // @Link pageshow:boolean
  change_reportRate() {
    // Communication.changPhysicalKeyboardExistState(false)
    setTimeout(() => {
      Communication.getDeviceInfo([0x13, this.reportRate_currIndex])
    }, 50)

    // switch (this.reportRate_currIndex) {
    //   case 0:
    //     Communication.getDeviceInfo([0x13, 0x00])
    //     break;
    //   case 1:
    //     Communication.getDeviceInfo([0x13, 0x01])
    //     break;
    //   case 2:
    //     Communication.getDeviceInfo([0x13, 0x02])
    //     break;
    //   case 3:
    //     Communication.getDeviceInfo([0x13, 0x03])
    //     break;
    // }

    // if (this.reportRate_currIndex === 1) {
    //   Communication.getDeviceInfo([0x13, 0x01])
    // }
    // if (this.reportRate_currIndex === 2) {
    //   Communication.getDeviceInfo([0x13, 0x02])
    // }
    // if (this.reportRate_currIndex === 3) {
    //   Communication.getDeviceInfo([0x13, 0x03])
    // }
  }
  change_LEDstate(){
    setTimeout(()=>{
      if (this.currLED){
        Communication.getDeviceInfo([0x83])
      }else {
        Communication.getDeviceInfo([0x84])
      }
    },50)
  }
  build() {
    Flex({ space: { main: LengthMetrics.px(15) }, direction: FlexDirection.Column }) {
      Text("DPI")
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      Select(this.reportRate)
        .value(this.currportRate.toString())
        .onSelect((index: number) => {
          this.DPI_currIndex = index
        })
        .selected(0)
        .width('100%')
        .font({ size: $r('app.float.default_text_font_size_14'), weight: 400 })
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        .borderRadius(4)
        .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
        .backgroundColor(Color.White)
      // Select()
      Text("回报率")
        .fontSize($r('app.float.default_text_font_size_14'))
        .fontWeight(400)
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
      Select(this.reportRate)
        .value(this.currportRate.toString())
        .onSelect((index: number) => {
          this.reportRate_currIndex = index
        })
        .selected(0)
        .width('100%')
        .font({ size: $r('app.float.default_text_font_size_14'), weight: 400 })
        .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        .borderRadius(4)
        .border({ width: 1, color: $r('app.string.DEFAULT_BORDER_COLOR') })
        .backgroundColor(Color.White)

      Row() {
        Text("LED灯效")
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Blank()
        Row() {
          Radio({
            value: 'Radio2', group: 'radioGroup',
            indicatorType: RadioIndicatorType.DOT
          }).checked(this.currLED)
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************打开氛围灯****************************************')
                  this.currLED=true
              }
            })
          Text("开启")
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.currLED = true
        })

        Row() {
          Radio({
            value: 'Radio2', group: 'radioGroup',
            indicatorType: RadioIndicatorType.DOT
          }).checked(!this.currLED)
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************关闭氛围灯****************************************')
                  this.currLED=false

              }
            })
          Text("关闭")
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(() => {
          this.currLED = false
        })
      }
      .width('100%')

      Row() {
        Text("低电量提醒")
          .fontSize($r('app.float.default_text_font_size_14'))
          .fontWeight(400)
          .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        Blank()
        Row() {
          Radio({
            value: 'Radio2', group: 'lowPowerAlertEnabled',
            indicatorType: RadioIndicatorType.DOT
          }).checked(this.lowPowerAlertEnabled)
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************打开低电量提醒****************************************')

              }
            })
          Text("开启")
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(()=>{
          this.lowPowerAlertEnabled=true
        })

        Row() {
          Radio({
            value: 'Radio2', group: 'lowPowerAlertEnabled',
            indicatorType: RadioIndicatorType.DOT
          }).checked(!this.lowPowerAlertEnabled)
            .height(14)
            .width(14)
            .onChange((isChecked: boolean) => {
              if (isChecked) {
                console.log('*****************************关闭低电量提醒****************************************')
              }
            })
          Text("关闭")
            .fontSize($r('app.float.default_text_font_size_14'))
            .fontWeight(400)
            .fontColor($r('app.string.DEFAULT_FONT_COLOR'))
        }
        .onClick(()=>{
          this.lowPowerAlertEnabled=false
        })

      }
      .width('100%')


    }
    .width('100%')
  }
}