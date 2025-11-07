import { http } from 'api'
import {
  getCode_Params, register_Response, //获取验证码
  resetPwd_Params,updateName_Params //修改密码
} from '../model/UserModel'

// getCode_Params为参数的类型声明，之后在页面中传入参数时，TS能够正确推断并代码提示
// getCode_Response为服务器端返回的，页面中要渲染的那部分数据的数据类型, 之后在页面中也能正确推断并代码提示
/**
 * 获取验证码
 * @param params
 * @returns
 */
export function _getCode(params: getCode_Params) {
  return http.post<string, getCode_Params>('/api/getCode', params);
}


/**
 * 修改密码
 * @param params
 * @returns
 */
export function _resetPwd(params: resetPwd_Params) {
  return http.post<register_Response, resetPwd_Params>('/api/resetPwd', params);
}

/**
 * 更新用户昵称
 * @param params
 * @returns
 */
export function _updateName(params: updateName_Params) {
  return http.post<register_Response, updateName_Params>('/api/resetPwd', params);
}

