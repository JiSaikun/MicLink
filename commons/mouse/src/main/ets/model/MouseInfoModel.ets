import { BaseParams } from 'api'

/**
 * 获取用户按键模式详情
 */
export interface getModelInfo_Params extends BaseParams {
  sno: string //设备号
  productCode: string //产品编码
  languageCode: string
}

/**
 * 文本翻译
 */
export interface translate_Params extends BaseParams {
  appkey: string //获取用户按键模式详情中得到
  from: string //源语言
  productCode: string //产品编码
  sno: string //设备号
  text: string //翻译内容
  to: string //翻译语言
}

export interface translate_Response {
  transText:string
  text:string
}