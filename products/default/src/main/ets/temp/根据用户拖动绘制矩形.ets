// DraggableResizableRect.ets

// 定义控制点类型
interface ControlHandle {
  x: number;
  y: number;
  type: string;
}

@Entry
@Component
struct DraggableResizableRect {
  // Canvas上下文
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D();

  // 矩形属性
  @State rectX: number = 100;
  @State rectY: number = 100;
  @State rectWidth: number = 150;
  @State rectHeight: number = 100;

  // 状态
  @State isDragging: boolean = false;
  @State isResizing: boolean = false;
  @State activeHandle: string = 'none';

  // 画布尺寸
  private canvasWidth: number = 350;
  private canvasHeight: number = 400;

  // 拖拽起始位置
  private startX: number = 0;
  private startY: number = 0;
  private startRectX: number = 0;
  private startRectY: number = 0;
  private startRectWidth: number = 0;
  private startRectHeight: number = 0;

  // 绘制矩形
  private drawRect(): void {
    // 清空画布
    this.ctx.clearRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 绘制背景
    this.ctx.fillStyle = '#F0F0F0';
    this.ctx.fillRect(0, 0, this.canvasWidth, this.canvasHeight);

    // 绘制圆角矩形
    const radius = 8;
    this.ctx.beginPath();
    this.ctx.moveTo(this.rectX + radius, this.rectY);
    this.ctx.lineTo(this.rectX + this.rectWidth - radius, this.rectY);
    this.ctx.quadraticCurveTo(this.rectX + this.rectWidth, this.rectY, this.rectX + this.rectWidth, this.rectY + radius);
    this.ctx.lineTo(this.rectX + this.rectWidth, this.rectY + this.rectHeight - radius);
    this.ctx.quadraticCurveTo(this.rectX + this.rectWidth, this.rectY + this.rectHeight,
      this.rectX + this.rectWidth - radius, this.rectY + this.rectHeight);
    this.ctx.lineTo(this.rectX + radius, this.rectY + this.rectHeight);
    this.ctx.quadraticCurveTo(this.rectX, this.rectY + this.rectHeight, this.rectX, this.rectY + this.rectHeight - radius);
    this.ctx.lineTo(this.rectX, this.rectY + radius);
    this.ctx.quadraticCurveTo(this.rectX, this.rectY, this.rectX + radius, this.rectY);
    this.ctx.closePath();

    // 填充
    this.ctx.fillStyle = '#4A90E2';
    this.ctx.fill();

    // 边框
    this.ctx.lineWidth = 2;
    this.ctx.strokeStyle = '#2C3E50';
    this.ctx.stroke();

    // 绘制控制点
    this.drawHandles();

    // 绘制尺寸信息
    this.drawSizeInfo();
  }

  // 绘制控制点
  private drawHandles(): void {
    const size = 10;

    // 创建控制点数组 - 使用明确的类型
    const handles: ControlHandle[] = [
      { x: this.rectX, y: this.rectY, type: 'nw' },
      { x: this.rectX + this.rectWidth, y: this.rectY, type: 'ne' },
      { x: this.rectX, y: this.rectY + this.rectHeight, type: 'sw' },
      { x: this.rectX + this.rectWidth, y: this.rectY + this.rectHeight, type: 'se' }
    ];

    this.ctx.fillStyle = '#FFFFFF';
    this.ctx.strokeStyle = '#2C3E50';
    this.ctx.lineWidth = 1;

    for (let i = 0; i < handles.length; i++) {
      const handle: ControlHandle = handles[i];
      this.ctx.beginPath();
      this.ctx.rect(handle.x - size/2, handle.y - size/2, size, size);
      this.ctx.fill();
      this.ctx.stroke();
    }
  }

  // 绘制尺寸信息
  private drawSizeInfo(): void {
    this.ctx.fillStyle = '#000000';
    this.ctx.font = '14px Arial';
    this.ctx.textAlign = 'center';

    const centerX = this.rectX + this.rectWidth / 2;
    const centerY = this.rectY + this.rectHeight / 2;

    this.ctx.fillText(`${Math.round(this.rectWidth)}×${Math.round(this.rectHeight)}`, centerX, centerY);
  }

