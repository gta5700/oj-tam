unit ojScreenLock;

interface
uses  Windows, classes, sysUtils, Forms, StdCtrls, Controls, Graphics, messages,
      GraphUtil, Contnrs, DB, Variants, ExtCtrls, types,
      ojUndoOperation;

type

  TojScreenLockForm = class(TCustomForm)
  private
    FDetailText: string;
    FGradientStopColor: TColor;
    FGradientStartColor: TColor;
    procedure setIsScreenLockActive(const Value: boolean);
    procedure setDetailText(const Value: string);
    procedure setGradientStartColor(const Value: TColor);
    procedure setGradientStopColor(const Value: TColor);
  protected
    FDisabledHandle: HWND;
    FIsScreenLockActive: boolean;
    procedure InitializeNewForm; override;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNCHitTest(var Msg: TWMNCHitTest) ; message WM_NCHitTest;
    procedure WMEraseBkgnd(var Message: TWmEraseBkgnd); message WM_ERASEBKGND;
    //  procedure WMTimer(var Message: TWMTimer); message WM_TIMER;

    procedure InnerLockScreen; virtual;
    procedure InnerUnlockScreen; virtual;
    function  UnlockScreenQuery:boolean;virtual;
    procedure DrawBackground; virtual;
  protected
    procedure LockScreen;
    procedure UnlockScreen;
  public
    destructor Destroy;override;
    function CloseQuery: Boolean; override;
  public
    property IsScreenLockActive: boolean read FIsScreenLockActive write setIsScreenLockActive;
    property DetailText: string read FDetailText write setDetailText;
    property GradientStartColor: TColor read FGradientStartColor write setGradientStartColor;
    property GradientStopColor: TColor read FGradientStopColor write setGradientStopColor;
  end;


  IojScreenLockContext = interface ['{D835ECCE-BF66-4263-8FD3-A2364B7F958B}']
    function getName: string;
    procedure setName(const Value: string);
    function getCaption: string;
    procedure setCaption(const Value: string);
    function getHeight: integer;
    procedure setHeight(const Value: integer);
    function getWidth: integer;
    procedure setWidth(const Value: integer);
    function getDetailText: string;
    procedure setDetailText(const Value: string);
    function getGradientStartColor: TColor;
    function getGradientStopColor: TColor;
    procedure setGradientStartColor(const Value: TColor);
    procedure setGradientStopColor(const Value: TColor);

    function Form: TCustomForm;
    procedure LockScreen;
    procedure UnLockScreen;
    function LockCount:integer;
    function IsLockActive: boolean;
    function LockTime: TTime;

    procedure ReleaseContext;
    function _RefCount:integer;

    property Name: string read getName write setName;
    property Caption: string read getCaption write setCaption;
    property Width: integer read getWidth write setWidth;
    property Height: integer read getHeight write setHeight;
    property DetailText: string read getDetailText write setDetailText;
    property GradientStartColor: TColor read getGradientStartColor write setGradientStartColor;
    property GradientStopColor: TColor read getGradientStopColor write setGradientStopColor;
  end;


  TojRootLockContext = class;
  TojUserLockContext = class(TInterfacedObject, IojScreenLockContext)
  protected
    FRoot: TojRootLockContext;
    FUndos: TObjectList;
    FCalledLocalLock: boolean;
    FCalledLocalRelease: boolean;
    FName: string;
  private
    function getName: string;
    procedure setName(const Value: string);
    function getCaption: string;
    procedure setCaption(const Value: string);
    function getHeight: integer;
    function getWidth: integer;
    procedure setHeight(const Value: integer);
    procedure setWidth(const Value: integer);
    function getDetailText: string;
    procedure setDetailText(const Value: string);
    function getGradientStartColor: TColor;
    function getGradientStopColor: TColor;
    procedure setGradientStartColor(const Value: TColor);
    procedure setGradientStopColor(const Value: TColor);
  protected
    constructor Create(Root: TojRootLockContext);virtual;
    function Root: TojRootLockContext;
    function Form: TCustomForm;
    procedure LockScreen;
    procedure UnLockScreen;
    function LockCount: integer;
    function IsLockActive: boolean;
    function LockTime: TTime;

    procedure ReleaseContext;
    function _RefCount:integer;

    procedure UndoAll;
    property Name: string read getName write setName;

    property Caption: string read getCaption write setCaption;
    property Width: integer read getWidth write setWidth;
    property Height: integer read getHeight write setHeight;
    property DetailText: string read getDetailText write setDetailText;

    property GradientStartColor: TColor read getGradientStartColor write setGradientStartColor;
    property GradientStopColor: TColor read getGradientStopColor write setGradientStopColor;
  public
    destructor Destroy;override;
  end;

  TojRootLockContext = class(TInterfacedObject)
  protected
    FScreenLockForm: TojScreenLockForm;
    FScreenLockCount: integer;
    FChildContextList: TList;
    FLockStart: TDateTime;
  protected
    constructor Create;virtual;
    function Form: TCustomForm;
    procedure LockScreen;
    procedure UnLockScreen;
    function LockCount: integer;
    function IsLockActive: boolean;

    function LockTime: TTime;

    function CreateChild: IojScreenLockContext;
    function IsChild(p_Context: IojScreenLockContext): boolean;
    function IsLastChild(p_Context: IojScreenLockContext): boolean;
    procedure RemoveFromChildContextList(p_Context: IojScreenLockContext);
    procedure ReleaseChildContext(p_Context: IojScreenLockContext);
  public
    destructor Destroy;override;
  end;


  TojScreenLock = class sealed
  private
    class var FRootContext: TojRootLockContext;
  public
    class function getContext(p_LockScreen: boolean = TRUE; p_Caption: string = ''): IojScreenLockContext;
  end;


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
  Params.Style:= Params.Style ;//OR WS_SIZEBOX;  //  niebeiska belka wokol
