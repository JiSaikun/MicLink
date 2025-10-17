import { http } from 'api'
import { getModelInfoModel } from 'config'
import { addCustomerKey_Params,addCustomerKey_Response } from '../model/UserModel'


// getCode_Params为参数的类型声明，之后在页面中传入参数时，TS能够正确推断并代码提示
// getCode_Response为服务器端返回的，页面中要渲染的那部分数据的数据类型, 之后在页面中也能正确推断并代码提示
/**
 * 用户按键模式详情
 * @param params
 * @returns
 */
export function _addCustomerKey(params: addCustomerKey_Params) {
  return http.post<addCustomerKey_Response, addCustomerKey_Params>('/api/addCustomerKey', params);
}

