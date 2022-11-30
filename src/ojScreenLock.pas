unit ojScreenLock;
{
  2020-02-11  GTA OK dziala
  2020-05-27  GTA OK THREAD dziala
}

interface
uses  classes, Vcl.Forms, System.SysUtils, Vcl.Controls, Winapi.Windows, Vcl.Graphics,
      Winapi.Messages, Generics.Collections, ShellApi, psApi;



type
  TojScreenLock = class;
  TojScreenLockParams = class;
  TojCustomScreenLockForm = class;
  TojEraseBkgndProc = procedure(Canvas: TCanvas; Params: TojScreenLockParams) of object;

  TojScreenLockParams = class(TPersistent)
  public type
    TojGradientProfile = (gpInfo, gpWarning, gpError);
  public const
    _GradientProfile: array[TojGradientProfile] of record
      StartColor: TColor;
      EndColor: TColor;
    end = (
      (StartColor: clWhite; EndColor: clBtnFace),       //  gpInfo
      (StartColor: clBtnFace;  EndColor: clMedGray),    //  gcWarrning
      (StartColor: clYellow;  EndColor: clRed)          //  gcError
    );

  private
    FOwner: TojCustomScreenLockForm;
    FShowDropShadow: boolean;
    FShowBorder: boolean;
    FAllowMove: boolean;
    FAllowResize: boolean;
    FCloseOnALT_F4: boolean;
    FMinWidth: integer;
    FMinHeight: integer;
    FMaxWidth: integer;
    FMaxHeight: integer;
    FCheckMinSize: boolean;
    FCheckMaxSize: boolean;
    FWidth: integer;
    FHeight: integer;
    FCaption: string;
    FText: string;
    FEraseBkgndProc: TojEraseBkgndProc;
    FGradientProfile: TojGradientProfile;
    FLockStartTime: TDateTime;
    FShowMemoryUsage: boolean;
    FTextHAlign: TAlignment;
    FTextVAlign: TVerticalAlignment;
    procedure setShowDropShadow(const Value: boolean);
    procedure setShowBorder(const Value: boolean);
    procedure setAllowMove(const Value: boolean);
    procedure setAllowResize(const Value: boolean);
    procedure setCloseOnALT_F4(const Value: boolean);

    procedure setMinWidth(const Value: integer);
    procedure setMaxWidth(const Value: integer);
    procedure setMinHeight(const Value: integer);
    procedure setMaxHeight(const Value: integer);

    procedure setCheckMaxSize(const Value: boolean);
    procedure setCheckMinSize(const Value: boolean);

    procedure setWidth(const Value: integer);
    procedure setHeight(const Value: integer);
    procedure setCaption(const Value: string);
    procedure setText(const Value: string);
    
    procedure setEraseBkgndProc(const Value: TojEraseBkgndProc);
    procedure setGradientProfile(const Value: TojGradientProfile);
    procedure setLockStartTime(const Value: TDateTime);
    procedure setShowMemoryUsage(const Value: boolean);

    procedure setTextVAlign(const Value: TVerticalAlignment);
    procedure setTextHAlign(const Value: TAlignment);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(p_Owner: TojCustomScreenLockForm);overload;virtual;

    function Owner: TojCustomScreenLockForm;virtual;
    procedure ParamsChanged; virtual;
  published
    property ShowDropShadow: boolean read FShowDropShadow write setShowDropShadow;
    property ShowBorder: boolean read FShowBorder write setShowBorder;
    property AllowResize: boolean read FAllowResize write setAllowResize;
    property AllowMove: boolean read FAllowMove write setAllowMove;
    //  protected
    property CloseOnALT_F4: boolean read FCloseOnALT_F4 write setCloseOnALT_F4;

    property CheckMinSize: boolean read FCheckMinSize write setCheckMinSize;
    property CheckMaxSize: boolean read FCheckMaxSize write setCheckMaxSize;
    property MinWidth: integer read FMinWidth write setMinWidth;
    property MaxWidth: integer read FMaxWidth write setMaxWidth;
    property MinHeight: integer read FMinHeight write setMinHeight;
    property MaxHeight: integer read FMaxHeight write setMaxHeight;

    property Width: integer read FWidth write setWidth;
    property Height: integer read FHeight write setHeight;

    property TextHAlign: TAlignment read FTextHAlign write setTextHAlign;
    property TextVAlign: TVerticalAlignment read FTextVAlign write setTextVAlign;

    property Caption: string read FCaption write setCaption;
    property Text: string read FText write setText;
    property LockStartTime: TDateTime read FLockStartTime write setLockStartTime;

    property EraseBkgndProc: TojEraseBkgndProc read FEraseBkgndProc write setEraseBkgndProc;
    property GradientProfile: TojGradientProfile read FGradientProfile write setGradientProfile;

    property ShowMemoryUsage: boolean read FShowMemoryUsage write setShowMemoryUsage;
  end;


  TojCustomScreenLockForm = class(TCustomForm)
  private
    FParams: TojScreenLockParams;
    FIsShowingLock: boolean;
    FIsClosingLock: boolean;
    FPrevActiveWindow: HWND;
    CNST_ERASE_BKGND_TIMER: NativeUInt;
    function getIsScreenLocked: boolean;
  protected
    procedure WMTimer(var Msg: TWMTimer); message WM_TIMER;

    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMActivate(var Message: TWMActivate); message WM_ACTIVATE;
    procedure CMChildKey(var Message: TCMChildKey); message CM_CHILDKEY;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    procedure WMGetMinMaxInfo(var AMsg: TWMGetMinMaxInfo); message WM_GETMINMAXINFO;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure InitializeNewForm;override;

    procedure inner_ShowLock(p_X, p_Y, p_Width, p_Height: integer);
    procedure inner_CloseLock();
    function calcPosition(CenterForm: TCustomForm): TPoint;

    procedure startEraseBkgndTimer();
    procedure stopEraseBkgndTimer();
  public
    procedure ShowLock(p_X, p_Y, p_Width, p_Height: integer);overload;
    procedure ShowLock();overload;
    procedure CloseLock;

    procedure EraseBkgnd(Canvas: TCanvas; Params: TojScreenLockParams);
    procedure EraseBkgnd_gradient(Canvas: TCanvas; Params: TojScreenLockParams);

    destructor Destroy;override;
  published
    property IsScreenLocked: boolean read getIsScreenLocked;
    property Params: TojScreenLockParams read FParams;
  end;


  IojScreenLock = interface['{70E5B6BA-0D5F-492A-96B4-D7E60B41FAF6}']
    function getName: string;
    procedure setName(const Value: string);
    function getCaption: string;
    procedure setCaption(const Value: string);
    function getText: string;
    procedure setText(const Value: string);

    function RefCount:integer;
    procedure LockScreen;
    procedure UnLockScreen;
    function LockCount: integer;
    function LockObjCount: integer;
    function IsLockActive: boolean;
    function Form: TCustomForm;
    function Params: TojScreenLockParams;
    function CreateChild: IojScreenLock;

    property Name: string read getName write setName;
    property Caption: string read getCaption write setCaption;
    property Text: string read getText write setText;

    procedure execThreadTask(const ThreadProc: TProc);
  end;

  TojScreenLock = class(TInterfacedObject, IojScreenLock)
  private
    class var ScreenLock: IojScreenLock;
  private
    FName: string;
    function getName: string;
    procedure setName(const Value: string);
    function getCaption: string;
    function getText: string;
    procedure setCaption(const Value: string);
    procedure setText(const Value: string);
  type
    TojSharedData = class(TObject)
    public
      ScreenLockForm: TojCustomScreenLockForm;
      Pociotki: TObjectList<TojScreenLock>;
      CalledLock: TObjectList<TojScreenLock>;
      constructor Create;
      destructor Destroy;override;
    end;
  protected
    FSharedData: TojSharedData;
    function NeedScreenLockForm: TojCustomScreenLockForm;

    //  procedure IojScreenLock.LockScreen = LockScreen;
    function RefCount:integer;
    procedure LockScreen;
    procedure UnLockScreen;

    function LockCount: integer;
    function LockObjCount: integer;
    function IsLockActive: boolean;
    function Form: TCustomForm;
    function Params: TojScreenLockParams;
    function CreateChild: IojScreenLock;

    procedure execThreadTask(const ThreadProc: TProc);

    property Name: string read getName write setName;
    property Caption: string read getCaption write setCaption;
    property Text: string read getText write setText;
  protected
    constructor CreateNew(p_ScreenLock: TojScreenLock = nil);virtual;
  public
    destructor Destroy;override;
  public
    class function Create(p_Caption: string = ''; p_Text: string = ''; p_LockScreen:boolean = TRUE): IojScreenLock;
    class function getLock(p_Text: string = ''): IojScreenLock;
  end;


