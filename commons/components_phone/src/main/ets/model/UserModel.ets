import { BaseParams } from 'api'

/**
 * 获取用户按键模式详情
 */
export interface addCustomerKey_Params extends BaseParams {
  cmdId: string //指令ID
  keyId: string //按键ID
  opId: string //操作ID
  sno: string //设备号
  userModelId: string //按鍵模式ID
}

/**
 * 获取用户按键模式详情
 */
export interface addCustomerKey_Response extends BaseParams {
  // cmdId: string //指令ID
  // keyId: string //按键ID
  // opId: string //操作ID
  // sno: string //设备号
  // userModelId: string //按鍵模式ID
}
/**
 * 重置按键设置
 */
export interface resetCustomerKey_Params extends BaseParams {
  sno: string //设备号
  userModelId: string //按鍵模式ID
}
export interface resetCustomerKey_Response extends BaseParams {
  // cmdId: string //指令ID
  // keyId: string //按键ID
  // opId: string //操作ID
  // sno: string //设备号
  // userModelId: string //按鍵模式ID
}

export interface feedbackAdd_Params {
  channalName?: string, //渠道名称
  content?: string //问题描述
  memberId?: number //用户ID
  phone?: string //联系方式
  productName?: string //产品名称
  serialNo?: string //设备序列号
  title?: string //标题
}
export interface feedbackAddy_Response {

}
