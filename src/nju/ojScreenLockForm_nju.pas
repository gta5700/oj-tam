unit ojScreenLockForm_nju;

interface
uses  classes, Vcl.Forms, System.SysUtils, Vcl.Controls, Winapi.Windows, Vcl.Graphics,
      Winapi.Messages, ojPainter;



type

  TojCustomScreenLockForm = class;
  TojScreenLockParams = class;

  TojScreenLockParams = class(TPersistent)
  private
    FOwner: TojCustomScreenLockForm;
    FShowDropShadow: boolean;
    FShowBorder: boolean;
    FAllowMove: boolean;
    FAllowResize: boolean;
    FCloseOnALT_F4: boolean;
    procedure setShowDropShadow(const Value: boolean);
    procedure setShowBorder(const Value: boolean);
    procedure setAllowMove(const Value: boolean);
    procedure setAllowResize(const Value: boolean);
    procedure setCloseOnALT_F4(const Value: boolean);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(p_Owner: TojCustomScreenLockForm);virtual;
    function Owner: TojCustomScreenLockForm;virtual;
    procedure ParamsChanged; virtual;
  published
    property ShowDropShadow: boolean read FShowDropShadow write setShowDropShadow;
    property ShowBorder: boolean read FShowBorder write setShowBorder;
    property AllowResize: boolean read FAllowResize write setAllowResize;
    property AllowMove: boolean read FAllowMove write setAllowMove;
    //  protected
    property CloseOnALT_F4: boolean read FCloseOnALT_F4 write setCloseOnALT_F4;
  end;

  TojCustomScreenLockForm = class(TCustomForm)
  private
    FParams: TojScreenLockParams;
    FIsShowingLock: boolean;
    FIsClosingLock: boolean;
    FPrevActiveWindow: HWND;
    FDefaultPainter: TojGradientPainter;
    function getIsScreenLocked: boolean;
    procedure setDefaultPainter(const Value: TojGradientPainter);
  protected
    //    procedure WMSysCommand(var Message: TWMSysCommand); message WM_SYSCOMMAND;
    //    procedure WMShowWindow(var Message: TWMShowWindow); message WM_SHOWWINDOW;
    //    procedure WMWindowPosChanged(var Msg: TWMWindowPosChanged); message WM_WINDOWPOSCHANGED;
    //    procedure WMMouseActivate(var Msg: TMessage); message WM_MOUSEACTIVATE;
    //    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCHitTest(var Msg: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMActivate(var Message: TWMActivate); message WM_ACTIVATE;
    procedure CMChildKey(var Message: TCMChildKey); message CM_CHILDKEY;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;

    procedure CreateParams(var Params: TCreateParams); override;
    procedure InitializeNewForm;override;
    procedure inner_ShowLock(p_X, p_Y, p_Width, p_Height: integer);
    procedure inner_CloseLock();
    function calcPosition(CenterForm: TCustomForm): TPoint;
    function createDefaultPainter: TojGradientPainter;
  public
    procedure ShowLock(p_X, p_Y, p_Width, p_Height: integer);overload;
    procedure ShowLock();overload;
    procedure CloseLock;

    destructor Destroy;override;
  published
    property IsScreenLocked: boolean read getIsScreenLocked;
    property Params: TojScreenLockParams read FParams;
    property DefaultPainter: TojGradientPainter read FDefaultPainter write setDefaultPainter;
  end;


implementation
uses Vcl.GraphUtil;

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

procedure TojScreenLockParams.setCloseOnALT_F4(const Value: boolean);
begin
  if FCloseOnALT_F4 <> Value then
  begin
    FCloseOnALT_F4:= Value;
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
  //inherited;
  //EXIT;

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


function TojCustomScreenLockForm.createDefaultPainter: TojGradientPainter;
begin
  result:= TojGradientPainter.Create(self, nil);
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
  FreeAndNil(FDefaultPainter);
  inherited;
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
  FDefaultPainter:= createDefaultPainter();

  Visible:= FALSE;
  BorderStyle:= bsNone;
  BorderWidth:= 0;
  Position:= poOwnerFormCenter;
  self.KeyPreview:= TRUE;
  //  fsStayOnTop stawarza problemy przy minimalizacji, przez klikniecie na pasek zadan
  // FormStyle:= fsStayOnTop;


  self.Width:= 350;
  self.Height:= 120;
end;


procedure TojCustomScreenLockForm.inner_CloseLock;
begin
  if not IsScreenLocked then Exit;
  if FIsClosingLock then Exit;

  FIsClosingLock:= TRUE;
  try
    //  before close itp
    if GetCapture <> 0
    then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);

    ReleaseCapture;

    EnableWindow(FPrevActiveWindow, TRUE);
    FPrevActiveWindow:= 0;
    Hide;
  finally
    FIsClosingLock:= FALSE;
  end;

end;

procedure TojCustomScreenLockForm.inner_ShowLock(p_X, p_Y, p_Width, p_Height: integer);
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

    //  zle parametry
    //  SetWindowPos(self.Handle, HWND_TOPMOST, p_X, p_Y, p_Width, p_Height, SWP_SHOWWINDOW);
    //  self.Visible:= TRUE;

    self.SetBounds(p_X, p_Y, p_Width, p_Height);
    //self.PopupParent:= GetParentForm(self);
    Show;

    EnableWindow(FPrevActiveWindow, FALSE);
    SendMessage(FPrevActiveWindow, WM_NCACTIVATE, 1, 0);
    BringToFront;

    //  Self.DefaultPainter.Invalidate;

    self.Paint;
    Application.ProcessMessages;
  finally
    FIsShowingLock:= FALSE;
  end;
end;

procedure TojCustomScreenLockForm.setDefaultPainter(const Value: TojGradientPainter);
begin
  if (FDefaultPainter <> Value) then
  begin
    FreeAndNil(FDefaultPainter);
    if Assigned(Value)
    then FDefaultPainter:= Value
    else FDefaultPainter:= createDefaultPainter();

    FDefaultPainter.Invalidate;
  end;
end;

procedure TojCustomScreenLockForm.ShowLock;
var v_pkt: TPoint;
begin
  v_pkt:= calcPosition(nil);
  ShowLock(v_pkt.X, v_pkt.Y, self.Width, self.Height);
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
begin
  inherited;
  //Message.Result:= 0; //  nic nie dotykamy, odpali sie standardowe rysowanie
  FDefaultPainter.Invalidate;
  Message.Result:= 1;
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

end.
