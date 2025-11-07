import { BaseParams } from 'api';

/**
 * 获取验证码
 */
export interface getCode_Params extends BaseParams {
  account: string
  accountType: string
  codeType: string
}

/**
 * 注册登录
 */
export interface register_Params extends BaseParams {
  account: string //账号
  code: string //验证码
  password: string //密码
  type: string //账号类型,可用值:PHONE,EMAIL,VISITOR
}

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
 * 用户登录
 * 暂和验证码登录混合
 */
export interface login_Params extends BaseParams {
  account: string //账号
  password?: string //密码
  code?: string //验证码
}

/**
 * 修改密码
 */
export interface resetPwd_Params extends BaseParams {
  account: string //账号
  code: string //验证码
  password: string //密码
}