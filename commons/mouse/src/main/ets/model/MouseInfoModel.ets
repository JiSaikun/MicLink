import { BaseParams } from 'api'

/**
 * 注册登录
 */
export interface getModelInfo_Params extends BaseParams {
  sno: string //设备号
  productCode: string //产品编码
  languageCode: string //密码
}
