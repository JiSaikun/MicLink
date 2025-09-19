export interface getModelInfoModel { //用户按键模式详情，接口获取的数据
  id: number
  productId: number
  productModelId: number
  type: string,
  name: null,
  memberId: null,
  sno: string,
  first: number,
  lastUpdatedDate: number,
  keyInfos: keyInfosModel[] //按键信息
  appkey: string
  languages: languagesModel[]
  transLanguages: languagesModel[]
  ttsLanguages: languagesModel[]
  regionregion: string
  cmds: []
  xfocr: xfocreModel
  images: imagesModel[]
  functions: []
  lives: string
  chatIeUrl: string
  chatChromeUrl: string
  pLevel: string
}

interface keyInfosModel {
  edit: number,
  keyName: string, //按键名 --语音键
  opId: number,
  keyId: number,
  keyUp: string,
  attr2: string,
  attr1: string,
  childs: keyInfos_childsModel[]
  parentId: number
  attr0: string
  cmdId: number
  names: LanguageNames
  name: string
  id: number
  keyDown: string
  productModelId: number
  first: number
  key: string


}

interface keyInfos_childsModel {
  edit: number,
  keyName: string, //按键名 --语音键
  opId: number,
  keyId: number,
  keyUp: string,
  attr2: string,
  attr1: string,
  childs: keyInfos_childs_childsModel[]
  parentId: number
  attr0: string
  cmdId: number
  names: LanguageNames
  opName: string
  name: string
  id: number
  operation: string
  productModelId: number
  first: number
}

type LanguageNames = Record<string, string>;

interface keyInfos_childs_childsModel {
  edit: number,
  keyName: string, //按键名 --语音键
  opId: number,
  keyId: number,
  cmdName: string //按键具体功能
  attr2: string,
  attr1: string,
  parentId: number
  attr0: string
  cmdId: number
  names: LanguageNames
  opName: string
  name: string //按键具体功能
  cmd: string
  id: number
  productModelId: number
  first: number
}

interface languagesModel {
  code: string //语言编号
  nameFil_ph: string //菲律宾语
  icon: string //国旗
  nameEs_es: string //西班牙语
  nameJp: string //日语
  nameTw: string //中文-繁体
  formatSize: formatSizeModel
  nameUygur: string //维吾尔语
  nameHi_in: string //印地语
  nameMo_mo: string //传统蒙古文
  nameRu_ru: string //俄语
  nameIt_it: string //意大利语
  nameZh_ti: string //藏文
  nameEn: string //英语
  sort: number
  nameMay_may: string //马来语
  nameAr_sa: string //阿拉伯语
  nameDe_de: string //德语
  name: string //中文
  nameKo_kr: string //韩语/朝鲜语
  nameId_id: string //印尼语
  nameTr_tr: string //土耳其语
  nameKa_ka: string //哈萨克语
  nameFr_fr: string //法语
  nameMn_mn: string //蒙古语
  nameTh_th: string //泰语
  nameVi_vn: string //越南语
}

interface formatSizeModel {
  opus40: number
  adpcm: number
  mp3: number
  speex?: number
  opus: number
  pcm: number
}

interface xfocreModel {
  languages: languagesModel[]
  appId: string
  appKey: string
}

type imagesModel = Record<string, imagesDataModel[]>;
type imagesDataModel = Record<string, string>;
