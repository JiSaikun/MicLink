import { http } from 'api'
import { register_Response } from 'common';
import {
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

