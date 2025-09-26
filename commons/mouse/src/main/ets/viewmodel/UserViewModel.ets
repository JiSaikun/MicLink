import { http } from 'api'
import { getModelInfoModel } from 'config'
import { getModelInfo_Params, translate_Params, translate_Response } from '../model/MouseInfoModel'


// getCode_Params为参数的类型声明，之后在页面中传入参数时，TS能够正确推断并代码提示
// getCode_Response为服务器端返回的，页面中要渲染的那部分数据的数据类型, 之后在页面中也能正确推断并代码提示
/**
 * 用户按键模式详情
 * @param params
 * @returns
 */
export function _getModelInfo(params: getModelInfo_Params) {
  return http.get<getModelInfoModel, getModelInfo_Params>('/api/getModelInfo', params);
}

/**
 * 文本翻译
 */
export function _translate(params: translate_Params) {
  return http.post<translate_Response, translate_Params>('/api/v1/translate', params);
}