implementation
uses  math, Vcl.GraphUtil, System.UITypes;


{ TojScreenLockParams }

constructor TojScreenLockParams.Create(p_Owner: TojCustomScreenLockForm);
begin
  inherited Create;
  FOwner:= p_Owner;
  FShowDropShadow:= FALSE;
  FShowBorder:= TRUE;
  FAllowResize:= TRUE;
  FAllowMove:= TRUE;
  FCloseOnALT_F4:= FALSE;

  FWidth:= 450;
  FHeight:= 130;

  FCheckMinSize:= TRUE;
  FCheckMaxSize:= TRUE;
  FMinWidth:= 350;
  FMinHeight:= 120;
  FMaxWidth:= 450;
  FMaxHeight:= 200;

  FCaption:= 'Proszê czekaæ';
  FText:= '';
  FTextHAlign:= TAlignment.taLeftJustify;
  FTextVAlign:= TVerticalAlignment.taVerticalCenter;


  //FLockStart:= 0.0;
  FLockStartTime:= 0.0;

  FEraseBkgndProc:= nil;
  FGradientProfile:= gpInfo;
  ShowMemoryUsage:= FALSE;
end;


function TojScreenLockParams.GetOwner: TPersistent;
begin
  result:= FOwner;
end;

function TojScreenLockParams.Owner: TojCustomScreenLockForm;
begin
  result:= FOwner;
end;

procedure TojScreenLockParams.ParamsChanged;
begin
  if (Owner <> nil) AND Owner.IsScreenLocked
  then Owner.Invalidate;
end;

procedure TojScreenLockParams.setAllowMove(const Value: boolean);
begin
  if FAllowMove <> Value then
  begin
    FAllowMove:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setAllowResize(const Value: boolean);
begin
  if FAllowResize <> Value then
  begin
    FAllowResize:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setCaption(const Value: string);
