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
  cmdId: string //指令ID
  keyId: string //按键ID
  opId: string //操作ID
  sno: string //设备号
  userModelId: string //按鍵模式ID
}