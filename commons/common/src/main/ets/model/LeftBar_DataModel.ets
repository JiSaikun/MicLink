export interface Ai_Model{
  img:string,
  title:string,
  select:string,
  web:string
}

export const AiModel_data:Ai_Model[]=[
  {
    img:'assistant',title:'AI-助手',select:'select_assistant',
    web:'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452'
  },{
    img:'office',title:'AI-办公',select:'select_office',
    web:'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/aiOffice'
  },{
    img:'agent',title:'AI-智能体',select:'select_agent',
    web:'https://asrai.miclink.net/?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/aiAgent'
  },{
    img:'command',title:'AI-指令',select:'select_command',
    web:''
  },{
    img:'navigation',title:'导航库',select:'select_navigation',
    web:'https://asrai.miclink.net?sno=123123123&productCode=999999&config=configMiclink_B_1755079145452#/navLibrary'
  },{
    img:'video',title:'视频库',select:'select_video',
    web:'https://asrai.miclink.net?sno=123123123&productCode=999999&config=configMiclink_B_1755079145452#/videoGallery'
  },{
    img:'template',title:'模板库',select:'select_template',
    web:'https://asrai.miclink.net/?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/temLibrary'
  }
]
export const bottom_data:Ai_Model[]=[
  {
    img:'deviceSettings',title:'设备设置',select:'select_deviceSettings',
    web:''
  },{
    img:'enterpriseCentre',title:'企业中心',select:'select_enterpriseCentre',
    web:'https://www.miclink.info/'
  },{
    img:'helpCenter',title:'帮助中心',select:'select_helpCenter',
    web:'https://asrai.miclink.net?sno=123123123&productCode=999999&config=configMiclink_B_1755079145452#/helpCenter'
  }
]