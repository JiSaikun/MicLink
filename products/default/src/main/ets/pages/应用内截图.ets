// DraggableResizableRect.ets

import display from '@ohos.display';

// 定义控制点类型
interface ControlHandle {
  x: number;
  y: number;
  type: string;
}

interface Point {
  x: number;
  y: number;
}
@Entry
@Component
export struct DraggableResizableRect {
  // Canvas设置和上下文
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  // 组件尺寸
  @State canvasWidth: number = 0;
  @State canvasHeight: number = 0;

  // 矩形属性 - 初始设置小一些
  @State rectX: number = 50;
  @State rectY: number = 100;
  @State rectWidth: number = 100;
  @State rectHeight: number = 100;

  // 保存按钮属性
  private saveBtnWidth: number = 40;
  private saveBtnHeight: number = 40;
  @State saveBtnX: number = 0;
  @State saveBtnY: number = 0;
  @State isHoverSaveBtn: boolean = false;

  // 状态
  @State isDragging: boolean = false;
  @State isResizing: boolean = false;
  @State activeHandle: string = 'none';

  // 拖拽起始位置
  private startX: number = 0;
  private startY: number = 0;
  private startRectX: number = 0;
  private startRectY: number = 0;
  private startRectWidth: number = 0;
  private startRectHeight: number = 0;

  // 绘制蒙层和矩形
  private drawMaskAndRect(): void {
    if (this.canvasWidth === 0 || this.canvasHeight === 0) return;

    // 清空画布
    this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 首先绘制半透明黑色蒙层
    this.ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
    this.ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 在矩形位置清除蒙层，显示底层内容
    this.ctx.clearRect(this.rectX, this.rectY, this.rectWidth, this.rectHeight);

    // 绘制矩形边框（蓝色）
    this.ctx.lineWidth = 3;
    this.ctx.strokeStyle = '#4A90E2';
    this.ctx.strokeRect(this.rectX, this.rectY, this.rectWidth, this.rectHeight);

    // 绘制控制点（四个角的白点）
    this.drawHandles();

    // 更新保存按钮位置
    this.updateSaveButtonPosition();
  }

  // 绘制控制点
  private drawHandles(): void {
    const size = 15;
    const handles: ControlHandle[] = [
      { x: this.rectX, y: this.rectY, type: 'nw' },
      { x: this.rectX + this.rectWidth, y: this.rectY, type: 'ne' },
      { x: this.rectX, y: this.rectY + this.rectHeight, type: 'sw' },
      { x: this.rectX + this.rectWidth, y: this.rectY + this.rectHeight, type: 'se' }
    ];

    // 绘制白色圆形控制点
    this.ctx.fillStyle = '#FFFFFF';
    this.ctx.strokeStyle = '#4A90E2';
    this.ctx.lineWidth = 2;

    for (let i = 0; i < handles.length; i++) {
      const handle = handles[i];
      this.ctx.beginPath();
      this.ctx.arc(handle.x, handle.y, size/2, 0, Math.PI * 2);
      this.ctx.fill();
      this.ctx.stroke();
    }
  }

  // 更新保存按钮位置 - 紧贴矩形右下角
  private updateSaveButtonPosition(): void {
    // 计算按钮位置（紧贴矩形右下角）
    let newSaveBtnX = this.rectX + this.rectWidth - this.saveBtnWidth - 5; // 稍微内嵌2px
    let newSaveBtnY = this.rectY + this.rectHeight + 5; // 稍微内嵌2px

    // 确保按钮不会超出组件边界
    if (newSaveBtnY + this.saveBtnHeight > this.canvasHeight - 2) {
      newSaveBtnY = this.canvasHeight - this.saveBtnHeight - 2;
    }
    if (newSaveBtnX + this.saveBtnWidth > this.canvasWidth - 2) {
      newSaveBtnX = this.canvasWidth - this.saveBtnWidth - 2;
    }
    if (newSaveBtnX < 2) {
      newSaveBtnX = 2;
    }

    // 更新按钮位置
    this.saveBtnX = newSaveBtnX;
    this.saveBtnY = newSaveBtnY;
  }

