import { BaseParams } from 'api';



export interface register_Response {
  unionid: string;
  channel: string;
  lastLoginDate: number | null;
  type: string;
  mac: string | null;
  platform: string | null;
  lastLoginIp: string | null;
  password: string;
  now: number;
  registrationId: string | null;
  id: number;
  lastUpdatedBy: string | null;
  address: string | null;
  chatExpiredTime: number;
  openid: string | null;
  totalTime: number;
  sex: string;
  artExpiredTime: number;
  avatar: string | null;
  appleId: string | null;
  version: number;
  expiredTime: number;
  token: string;
  lastUpdatedDate: number | null;
  createdDate: number;
  createdBy: string | null;
  name: string;
  account: string;
  status: number;
}


/**
 * 更新用户昵称
 */
export interface updateName_Params extends BaseParams {
  name: string //昵称
  token: string //令牌
}