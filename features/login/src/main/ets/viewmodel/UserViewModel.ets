import { http } from 'api'
import {
  getCode_Params, //获取验证码
  register_Params, //注册登录
  register_Response,
  login_Params, //密码登录
  resetPwd_Params, //修改密码
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
 * 注册登录
 * @param params
 * @returns
 */
export function _register(params: register_Params) {
  return http.post<register_Response, register_Params>('/api/register', params);
}

/**
 * 用户登录
 * @param params
 * @returns
 */
export function _login(params: login_Params) {
  return http.post<register_Response, login_Params>('/api/login', params);
}

/**
 * 修改密码
 * @param params
 * @returns
 */
export function _resetPwd(params: resetPwd_Params) {
  return http.post<register_Response, resetPwd_Params>('/api/resetPwd', params);
}

