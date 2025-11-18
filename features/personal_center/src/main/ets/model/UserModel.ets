import { BaseParams } from 'api';


/**
 * 更新用户昵称
 */
export interface updateName_Params extends BaseParams {
  name: string //昵称
  token: string //令牌
}