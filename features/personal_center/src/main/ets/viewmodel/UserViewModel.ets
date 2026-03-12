import { http } from 'api'
import { register_Response } from 'common';
import {
  goods_Params,
  goods_Response,
  pay_Params,
  pay_Response,
  queryOrderStatus_Params,
  updateName_Params //修改密码
} from '../model/UserModel'


/**
 * 更新用户昵称
 * @param params
 * @returns
 */
export function _updateName(params: updateName_Params) {
  return http.post<register_Response, updateName_Params>('/api/updateName', params);
}

/**
 * 商品列表
 * @param params
 * @returns
 */
export function _goods(params: goods_Params = { type: "MOUSE" }) {
  return http.get<goods_Response[], goods_Params>('/api/goods', params);
}

/**
 * 下单
 * @param params
 * @returns
 */
export function _pay(params: pay_Params) {
  return http.get<pay_Response, pay_Params>('/api/pay', params);
}

/**
 * 查询订单状态
 * @param params
 * @returns
 */
export function _queryOrderStatus(params: queryOrderStatus_Params) {
  return http.get<pay_Response, queryOrderStatus_Params>('/api/queryOrderStatus', params);
}

