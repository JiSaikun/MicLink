import {Languages,LanguageNames}from 'config'
export interface Ai_Model{
  img:string,
  title:LanguageNames,
  select:string,
  web:string
}

export const AiModel_data:Ai_Model[]=[
  {
    img:'assistant',title:Languages.ai_assistant,select:'select_assistant',
    web:'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452'
  },{
    img:'office',title:Languages.ai_office,select:'select_office',
    web:'https://asrai.miclink.net?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/aiOffice'
  },{
    img:'agent',title:Languages.ai_agent,select:'select_agent',
    web:'https://asrai.miclink.net/?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/aiAgent'
  },{
    img:'command',title:Languages.ai_command,select:'select_command',
    web:'Command_Ai'
  },{
    img:'navigation',title:Languages.navigation,select:'select_navigation',
    web:'https://asrai.miclink.net?sno=123123123&productCode=999999&config=configMiclink_B_1755079145452#/navLibrary'
  },{
    img:'video',title:Languages.video,select:'select_video',
    web:'https://asrai.miclink.net?sno=123123123&productCode=999999&config=configMiclink_B_1755079145452#/videoGallery'
  },{
    img:'template',title:Languages.template,select:'select_template',
    web:'https://asrai.miclink.net/?sno=123&productCode=999999&config=configMiclink_B_1755079145452#/temLibrary'
  }
]
export const bottom_data:Ai_Model[]=[
  {
    img:'deviceSettings',title:Languages.deviceSettings,select:'select_deviceSettings',
    web:'DeviceSettings'
  },{
    img:'enterpriseCentre',title:Languages.enterpriseCentre,select:'select_enterpriseCentre',
    web:'https://www.miclink.info/'
  },{
    img:'helpCenter',title:Languages.helpCenter,select:'select_helpCenter',
    web:'https://asrai.miclink.net?sno=123123123&productCode=999999&config=configMiclink_B_1755079145452#/helpCenter'
  }
]