begin
  if FCaption <> Value then
  begin
    FCaption:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setCheckMaxSize(const Value: boolean);
begin
  if FCheckMaxSize <> Value then
  begin
    FCheckMaxSize:= Value;

    if FCheckMaxSize then
    begin
      FWidth:= Min(FMaxWidth, FWidth);
      FHeight:= Min(FMaxHeight, FHeight);
    end;

    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setCheckMinSize(const Value: boolean);
begin
  if FCheckMinSize <> Value then
  begin
    FCheckMinSize:= Value;

    if FCheckMinSize then
    begin
      FWidth:= Max(FMinWidth, FWidth);
      FHeight:= Max(FMinHeight, FHeight);
    end;

    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setCloseOnALT_F4(const Value: boolean);
begin
  if FCloseOnALT_F4 <> Value then
  begin
    FCloseOnALT_F4:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setEraseBkgndProc(const Value: TojEraseBkgndProc);
begin
  if TMethod(FEraseBkgndProc) <> TMethod(Value) then
  begin
    FEraseBkgndProc:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setGradientProfile(const Value: TojGradientProfile);
begin
  if FGradientProfile <> Value then
  begin
    FGradientProfile:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setHeight(const Value: integer);
var v_value: integer;
begin
  if FHeight <> Value then
  begin
    v_value:= Value;
    if FCheckMinSize then v_value:= Max(v_value, FMinHeight);
    if FCheckMaxSize then v_value:= Min(v_value, FMaxHeight);

    FHeight:= v_value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setLockStartTime(const Value: TDateTime);
begin
  if FLockStartTime <> Value then
  begin
    FLockStartTime:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setMaxHeight(const Value: integer);
begin
  if FMaxHeight <> Value then
  begin
    FMaxHeight:= Value;

    // dopasuj wysokosc
    if FCheckMaxSize
    then FHeight:= Min(FMaxHeight, FHeight);

    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setMaxWidth(const Value: integer);
begin
  if FMaxWidth <> Value then
  begin
    FMaxWidth:= Value;
    // dopasuj szerosc
    if FCheckMaxSize
    then FWidth:= Min(FMaxWidth, FWidth);

    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setMinHeight(const Value: integer);
begin
  if FMinHeight <> Value then
  begin
    FMinHeight:= Value;

    // dopasuj wysokosc
    if FCheckMinSize
    then FHeight:= Max(FMinHeight, FHeight);

    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setMinWidth(const Value: integer);
begin
  if FMinWidth <> Value then
  begin
    FMinWidth:= Value;

    // dopasowac szerokosc
    if FCheckMinSize
    then FWidth:= Max(FMinWidth, FWidth);
    
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setShowBorder(const Value: boolean);
begin
  if FShowBorder <> Value then
  begin
    FShowBorder:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setShowDropShadow(const Value: boolean);
begin
  if FShowDropShadow <> Value then
  begin
    FShowDropShadow:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setShowMemoryUsage(const Value: boolean);
begin
  if FShowMemoryUsage <> Value then
  begin
    FShowMemoryUsage:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setText(const Value: string);
begin
  if FText <> Value then
  begin
    FText:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setTextHAlign(const Value: TAlignment);
begin
  if FTextHAlign <> Value then
  begin
    FTextHAlign:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setTextVAlign(const Value: TVerticalAlignment);
begin
  if FTextVAlign <> Value then
  begin
    FTextVAlign:= Value;
    ParamsChanged;
  end;
end;

procedure TojScreenLockParams.setWidth(const Value: integer);
var v_value: integer;
begin
  if FWidth <> Value then
  begin
    v_value:= Value;
    if FCheckMinSize then v_value:= Max(v_value, FMinWidth);
    if FCheckMaxSize then v_value:= Min(v_value, FMaxWidth);

    FWidth:= v_value;
    ParamsChanged;
  end;
end;



{ TojCustomScreenLockForm }

function TojCustomScreenLockForm.calcPosition(CenterForm: TCustomForm): TPoint;
begin
  //  centrujemy wg okna, g³ownego lub podanego jako paramter
  if not Assigned(CenterForm)
  then CenterForm:= Application.MainForm;

  if Assigned(CenterForm) and (CenterForm <> self) then
  begin
    result.X:= ((CenterForm.Width - Width) div 2) + CenterForm.Left;
    result.Y:= ((CenterForm.Height - Height) div 2) + CenterForm.Top;
  end
  else
  begin
    result.X:= (Screen.Width - Width) div 2;
    result.Y:= (Screen.Height - Height) div 2;
  end;
  if result.X < Screen.DesktopLeft then
    result.X:= Screen.DesktopLeft;
  if result.Y < Screen.DesktopTop then
    result.Y:= Screen.DesktopTop;
end;

procedure TojCustomScreenLockForm.CloseLock;
begin
  inner_CloseLock();
end;

procedure TojCustomScreenLockForm.CMChildKey(var Message: TCMChildKey);
begin
  // Alt+F4 nie zamyka okna
  if (Message.CharCode = VK_F4) then
  begin
    if HiWord(GetKeyState(VK_LMENU)) <> 0 then
    begin
      Message.Result:= 1;
      Message.CharCode:= 0; // blokujemy zawsze,
      if FParams.CloseOnALT_F4
      then inner_CloseLock();
    end;
  end;

  //  Escape nie zamyka okna
  if (Message.CharCode = VK_ESCAPE) then
  begin
    Message.Result:= 1;
  end;
