unit ojScreenLock_nju;

interface
uses  classes, forms, dialogs, sysUtils, system.types, Vcl.Graphics,
      ojScreenLockForm_nju, ojThreadUtils_nju, ojPainter;

type

  TojScreenLock = class;
  TojScreenLockPainter = class;
  TojUserScreenLockContext = class;
  TojRootScreenLockContext = class;


  IojScreenLockContext = Interface['{C4232F3C-DF6A-4746-A412-FBC19D9BD752}']
    function getName: string;
    procedure setName(const Value: string);
    function getCaption: string;
    procedure setCaption(const Value: string);
    function getText: string;
    procedure setText(const Value: string);
    function getHeight: Integer;
    function getWidth: Integer;
    procedure setHeight(const Value: Integer);
    procedure setWidth(const Value: Integer);
    function Root: TojRootScreenLockContext;
    function IsRoot: boolean;
    function Form: TCustomForm;
    procedure LockScreen;
    procedure UnLockScreen;
    function LockCount: integer;
    function IsLockActive: boolean;
    function LockTime: TTime;
    function TH: IojMiniThread;
    procedure ReleaseContext;
    function _RefCount:integer;
    procedure AddTask(TaskName: string; ProcCtx: TojThreadTaskProcedure; p_CallbackProc: TojThreadTaskProcedure);overload;
    function WaitForIdle(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    property Caption: string read getCaption write setCaption;
    property Text: string read getText write setText;
    property Width: Integer read getWidth write setWidth;
    property Height: Integer read getHeight write setHeight;
    property Name: string read getName write setName;
  end;

  TojUserScreenLockContext = class(TInterfacedObject, IojScreenLockContext)
  private
    FRoot: TojRootScreenLockContext;
    FName: string;
    FCalledLocalLock: boolean;
    FCalledLocalRelease: boolean;
    function getName: string;
    procedure setName(const Value: string);
  protected
    constructor Create(Root: TojRootScreenLockContext);virtual;
  public
    //  metody wspolne \ lokalne
    function Root: TojRootScreenLockContext;
    function IsRoot: boolean;
    procedure ReleaseContext;virtual;
    function _RefCount:integer;virtual;
    property Name: string read getName write setName;
  public
    //  te forwarduj¹ funkcjonalnosc do Root-a, do nadpisanie w roocie
    function Form: TCustomForm;virtual;
    procedure LockScreen;virtual;
    procedure UnLockScreen;virtual;
    function LockCount: integer; virtual;
    function IsLockActive: boolean;virtual;
    function LockTime: TTime;virtual;
    function TH: IojMiniThread; virtual;
    procedure AddTask(TaskName: string; ProcCtx: TojThreadTaskProcedure; p_CallbackProc: TojThreadTaskProcedure);overload;virtual;
    function WaitForIdle(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;virtual;
    function getCaption: string; virtual;
    procedure setCaption(const Value: string);virtual;

    function getText: string; virtual;
    procedure setText(const Value: string);virtual;

    function getHeight: Integer; virtual;
    function getWidth: Integer; virtual;
    procedure setHeight(const Value: Integer); virtual;
    procedure setWidth(const Value: Integer); virtual;

    property Caption: string read getCaption write setCaption;
    property Text: string read getText write setText;
    property Width: Integer read getWidth write setWidth;
    property Height: Integer read getHeight write setHeight;

  public
    destructor Destroy;override;
  end;

  TojRootScreenLockContext = class(TojUserScreenLockContext)
  private
  protected
    FThread: IojThread;
    FThreadMini: IojMiniThread;
    FScreenLockForm: TojCustomScreenLockForm;
    FScreenLockCount: integer;
    FChildContextList: TList;
    FLockStart: TDateTime;
    FCaption: string;
    FText: string;
  protected
    procedure CreateScreeenLockForm;
  public
    function CreateChild: IojScreenLockContext;
    function IsChild(p_Context: IojScreenLockContext): boolean;
    function IsLastChild(p_Context: IojScreenLockContext): boolean;
    procedure RemoveFromChildContextList(p_Context: IojScreenLockContext);
    procedure ReleaseChildContext(p_Context: IojScreenLockContext);
  public
    //  metody wspolne \ lokalne
  public
    //  te s¹ forwardowane do Root-a, do nadpisanie w roocie
    function Form: TCustomForm;override;
    procedure LockScreen;override;
    procedure UnLockScreen;override;
    function LockCount: integer; override;
    function IsLockActive: boolean;override;
    function LockTime: TTime;override;
    function TH: IojMiniThread; override;
    procedure AddTask(TaskName: string; ProcCtx: TojThreadTaskProcedure; p_CallbackProc: TojThreadTaskProcedure);override;
    function WaitForIdle(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;override;
    procedure ReleaseContext;override;
    function getCaption: string; override;
    procedure setCaption(const Value: string); override;

    function getText: string; override;
    procedure setText(const Value: string);override;

    function getHeight: Integer; override;
    function getWidth: Integer; override;
    procedure setHeight(const Value: Integer); override;
    procedure setWidth(const Value: Integer); override;
  public
    constructor Create();reintroduce;overload;virtual;
    destructor Destroy;override;
  end;

  TojScreenLock = class sealed
  private
    class var FRootContext: TojRootScreenLockContext;
  public
    class function getContext(p_LockScreen: boolean = TRUE; p_Caption: string = ''): IojScreenLockContext;
  end;

  TojScreenLockPainter = class(TojGradientPainter)
  protected
    procedure Paint(Canvas: TCanvas; DrawContext: Pointer);override;
  end;

implementation
uses math, system.UITypes;

{ TojUserScreenLockContext }

procedure TojUserScreenLockContext.AddTask(TaskName: string; ProcCtx, p_CallbackProc: TojThreadTaskProcedure);
begin
  Root.AddTask(TaskName, ProcCtx, p_CallbackProc);
end;

constructor TojUserScreenLockContext.Create(Root: TojRootScreenLockContext);
begin
  //  inherited;
  FRoot:= Root;
  FCalledLocalLock:= FALSE;
  FCalledLocalRelease:= FALSE;
end;

destructor TojUserScreenLockContext.Destroy;
begin
  if FCalledLocalLock then ShowMessage('TojUserScreenLockContext.Destroy -> '+ self.Name +'.LocalLock still active');

  if not FCalledLocalRelease then
  begin
    //  to prevent loop
    ShowMessage('TojUserScreenLockContext.Destroy -> '+ self.Name +' do ForceRelease');
    if self.RefCount = 0 then self._AddRef;
    self.ReleaseContext;
  end;

  inherited;
end;

function TojUserScreenLockContext.Form: TCustomForm;
begin
  result:= Root.Form;
end;

function TojUserScreenLockContext.getCaption: string;
begin
  result:= Root.getCaption;
end;

function TojUserScreenLockContext.getHeight: Integer;
begin
  result:= Root.Height;
end;

function TojUserScreenLockContext.getName: string;
begin
  result:= FName;
end;

function TojUserScreenLockContext.getText: string;
begin
  result:= Root.getText;
end;

function TojUserScreenLockContext.getWidth: Integer;
begin
  result:= Root.Width;
end;

function TojUserScreenLockContext.IsLockActive: boolean;
begin
  result:= Root.IsLockActive;
end;

function TojUserScreenLockContext.IsRoot: boolean;
begin
  result:= Assigned(FRoot) AND (FRoot = self);
end;

function TojUserScreenLockContext.LockCount: integer;
begin
  result:= Root.LockCount;
end;

procedure TojUserScreenLockContext.LockScreen;
begin
  if not FCalledLocalLock then
  begin
    Root.LockScreen;
    FCalledLocalLock:= TRUE;
  end;
end;

function TojUserScreenLockContext.LockTime: TTime;
begin
  result:= Root.LockTime;
end;

procedure TojUserScreenLockContext.ReleaseContext;
begin
  //  babol ??????
  if not IsRoot then
  begin
    Root.ReleaseChildContext(self);
    //  UnlockScreen jest robiony przez roota
    //  UnlockScreen;
    FCalledLocalRelease:= TRUE;
    FRoot:= nil;
  end;
end;

function TojUserScreenLockContext.Root: TojRootScreenLockContext;
begin
  result:= FRoot;
end;

procedure TojUserScreenLockContext.setCaption(const Value: string);
begin
  Root.setCaption(Value);
end;

procedure TojUserScreenLockContext.setHeight(const Value: Integer);
begin
  Root.Height:= Value;
end;

procedure TojUserScreenLockContext.setName(const Value: string);
begin
  FName:= Value;
end;

procedure TojUserScreenLockContext.setText(const Value: string);
begin
  Root.Text:= Value;
end;

procedure TojUserScreenLockContext.setWidth(const Value: Integer);
begin
  Root.Width:= Value;
end;

function TojUserScreenLockContext.TH: IojMiniThread;
begin
  result:= Root.TH;
end;

procedure TojUserScreenLockContext.UnLockScreen;
begin
  if FCalledLocalLock then
  begin
    Root.UnLockScreen;
    FCalledLocalLock:= FALSE;
  end;
end;

function TojUserScreenLockContext.WaitForIdle(TimeOut: Cardinal;ProcessMessages: boolean): boolean;
begin
  result:= Root.WaitForIdle(TimeOut, ProcessMessages);
end;

function TojUserScreenLockContext._RefCount: integer;
begin
  result:= self.RefCount;
end;

{ TojRootScreenLockContext }

procedure TojRootScreenLockContext.AddTask(TaskName: string; ProcCtx,p_CallbackProc: TojThreadTaskProcedure);
begin
  FThreadMini.AddTask( TojThreadTaskEx.Create(TaskName, ProcCtx, p_CallbackProc) );
end;

constructor TojRootScreenLockContext.Create;
var v_thread: TojThread;
begin
  inherited Create(self);
  v_thread:= TojThread.Create(nil);
  v_thread.IgnoreUnhandledTaskExceptions:= TRUE;
  v_thread.IgnoreUnhandledThreadExceptions:= TRUE;

  FThread:= v_thread;
  FThreadMini:= v_thread;


  //  zeby destryktor sie nie czepial
  FCalledLocalRelease:= TRUE;

  //  FreeNotification ????
  CreateScreeenLockForm;

  FScreenLockCount:= 0;
  FLockStart:= 0.0;
  FChildContextList:= TList.Create;
end;

function TojRootScreenLockContext.CreateChild: IojScreenLockContext;
begin
  result:= TojUserScreenLockContext.Create(self);
  //  weak reference
  FChildContextList.Add(Pointer(result));
end;

procedure TojRootScreenLockContext.CreateScreeenLockForm;
begin
  FScreenLockForm:= TojCustomScreenLockForm.CreateNew(nil);
  FScreenLockForm.Params.AllowResize:= FALSE;
  FScreenLockForm.DefaultPainter:= TojScreenLockPainter.Create(FScreenLockForm, self);
  FScreenLockForm.DefaultPainter.DrawTimeout:= 1; // 1 sekunda
end;

destructor TojRootScreenLockContext.Destroy;
begin
  if FScreenLockForm.IsScreenLocked OR (FScreenLockCount > 0)
  then ShowMessage('TojRootScreenLockContext.Destroy -> ScreenLock still active ');

  FThreadMini:= nil;

  //  ?????
  FThread.Terminate;
  FThread:= nil;

  // destruktor odpali unlocka, ew. petelka po ChildKontextach
  FreeAndNil(FScreenLockForm);
  FreeAndNil(FChildContextList);
  inherited;
end;

function TojRootScreenLockContext.Form: TCustomForm;
begin
  result:= FScreenLockForm;
end;

function TojRootScreenLockContext.getCaption: string;
begin
  result:= FCaption;
end;

function TojRootScreenLockContext.getHeight: Integer;
begin
  result:= FScreenLockForm.Height;
end;

function TojRootScreenLockContext.getText: string;
begin
  result:= FText;
end;

function TojRootScreenLockContext.getWidth: Integer;
begin
  result:= FScreenLockForm.Width;
end;

function TojRootScreenLockContext.IsChild(p_Context: IojScreenLockContext): boolean;
begin
  //  weak reference
  result:= (FChildContextList.IndexOf(Pointer(p_Context)) >= 0);
end;

function TojRootScreenLockContext.IsLastChild(p_Context: IojScreenLockContext): boolean;
begin
  //  weak reference
  result:= (FChildContextList.Count > 0)
       AND (FChildContextList.Last = Pointer(p_Context));
end;

function TojRootScreenLockContext.IsLockActive: boolean;
begin
  result:= FScreenLockForm.IsScreenLocked;
end;

function TojRootScreenLockContext.LockCount: integer;
begin
  result:= FScreenLockCount;
end;

procedure TojRootScreenLockContext.LockScreen;
begin
  Inc(FScreenLockCount);
  FScreenLockForm.ShowLock;
  if FScreenLockCount = 1 then
  begin
    FLockStart:= Now;
    //
  end;
  //  kazde wywolanie Lock to nowy kontext i np nowy caption
  //  if Assigned(FScreenLockForm) AND Assigned(FScreenLockForm.DefaultPainter)
  //  then FScreenLockForm.DefaultPainter.Invalidate
  //  werjsa przez DefaultPainter ma jakiegos LAG-a
  if Assigned(FScreenLockForm)
  then FScreenLockForm.Invalidate;
end;

function TojRootScreenLockContext.LockTime: TTime;
begin
  if FLockStart = 0.0
  then result:= 0.0
  else result:= Now - FLockStart;
end;

procedure TojRootScreenLockContext.ReleaseChildContext(p_Context: IojScreenLockContext);
begin
  if not Assigned(p_Context) then
  begin
    ShowMessage('TojRootScreenLockContext.ReleaseChildContext -> Context not assigned');
    Exit;
  end;

  if not IsChild( p_Context ) then
  begin
    ShowMessage('TojRootScreenLockContext.ReleaseChildContext -> Context: '+ p_Context.Name +' is not a valid child');
    Exit;
  end;

  if not IsLastChild(p_Context) then
  begin
    ShowMessage('TojRootScreenLockContext.ReleaseChildContext: '+ p_Context.Name +' -> niepoprawna kolejnosc zwalniania kontextow');
    //  kontynuujemy
  end;

  p_Context.UnLockScreen;
  RemoveFromChildContextList(p_Context);
end;

procedure TojRootScreenLockContext.ReleaseContext;
begin
  //   w sumie nic nie powinna robic,
  //  ew. zwolnic wszystkie ChildContexty
  //  zeby destryktor sie nie czepial, ew. na sztywno w constructorze ustawic
  //   FCalledLocalRelease:= TRUE;
end;

procedure TojRootScreenLockContext.RemoveFromChildContextList(p_Context: IojScreenLockContext);
begin
  //  wear reference
  FChildContextList.Remove(Pointer( p_Context ));
end;

procedure TojRootScreenLockContext.setCaption(const Value: string);
begin
  FCaption:= Value;

  if Assigned(FScreenLockForm) AND Assigned(FScreenLockForm.DefaultPainter)
  then FScreenLockForm.DefaultPainter.Invalidate;
end;

procedure TojRootScreenLockContext.setHeight(const Value: Integer);
begin
  FScreenLockForm.Height:= Value;
end;

procedure TojRootScreenLockContext.setText(const Value: string);
begin
  FText:= Value;

  if Assigned(FScreenLockForm) AND Assigned(FScreenLockForm.DefaultPainter)
  then FScreenLockForm.DefaultPainter.Invalidate;
end;

procedure TojRootScreenLockContext.setWidth(const Value: Integer);
begin
  FScreenLockForm.Width:= Value;
end;

function TojRootScreenLockContext.TH: IojMiniThread;
begin
  result:= FThreadMini;
end;

procedure TojRootScreenLockContext.UnLockScreen;
begin
  dec(FScreenLockCount);
  if FScreenLockCount = 0 then
  begin
    FScreenLockForm.CloseLock;
    FLockStart:= 0.0;
    //  skoro zamkniete, te recreate, zeby ustawienia np. szerokosc, wysokosc
    //  wrocily do poprzednich ustawien
    FScreenLockForm.Release;
    CreateScreeenLockForm;
  end;
end;

function TojRootScreenLockContext.WaitForIdle(TimeOut: Cardinal; ProcessMessages: boolean): boolean;
begin
  result:= FThreadMini.WaitForIdle(TimeOut, ProcessMessages);
end;

{ TojScreenLock }

class function TojScreenLock.getContext(p_LockScreen: boolean; p_Caption: string): IojScreenLockContext;
begin
  if not Assigned(TojScreenLock.FRootContext)
  then TojScreenLock.FRootContext:= TojRootScreenLockContext.Create;

  result:= TojScreenLock.FRootContext.CreateChild;
  if p_Caption <> ''
  then result.Caption:= p_Caption;

  if p_LockScreen then result.LockScreen;
end;

{ TojScreenLockPainter }

procedure TojScreenLockPainter.Paint(Canvas: TCanvas; DrawContext: Pointer);
var v_caption_rect, v_text_rect, v_time_rect: TRect;
    v_ctx: TojRootScreenLockContext;
    v_text: string;
const CNST_MARGIN = 5;
begin
  inherited Paint(Canvas, DrawContext);

  if Assigned(DrawContext)
  then v_ctx:= TojRootScreenLockContext(DrawContext)
  else exit;

  // lock time
  if v_ctx.LockTime <> 0.0 then
  begin
    Canvas.Brush.Style:= bsClear;
    Canvas.Font.Style:= Canvas.Font.Style + [fsBold];
    v_text:= TimeToStr(v_ctx.LockTime);

    v_time_rect:= PaintedControl.ClientRect;
    v_time_rect.Top:= v_time_rect.Top + CNST_MARGIN;
    v_time_rect.Right:= v_time_rect.Right - CNST_MARGIN;
    v_time_rect.Left:= v_time_rect.Right - Canvas.TextWidth(v_text);
    v_time_rect.Bottom:= v_time_rect.Top + Canvas.TextHeight(v_text);

    Canvas.TextRect(v_time_rect, v_text, [tfSingleLine, tfEndEllipsis, tfRight, tfVerticalCenter]);

//    Canvas.Brush.Color:= clRed ;
//    Canvas.Pen.Color:= clLime;
//    Canvas.Brush.Style:= bsSolid;
//    Canvas.FrameRect(v_time_rect);
  end
  else
    getTime;


  // caption
  if v_ctx.Caption <> '' then
  begin
    Canvas.Brush.Style:= bsClear;
    Canvas.Font.Style:= Canvas.Font.Style + [fsBold];
    v_caption_rect:= PaintedControl.ClientRect;
    v_caption_rect.Top:= v_caption_rect.Top + CNST_MARGIN;
    v_caption_rect.Left:= v_caption_rect.Left + CNST_MARGIN;
    v_caption_rect.Bottom:= v_caption_rect.Top + Canvas.TextHeight(v_ctx.Caption);

    if v_ctx.LockTime = 0.0
    then v_caption_rect.Right:= v_caption_rect.Right - CNST_MARGIN
    else v_caption_rect.Right:= v_time_rect.Left - CNST_MARGIN;

    v_text:= v_ctx.Caption;
    Canvas.TextRect(v_caption_rect, v_text, [tfSingleLine, tfEndEllipsis, tfLeft, tfVerticalCenter]);

//    Canvas.Brush.Color:= clRed ;
//    Canvas.Pen.Color:= clLime;
//    Canvas.Brush.Style:= bsSolid;
//    Canvas.FrameRect(v_caption_rect);
  end;

  // opis
  if v_ctx.Text <> '' then
  begin
    Canvas.Brush.Style:= bsClear;
    Canvas.Font.Style:= Canvas.Font.Style - [fsBold];

    v_text_rect:= PaintedControl.ClientRect;
    v_text_rect.Left:= v_text_rect.Left + CNST_MARGIN;
    v_text_rect.Right:= v_text_rect.Right - CNST_MARGIN;
    v_text_rect.Bottom:= v_text_rect.Bottom - CNST_MARGIN;

    if (v_ctx.Caption <> '') OR (v_ctx.LockTime <> 0.0)
    then v_text_rect.Top:= Max(v_time_rect.Bottom, v_caption_rect.Bottom) + CNST_MARGIN
    else v_text_rect.Top:= v_text_rect.Top + CNST_MARGIN;

    v_text:= v_ctx.Text;
    Canvas.TextRect(v_text_rect, v_text, [tfWordBreak, tfLeft, tfVerticalCenter]);

//    Canvas.Brush.Color:= clRed ;
//    Canvas.Pen.Color:= clLime;
//    Canvas.Brush.Style:= bsSolid;
//    Canvas.FrameRect(v_text_rect);
  end
  else
    GetTime;

end;

initialization
  TojScreenLock.FRootContext:= nil;
finalization
  FreeAndNil(TojScreenLock.FRootContext);
end.
