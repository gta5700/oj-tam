unit ojPainter;

interface
uses  Vcl.GraphUtil, Vcl.Controls, Vcl.ExtCtrls, System.SysUtils, Vcl.Forms,
      Vcl.Graphics, System.Types;

type

  TojCustomPainter = class;
  TojGradientPainter = class;

  TojCustomPainter = class(TObject)
  private
    FTImer: TTimer;
    FPaintedControl: TControl;
    FDrawContext: Pointer;
    procedure inner_OnTimer(Sender: TObject);
    function getDrawTimeout: byte;
    procedure setDrawTimeout(const Value: byte);
  protected
    procedure Paint(Canvas: TCanvas; DrawContext: Pointer);virtual;
  public
    constructor Create(PaintedControl: TControl; DrawContext: Pointer = nil);virtual;
    destructor Destroy;override;
    procedure Invalidate;
  protected
    property DrawContext: Pointer read FDrawContext write FDrawContext;
    property PaintedControl: TControl read FPaintedControl write FPaintedControl;
  public
    property DrawTimeout: byte read getDrawTimeout write setDrawTimeout;
  end;

  TojGradientPainter = class(TojCustomPainter)
  private
    FGradientStopColor: TColor;
    FGradientStartColor: TColor;
  protected
    procedure Paint(Canvas: TCanvas; DrawContext: Pointer);override;
  public
    constructor Create(PaintedControl: TControl; DrawContext: Pointer);override;
    property GradientStartColor: TColor read FGradientStartColor write FGradientStartColor;
    property GradientStopColor: TColor read FGradientStopColor write FGradientStopColor;
  end;


  TojScreenLockPainter_LOCK = class(TojGradientPainter)
  private
    FCaption: string;
    FText: string;
    FLockTimeStart: TTime;
  protected
    procedure Paint(Canvas: TCanvas; DrawContext: Pointer);override;
  public
    constructor Create(PaintedControl: TControl; DrawContext: Pointer);override;
    property Caption: string read FCaption write FCaption;
    property Text: string read FText write FText;
    property LockTimeStart: TTime read FLockTimeStart write FLockTimeStart;
  end;

implementation
uses math, system.UITypes;

{ TojUserPainter }

constructor TojCustomPainter.Create(PaintedControl: TControl; DrawContext: Pointer);
begin
  inherited Create;
  FPaintedControl:= PaintedControl;
  FDrawContext:= DrawContext;
  FTImer:= TTimer.Create(nil);
  FTImer.Enabled:= FALSE;
  FTImer.OnTimer:= self.inner_OnTimer;
end;

destructor TojCustomPainter.Destroy;
begin
  FreeAndNil(FTimer);
  inherited;
end;


procedure TojCustomPainter.Invalidate;
var v_canvas: TControlCanvas;
begin
  if not Assigned(PaintedControl)
     OR (not PaintedControl.Visible)
     OR ((PaintedControl is TWinControl) AND (not TWinControl(PaintedControl).HandleAllocated))
  then Exit;

  v_canvas:= TControlCanvas.Create;
  try
    v_canvas.Control:= self.PaintedControl;
    Paint(v_canvas, self.DrawContext);
  finally
    FreeAndNil(v_canvas);
  end;
end;

procedure TojCustomPainter.Paint(Canvas: TCanvas; DrawContext: Pointer);
begin
end;

function TojCustomPainter.getDrawTimeout: byte;
begin
  if FTimer.Enabled
  then result:= FTimer.Interval div 1000
  else result:= 0;
end;


procedure TojCustomPainter.inner_OnTimer(Sender: TObject);
begin
  Invalidate;
end;

procedure TojCustomPainter.setDrawTimeout(const Value: byte);
begin
  FTimer.Interval:= Value * 1000;
  FTimer.Enabled:= (Value <> 0);
end;

{ TojScreenLockPainter_LOCK }