end;


procedure TojCustomScreenLockForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);

  if self.FParams.ShowDropShadow then
    Params.WindowClass.style:= Params.WindowClass.style OR CS_DROPSHADOW;

  if self.FParams.ShowBorder then
    Params.Style:= Params.Style OR WS_BORDER;

  //  niebeiska belka wokol dla Win7 dla 10 jest biala belka na gorze
  //  robimy recznie machlojk¹ w NCHITTEST
  //  if self.FParams.ShowSizeBox then
  //    Params.Style:= Params.Style OR WS_SIZEBOX { OR WS_THICKFRAME};

  //  if (TCustomBCEditor(FEditor).DoubleBuffered and not (csDesigning in ComponentState)) then
  //    Params.ExStyle := Params.ExStyle or WS_EX_COMPOSITED;
end;

destructor TojCustomScreenLockForm.Destroy;
begin
  if IsScreenLocked then CloseLock;
  FreeAndNil(FParams);
  inherited;
end;


function GetMemoryUsed: UInt64;
var
  st: TMemoryManagerState;
  sb: TSmallBlockTypeState;
begin
  GetMemoryManagerState(st);
  result :=  st.TotalAllocatedMediumBlockSize +
           + st.TotalAllocatedLargeBlockSize;
  for sb in st.SmallBlockTypeStates do begin
    result := result + sb.UseableBlockSize * sb.AllocatedBlockCount;
  end;
end;




function RefreshSnapShot: string;
var
  LInd: integer;
  LAllocatedSize, LTotalBlocks, LTotalAllocated, LTotalReserved: Cardinal;

  FMemoryManagerState: TMemoryManagerState;
  FMemoryMap: TMemoryMap;
begin
  result:= '';
  {Get the state}
  GetMemoryManagerState(FMemoryManagerState);
  GetMemoryMap(FMemoryMap);

  result:=
    format('LTotalBlocks = %d%s', [LTotalBlocks, sLineBreak]) +
    format('LTotalAllocated = %d%s', [LTotalAllocated, sLineBreak]) +
    format('LTotalReserved = %d%s', [LTotalReserved, sLineBreak]);

  if LTotalReserved > 0
  then result:= result +FormatFloat('XXXX = 0.##%', LTotalAllocated/LTotalReserved * 100);
end;


function CsiGetProcessMemory: Int64;
var
  lMemoryCounters: TProcessMemoryCounters;
  lSize: Integer;
begin
  lSize := SizeOf(lMemoryCounters);
  FillChar(lMemoryCounters, lSize, 0);
  if GetProcessMemoryInfo(GetCurrentProcess, @lMemoryCounters, lSize) then
    Result := lMemoryCounters.PageFileUsage
  else
    Result := 0;

end;

procedure TojCustomScreenLockForm.EraseBkgnd(Canvas: TCanvas; Params: TojScreenLockParams);
var v_rect, v_caption_rect, v_text_rect, v_time_rect, v_temp_rect: TRect;
    v_text: string;
    v_height: integer;
    v_buffer: TBitmap;
    v_canvas: TCanvas;

    FMemoryManagerState: TMemoryManagerState;
    v_MemoryCounters: TProcessMemoryCounters;
    v_Size: integer;

    v_flags: TTextFormat;
