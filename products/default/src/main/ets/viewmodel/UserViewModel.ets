import { http } from 'api'
import { getCode_Params, getCode_Response } from '../model/UserModel'

// UserParams为参数的类型声明，之后在页面中传入参数时，TS能够正确推断并代码提示
// UserModel为服务器端返回的，页面中要渲染的那部分数据的数据类型, 之后在页面中也能正确推断并代码提示
/**
 * 获取验证码
 * @param data
 * @returns
 */
// export function _getCode(data: getCode_Params) {
//   return http.get<getCode_Response>("/user", data)
// }