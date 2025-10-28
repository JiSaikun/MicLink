import { http } from 'api'
import { addCustomerKey_Params,addCustomerKey_Response ,resetCustomerKey_Params,resetCustomerKey_Response} from '../model/UserModel'


// getCode_Params为参数的类型声明，之后在页面中传入参数时，TS能够正确推断并代码提示
// getCode_Response为服务器端返回的，页面中要渲染的那部分数据的数据类型, 之后在页面中也能正确推断并代码提示
/**
 * 自定义按键
 * @param params
 * @returns
 */
export function _addCustomerKey(params: addCustomerKey_Params) {
  return http.post<addCustomerKey_Response, addCustomerKey_Params>('/api/addCustomerKey', params);
}

/**
 * 重置按键设置
 * @param params
 * @returns
 */
export function _resetCustomerKey(params: resetCustomerKey_Params) {
  return http.post<resetCustomerKey_Response, resetCustomerKey_Params>('/api/resetCustomerKey', params);
}