end;

destructor TojScreenLockForm.Destroy;
begin
  InnerUnlockScreen;
  inherited;
end;

procedure TojScreenLockForm.DrawBackground;
var v_rect: TRect;
    v_text_rect: TRect;
    v_string: string;
const CNST_CAPTION_HEIGHT = 25;
      CNST_MARGIN = 10;
begin
  v_rect:= self.ClientRect;

  GradientFillCanvas(self.Canvas, FGradientStartColor, FGradientStopColor, v_rect, gdVertical);

  if self.Caption <> '' then
  begin
    Canvas.Brush.Style:= bsClear;
    v_text_rect:= self.ClientRect;
    v_text_rect.Inflate(-CNST_MARGIN, -CNST_MARGIN);
    v_text_rect.Height:= v_text_rect.Top + CNST_CAPTION_HEIGHT;
    v_string:= self.Caption;
    Canvas.TextRect(v_text_rect, v_string, [tfSingleLine, tfEndEllipsis, tfLeft, tfVerticalCenter]);
  end;

  if self.DetailText <> '' then
  begin
    Canvas.Brush.Style:= bsClear;
    v_text_rect:= self.ClientRect;
    v_text_rect.Inflate(-CNST_MARGIN, -CNST_MARGIN);
    if self.Caption <> ''
    then v_text_rect.Top:= v_text_rect.Top + CNST_CAPTION_HEIGHT + CNST_MARGIN + CNST_MARGIN;

    v_string:= self.DetailText;
    Canvas.TextRect(v_text_rect, v_string, [tfWordBreak, tfLeft, tfTop]);

    Canvas.Brush.Style:= bsSolid;
    Canvas.Brush.Color:= clGrayText;
    v_text_rect.Inflate(CNST_MARGIN div 2, CNST_MARGIN div 2);
    Canvas.FrameRect(v_text_rect);
  end;

end;

procedure TojScreenLockForm.InitializeNewForm;
begin
  inherited;
  FDisabledHandle:= 0;
  FIsScreenLockActive:= FALSE;
  FDetailText:= '';
  FGradientStartColor:= clWhite;
  FGradientStopColor:= clSkyBlue;

  self.BorderStyle:= bsNone;
  self.BorderWidth:= 1;
  self.Color:= clSkyBlue;
  self.DefaultMonitor:= dmDesktop;
  self.Position:= poMainFormCenter;
  self.Position:= poOwnerFormCenter;

  self.KeyPreview:= TRUE;

  self.Width:= 350;
  self.Height:= 120;

  self.Width:= 450;
  self.Height:= 170;
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

procedure TojScreenLockForm.setDetailText(const Value: string);
begin
  if FDetailText <> Value then
  begin
    FDetailText := Value;
    Invalidate;
  end;
end;

procedure TojScreenLockForm.setGradientStartColor(const Value: TColor);
begin
  if FGradientStartColor <> Value then
  begin
    FGradientStartColor:= Value;
    Invalidate;
  end;
end;

procedure TojScreenLockForm.setGradientStopColor(const Value: TColor);
begin
  if FGradientStopColor <> Value then
  begin
    FGradientStopColor:= Value;
    Invalidate;
  end;
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
  Message.Result:= 0;
  //  inherited;
end;

procedure TojScreenLockForm.WMNCHitTest(var Msg: TWMNCHitTest);
begin
  inherited;
  if Msg.Result = htClient then Msg.Result:= htCaption;