constructor TojScreenLockPainter_LOCK.Create(PaintedControl: TControl; DrawContext: Pointer);
begin
  inherited Create(PaintedControl, DrawContext);
  FCaption:= '';
  FText:= '';
  FLockTimeStart:= 0.0;
end;

procedure TojScreenLockPainter_LOCK.Paint(Canvas: TCanvas; DrawContext: Pointer);
var v_rect, v_caption_rect, v_text_rect, v_time_rect: TRect;
    v_text: string;
const CNST_MARGIN = 5;
begin
  v_rect:= PaintedControl.ClientRect;
  GradientFillCanvas(Canvas, clWhite, clSkyBlue, v_rect, gdVertical);

  // lock time
  if self.FLockTimeStart <> 0.0 then
  begin
    Canvas.Brush.Style:= bsClear;
    Canvas.Font.Style:= Canvas.Font.Style + [fsBold];
    v_text:= TimeToStr(Time() - self.FLockTimeStart);

    v_time_rect:= PaintedControl.ClientRect;
    v_time_rect.Top:= v_time_rect.Top + CNST_MARGIN;
    v_time_rect.Right:= v_time_rect.Right - CNST_MARGIN;
    v_time_rect.Left:= v_time_rect.Right - Canvas.TextWidth(v_text);
    v_time_rect.Bottom:= v_time_rect.Top + Canvas.TextHeight(v_text);

    Canvas.TextRect(v_time_rect, v_text, [tfSingleLine, tfEndEllipsis, tfRight, tfVerticalCenter]);
  end;


  // caption
  if self.FCaption <> '' then
  begin
    Canvas.Brush.Style:= bsClear;
    Canvas.Font.Style:= Canvas.Font.Style + [fsBold];
    v_caption_rect:= PaintedControl.ClientRect;
    v_caption_rect.Top:= v_caption_rect.Top + CNST_MARGIN;
    v_caption_rect.Left:= v_caption_rect.Left + CNST_MARGIN;
    v_caption_rect.Bottom:= v_caption_rect.Top + Canvas.TextHeight(self.FCaption);

    if self.FLockTimeStart = 0.0
    then v_caption_rect.Right:= v_caption_rect.Right - CNST_MARGIN
    else v_caption_rect.Right:= v_time_rect.Left - CNST_MARGIN;

    Canvas.TextRect(v_caption_rect, FCaption, [tfSingleLine, tfEndEllipsis, tfLeft, tfVerticalCenter]);
  end;

  // opis
  if self.FText <> '' then
  begin
    Canvas.Brush.Style:= bsClear;
    Canvas.Font.Style:= Canvas.Font.Style - [fsBold];

    v_text_rect:= PaintedControl.ClientRect;
    v_text_rect.Left:= v_text_rect.Left + CNST_MARGIN;
    v_text_rect.Right:= v_text_rect.Right - CNST_MARGIN;
    v_text_rect.Bottom:= v_text_rect.Bottom - CNST_MARGIN;

    if (self.FCaption <> '') OR (self.FLockTimeStart <> 0.0)
    then v_text_rect.Top:= Max(v_time_rect.Bottom, v_caption_rect.Bottom) + CNST_MARGIN
    else v_text_rect.Top:= v_text_rect.Top + CNST_MARGIN;

    Canvas.TextRect(v_text_rect, FText, [tfWordBreak, tfEndEllipsis, tfLeft, tfVerticalCenter]);
  end;

end;

{ TojGradientPainter }

constructor TojGradientPainter.Create(PaintedControl: TControl; DrawContext: Pointer);
begin
  inherited Create(PaintedControl, DrawContext);
  FGradientStopColor:= clSkyBlue;
  FGradientStartColor:= clWhite;
end;

procedure TojGradientPainter.Paint(Canvas: TCanvas; DrawContext: Pointer);
var v_rect: TRect;
begin
  v_rect:= PaintedControl.ClientRect;
  GradientFillCanvas(Canvas, clWhite, clSkyBlue, v_rect, gdVertical);
end;

end.