  // 检测点击位置
  private detectHit(x: number, y: number): string {
    const size = 10;
    const halfSize = size / 2;

    // 创建控制点数组 - 使用明确的类型
    const handles: ControlHandle[] = [
      { x: this.rectX, y: this.rectY, type: 'nw' },
      { x: this.rectX + this.rectWidth, y: this.rectY, type: 'ne' },
      { x: this.rectX, y: this.rectY + this.rectHeight, type: 'sw' },
      { x: this.rectX + this.rectWidth, y: this.rectY + this.rectHeight, type: 'se' }
    ];

    for (let i = 0; i < handles.length; i++) {
      const handle: ControlHandle = handles[i];
      if (x >= handle.x - halfSize && x <= handle.x + halfSize &&
        y >= handle.y - halfSize && y <= handle.y + halfSize) {
        return handle.type;
      }
    }

    // 检查是否在矩形内
    if (x >= this.rectX && x <= this.rectX + this.rectWidth &&
      y >= this.rectY && y <= this.rectY + this.rectHeight) {
      return 'move';
    }

    return 'none';
  }

  // 限制边界
  private clampRect(): void {
    const minSize = 30;

    // 最小尺寸
    if (this.rectWidth < minSize) this.rectWidth = minSize;
    if (this.rectHeight < minSize) this.rectHeight = minSize;

    // 边界限制
    if (this.rectX < 0) this.rectX = 0;
    if (this.rectY < 0) this.rectY = 0;
    if (this.rectX + this.rectWidth > this.canvasWidth) {
      this.rectX = this.canvasWidth - this.rectWidth;
    }
    if (this.rectY + this.rectHeight > this.canvasHeight) {
      this.rectY = this.canvasHeight - this.rectHeight;
    }
  }

  // 处理尺寸调整
  private handleResize(dx: number, dy: number): void {
    const minSize = 30;

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

  // 重置
  private resetRect(): void {
    this.rectX = 100;
    this.rectY = 100;
    this.rectWidth = 150;
    this.rectHeight = 100;
    this.drawRect();
  }

  build() {
    Column({ space: 10 }) {
      // 标题
      Text('可拖拽调整尺寸的矩形')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 10 })

      // 控制面板
      Row({ space: 10 }) {
        Button('重置')
          .onClick(() => {
            this.resetRect();
          })

        Button('随机尺寸')
          .onClick(() => {
            this.rectWidth = 80 + Math.random() * 120;
            this.rectHeight = 60 + Math.random() * 100;
            this.clampRect();
            this.drawRect();
          })
      }
      .margin({ bottom: 10 })

      // 画布
      Stack() {
        Canvas(this.ctx)
          .width(this.canvasWidth)
          .height(this.canvasHeight)
          .backgroundColor('#F8F8F8')
          .border({ width: 1, color: '#CCCCCC' })
          .onReady(() => {
            this.drawRect();
          })
          .onTouch((event: TouchEvent) => {
            if (event.touches.length > 0) {
              const touch = event.touches[0];

              switch (event.type) {
                case TouchType.Down:
                  this.activeHandle = this.detectHit(touch.x, touch.y);
                  if (this.activeHandle !== 'none') {
                    this.startX = touch.x;
                    this.startY = touch.y;
                    this.startRectX = this.rectX;
                    this.startRectY = this.rectY;
                    this.startRectWidth = this.rectWidth;
                    this.startRectHeight = this.rectHeight;
                    this.isDragging = this.activeHandle === 'move';
                    this.isResizing = !this.isDragging;
                  }
                  break;

                case TouchType.Move:
                  if (this.activeHandle !== 'none') {
                    const dx = touch.x - this.startX;
                    const dy = touch.y - this.startY;
                    this.handleResize(dx, dy);
                    this.drawRect();
                  }
                  break;

                case TouchType.Up:
                case TouchType.Cancel:
                  this.activeHandle = 'none';
                  this.isDragging = false;
                  this.isResizing = false;
                  break;
              }
            }
          })

        // 信息显示
        Column({ space: 5 }) {
          Text(`位置: (${Math.round(this.rectX)}, ${Math.round(this.rectY)})`)
          Text(`尺寸: ${Math.round(this.rectWidth)} × ${Math.round(this.rectHeight)}`)
        }
        .backgroundColor('#FFFFFF')
        .opacity(0.8)
        .padding(8)
        .borderRadius(4)
        .position({ x: 10, y: 10 })
      }
      .width(this.canvasWidth)
      .height(this.canvasHeight)

      // 操作说明
      Column({ space: 5 }) {
        Text('操作说明:')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
        Text('• 拖拽矩形内部: 移动位置')
          .fontSize(12)
        Text('• 拖拽四个角点: 调整大小')
          .fontSize(12)
      }
      .margin({ top: 10 })
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .alignItems(HorizontalAlign.Center)
  }
}