end;


{ TojUserLockContext }

constructor TojUserLockContext.Create(Root: TojRootLockContext);
begin
  inherited Create;
  FRoot:= Root;
  FCalledLocalLock:= FALSE;
  FCalledLocalRelease:= FALSE;
  FUndos:= TObjectList.Create(TRUE);
end;

destructor TojUserLockContext.Destroy;
begin
  if FCalledLocalLock then ShowMessage('TojUserLockContext.Destroy -> '+ self.Name +'.LocalLock still active');

  if not FCalledLocalRelease then
  begin
    //  to prevent loop
    ShowMessage('TojUserLockContext.Destroy -> '+ self.Name +' do ForceRelease');
    if self.RefCount = 0 then self._AddRef;
    self.ReleaseContext;
  end;

  FreeAndNil(FUndos);
  inherited;
end;


function TojUserLockContext.Form: TCustomForm;
begin
  result:= Root.Form;
end;

function TojUserLockContext.getCaption: string;
begin
  result:= Root.Form.Caption;
end;

function TojUserLockContext.getDetailText: string;
begin
  result:= TojScreenLockForm(Root.Form).DetailText;
end;

function TojUserLockContext.getGradientStartColor: TColor;
begin
  result:= TojScreenLockForm(Root.Form).GradientStartColor;
end;

function TojUserLockContext.getGradientStopColor: TColor;
begin
  result:= TojScreenLockForm(Root.Form).GradientStopColor;
end;

function TojUserLockContext.getHeight: integer;
begin
  result:= Root.Form.Height;
end;

function TojUserLockContext.getName: string;
begin
  result:= FName;
end;

function TojUserLockContext.getWidth: integer;
begin
  result:= Root.Form.Width;
end;

function TojUserLockContext.IsLockActive: boolean;
begin
  result:= Root.IsLockActive;
end;

function TojUserLockContext.LockCount: integer;
begin
  result:= Root.LockCount;
end;

procedure TojUserLockContext.LockScreen;
begin
  if not FCalledLocalLock then
  begin
    Root.LockScreen;
    FCalledLocalLock:= TRUE;
  end;
end;

function TojUserLockContext.LockTime: TTime;
begin
  result:= Root.LockTime;
end;

procedure TojUserLockContext.ReleaseContext;
begin
  //  babol ??????
  Root.ReleaseChildContext(self);
  UndoAll;
  FCalledLocalRelease:= TRUE;
  FRoot:= nil;
end;

function TojUserLockContext.Root: TojRootLockContext;
begin
  if FCalledLocalRelease AND not Assigned(FRoot)
  then raise Exception.Create('TojUserLockContext.Root -> current context already released');

  result:= FRoot;
end;

procedure TojUserLockContext.setCaption(const Value: string);
var v_undo: TojCustomUndoOperation;
begin
  v_undo:= TojUndoPropertyOperation.Create(Root.Form, 'Caption', Value);
  FUndos.Add(v_undo);
  Root.Form.Invalidate; //  ????
end;

procedure TojUserLockContext.setDetailText(const Value: string);
var v_undo: TojCustomUndoOperation;
begin
  v_undo:= TojUndoPropertyOperation.Create(Root.Form, 'DetailText', Value);
  FUndos.Add(v_undo);
  Root.Form.Invalidate; //  ????
end;

procedure TojUserLockContext.setGradientStartColor(const Value: TColor);
var v_undo: TojCustomUndoOperation;
begin
  v_undo:= TojUndoPropertyOperation.Create(Root.Form, 'GradientStartColor', Value);
  FUndos.Add(v_undo);
  Root.Form.Invalidate; //  ????
end;

procedure TojUserLockContext.setGradientStopColor(const Value: TColor);
var v_undo: TojCustomUndoOperation;
begin
  v_undo:= TojUndoPropertyOperation.Create(Root.Form, 'GradientStopColor', Value);
  FUndos.Add(v_undo);
  Root.Form.Invalidate; //  ????
end;

procedure TojUserLockContext.setHeight(const Value: integer);
var v_undo: TojCustomUndoOperation;
begin
  v_undo:= TojUndoPropertyOperation.Create(Root.Form, 'Height', Value);
  FUndos.Add(v_undo);
  Root.Form.Invalidate; //  ????
end;

procedure TojUserLockContext.setName(const Value: string);
begin
  if FName <> Value then
    FName:= Value;
end;