  // 检测点击位置
  private detectHit(x: number, y: number): string {
    const handleSize = 15;

    // 检查控制点
    const handles: ControlHandle[] = [
      { x: this.rectX, y: this.rectY, type: 'nw' },
      { x: this.rectX + this.rectWidth, y: this.rectY, type: 'ne' },
      { x: this.rectX, y: this.rectY + this.rectHeight, type: 'sw' },
      { x: this.rectX + this.rectWidth, y: this.rectY + this.rectHeight, type: 'se' }
    ];

    for (let i = 0; i < handles.length; i++) {
      const handle = handles[i];
      const distance = Math.sqrt(Math.pow(x - handle.x, 2) + Math.pow(y - handle.y, 2));
      if (distance <= handleSize) {
        return handle.type;
      }
    }

    // 检查保存按钮
    if (x >= this.saveBtnX && x <= this.saveBtnX + this.saveBtnWidth &&
      y >= this.saveBtnY && y <= this.saveBtnY + this.saveBtnHeight) {
      return 'save';
    }

    // 检查是否在矩形内（用于移动）
    if (x >= this.rectX && x <= this.rectX + this.rectWidth &&
      y >= this.rectY && y <= this.rectY + this.rectHeight) {
      return 'move';
    }

    return 'none';
  }

  // 限制边界 - 修复左侧边缘问题
  private clampRect(): void {
    const minSize = 50;
    const margin = 10; // 增加边距，确保不会超出窗口

    // 最小尺寸
    if (this.rectWidth < minSize) this.rectWidth = minSize;
    if (this.rectHeight < minSize) this.rectHeight = minSize;

    // 边界限制
    // 左侧边缘：确保不会小于边距
    if (this.rectX < margin) {
      this.rectX = margin;
    }

    // 右侧边缘：确保不会超出边界
    if (this.rectX + this.rectWidth > this.canvasWidth - margin) {
      // 如果宽度太大，先调整宽度
      if (this.rectWidth > this.canvasWidth - 2 * margin) {
        this.rectWidth = this.canvasWidth - 2 * margin;
      }
      this.rectX = this.canvasWidth - margin - this.rectWidth;
    }

    // 上边缘：确保不会小于边距
    if (this.rectY < margin) {
      this.rectY = margin;
    }

    // 下边缘：确保不会超出边界
    if (this.rectY + this.rectHeight > this.canvasHeight - margin) {
      // 如果高度太大，先调整高度
      if (this.rectHeight > this.canvasHeight - 2 * margin) {
        this.rectHeight = this.canvasHeight - 2 * margin;
      }
      this.rectY = this.canvasHeight - margin - this.rectHeight;
    }
  }

  // 处理尺寸调整
  private handleResize(dx: number, dy: number): void {
    const minSize = 50;

    switch (this.activeHandle) {
      case 'nw': // 左上角
        this.rectX = this.startRectX + dx;
        this.rectY = this.startRectY + dy;
        this.rectWidth = this.startRectWidth - dx;
        this.rectHeight = this.startRectHeight - dy;
        break;
      case 'ne': // 右上角
        this.rectY = this.startRectY + dy;
        this.rectWidth = this.startRectWidth + dx;
        this.rectHeight = this.startRectHeight - dy;
        break;
      case 'sw': // 左下角
        this.rectX = this.startRectX + dx;
        this.rectWidth = this.startRectWidth - dx;
        this.rectHeight = this.startRectHeight + dy;
        break;
      case 'se': // 右下角
        this.rectWidth = this.startRectWidth + dx;
        this.rectHeight = this.startRectHeight + dy;
        break;
      case 'move': // 移动
        this.rectX = this.startRectX + dx;
        this.rectY = this.startRectY + dy;
        break;
    }

    // 边界限制
    this.clampRect();
  }

