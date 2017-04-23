unit ojScreenLock;

interface
uses  Windows, classes, sysUtils, Forms, StdCtrls, Controls, Graphics, messages,
      GraphUtil, Contnrs, DB, Variants, ExtCtrls;

type

  TojScreenLockForm = class(TCustomForm)
  private
    procedure setIsScreenLockActive(const Value: boolean);
  protected
    FDisabledHandle: HWND;
    FIsScreenLockActive: boolean;
    procedure InitializeNewForm; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNCHitTest(var Msg: TWMNCHitTest) ; message WM_NCHitTest;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;

    procedure InnerLockScreen; virtual;
    procedure InnerUnlockScreen; virtual;
    function  UnlockScreenQuery:boolean;virtual;
    procedure DrawBackground; virtual;
  protected
    procedure LockScreen;
    procedure UnlockScreen;
  public
    property IsScreenLockActive: boolean read FIsScreenLockActive write setIsScreenLockActive;
  public
    destructor Destroy;override;
    function CloseQuery: Boolean; override;
  end;


  IojScreenLockContext = interface ['{D835ECCE-BF66-4263-8FD3-A2364B7F958B}']
    function Form: TCustomForm;
    procedure LockScreen;
    procedure UnLockScreen;
    function LockCount:integer;
    function IsLockActive: boolean;

    //  procedure setCaption(Caption: string);
    //  procedure addLog(LogMessage: string);
  end;

  TojCustomLockContext = class(TInterfacedObject, IojScreenLockContext)
  protected
    function Form: TCustomForm;virtual;abstract;
    procedure LockScreen;virtual;abstract;
    procedure UnLockScreen; virtual;abstract;
    function LockCount: integer; virtual;abstract;
    function IsLockActive: boolean; virtual;abstract;
  end;

  TojUserLockContext = class(TojCustomLockContext)
  protected
    FRoot: TojCustomLockContext;
    FCalledLocalLock: boolean;
  protected
    constructor Create(Root: TojCustomLockContext);virtual;
    function Form: TCustomForm;override;
    procedure LockScreen;override;
    procedure UnLockScreen; override;
    function LockCount: integer;override;
    function IsLockActive: boolean; override;
  public
    destructor Destroy;override;
  end;


  //  zapewnia TYLKO dostep do formy i zlicza klikniecia
  TojRootLockContext = class(TojCustomLockContext)
  protected
    FScreenLockForm: TojScreenLockForm;
    FScreenLockCount: integer;
  protected
    constructor Create;virtual;
    function Form: TCustomForm;override;
    procedure LockScreen;override;
    procedure UnLockScreen; override;
    function LockCount: integer;override;
    function IsLockActive: boolean; override;
    function CreateChild: TojCustomLockContext;
  public
    destructor Destroy;override;
  end;

  TojScreenLock = class sealed
  private
    class var FRootContext: TojRootLockContext;
  public
    class function getContext(p_LockScreen: boolean = TRUE; p_Caption: string = ''): IojScreenLockContext;
    class procedure freeContext(p_Context: IojScreenLockContext);
  end;


//  TojRootLockContext = class;
//  TojUserLockContext = class;
//  IojScreenLockContext = interface ['{D835ECCE-BF66-4263-8FD3-A2364B7F958B}']
//    function Form: TCustomForm;
//    procedure LockScreen;
//    procedure UnLockScreen;
//    function LockCount:integer;
//    function IsLockActive: boolean;
//  end;



//  TojScreenLock = class(TInterfacedObject)
//  private
//    class var FScreenLockForm: TojScreenLockForm;
//    class var FScreenLockCount: integer;
//    class var FContextCount: integer;
//  protected
//    class procedure _LockScreen;
//    class procedure _UnLockScreen;
//    class function _LockCount: integer;
//    constructor Create;virtual;
//  public
//    destructor Destroy;override;
//    //class function getContext(p_LockScreen: boolean = TRUE): IojScreenLockContext;
//    class function getContext(p_LockScreen: boolean = TRUE): TojScreenLockContext;
//
//  end;
//
//  IojScreenLockContext = interface ['{4466706D-9910-4FBD-85CB-939B08AB5DB2}']
//    function Form: TCustomForm;
//    procedure LockScreen;
//    procedure UnLockScreen;
//    function LockCount:integer;
//    function LockActive: boolean;
//  end;
//
//  TojScreenLockContext = class(TInterfacedObject, IojScreenLockContext)
//  private
//    FCalledLocalLock: boolean;
//  protected
//    constructor Create;virtual;
//  public
//    function Form: TCustomForm;
//    function LockCount:integer;
//    procedure LockScreen;
//    procedure UnLockScreen;
//    function LockActive: boolean;
//  end;



implementation
uses  Dialogs;

{ TojScreenLockForm }

procedure TojScreenLockForm.UnlockScreen;
begin
  InnerUnlockScreen;
end;

function TojScreenLockForm.UnlockScreenQuery: boolean;
begin
  result:= (not FIsScreenLockActive) OR (csDestroying in self.ComponentState);
