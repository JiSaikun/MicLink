import { getModelInfoModel, keyInfosModel, keyInfos_childsModel, keyInfos_childs_childsModel } from "config";

/**
 * 剔除指定cmd的按键配置
 * @param getModelInfo 原始按键配置数据
 * @returns Promise<getModelInfoModel> 剔除后的配置数据
 */
export function keyConfigExclusion(getModelInfo: getModelInfoModel): Promise<getModelInfoModel> {
  return new Promise((resolve, reject) => {
    try {
      // 1. 从AppStorage获取需要剔除的cmd列表（增加空值判断，避免报错）
      const excludeCmds = AppStorage.get('keyConfigExclusion') as string[] || [];
      if (!Array.isArray(excludeCmds)) {
        reject(new Error("keyConfigExclusion 不是合法的数组格式"));
        return;
      }

      let new_keyInfos: keyInfosModel[] = [];
      // 2. 遍历一级keyInfos（修改循环变量名，避免嵌套冲突）
      getModelInfo.keyInfos?.forEach((keyInfoItem) => {
        if (!keyInfoItem) return; // 空值保护

        let new_keyInfos_childs: keyInfos_childsModel[] = [];
        // 3. 遍历二级childs
        keyInfoItem.childs?.forEach((childItem) => {
          if (!childItem) return; // 空值保护

          let new_keyInfos_childs_childs: keyInfos_childs_childsModel[] = [];
          // 4. 遍历三级childs，过滤需要剔除的cmd
          childItem.childs?.forEach((grandChildItem) => {
            if (!grandChildItem) return; // 空值保护

            // 判断当前项是否需要保留（不在剔除列表中则保留）
            const needKeep = !excludeCmds.includes(grandChildItem.cmd || '');
            if (needKeep) {
              new_keyInfos_childs_childs.push(grandChildItem);
            }
          });

          // 5. 给二级childs赋值过滤后的三级childs
          let keyInfos_childs: keyInfos_childsModel = {
            edit: childItem.edit,
            keyName: childItem.keyName,
            opId: childItem.opId,
            keyId: childItem.keyId,
            keyUp: childItem.keyUp,
            childs: new_keyInfos_childs_childs, // 关键修复：赋值过滤后的三级数据
            parentId: childItem.parentId,
            cmdId: childItem.cmdId,
            names: childItem.names,
            opName: childItem.opName,
            name: childItem.name,
            id: childItem.id,
            operation: childItem.operation,
            productModelId: childItem.productModelId,
            first: childItem.first,
            attr0: childItem.attr0,
            attr1: childItem.attr1,
            attr2: childItem.attr2
          };
          new_keyInfos_childs.push(keyInfos_childs);
        });

        // 6. 组装一级keyInfos数据
        let keyInfos: keyInfosModel = {
          edit: keyInfoItem.edit,
          keyName: keyInfoItem.keyName,
          opId: keyInfoItem.opId,
          keyId: keyInfoItem.keyId,
          keyUp: keyInfoItem.keyUp,
          childs: new_keyInfos_childs, // 二级childs赋值
          parentId: keyInfoItem.parentId,
          cmdId: keyInfoItem.cmdId,
          names: keyInfoItem.names,
          name: keyInfoItem.name,
          id: keyInfoItem.id,
          keyDown: keyInfoItem.keyDown,
          productModelId: keyInfoItem.productModelId,
          first: keyInfoItem.first,
          key: keyInfoItem.key,
          attr0: keyInfoItem.attr0,
          attr1: keyInfoItem.attr1,
          attr2: keyInfoItem.attr2
        };
        new_keyInfos.push(keyInfos);
      });

      console.log("剔除前的按键配置：", JSON.stringify(getModelInfo.keyInfos[0].childs[0].childs[getModelInfo.keyInfos[0].childs[0].childs.length-1]));
      console.log("剔除条件：",JSON.stringify(AppStorage.get('keyConfigExclusion')));
      console.log("剔除后的按键配置：", JSON.stringify(new_keyInfos[0].childs[0].childs[new_keyInfos[0].childs[0].childs.length-1]));

      // ========== 核心修复：替换对象扩展运算符，手动赋值所有字段 ==========
      const resultData: getModelInfoModel = {
        id: getModelInfo.id,
        productId: getModelInfo.productId,
        productModelId: getModelInfo.productModelId,
        type: getModelInfo.type,
        name: getModelInfo.name,
        memberId: getModelInfo.memberId,
        sno: getModelInfo.sno,
        first: getModelInfo.first,
        lastUpdatedDate: getModelInfo.lastUpdatedDate,
        keyInfos: new_keyInfos, // 替换为过滤后的keyInfos
        appkey: getModelInfo.appkey,
        languages: getModelInfo.languages,
        transLanguages: getModelInfo.transLanguages,
        ttsLanguages: getModelInfo.ttsLanguages,
        regionregion: getModelInfo.regionregion,
        cmds: getModelInfo.cmds,
        xfocr: getModelInfo.xfocr,
        images: getModelInfo.images,
        functions: getModelInfo.functions,
        lives: getModelInfo.lives,
        chatIeUrl: getModelInfo.chatIeUrl,
        chatChromeUrl: getModelInfo.chatChromeUrl,
        pLevel: getModelInfo.pLevel
      };

      // 7. 返回剔除后的完整配置
      resolve(resultData);
    } catch (error) {
      // 8. 异常捕获，避免Promise卡死
      console.error("按键配置剔除失败：", error);
      reject(error instanceof Error ? error : new Error(String(error)));
    }
  });
}