procedure TojUserLockContext.setWidth(const Value: integer);
var v_undo: TojCustomUndoOperation;
begin
  v_undo:= TojUndoPropertyOperation.Create(Root.Form, 'Width', Value);
  FUndos.Add(v_undo);
  Root.Form.Invalidate; //  ????
end;

procedure TojUserLockContext.UndoAll;
var i:integer;
    v_undo: TojCustomUndoOperation;
begin
  for i:= FUndos.Count-1 downTo 0 do
  begin
    v_undo:= TojCustomUndoOperation(FUndos[i]);
    v_undo.Undo;
    FUndos.Delete(i);
  end;
end;

procedure TojUserLockContext.UnLockScreen;
begin
  if FCalledLocalLock then
  begin
    Root.UnLockScreen;
    FCalledLocalLock:= FALSE;
  end;
end;

function TojUserLockContext._RefCount: integer;
begin
  result:= self.RefCount;
end;

{ TojRootLockContext }

constructor TojRootLockContext.Create;
begin
  inherited Create;
  FScreenLockForm:= TojScreenLockForm.CreateNew(nil);
  FScreenLockCount:= 0;
  FLockStart:= 0.0;

  FChildContextList:= TList.Create;
end;

function TojRootLockContext.CreateChild: IojScreenLockContext;
begin
  result:= TojUserLockContext.Create(self);

  //  weak reference
  FChildContextList.Add(Pointer(result));
end;

destructor TojRootLockContext.Destroy;
begin
  if FScreenLockForm.IsScreenLockActive OR (FScreenLockCount > 0)
  then ShowMessage('TojRootLockContext.Destroy -> ScreenLock still active ');

  FreeAndNil(FScreenLockForm);
  FreeAndNil(FChildContextList);
  inherited;
end;

function TojRootLockContext.Form: TCustomForm;
begin
  result:= FScreenLockForm;
end;

function TojRootLockContext.IsChild(p_Context: IojScreenLockContext): boolean;
begin
  //  weak reference
  result:= (FChildContextList.IndexOf(Pointer(p_Context)) >= 0);
end;

function TojRootLockContext.IsLastChild(p_Context: IojScreenLockContext): boolean;
begin
  //  weak reference
  result:= (FChildContextList.Count > 0)
       AND (FChildContextList.Last = Pointer(p_Context));
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
  if FScreenLockCount = 1 then FLockStart:= Now;
end;

function TojRootLockContext.LockTime: TTime;
begin
  if FLockStart = 0.0
  then result:= 0.0
  else result:= Now - FLockStart;
end;

procedure TojRootLockContext.ReleaseChildContext(p_Context: IojScreenLockContext);
begin

  if not Assigned(p_Context) then
  begin
    ShowMessage('TojRootLockContext.ReleaseChildContext -> Context not assigned');
    Exit;
  end;

  if not IsChild( p_Context ) then
  begin
    ShowMessage('TojRootLockContext.ReleaseChildContext -> Context: '+ p_Context.Name +' is not a valid child');
    Exit;
  end;

  if not IsLastChild(p_Context) then
  begin
    ShowMessage('TojRootLockContext.ReleaseChildContext: '+ p_Context.Name +' -> niepoprawna kolejnosc zwalniania kontextow');
    //  kontynuujemy
  end;

  p_Context.UnLockScreen;
  RemoveFromChildContextList(p_Context);

  //  nie zwalniamy Formy, zeby zachowac, np. wymiar okna zmieniony przez usera
  //  if LockCount( = 0) AND (FChildContext.Count = 0)
  //  then FreeAndNil(TojScreenLock.FRootContext);
end;

procedure TojRootLockContext.RemoveFromChildContextList(p_Context: IojScreenLockContext);
begin
  //  wear reference
  FChildContextList.Remove(Pointer( p_Context ));
end;


procedure TojRootLockContext.UnLockScreen;
begin
  dec(FScreenLockCount);
  FScreenLockForm.IsScreenLockActive:= (FScreenLockCount > 0);
  if FScreenLockCount = 0 then FLockStart:= 0.0;
end;

{ TojScreenLock }

class function TojScreenLock.getContext(p_LockScreen: boolean; p_Caption: string): IojScreenLockContext;
begin
  if not Assigned(TojScreenLock.FRootContext)
  then TojScreenLock.FRootContext:= TojRootLockContext.Create;

  result:= TojScreenLock.FRootContext.CreateChild;
  if p_Caption <> ''
  then result.Caption:= p_Caption;

  //  if p_Caption <> '' then result.setCaption(p_Caption);
  if p_LockScreen then result.LockScreen;
end;

initialization
  TojScreenLock.FRootContext:= nil;
finalization
  FreeAndNil(TojScreenLock.FRootContext);
end.