end;

function TojScreenLockForm.CloseQuery: Boolean;
begin
  result:= UnlockScreenQuery AND (inherited CloseQuery);
end;

procedure TojScreenLockForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  //  csOpaque
  Params.Style:= Params.Style OR WS_BORDER;
  Params.Style:= Params.Style ; //OR WS_SIZEBOX;  //  niebeiska belka wokó³
end;

destructor TojScreenLockForm.Destroy;
begin
  InnerUnlockScreen;
  inherited;
end;

procedure TojScreenLockForm.DrawBackground;
var v_rect: TRect;
begin
  v_rect:= self.ClientRect;
  //  GradientFillCanvas(self.Canvas, clSkyBlue, clBlack, v_rect, gdVertical);
  //  GradientFillCanvas(self.Canvas, clSkyBlue, clWhite, v_rect, gdVertical);
  GradientFillCanvas(self.Canvas, clWhite, clSkyBlue, v_rect, gdVertical);
end;

procedure TojScreenLockForm.InitializeNewForm;
begin
  inherited;
  FDisabledHandle:= 0;
  FIsScreenLockActive:= FALSE;

  self.BorderStyle:= bsNone;
  self.BorderWidth:= 1;
  self.Color:= clSkyBlue;
  self.DefaultMonitor:= dmDesktop;
  self.Position:= poMainFormCenter;
  self.KeyPreview:= TRUE;

  self.Width:= 350;
  self.Height:= 120;
end;

procedure TojScreenLockForm.InnerLockScreen;
begin
  if FIsScreenLockActive then Exit;

  if Assigned(Screen.ActiveCustomForm)
  then FDisabledHandle:= Screen.ActiveCustomForm.Handle
  else FDisabledHandle:= Application.MainFormHandle;

  if GetCapture <> 0
  then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);

  ReleaseCapture;
  FIsScreenLockActive:= TRUE;
  Show;

  EnableWindow(FDisabledHandle, FALSE);
  SendMessage(FDisabledHandle, WM_NCACTIVATE, 1, 0);

  BringToFront;
  self.Paint;
  Application.ProcessMessages;
end;

procedure TojScreenLockForm.InnerUnlockScreen;
begin
  if not FIsScreenLockActive then Exit;

  if GetCapture <> 0
  then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);

  ReleaseCapture;

  EnableWindow(FDisabledHandle, TRUE);
  FDisabledHandle:= 0;

  FIsScreenLockActive:= FALSE;
  Hide;
end;

procedure TojScreenLockForm.LockScreen;
begin
  InnerLockScreen;
end;

procedure TojScreenLockForm.setIsScreenLockActive(const Value: boolean);
begin
  if FIsScreenLockActive <> Value then
  begin
    if Value then innerLockScreen else innerUnlockScreen;
  end;
end;

procedure TojScreenLockForm.WMEraseBkgnd(var Message: TWmEraseBkgnd);
begin
  DrawBackground;
  Message.Result:= 1;
end;

procedure TojScreenLockForm.WMNCHitTest(var Msg: TWMNCHitTest);
begin
  inherited;
  if Msg.Result = htClient then Msg.Result:= htCaption;
end;


//{ TojScreenLock }
//
//constructor TojScreenLock.Create;
//begin
//  inherited Create;
//  inc(TojScreenLock.FContextCount);
//end;
//
//destructor TojScreenLock.Destroy;
//begin
//  inherited;
//  dec(TojScreenLock.FContextCount);
//end;
//
//class function TojScreenLock.getContext(p_LockScreen: boolean): TojScreenLockContext;
//begin
//  result:= TojScreenLockContext.Create;
//
//  //  zzawsze tworzymy
//  if not Assigned(TojScreenLock.FScreenLockForm)
//  then TojScreenLock.FScreenLockForm:= TojScreenLockForm.CreateNew(nil);
//
//  if p_LockScreen then result.LockScreen;
//end;
//
//class function TojScreenLock._LockCount: integer;
//begin
//  result:= TojScreenLock.FScreenLockCount;
//end;
//
//class procedure TojScreenLock._LockScreen;
//begin
//
//  //  forma ZAWSZE istnieje
//  TojScreenLock.FScreenLockForm.LockScreen;
//  inc(TojScreenLock.FScreenLockCount);
//
////  if Assigned(TojScreenLock.FScreenLockForm)
////  then inc(TojScreenLock.FScreenLockCount)
////  else
////  begin
////    TojScreenLock.FScreenLockForm:= TojScreenLockForm.CreateNew(nil);
////    inc(TojScreenLock.FScreenLockCount);
////    TojScreenLock.FScreenLockForm.LockScreen;
////  end;
//
//end;
//
//class procedure TojScreenLock._UnLockScreen;
//begin
//
//
//    if TojScreenLock.FContextCount = 0 then
//    begin
//      TojScreenLock.FScreenLockForm.Free;
//      TojScreenLock.FScreenLockForm:= nil;
//      TojScreenLock.FScreenLockCount:= 0;
//      TojScreenLock.FContextCount:= 0;
//    end;
//
//
//
//
////  if not Assigned(TojScreenLock.FScreenLockForm) AND (TojScreenLock.FScreenLockCount<>0)
////  then TojScreenLock.FScreenLockCount:= 0;
////
////  if Assigned(TojScreenLock.FScreenLockForm) then
////  begin
////    dec(TojScreenLock.FScreenLockCount);
////
////    if TojScreenLock.FScreenLockCount = 0 then
////    begin
////      TojScreenLock.FScreenLockForm.UnlockScreen;
////      FreeAndNil(TojScreenLock.FScreenLockForm);
////    end;
////  end;
//
//end;
//
//{ TojScreenLockContext }
//
//constructor TojScreenLockContext.Create;
//begin
//  inherited Create;
//  FCalledLocalLock:= FALSE;
//end;
//
//
//function TojScreenLockContext.Form: TCustomForm;
//begin
//  result:= TojScreenLock.FScreenLockForm;
//end;
//
//function TojScreenLockContext.LockActive: boolean;
//begin
//  result:= Assigned(TojScreenLock.FScreenLockForm)
//      AND (TojScreenLock.FScreenLockForm.IsScreenLockActive);
//end;
//
//function TojScreenLockContext.LockCount: integer;
//begin
//  result:= TojScreenLock.FScreenLockCount;
//end;
//
//procedure TojScreenLockContext.LockScreen;
//begin
//  if FCalledLocalLock
//  then raise Exception.Create('TojScreenLockContext.LockScreen -> already Locked');
//
//  TojScreenLock._LockScreen;
//  FCalledLocalLock:= TRUE;
//end;
//
//procedure TojScreenLockContext.UnLockScreen;
//begin
//  if FCalledLocalLock then
//  begin
//    TojScreenLock._UnLockScreen;
//    FCalledLocalLock:= FALSE;
//  end;
//
//end;

