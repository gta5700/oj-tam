unit ojWndProcHook;

interface
uses  System.classes, System.SysUtils, VCL.Controls, Generics.Collections,
      Generics.Defaults,
      Vcl.Forms, Messages, Windows;

//  https://github.com/TurboPack/Orpheus/blob/master/source/ovcabtn.pas
//  http://crosswire.org/svn/biblecs/branches/wince/TntUnicodeControls/TntControls.pas
//  How to Detect the Start Move/Resize, Move and Stop Move/Resize events of a Delphi Form
//  https://delphi.cjcsoft.net/viewthread.php?tid=43678
//  https://stackoverflow.com/questions/63476818/how-to-detect-form-resize-end-maybe-by-using-the-tapplicationevents-component


const
  OJ_MSG_START = WM_APP + 123;
  OJ_MSG_RECREATE_HOOK_REQUEST  = OJ_MSG_START + 1;
  OJ_MSG_ARE_YOU_HOOKED_ALREADY = OJ_MSG_START + 2;

type
  TojUserWndAnon = reference to procedure(var Msg : TMessage);
  TojUserWndMethod = procedure(var Msg : TMessage) of object;

  TojWndProcHook = class
  private
    FControl: TWinControl;
    FNewWndProc: Pointer;
    FPrevWndProc: Pointer;
    FUserWndAnon: TojUserWndAnon;
    FUserWndMeth: TojUserWndMethod;
    procedure setControl(const Value: TWinControl);
  protected
    procedure NewWndProc(var Msg : TMessage);
    procedure checkControl(p_Control: TWinControl);overload;
  protected
    FEmbedHWND: HWND;
    procedure EmbedWndProc(var Msg : TMessage);virtual;
  public
    constructor Create(p_Control: TWinControl); virtual;
    destructor Destroy; override;
  public
    function IsHooked: boolean;
    function CheckControl: boolean; overload;

    function HookControl: TojWndProcHook;
    function UnHookControl: TojWndProcHook;

    function NewControl(const Value: TWinControl): TojWndProcHook;
    function NewUserWndAnon(const Value: TojUserWndAnon): TojWndProcHook;
    function NewUserWndMeth(const Value: TojUserWndMethod): TojWndProcHook;

    property Control: TWinControl read FControl write setControl;
    property UserWndAnon: TojUserWndAnon read FUserWndAnon write FUserWndAnon;
    property UserWndMeth: TojUserWndMethod read FUserWndMeth write FUserWndMeth;
  end;


implementation

type
  TojFejkWinControl = class(TWinControl);


{ TojWndProcHook }

procedure TojWndProcHook.checkControl(p_Control: TWinControl);
var v_hook: TojWndProcHook;
begin
  if Assigned(p_Control) AND p_Control.HandleAllocated then
  begin
    v_hook:= TojWndProcHook(SendMessage(p_Control.Handle, OJ_MSG_ARE_YOU_HOOKED_ALREADY, 0, 0));

    if v_hook = self 
    then raise Exception.Create('TojWndProcHook.checkControl -> TA DA jakas petla');
    
    if Assigned(v_hook)
    then raise Exception.Create('TojWndProcHook.checkControl -> control is already hooked');
  end;
end;

function TojWndProcHook.checkControl: boolean;
var v_hook: TojWndProcHook;
begin
  result:= TRUE;
  if Assigned(FControl) AND FControl.HandleAllocated then
  begin
    v_hook:= TojWndProcHook(SendMessage(FControl.Handle, OJ_MSG_ARE_YOU_HOOKED_ALREADY, 0, 0));
    result:= (v_hook = nil);
  end;
end;

constructor TojWndProcHook.Create(p_Control: TWinControl);
begin
  inherited Create;
  FPrevWndProc:= nil;
  FNewWndProc:= nil;
  FControl:= p_Control;
  
  FUserWndAnon:= nil;
  FUserWndMeth:= nil;
  
  //  create a callable window proc pointer
  FNewWndProc:= System.Classes.MakeObjectInstance(NewWndProc);

  //  tworzymy wlasn¹ wewnêtrzn¹ petlê komunikatów
  FEmbedHWND:= System.classes.AllocateHWnd(EmbedWndProc);
end;

destructor TojWndProcHook.Destroy;
begin
  UnHookControl;
  System.Classes.FreeObjectInstance(FNewWndProc);
  FNewWndProc:= nil;

  if FEmbedHWND <> 0 then
  begin
    DeallocateHWnd(FEmbedHWND);
    FEmbedHWND:= 0;
  end;
  
  FUserWndAnon:= nil;
  FUserWndMeth:= nil;
  
  inherited;
end;

