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
    web:''
  },{
    img:'office',title:Languages.ai_office,select:'select_office',
    web:'#/aiOffice'
  },{
    img:'agent',title:Languages.ai_agent,select:'select_agent',
    web:'#/aiAgent'
  },{
    img:'command',title:Languages.ai_command,select:'select_command',
    web:'Command_Ai'
  },{
    img:'navigation',title:Languages.navigation,select:'select_navigation',
    web:'#/navLibrary'
  },{
    img:'video',title:Languages.video,select:'select_video',
    web:'#/videoGallery'
  },{
    img:'template',title:Languages.template,select:'select_template',
    web:'#/temLibrary'
  }
]
export const bottom_data:Ai_Model[]=[
  {
    img:'deviceSettings',title:Languages.deviceSettings,select:'select_deviceSettings',
    web:'DeviceSettings'
  },{
    img:'enterpriseCentre',title:Languages.enterpriseCentre,select:'select_enterpriseCentre',
    web:''
  },{
    img:'helpCenter',title:Languages.helpCenter,select:'select_helpCenter',
    web:'#/helpCenter'
  }
]