const CNST_MARGIN = 5;
begin
  v_rect:= Params.Owner.ClientRect;

  //  lub wynies buffer do WM_ERASEBCK
  v_buffer:= TBitmap.Create;
  try
    v_buffer.SetSize(v_rect.Width, v_rect.Height);
    v_canvas:= v_buffer.Canvas;
    v_canvas.Font.Assign(Canvas.Font);
    //  v_canvas.Assign(Canvas);  //???

    GradientFillCanvas(v_canvas,
        Params._GradientProfile[Params.GradientProfile].StartColor,
        Params._GradientProfile[Params.GradientProfile].EndColor,
        v_rect, gdVertical);

    // lock time
    if Params.LockStartTime <> 0.0 then
    begin
      v_canvas.Brush.Style:= bsClear;
      v_canvas.Font.Style:= v_canvas.Font.Style + [fsBold];
      v_text:= TimeToStr(Now() - Params.LockStartTime);

      v_time_rect:= Params.Owner.ClientRect;
      v_time_rect.Top:= v_time_rect.Top + CNST_MARGIN;
      v_time_rect.Right:= v_time_rect.Right - CNST_MARGIN;
      v_time_rect.Left:= v_time_rect.Right - v_canvas.TextWidth(v_text);
      v_time_rect.Bottom:= v_time_rect.Top + v_canvas.TextHeight(v_text);

      v_canvas.TextRect(v_time_rect, v_text, [tfSingleLine, tfEndEllipsis, tfRight, tfVerticalCenter]);
    end;

    // caption
    if Params.Caption <> '' then
    begin
      v_canvas.Brush.Style:= bsClear;
      v_canvas.Font.Style:= v_canvas.Font.Style + [fsBold];
      v_caption_rect:= Params.Owner.ClientRect;
      v_caption_rect.Top:= v_caption_rect.Top + CNST_MARGIN;
      v_caption_rect.Left:= v_caption_rect.Left + CNST_MARGIN;
      v_caption_rect.Bottom:= v_caption_rect.Top + v_canvas.TextHeight(Params.Caption);

      if Params.LockStartTime = 0.0
      then v_caption_rect.Right:= v_caption_rect.Right - CNST_MARGIN
      else v_caption_rect.Right:= v_time_rect.Left - CNST_MARGIN;

      v_text:= Params.Caption;
      v_canvas.TextRect(v_caption_rect, v_text, [tfSingleLine, tfEndEllipsis, tfLeft, tfVerticalCenter]);
    end;

    // opis
    if (Params.Text <> '') AND not Params.ShowMemoryUsage then
    begin
      v_canvas.Brush.Style:= bsClear;
      v_canvas.Font.Style:= v_canvas.Font.Style - [fsBold];

      v_text_rect:= Params.Owner.ClientRect;
      v_text_rect.Left:= v_text_rect.Left + CNST_MARGIN;
      v_text_rect.Right:= v_text_rect.Right - CNST_MARGIN;
      v_text_rect.Bottom:= v_text_rect.Bottom - CNST_MARGIN;

      if (Params.Caption <> '')
      then v_text_rect.Top:= MAX(v_text_rect.Top, v_caption_rect.Bottom);

      if (Params.LockStartTime <> 0.0)
      then v_text_rect.Top:= MAX(v_text_rect.Top, v_time_rect.Bottom);

      v_text_rect.Top:= v_text_rect.Top + CNST_MARGIN;
      v_text:= Params.Text;

      v_flags:= [tfWordBreak, tfEndEllipsis];
      case Params.TextHAlign of
        taLeftJustify: v_flags:= v_flags + [tfLeft];
        taRightJustify: v_flags:= v_flags + [tfRight];
        taCenter: v_flags:= v_flags + [tfCenter];
      end;

      case Params.TextVAlign of
        taAlignTop: v_flags:= v_flags + [tfTop];
        taAlignBottom: v_flags:= v_flags + [tfBottom];
        taVerticalCenter: v_flags:= v_flags + [tfVerticalCenter];
      end;

      //  v_canvas.Brush.Color:= clLime;
      //  v_canvas.Brush.Style:= bsSolid;
      //  v_canvas.DrawFocusRect(v_text_rect);

      //  v_text_rect w tym obszarze mamy sie zmieœcic
      //  v_temp_rect w tym obszarze miesci sie text ale przycinamy jego wysokosc i szerokosc
      v_temp_rect:= TRect.Create(0, 0, v_text_rect.Width, v_text_rect.Height);
      v_canvas.TextRect(v_temp_rect, v_text, v_flags + [tfCalcRect]);
      v_temp_rect.Height:= Min(v_temp_rect.Height, v_text_rect.Height);
      v_temp_rect.Width:= v_text_rect.Width;

      // przesuwamy w zale¿noœci od VAlignment
      case Params.TextVAlign of
        taAlignTop: v_temp_rect.Offset(v_text_rect.Left + (v_text_rect.width - v_temp_rect.Width) div 2,
                                       v_text_rect.Top);
        taAlignBottom: v_temp_rect.Offset(v_text_rect.Left + (v_text_rect.width - v_temp_rect.Width) div 2,
                                          v_text_rect.Top + (v_text_rect.height - v_temp_rect.Height));
        taVerticalCenter: v_temp_rect.Offset(v_text_rect.Left + (v_text_rect.width - v_temp_rect.Width) div 2,
                                             v_text_rect.Top + (v_text_rect.height - v_temp_rect.Height) div 2);
      end;

      v_canvas.Brush.Style:= bsClear;
      v_canvas.TextRect(v_temp_rect, v_text, v_flags);
    end;

    if Params.ShowMemoryUsage then
    begin
      v_canvas.Brush.Style:= bsClear;
      v_canvas.Font.Style:= v_canvas.Font.Style - [fsBold];

      v_text_rect:= Params.Owner.ClientRect;
      v_text_rect.Left:= v_text_rect.Left + CNST_MARGIN;
      v_text_rect.Right:= v_text_rect.Right - CNST_MARGIN;
      v_text_rect.Bottom:= v_text_rect.Bottom - CNST_MARGIN;

      if (Params.Caption <> '')
      then v_text_rect.Top:= MAX(v_text_rect.Top, v_caption_rect.Bottom);

      if (Params.LockStartTime <> 0.0)
      then v_text_rect.Top:= MAX(v_text_rect.Top, v_time_rect.Bottom);

      v_text_rect.Top:= v_text_rect.Top + CNST_MARGIN;

      GetMemoryManagerState(FMemoryManagerState);
      v_text:= format(
          'AllocatedMediumBlockCount = %d%s'+
          'TotalAllocatedMediumBlockSize = %d%s'+
          'ReservedMediumBlockAddressSpace = %d%s'+
          'AllocatedLargeBlockCount = %d%s'+
          'TotalAllocatedLargeBlockSize = %d%s'+
          'ReservedLargeBlockAddressSpace = %d%s',

          [FMemoryManagerState.AllocatedMediumBlockCount, sLineBreak,
           FMemoryManagerState.TotalAllocatedMediumBlockSize, sLineBreak,
           FMemoryManagerState.ReservedMediumBlockAddressSpace, sLineBreak,
           FMemoryManagerState.AllocatedLargeBlockCount, sLineBreak,
           FMemoryManagerState.TotalAllocatedLargeBlockSize, sLineBreak,
           FMemoryManagerState.ReservedLargeBlockAddressSpace, sLineBreak
          ]);


      v_text:= RefreshSnapShot;


      v_Size := SizeOf(v_MemoryCounters);
      FillChar(v_MemoryCounters, v_Size, 0);
      if GetProcessMemoryInfo(GetCurrentProcess, @v_MemoryCounters, v_Size) then
      v_text:= format(
          'WorkingSetSize = %d%s'+
          'PeakWorkingSetSize = %d%s'+
          'PagefileUsage = %d%s'+
          'PeakPagefileUsage = %d%s',

          [v_MemoryCounters.WorkingSetSize, sLineBreak,
           v_MemoryCounters.PeakWorkingSetSize, sLineBreak,
           v_MemoryCounters.PagefileUsage, sLineBreak,
           v_MemoryCounters.PeakPagefileUsage, sLineBreak
          ]);

      v_canvas.TextRect(v_text_rect, v_text, [tfWordBreak, tfEndEllipsis, tfLeft, tfVerticalCenter]);
    end;

    Canvas.CopyRect(v_rect, v_canvas, v_rect);
  finally
    FreeAndNil(v_buffer);
  end;