procedure TojWndProcHook.EmbedWndProc(var Msg: TMessage);
begin
  if Msg.Msg = OJ_MSG_RECREATE_HOOK_REQUEST then
    try
      HookControl;
    except
      Application.HandleException(Self);
    end
  else
    Msg.Result:= DefWindowProc(FEmbedHWND, Msg.Msg, Msg.wParam, Msg.lParam);
end;

function TojWndProcHook.HookControl: TojWndProcHook;
var v_pointer: Pointer;
begin
  result:= self;
  if FControl = nil
  then raise Exception.Create('TojWndProcHook.HookControl -> Control = nil');

  //  save original window procedure if not already saved
  checkControl(FControl);
      
  FControl.HandleNeeded;
  v_pointer:= Pointer(GetWindowLong(FControl.Handle, GWL_WNDPROC));

  //  kontrolka jest ta sama ale moglo pojsc na niej ReCreateWnd
  if (v_pointer <> FNewWndProc) then
  begin    
    FPrevWndProc:= Pointer(GetWindowLong(FControl.Handle, GWL_WNDPROC));
    //  change to ours
    SetWindowLong(FControl.Handle, GWL_WNDPROC, NativeInt(FNewWndProc));
  end;

end;

function TojWndProcHook.NewControl(const Value: TWinControl): TojWndProcHook;
begin
  result:= self;
  setControl(Value);
end;

function TojWndProcHook.NewUserWndMeth(const Value: TojUserWndMethod): TojWndProcHook;
begin
  result:= self;
  if TMethod(Value) <> TMethod(FUserWndMeth)
  then FUserWndMeth:= Value;
end;

function TojWndProcHook.NewUserWndAnon(const Value: TojUserWndAnon): TojWndProcHook;
begin
  result:= self;

  if not TEqualityComparer<TojUserWndAnon>.Default.Equals(Value,  FUserWndAnon)
  then FUserWndAnon:= Value;
end;

function TojWndProcHook.IsHooked: boolean;
begin
  result:= (FPrevWndProc <> nil) AND (FNewWndProc <> nil);
end;

procedure TojWndProcHook.NewWndProc(var Msg: TMessage);
begin
  //  defaultowa obsluga, odpalenie oryginalnego wndProc
  if Assigned(FControl) then
  begin
    if Assigned(FPrevWndProc)
    then Msg.Result:= CallWindowProc(FPrevWndProc, FControl.Handle, Msg.Msg, Msg.wParam, Msg.lParam)
    else Msg.Result:= CallWindowProc(TojFejkWinControl(FControl).DefWndProc, FControl.Handle, Msg.Msg, Msg.wParam, Msg.lParam);
    //else Msg.Result:= DefWindowProc(FControl.Handle, Msg.Msg, Msg.wParam, Msg.lParam);
  end;

  //  lokalne machlojki
  //  if we get this message, we must be attached -- return self
  if Msg.Msg = OJ_MSG_ARE_YOU_HOOKED_ALREADY
  then Msg.Result:= NativeInt(Self)
  else
  begin
    if Msg.Msg = WM_DESTROY then
    begin
      //  the window handle for the attached control has been destroyed
      //  we need to un-attach and then re-attach (if possible)
      UnHookControl;

      //  do embedowej petli komunika zeby odtworzyl Hooka
      if Assigned(FControl) AND not (csDestroying in FControl.ComponentState)
      then PostMessage(FEmbedHWND, OJ_MSG_RECREATE_HOOK_REQUEST, 0, 0);
    end;

    try
      if Assigned(FUserWndAnon) then FUserWndAnon(Msg);
      if Assigned(FUserWndMeth) then FUserWndMeth(Msg); 
    except
      Application.HandleException(Self);   
    end;
    
  end;
end;

procedure TojWndProcHook.setControl(const Value: TWinControl);
var v_ctrl: TojWndProcHook;
begin
  if FControl <> Value then
  begin
    UnHookControl;

    checkControl(Value);
    //  if Assigned(Value) AND Value.HandleAllocated then
    //  begin
    //    v_ctrl:= TojWndProcHook(SendMessage(Value.Handle, OJ_MSG_ARE_YOU_HOOKED_ALREADY, 0, 0));
    //    if Assigned(v_ctrl)
    //    then raise Exception.Create('TojWndProcHook.setControl -> control is already hooked');
    //  end;

    FControl:= Value;
  end;

end;

function TojWndProcHook.UnHookControl: TojWndProcHook;
begin
  result:= self;

  if Assigned(FControl) then
  begin
    if Assigned(FPrevWndProc) AND FControl.HandleAllocated
    then SetWindowLong(FControl.Handle, GWL_WNDPROC, NativeInt(FPrevWndProc));
  end;
  FPrevWndProc:= nil;
end;

initialization;

finalization;

end.
