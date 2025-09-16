/**
 * *****************************************************************************************音频处理器类
 */
// 音频处理器类
// 处理单个ADPCM编码，返回预测值和新的索引
interface model_encoding_ADPC {
  predict: number,
  predictIdx: number
}

export  class SmartMouseAudioProcessor {
  private readonly BKEY: Uint8Array = new Uint8Array([
    0x31, 0xec, 0x06, 0xa2, 0x0c, 0x90, 0x12, 0x9d, 0x20, 0xa3,
    0x6b, 0x41, 0xbb, 0x40, 0x68, 0x5a, 0x4b, 0x12, 0xf4, 0x11,
    0x03, 0x9a, 0x4b, 0x12, 0xf6, 0x11, 0x03, 0x76, 0x0a, 0x12,
    0xd4, 0x48, 0x10, 0x49, 0x20, 0xf2, 0x20, 0x03, 0x54, 0x49,
    0x24, 0xf4, 0x20, 0x03, 0x92, 0x12, 0xf6, 0x02, 0x03, 0x20,
    0xa4, 0x91, 0x02, 0xdb, 0xc1, 0xda, 0x49, 0x19, 0x4a, 0x09,
    0x6e, 0xed, 0x6b, 0x49, 0xf8, 0xab, 0x94, 0xc1, 0x77, 0x48,
    0x01, 0xaf, 0x28, 0xc0, 0x2a, 0x39, 0x9f, 0x08, 0x90, 0x01,
    0x9e, 0x01, 0xa0, 0x09, 0x90, 0x74, 0x9a, 0x81, 0x87, 0x2b,
    0x4d, 0xab, 0x20, 0xc0, 0x75, 0x87, 0xbe, 0xec, 0x30, 0xec
  ]);

  // 处理原始音频数据并返回解码后的PCM数据
  processVoiceData(frame: Uint8Array): Int16Array | null {
    if (frame.length < 32) {
      return null;
    }

    try {
      // 解析预测值和索引
      const ps = new Int16Array(2);
      ps[0] = (frame[0] | (frame[1] << 8)); // predict（低字节在前）
      ps[1] = (frame[2] | (frame[3] << 8)); // predictIdx

      // 提取ADPCM编码数据（从第5字节开始）
      const adpcm = frame.subarray(4);

      // 解码为PCM（每字节ADPCM包含2个PCM样本）
      const pcmData = new Int16Array(adpcm.length * 2);
      this.adpcmToPcm(ps, pcmData, adpcm);

      return pcmData;
    } catch (e) {
      console.error('音频处理失败:', e);
      return null;
    }
  }

  // Telink 音频数据解密（逐字节异或）
  miclinkDecrypt(indata: Uint8Array, len: number = 32): Uint8Array {
    const hexString = Array.from(indata).map(b => b.toString(16).padStart(2, '0')).join(' ');
    console.log('*****************接收到的语音初始数据********************************','\n',hexString)
    if (indata.length < len || this.BKEY.length < len) {
      throw new Error("Data or key length too short——————语音数据应为32位，长度不够不予解析");
    }

    const outdata = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      outdata[i] = indata[i] ^ this.BKEY[i]; // 异或解密
    }
    console.log('***********************************解密结果**************************：','\t',Array.from(outdata).map(b => b.toString(16).padStart(2, '0')).join(' '))
    return outdata;
  }

  // ADPCM解码为PCM的核心算法
  private adpcmToPcm(ps: Int16Array, pd: Int16Array, codes: Uint8Array): void {
    let predict = ps[0];
    let predictIdx = ps[1] & 0xFF;
    let i = 0;

    // 遍历每个ADPCM字节（每个字节包含2个4位编码）
    for (let byteIndex = 0; byteIndex < codes.length && i < pd.length; byteIndex++) {
      const codeByte = codes[byteIndex];

      // 处理低4位（第一个样本）
      let code = codeByte & 0x0F;
      let state = this.processCode(code, predict, predictIdx);
      predict = state.predict;
      predictIdx = state.predictIdx;
      if (i < pd.length) {
        pd[i++] = predict;
      }

      // 处理高4位（第二个样本）
      if (i < pd.length) {
        code = (codeByte >> 4) & 0x0F;
        state = this.processCode(code, predict, predictIdx);
        predict = state.predict;
        predictIdx = state.predictIdx;
        pd[i++] = predict;
      }
    }
  }

  // 处理单个ADPCM编码，返回预测值和新的索引
  private processCode(code: number, predict: number, predictIdx: number): model_encoding_ADPC {
    // ADPCM解码表（固定值）
    const idxtbl = [
      -1, -1, -1, -1, 2, 4, 6, 8,
      -1, -1, -1, -1, 2, 4, 6, 8
    ];

    const steptbl = [
      7, 8, 9, 10, 11, 12, 13, 14, 16, 17,
      19, 21, 23, 25, 28, 31, 34, 37, 41, 45,
      50, 55, 60, 66, 73, 80, 88, 97, 107, 118,
      130, 143, 157, 173, 190, 209, 230, 253, 279, 307,
      337, 371, 408, 449, 494, 544, 598, 658, 724, 796,
      876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066,
      2272, 2499, 2749, 3024, 3327, 3660, 4026, 4428, 4871, 5358,
      5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899,
      15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
    ];

    // 计算预测差值
    const step = steptbl[predictIdx];
    let diffq = step >> 3;

    if ((code & 4) !== 0) {
      diffq += step;
    }
    if ((code & 2) !== 0) {
      diffq += step >> 1;
    }
    if ((code & 1) !== 0) {
      diffq += step >> 2;
    }

    // 应用差值到预测值
    if ((code & 8) !== 0) {
      predict -= diffq;
    } else {
      predict += diffq;
    }

    // 限制PCM值范围（-32768 到 32767）
    if (predict > 32767) {
      predict = 32767;
    }
    if (predict < -32768) {
      predict = -32768;
    }

    // 更新索引并限制范围
    predictIdx += idxtbl[code];
    if (predictIdx < 0) {
      predictIdx = 0;
    }
    if (predictIdx > 88) {
      predictIdx = 88;
    }

    return { predict, predictIdx };
  }

  // 将解码后的PCM数据（Int16Array）转换为字节流（Uint8Array）
  int16ArrayToBytes(list: Int16Array): Uint8Array {
    const byteData = new ArrayBuffer(list.length * 2);
    const view = new DataView(byteData);
    for (let i = 0; i < list.length; i++) {
      view.setInt16(i * 2, list[i], true); // 小端字节序
    }
    return new Uint8Array(byteData);
  }
}