  // 保存四个角点
  private saveCorners(): void {
    const corners: Point[] = [
      { x: this.rectX, y: this.rectY }, // 左上
      { x: this.rectX + this.rectWidth, y: this.rectY }, // 右上
      { x: this.rectX + this.rectWidth, y: this.rectY + this.rectHeight }, // 右下
      { x: this.rectX, y: this.rectY + this.rectHeight }  // 左下
    ];
    // 打印四个角的位置
    console.log('四个角点坐标：');
    console.log('左上角:', JSON.stringify(corners[0]));
    console.log('右上角:', JSON.stringify(corners[1]));
    console.log('右下角:', JSON.stringify(corners[2]));
    console.log('左下角:', JSON.stringify(corners[3]));

    // 同时打印到控制台的格式化信息
    console.log(`矩形位置: (${this.rectX.toFixed(0)}, ${this.rectY.toFixed(0)})`);
    console.log(`矩形尺寸: ${this.rectWidth.toFixed(0)} × ${this.rectHeight.toFixed(0)}`);
    console.log('---');

    AppStorage.setOrCreate('sigejiao', corners);

    // 保存成功的视觉反馈
    this.isHoverSaveBtn = true;

    // 延迟重置按钮状态
    setTimeout(() => {
      this.isHoverSaveBtn = false;
    }, 300);
  }

  build() {
    Stack() {
      // Canvas组件 - 设置为填充父容器
      Canvas(this.ctx)
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0)') // 完全透明背景
        .onReady(() => {
          // 在onReady中获取Canvas的实际尺寸
          this.canvasWidth = this.ctx.width;
          this.canvasHeight = this.ctx.height;

          // 初始化矩形位置在组件中心
          this.rectX = this.canvasWidth / 2 - 50;
          this.rectY = this.canvasHeight / 2 - 50;

          // 确保初始位置在边界内
          this.clampRect();

          this.drawMaskAndRect();
        })
        .onTouch((event: TouchEvent) => {
          if (event.touches.length > 0) {
            const touch = event.touches[0];

            switch (event.type) {
              case TouchType.Down:
                this.activeHandle = this.detectHit(touch.x, touch.y);
                if (this.activeHandle !== 'none') {
                  if (this.activeHandle === 'save') {
                    // 点击保存按钮
                    this.saveCorners();
                  } else {
                    // 开始拖拽或调整
                    this.startX = touch.x;
                    this.startY = touch.y;
                    this.startRectX = this.rectX;
                    this.startRectY = this.rectY;
                    this.startRectWidth = this.rectWidth;
                    this.startRectHeight = this.rectHeight;
                    this.isDragging = this.activeHandle === 'move';
                    this.isResizing = !this.isDragging;
                  }
                }
                break;

              case TouchType.Move:
                if (this.activeHandle !== 'none' && this.activeHandle !== 'save') {
                  const dx = touch.x - this.startX;
                  const dy = touch.y - this.startY;
                  this.handleResize(dx, dy);
                  this.drawMaskAndRect();
                }
                break;

              case TouchType.Up:
              case TouchType.Cancel:
                if (this.activeHandle !== 'save') {
                  this.activeHandle = 'none';
                }
                this.isDragging = false;
                this.isResizing = false;
                break;
            }
          }
        })

      // 保存按钮 - 使用ArkUI组件
      Row() {
        // 这里使用文本作为图标，你可以替换为实际的Image组件
        Text('✓')
          .fontSize(20)
          .fontColor('#FFFFFF')
      }
      .width(this.saveBtnWidth)
      .height(this.saveBtnHeight)
      .backgroundColor(this.isHoverSaveBtn ? '#2C3E50' : '#4A90E2')
      .borderRadius(8)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .position({ x: this.saveBtnX, y: this.saveBtnY })
      .onClick(() => {
        this.saveCorners();
      })
      .onTouch((event: TouchEvent) => {
        // 阻止事件冒泡，避免触发Canvas的触摸事件
        event.stopPropagation?.();
      })
    }
    .width('100%')
    .height('100%')
  }
}