end;

procedure TojCustomScreenLockForm.EraseBkgnd_gradient(Canvas: TCanvas; Params: TojScreenLockParams);
var v_rect: TRect;
    v_buffer: TBitmap;
    v_canvas: TCanvas;
const CNST_MARGIN = 5;
begin
  v_rect:= Params.Owner.ClientRect;
  v_buffer:= TBitmap.Create;
  try
    v_buffer.SetSize(v_rect.Width, v_rect.Height);
    v_canvas:= v_buffer.Canvas;

    GradientFillCanvas(v_canvas,
        Params._GradientProfile[Params.GradientProfile].StartColor,
        Params._GradientProfile[Params.GradientProfile].EndColor,
        v_rect, gdVertical);

    Canvas.CopyRect(v_rect, v_canvas, v_rect);
  finally
    FreeAndNil(v_buffer);
  end;
end;

function TojCustomScreenLockForm.getIsScreenLocked: boolean;
begin
  result:= (self.Visible);
end;

procedure TojCustomScreenLockForm.InitializeNewForm;
begin
  inherited;
  FPrevActiveWindow:= 0;
  FIsShowingLock:= FALSE;
  FIsClosingLock:= FALSE;
  FParams:= TojScreenLockParams.Create(self);

  Visible:= FALSE;
  BorderStyle:= bsNone;
  BorderWidth:= 0;
  Position:= poOwnerFormCenter;
  self.KeyPreview:= TRUE;
  //  fsStayOnTop stawarza problemy przy minimalizacji, przez klikniecie na pasek zadan
  //  FormStyle:= fsStayOnTop;

  self.Width:= FParams.Width;
  self.Height:= FParams.Height;

  CNST_ERASE_BKGND_TIMER:= 1599;
end;


procedure TojCustomScreenLockForm.inner_CloseLock;
begin
  if not IsScreenLocked then Exit;
  if FIsClosingLock then Exit;

  FIsClosingLock:= TRUE;
  try

    if self.WindowState in [wsNormal, wsMinimized, wsMaximized]
    then getTime;

    //  before close itp
    if GetCapture <> 0
    then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);

    ReleaseCapture;

    if self.WindowState in [wsNormal, wsMinimized, wsMaximized]
    then getTime;

    if not self.Visible
    then getTime;

    EnableWindow(FPrevActiveWindow, TRUE);
    FPrevActiveWindow:= 0;

    if not self.Visible
    then getTime;

    Hide;

    self.Params.LockStartTime:= 0.0;
  finally
    FIsClosingLock:= FALSE;
    self.stopEraseBkgndTimer;
  end;

end;

procedure TojCustomScreenLockForm.inner_ShowLock(p_X, p_Y, p_Width, p_Height: integer);
var v_width, v_height: integer;
begin
  if IsScreenLocked then Exit;
  if FIsShowingLock then Exit;

  FIsShowingLock:= TRUE;
  try
    //  GetParentForm
    if Assigned(Screen.ActiveCustomForm)
    then FPrevActiveWindow:= Screen.ActiveCustomForm.Handle
    else FPrevActiveWindow:= Application.MainFormHandle;

    if GetCapture <> 0
    then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);

    ReleaseCapture;

    //  nowy drop down parametry mogly sie zmienic, wiec robimy ReCreate
    if self.HandleAllocated AND not (csDesigning in self.ComponentState) then
      RecreateWnd;

    v_width:= p_Width;
    v_height:= p_Height;
    if FParams.CheckMinSize then
    begin
      v_width:= Max(v_width, FParams.MinWidth);
      v_height:= Max(v_height, FParams.MinHeight);
    end;

    if FParams.CheckMaxSize then
    begin
      v_width:= Min(v_width, FParams.MaxWidth);
      v_height:= Min(v_height, FParams.MaxHeight);
    end;

    self.SetBounds(p_X, p_Y, v_width, v_height);
    //self.PopupParent:= GetParentForm(self);

    // zeby mialo sie co odrysowac
    //  self.Params.LockStart:= Time(); // ????   :(
    self.Params.LockStartTime:= Now;

    Show;

    EnableWindow(FPrevActiveWindow, FALSE);
    SendMessage(FPrevActiveWindow, WM_NCACTIVATE, 1, 0);
    BringToFront;

    self.Paint;
    Application.ProcessMessages;
  finally
    FIsShowingLock:= FALSE;
    self.startEraseBkgndTimer;
  end;