{ TojUserLockContext }

constructor TojUserLockContext.Create(Root: TojCustomLockContext);
begin
  inherited Create;
  FRoot:= Root;
  FCalledLocalLock:= FALSE;
end;

destructor TojUserLockContext.Destroy;
begin
  //  zwolnienie locka nie Odblokowywyuje ekranu
  //  trzeba robic recznie
  if FCalledLocalLock then ShowMessage('TojUserLockContext.Destroy -> LocalLock still active');
  inherited;
end;

function TojUserLockContext.Form: TCustomForm;
begin
  result:= FRoot.Form;
end;

function TojUserLockContext.IsLockActive: boolean;
begin
  result:= FRoot.IsLockActive;
end;

function TojUserLockContext.LockCount: integer;
begin
  result:= FRoot.LockCount;
end;

procedure TojUserLockContext.LockScreen;
begin
  if not FCalledLocalLock then
  begin
    FRoot.LockScreen;
    FCalledLocalLock:= TRUE;
  end;
end;

procedure TojUserLockContext.UnLockScreen;
begin
  if FCalledLocalLock then
  begin
    FRoot.UnLockScreen;
    FCalledLocalLock:= FALSE;
  end;
end;

{ TojRootLockContext }

constructor TojRootLockContext.Create;
begin
  inherited Create;
  FScreenLockForm:= TojScreenLockForm.CreateNew(nil);
  FScreenLockCount:= 0;
end;

function TojRootLockContext.CreateChild: TojCustomLockContext;
begin
  result:= TojUserLockContext.Create(self);
end;

destructor TojRootLockContext.Destroy;
begin
  if FScreenLockForm.IsScreenLockActive OR (FScreenLockCount > 0)
  then ShowMessage('TojRootLockContext.Destroy -> ScreenLock still active ');

  FreeAndNil(FScreenLockForm);
  inherited;
end;

function TojRootLockContext.Form: TCustomForm;
begin
  result:= FScreenLockForm;
end;

function TojRootLockContext.IsLockActive: boolean;
begin
  result:= FScreenLockForm.IsScreenLockActive;
end;

function TojRootLockContext.LockCount: integer;
begin
  result:= FScreenLockCount;
end;

procedure TojRootLockContext.LockScreen;
begin
  Inc(FScreenLockCount);
  FScreenLockForm.IsScreenLockActive:= TRUE;
end;

procedure TojRootLockContext.UnLockScreen;
begin
  dec(FScreenLockCount);
  FScreenLockForm.IsScreenLockActive:= (FScreenLockCount > 0);
end;

{ TojScreenLock }

class function TojScreenLock.getContext(p_LockScreen: boolean; p_Caption: string): IojScreenLockContext;
begin
  if not Assigned(TojScreenLock.FRootContext)
  then TojScreenLock.FRootContext:= TojRootLockContext.Create;

  result:= TojScreenLock.FRootContext.CreateChild;

  //  if p_Caption <> '' then result.setCaption(p_Caption);
  if p_LockScreen then result.LockScreen;
end;

initialization
  TojScreenLock.FRootContext:= nil;
finalization
  FreeAndNil(TojScreenLock.FRootContext);
end.