end;


procedure TojCustomScreenLockForm.ShowLock;
var v_pkt: TPoint;
begin
  v_pkt:= calcPosition(nil);
  inner_ShowLock(v_pkt.X, v_pkt.Y, self.Params.Width, self.Params.Height);
end;

procedure TojCustomScreenLockForm.startEraseBkgndTimer;
begin
  SetTimer(self.Handle, CNST_ERASE_BKGND_TIMER, 1000, nil);
end;

procedure TojCustomScreenLockForm.stopEraseBkgndTimer;
begin
  KillTimer(self.Handle, CNST_ERASE_BKGND_TIMER);
end;

procedure TojCustomScreenLockForm.ShowLock(p_X, p_Y, p_Width, p_Height: integer);
begin
  inner_ShowLock(p_X, p_Y, p_Width, p_Height);
end;

procedure TojCustomScreenLockForm.WMActivate(var Message: TWMActivate);
begin
  inherited;
end;

procedure TojCustomScreenLockForm.WMEraseBkgnd(var Message: TWmEraseBkgnd);
var v_canvas: TControlCanvas;
begin
  //  inherited;
  //  Message.Result:= 0; //  nic nie dotykamy, odpali sie standardowe rysowanie

  v_canvas:= TControlCanvas.Create;
  try
    v_canvas.Control:= self;

    if Assigned(FParams.EraseBkgndProc)
    then FParams.EraseBkgndProc(v_canvas, self.FParams)

    else EraseBkgnd(v_canvas, self.FParams);

    Message.Result:= 1;   //  dotkneliœmy czyli zrobilimy wlasne malowanie
  finally
    FreeAndNil(v_canvas);
  end;

end;

procedure TojCustomScreenLockForm.WMGetMinMaxInfo(var AMsg: TWMGetMinMaxInfo);
var v_mmi: PMinMaxInfo;
begin
  inherited;

  v_mmi:= AMsg.MinMaxInfo;

  if Params.CheckMinSize then
  begin
    v_mmi.ptMinTrackSize.X:= Max(v_mmi.ptMinTrackSize.X, Params.MinWidth);
    v_mmi.ptMinTrackSize.Y:= Max(v_mmi.ptMinTrackSize.Y, Params.MinHeight);
  end;

  if Params.CheckMaxSize then
  begin
    v_mmi.ptMaxTrackSize.X:= Min(v_mmi.ptMaxTrackSize.X, Params.MaxWidth);
    v_mmi.ptMaxTrackSize.Y:= Min(v_mmi.ptMaxTrackSize.Y, Params.MaxHeight);
  end;
end;

procedure TojCustomScreenLockForm.WMNCHitTest(var Msg: TWMNCHitTest);
var v_delta: TRect;
    v_cx, v_cy: Integer;
begin
  inherited;

  if FParams.FAllowResize then
  with Msg, v_delta do
  begin
    v_cx:= GetSystemMetrics(SM_CXSIZEFRAME);
    v_cy:= GetSystemMetrics(SM_CYSIZEFRAME);

    Left:= XPos - BoundsRect.Left;
    Right:= BoundsRect.Right - XPos;
    Top:= YPos - BoundsRect.Top;
    Bottom:= BoundsRect.Bottom - YPos;

    if (Top < v_cy) AND (Left < v_cx) then
      result:= HTTOPLEFT
    else if (Top < v_cy) AND (Right < v_cx) then
      result:= HTTOPRIGHT
    else if (Bottom < v_cy) AND (Left < v_cx) then
      result:= HTBOTTOMLEFT
    else if (Bottom < v_cy) AND (Right < v_cx) then
      result:= HTBOTTOMRIGHT
    else if (Top < v_cy) then
      result:= HTTOP
    else if (Left < v_cx) then
      result:= HTLEFT
    else if (Bottom < v_cy) then
      result:= HTBOTTOM
    else if (Right < v_cx) then
      result:= HTRIGHT;
  end;

  // nie gryzie sie z FParams.FShowSizeBox
  if self.FParams.AllowMove AND (Msg.Result = htClient)
  then Msg.Result:= htCaption;

end;

procedure TojCustomScreenLockForm.WMTimer(var Msg: TWMTimer);
begin
  if Msg.TimerID = CNST_ERASE_BKGND_TIMER
  then self.Invalidate
  else inherited;
end;

{ TojScreenLock }

constructor TojScreenLock.CreateNew(p_ScreenLock: TojScreenLock);
begin
  inherited Create;
  FName:= '';

  if Assigned(p_ScreenLock) then
  begin
    FSharedData:= p_ScreenLock.FSharedData;
    FSharedData.Pociotki.Add( self );
  end
  else
  begin
    FSharedData:= TojSharedData.Create;
    FSharedData.Pociotki.Add( self );
  end;

end;

class function TojScreenLock.Create(p_Caption, p_Text: string; p_LockScreen:boolean): IojScreenLock;
begin
  //  jesli istnieje TYLKO 1 obiekt sterujacy
  if Assigned(TojScreenLock.ScreenLock) AND (TojScreenLock.ScreenLock.LockObjCount = 1)
  then TojScreenLock.ScreenLock:= nil;

  if not Assigned(TojScreenLock.ScreenLock) then 
  begin
    TojScreenLock.ScreenLock:= TojScreenLock.CreateNew(nil);
    TojScreenLock.ScreenLock.Name:= 'ROOT';
  end;

  //  zawsze zwracamy childa\pociotka,
  result:= TojScreenLock.ScreenLock.CreateChild;

  if p_Caption <> '' then result.Caption:= p_Caption;
  if p_Text <> '' then result.Text:= p_Text;
  if p_LockScreen then result.LockScreen;
end;                                                   

function TojScreenLock.CreateChild: IojScreenLock;
begin
  result:= TojScreenLock.CreateNew(self);
end;

destructor TojScreenLock.Destroy;
begin
  if self.Name = 'ROOT' 
  then GetTime;
  
  self.UnLockScreen;
  FSharedData.Pociotki.Remove(self);

  if FSharedData.Pociotki.Count = 0
  then FreeAndNil(FSharedData);

  inherited;
end;

procedure TojScreenLock.execThreadTask(const ThreadProc: TProc);
var v_th: TThread;
    v_exception: Exception;
const CNST_LOCAL_TIMEOUT = 25;
begin

  v_th:= TThread.CreateAnonymousThread(ThreadProc);
  try
    v_th.FreeOnTerminate:= FALSE;
    v_th.Start;
    while not v_th.Finished do
    begin
      WaitForSingleObject(v_th.Handle, CNST_LOCAL_TIMEOUT);
      Application.ProcessMessages;
    end;
    if v_th.Finished
    then getTime;

    if Assigned(v_th.FatalException) then
    begin
      v_exception:= ExceptClass(v_th.FatalException.ClassType).Create('');
      v_exception.Message:= Exception(v_th.FatalException).Message;
      raise v_exception;
    end;

  finally
    FreeAndNil(v_th)
  end;
end;

function TojScreenLock.Form: TCustomForm;
begin
  result:= FSharedData.ScreenLockForm;
end;

function TojScreenLock.getCaption: string;
begin
  result:= NeedScreenLockForm.Params.Caption;
end;

class function TojScreenLock.getLock(p_Text: string): IojScreenLock;
begin
  result:= TojScreenLock.Create('', p_Text, TRUE);
end;

function TojScreenLock.getName: string;
begin
  result:= FName;
end;

function TojScreenLock.getText: string;
begin
  result:= NeedScreenLockForm.Params.Text;
end;

function TojScreenLock.IsLockActive: boolean;
begin
  result:= Assigned(FSharedData.ScreenLockForm)
      AND FSharedData.ScreenLockForm.IsScreenLocked;
end;

function TojScreenLock.LockCount: integer;
begin
  result:= FSharedData.CalledLock.Count;
end;

function TojScreenLock.LockObjCount: integer;
begin
  result:= FSharedData.Pociotki.Count;
end;

procedure TojScreenLock.LockScreen;
begin
  if FSharedData.CalledLock.IndexOf(self) >= 0
  then Exit;

  NeedScreenLockForm;

  FSharedData.CalledLock.Add( self );

  if not FSharedData.ScreenLockForm.IsScreenLocked
  then FSharedData.ScreenLockForm.ShowLock;
end;

function TojScreenLock.NeedScreenLockForm: TojCustomScreenLockForm;
begin
  if FSharedData.ScreenLockForm = nil
  then FSharedData.ScreenLockForm:= TojCustomScreenLockForm.CreateNew(nil);

  result:= FSharedData.ScreenLockForm;
end;

function TojScreenLock.Params: TojScreenLockParams;
begin
  if Assigned(FSharedData.ScreenLockForm)
  then result:= FSharedData.ScreenLockForm.Params
  else result:= nil;
end;

function TojScreenLock.RefCount: integer;
begin
  result:= inherited RefCount;
end;

procedure TojScreenLock.setCaption(const Value: string);
begin
  with NeedScreenLockForm do
  begin
    Params.Caption:= Value;
    //  Invalidate; // ew. w paramsach
  end;
end;

procedure TojScreenLock.setName(const Value: string);
begin
  FName:= Value;
end;

procedure TojScreenLock.setText(const Value: string);
begin
  with NeedScreenLockForm do
  begin
    Params.Text:= Value;
    //  Invalidate; // ew. w paramsach
  end;
end;

procedure TojScreenLock.UnLockScreen;
begin
  if FSharedData.CalledLock.IndexOf(self) < 0
  then Exit;

  FSharedData.CalledLock.Remove( self );

  if FSharedData.CalledLock.Count = 0
  then FSharedData.ScreenLockForm.CloseLock;
end;

{ TojScreenLock.TojSharedData }

constructor TojScreenLock.TojSharedData.Create;
begin
  inherited;
  ScreenLockForm:= nil;
  Pociotki:= TObjectList<TojScreenLock>.Create(FALSE);
  CalledLock:= TObjectList<TojScreenLock>.Create(FALSE);
end;

destructor TojScreenLock.TojSharedData.Destroy;
begin
  FreeAndNil(ScreenLockForm);
  FreeAndNil(Pociotki);
  FreeAndNil(CalledLock);

  inherited;
end;

initialization
  TojScreenLock.ScreenLock:= nil;
finalization
  TojScreenLock.ScreenLock:= nil;

end.
