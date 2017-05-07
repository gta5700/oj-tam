(*
  2017-03-xx reset

*)

unit ojThreadUtils;

interface

uses  Windows, classes, sysUtils, Forms, StdCtrls, Controls, Graphics, messages,
      GraphUtil, Contnrs, DB, Variants, ExtCtrls;

type

  TojThreadLogType = (tltLog, tltDebug);

  TojThreadTask = class;
  TojThreadTaskContext = class;
  TojThreadTaskContextClass = class of TojThreadTaskContext;
  TojThreadTaskList = class;
  TojNotifyEventThreadTask = class;
  TojThread = class;


  TojThreadStartEvent = procedure of object;
  TojThreadEndEvent = procedure of object;
  TojThreadIdleEvent = procedure of object;
  TojThreadExceptionEvent = procedure(TaskName: string; E:Exception) of object;

  TojThreadTaskStartEvent = procedure(TaskName: string) of object;
  TojThreadTaskEndEvent = procedure(TaskName: string; Success: boolean; ReturnValue: Variant) of object;
  TojThreadTaskEndCallback = procedure(TaskName: string; Success: boolean; ReturnValue: Variant) of object;
  TojThreadTaskExceptionEvent = procedure(TaskName: string; E:Exception; var Handled: boolean) of object;

  TojThreadTaskLogReceiveEvent = procedure(TaskName: string; LogText: string; LogType: TojThreadLogType) of object;

//  TojThreadTaskEnd =  procedure(TaskName: string; LogText: string; LogType: TojThreadLogType) of object;


  {$region 'TojThreadTaskList'}

  TojThreadTaskList = class(TObject)
  private
    FList: TList;
    FLock: TRTLCriticalSection;
  protected
    procedure LockList;
    procedure UnlockList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(Task: TojThreadTask);
    function Pop: TojThreadTask;
    procedure Clear(FreeTasks: boolean);
    function Count: Integer;
    function IsEmpty: boolean;
    function AtLeast(ACount: integer = 1): boolean;
  end;

  {$endregion 'TojThreadTaskList'}

  {$region 'TojThreadTask'}

  //  zdarzenia Task-a s¹ odpalane i synchronizowane przez TojThread,
  //  task jest TYLKO kontenerem na "dane" do przetworzenia
  TojThreadTask = class
  private
    FTaskName: string;
    FThreadContext: TojThreadTaskContext;
    FThreadCustomContext: TojThreadTaskContext;
    FOnTaskEndCallback: TojThreadTaskEndCallback;
    FOnTaskException: TojThreadTaskExceptionEvent;
    procedure setThreadCustomContext(const Value: TojThreadTaskContext);
  protected
    function prepareContext: TojThreadTaskContext;
    function currentContext: TojThreadTaskContext;
    function getThreadTaskContextClass: TojThreadTaskContextClass;virtual;

    //  te sa synchronizowane przez watek
    procedure processTaskStartEvents(ctx: TojThreadTaskContext);virtual;
    procedure processTaskEndEvents(ctx: TojThreadTaskContext);virtual;
    procedure processTaskHandleExceptionEvents(ctx: TojThreadTaskContext; var Handled: boolean);virtual;

  public
    procedure Execute(ctx: TojThreadTaskContext);virtual;abstract;
    constructor Create(TaskName: string);overload;virtual;
    destructor Destroy;override;
  public
    property TaskName: string read FTaskName write FTaskName;
    property ThreadCustomContext: TojThreadTaskContext read FThreadCustomContext write setThreadCustomContext;
  public
    property OnTaskEndCallback: TojThreadTaskEndCallback read FOnTaskEndCallback write FOnTaskEndCallback;
    property OnTaskException: TojThreadTaskExceptionEvent read FOnTaskException write FOnTaskException;
  end;

  {$endregion 'TojThreadTask'}

  {$region 'TojNotifyEventThreadTask'}

  TojNotifyEventThreadTask = class(TojThreadTask)
  private
    FMethod: TNotifyEvent;
  public
    constructor Create(TaskName: string; Method: TNotifyEvent; TaskEndCallBack: TojThreadTaskEndCallback = nil);reintroduce;virtual;
    procedure Execute(ctx: TojThreadTaskContext);override;
  end;

  {$endregion 'TojNotifyEventThreadTask'}

  {$region 'TojMethodThreadTask'}

  TojMethodThreadTask = class(TojThreadTask)
  private
    FMethod: TThreadMethod;
  public
    constructor Create(TaskName: string; Method: TThreadMethod; TaskEndCallBack: TojThreadTaskEndCallback = nil);reintroduce;virtual;
    procedure Execute(ctx: TojThreadTaskContext);override;
  end;

  {$endregion 'TojMethodThreadTask'}

  {$region 'TojProcedureThreadTask'}

  TojProcedureThreadTask = class(TojThreadTask)
  private
    FMethod: TThreadProcedure;
  public
    constructor Create(TaskName: string; Method: TThreadProcedure; TaskEndCallBack: TojThreadTaskEndCallback = nil);reintroduce;virtual;
    procedure Execute(ctx: TojThreadTaskContext);override;
  end;

  {$endregion 'TojProcedureThreadTask'}


  {$region 'TojThreadTaskContext'}


  TojThreadTaskContext = class
  private
    FReturnValue: Variant;
    FThread: TojThread;
    FTask: TojThreadTask;
    FSuccess: boolean;
    FExceptionObject: Exception;
    FExceptionHandled: boolean;
  protected
    procedure connectTo(Thread: TojThread; Task: TojThreadTask);

    procedure setSuccess(const Value: boolean);
    procedure setExceptionHandled(const Value: boolean);
    procedure setExceptionObject(const Value: Exception);
  public
    constructor Create;virtual;
    destructor Destroy;override;
    procedure ForwardLog(const LogText: string; LogType: TojThreadLogType = tltLog);

    property Task: TojThreadTask read FTask;
    property Success: boolean read FSuccess;
    property ExceptionHandled: boolean read FExceptionHandled;
    property ExceptionObject: Exception read FExceptionObject;

    property ReturnValue: Variant read FReturnValue write FReturnValue;
  end;


  {$endregion 'TojThreadTaskContext'}


  {$region 'TojThread'}

  TojThread = class(TThread)
  private
    FTaskList: TojThreadTaskList;
    FCurrentTask: TojThreadTask;
    FCurrentContext: TojThreadTaskContext;
    FIsExecuting: Variant;
    // do obs³ugi wyj¹tków przez HandleThreadException
    FException: Exception;
  private
    FOnThreadStart: TojThreadStartEvent;
    FOnThreadEnd: TojThreadEndEvent;
    FOnThreadIdle: TojThreadIdleEvent;
    FOnThreadException: TojThreadExceptionEvent;

    FOnTaskStart: TojThreadTaskStartEvent;
    FOnTaskEnd: TojThreadTaskEndEvent;
    FOnTaskException: TojThreadTaskExceptionEvent;

    FOnTaskLogReceive: TojThreadTaskLogReceiveEvent;
    FIgnoreUnhandledTaskExceptions: boolean;
    function getIgnoreUnhandledTaskExceptions: boolean;
    procedure setIgnoreUnhandledTaskExceptions(const Value: boolean);
  protected
    procedure Execute; override;

    //  bezparametrowe procedury zeby dzialaly z Synchronize
    procedure DoThreadStart;virtual;
    procedure DoThreadEnd;virtual;
    procedure DoThreadIdle;virtual;
    procedure DoHandleThreadException;virtual;

    procedure DoProcessThreadTaskStart;virtual;
    procedure DoProcessThreadTaskEnd;virtual;
    procedure DoProcessTaskStart;virtual;
    procedure DoProcessTaskEnd;virtual;
    procedure DoProcessHandleException;virtual;

    procedure ThreadStart;
    procedure ThreadEnd;
    procedure ThreadIdle;
    procedure HandleThreadException;virtual;

    //  g³owne zdarzenie po stronie Thread-a
    procedure ProcessThreadTaskStart;
    procedure ProcessThreadTaskEnd;
    //  g³owne zdarzenie po stronie Task-a
    procedure ProcessTaskStart;
    procedure ProcessTaskEnd;
    //  mix zdarzenia dla Task-a i Thread-a
    procedure ProcessHandleException;

  public
    constructor Create(TaskList: TojThreadTaskList; CreateSuspended: boolean = TRUE);reintroduce;virtual;
    destructor Destroy;override;
    function IsIdle: boolean;
    function IsExecuting: boolean;

    procedure ForwardLog(const LogText: string; TaskName: string = ''; LogType: TojThreadLogType = tltLog);
  public
    property TaskList: TojThreadTaskList read FTaskList;
    property IgnoreUnhandledTaskExceptions: boolean read getIgnoreUnhandledTaskExceptions write setIgnoreUnhandledTaskExceptions;

    property OnThreadStart: TojThreadStartEvent read FOnThreadStart write FOnThreadStart;
    property OnThreadEnd: TojThreadEndEvent read FOnThreadEnd write FOnThreadEnd;
    property OnThreadIdle: TojThreadIdleEvent read FOnThreadIdle write FOnThreadIdle;
    property OnThreadException: TojThreadExceptionEvent read FOnThreadException write FOnThreadException;

    property OnTaskStart: TojThreadTaskStartEvent read FOnTaskStart write FOnTaskStart;
    property OnTaskEnd: TojThreadTaskEndEvent read FOnTaskEnd write FOnTaskEnd;
    property OnTaskException: TojThreadTaskExceptionEvent read FOnTaskException write FOnTaskException;

    property OnTaskLogReceive: TojThreadTaskLogReceiveEvent read FOnTaskLogReceive write FOnTaskLogReceive;
  end;

  {$endregion 'TojThread'}


  {$region 'TojThreadUtils'}

  IojThreadUtils = interface(IInterface)['{FE11FC7E-031E-4DEA-AC4C-1DAD57497734}']
    function getOnTaskEndEvent: TojThreadTaskEndEvent;
    function getOnTaskExceptionEvent: TojThreadTaskExceptionEvent;
    function getOnTaskStart: TojThreadTaskStartEvent;
    function getOnThreadEnd: TojThreadEndEvent;
    function getOnThreadException: TojThreadExceptionEvent;
    function getOnThreadIdle: TojThreadIdleEvent;
    function getOnThreadStart: TojThreadStartEvent;
    function getOnTaskLogReceive: TojThreadTaskLogReceiveEvent;
    function getIgnoreUnhandledTaskExceptions: boolean;

    procedure setOnTaskEndEvent(const Value: TojThreadTaskEndEvent);
    procedure setOnTaskExceptionEvent(const Value: TojThreadTaskExceptionEvent);
    procedure setOnTaskStart(const Value: TojThreadTaskStartEvent);
    procedure setOnThreadEnd(const Value: TojThreadEndEvent);
    procedure setOnThreadException(const Value: TojThreadExceptionEvent);
    procedure setOnThreadIdle(const Value: TojThreadIdleEvent);
    procedure setOnThreadStart(const Value: TojThreadStartEvent);
    procedure setOnTaskLogReceive(const Value: TojThreadTaskLogReceiveEvent);
    procedure setIgnoreUnhandledTaskExceptions(const Value: boolean);
    function IsIdle: boolean;
    function IsExecuting: boolean;
    procedure Terminate;
    procedure AddTask(Task: TojThreadTask);
    function WaitForIdle(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function WaitForTerm(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    //  function WaitForTask(TaskName: string; imeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;

    function TaskCount: integer;

    property IgnoreUnhandledTaskExceptions: boolean read getIgnoreUnhandledTaskExceptions write setIgnoreUnhandledTaskExceptions;

    property OnThreadStart: TojThreadStartEvent read getOnThreadStart write setOnThreadStart;
    property OnThreadEnd: TojThreadEndEvent read getOnThreadEnd write setOnThreadEnd;
    property OnThreadIdle: TojThreadIdleEvent read getOnThreadIdle write setOnThreadIdle;
    property OnThreadException: TojThreadExceptionEvent read getOnThreadException write setOnThreadException;

    property OnTaskStart: TojThreadTaskStartEvent read getOnTaskStart write setOnTaskStart;
    property OnTaskEnd: TojThreadTaskEndEvent read getOnTaskEndEvent write setOnTaskEndEvent;
    property OnTaskException: TojThreadTaskExceptionEvent read getOnTaskExceptionEvent write setOnTaskExceptionEvent;

    property OnTaskLogReceive: TojThreadTaskLogReceiveEvent read getOnTaskLogReceive write setOnTaskLogReceive;
  end;

  TojThreadUtils = class(TInterfacedObject, IojThreadUtils)
  private
    FThread: TojThread;
    function getOnTaskEndEvent: TojThreadTaskEndEvent;
    function getOnTaskExceptionEvent: TojThreadTaskExceptionEvent;
    function getOnTaskStart: TojThreadTaskStartEvent;
    function getOnThreadEnd: TojThreadEndEvent;
    function getOnThreadException: TojThreadExceptionEvent;
    function getOnThreadIdle: TojThreadIdleEvent;
    function getOnThreadStart: TojThreadStartEvent;
    procedure setOnTaskEndEvent(const Value: TojThreadTaskEndEvent);
    procedure setOnTaskExceptionEvent(const Value: TojThreadTaskExceptionEvent);
    procedure setOnTaskStart(const Value: TojThreadTaskStartEvent);
    procedure setOnThreadEnd(const Value: TojThreadEndEvent);
    procedure setOnThreadException(const Value: TojThreadExceptionEvent);
    procedure setOnThreadIdle(const Value: TojThreadIdleEvent);
    procedure setOnThreadStart(const Value: TojThreadStartEvent);
    function getOnTaskLogReceive: TojThreadTaskLogReceiveEvent;
    procedure setOnTaskLogReceive(const Value: TojThreadTaskLogReceiveEvent);
    function getIgnoreUnhandledTaskExceptions: boolean;
    procedure setIgnoreUnhandledTaskExceptions(const Value: boolean);
  public
    constructor Create(TaskList: TojThreadTaskList);virtual;
    destructor Destroy;override;
    function IsIdle: boolean;
    function IsExecuting: boolean;
    procedure Terminate;
    procedure AddTask(Task: TojThreadTask);
    function WaitForIdle(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function WaitForTerm(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function TaskCount: integer;
  public

    property IgnoreUnhandledTaskExceptions: boolean read getIgnoreUnhandledTaskExceptions write setIgnoreUnhandledTaskExceptions;

    property OnThreadStart: TojThreadStartEvent read getOnThreadStart write setOnThreadStart;
    property OnThreadEnd: TojThreadEndEvent read getOnThreadEnd write setOnThreadEnd;
    property OnThreadIdle: TojThreadIdleEvent read getOnThreadIdle write setOnThreadIdle;
    property OnThreadException: TojThreadExceptionEvent read getOnThreadException write setOnThreadException;

    property OnTaskStart: TojThreadTaskStartEvent read getOnTaskStart write setOnTaskStart;
    property OnTaskEnd: TojThreadTaskEndEvent read getOnTaskEndEvent write setOnTaskEndEvent;
    property OnTaskException: TojThreadTaskExceptionEvent read getOnTaskExceptionEvent write setOnTaskExceptionEvent;

    property OnTaskLogReceive: TojThreadTaskLogReceiveEvent read getOnTaskLogReceive write setOnTaskLogReceive;
  end;

  {$endregion 'TojThreadUtils'}

  function VarToPointer(Value: Variant): TObject;
  function PointerToVar(Value: Pointer): Variant;

implementation
uses dateUtils, types, dialogs;

function VarToPointer(Value: Variant): TObject;
var v_temp: NativeInt;
begin
  if VarIsNull(Value) OR VarIsClear(Value) OR VarIsEmpty(Value)
  then result:= nil
  else
    begin
      v_temp:= Value;
      result:= Pointer( v_temp );
    end;
end;

function PointerToVar(Value: Pointer): Variant;
var v_temp: NativeInt;
begin
  if Value = nil
  then result:= NULL
  else
    begin
      v_temp:= NativeInt(Value);
      result:= v_temp;
    end;
end;

{ TojThreadTaskList }

procedure TojThreadTaskList.Add(Task: TojThreadTask);
begin
  LockList;
  try
    FList.Add(Task);
  finally
    UnlockList;
  end;
end;

function TojThreadTaskList.AtLeast(ACount: integer): boolean;
begin
  LockList;
  try
    result:= (FList.Count >= ACount);
  finally
    UnlockList;
  end;
end;

procedure TojThreadTaskList.Clear(FreeTasks: boolean);
var i: integer;
begin
  LockList;
  try
    //  nie ma nil-i na liscie
    if FreeTasks then
    for i:= 0 to FList.Count-1 do
      TObject(FList[i]).Free;

    FList.Clear;
  finally
    UnlockList;
  end;
end;

function TojThreadTaskList.Count: Integer;
begin
  LockList;
  try
    result:= FList.Count;
  finally
    UnlockList;
  end;
end;

constructor TojThreadTaskList.Create;
begin
  inherited Create;
  InitializeCriticalSection(FLock);
  FList:= TList.Create;
end;

destructor TojThreadTaskList.Destroy;
begin
  LockList;    // Make sure nobody else is inside the list.
  try
    Clear(TRUE);
    inherited Destroy;
  finally
    UnlockList;
    DeleteCriticalSection(FLock);
  end;
end;

function TojThreadTaskList.IsEmpty: boolean;
begin
  LockList;
  try
    result:= (FList.Count = 0);
  finally
    UnlockList;
  end;
end;

procedure TojThreadTaskList.LockList;
begin
  EnterCriticalSection(FLock);
end;

function TojThreadTaskList.Pop: TojThreadTask;
begin
  LockList;
  try
    if FList.Count > 0 then
    begin
      result:= TojThreadTask(FList.First);
      FList.Delete(0);
    end
    else
      result:= nil;
  finally
    UnlockList;
  end;
end;

procedure TojThreadTaskList.UnlockList;
begin
  LeaveCriticalSection(FLock);
end;

{ TojThreadTask }

constructor TojThreadTask.Create(TaskName: string);
begin
  inherited Create;
  FTaskName:= TaskName;
  FThreadContext:= nil;
  FThreadCustomContext:= nil;
  FOnTaskEndCallback:= nil;
  FOnTaskException:= nil;
end;


function TojThreadTask.currentContext: TojThreadTaskContext;
begin
  //  zwarcamy istniejacy kontext, NIE TWORZYMY
  if Assigned(FThreadCustomContext)
  then result:= FThreadCustomContext
  else result:= FThreadContext;
end;

destructor TojThreadTask.Destroy;
begin
  FreeAndNil(FThreadContext);
  FreeAndNil(FThreadCustomContext);
  inherited;
end;

function TojThreadTask.getThreadTaskContextClass: TojThreadTaskContextClass;
begin
  result:= TojThreadTaskContext;
end;

function TojThreadTask.prepareContext: TojThreadTaskContext;
begin
  //  odpalana TYLKO raz
  if Assigned(FThreadCustomContext)
  then result:= FThreadCustomContext
  else
  begin
    FThreadContext:= getThreadTaskContextClass.Create;
    result:= FThreadContext;
  end;
end;

procedure TojThreadTask.processTaskEndEvents(ctx: TojThreadTaskContext);
begin
  //  ShowMessage('TojThreadTask.processTaskEndEvents -> ');
  if Assigned(FOnTaskEndCallback)
  then FOnTaskEndCallback(ctx.Task.TaskName, ctx.Success, ctx.ReturnValue);

  //  inne metody...
end;

procedure TojThreadTask.processTaskHandleExceptionEvents(ctx: TojThreadTaskContext; var Handled: boolean);
begin


end;

procedure TojThreadTask.processTaskStartEvents(ctx: TojThreadTaskContext);
begin
  //  na razie brak zdarzen...
end;

procedure TojThreadTask.setThreadCustomContext(const Value: TojThreadTaskContext);
begin
  FreeAndNil(FThreadCustomContext);
  FThreadCustomContext:= Value;
end;

{ TojNotifyEventThreadTask }

constructor TojNotifyEventThreadTask.Create(TaskName: string; Method: TNotifyEvent; TaskEndCallBack: TojThreadTaskEndCallback);
begin
  inherited Create(TaskName);
  OnTaskEndCallback:= TaskEndCallBack;
  FMethod:= Method;
end;

procedure TojNotifyEventThreadTask.Execute(ctx: TojThreadTaskContext);
begin
  //  ForwardMessage('uruchamia %s z klasy %s', [self.TaskName, self.ClassType.ClassName]);
  if Assigned(FMethod) then FMethod(self);
  ctx.ReturnValue:= NULL;
end;

{ TojMethodThreadTask }

constructor TojMethodThreadTask.Create(TaskName: string; Method: TThreadMethod; TaskEndCallBack: TojThreadTaskEndCallback);
begin
  inherited Create(TaskName);
  OnTaskEndCallback:= TaskEndCallBack;
  FMethod:= Method;
end;

procedure TojMethodThreadTask.Execute(ctx: TojThreadTaskContext);
begin
  //  ctx.ForwardMessage('uruchamia %s z klasy %s', [self.TaskName, self.ClassType.ClassName]);
  if Assigned(FMethod) then FMethod();
  ctx.ReturnValue:= NULL;
end;

{ TojThread }

constructor TojThread.Create(TaskList: TojThreadTaskList; CreateSuspended: boolean);
begin
  inherited Create(TRUE);

  if Assigned(TaskList)
  then FTaskList:= TaskList
  else FTaskList:= TojThreadTaskList.Create;

  FCurrentTask:= nil;
  FCurrentContext:= nil;
  FIsExecuting:= NULL;
  FIgnoreUnhandledTaskExceptions:= FALSE;
  if not CreateSuspended then
    Start;  //  resume
end;

destructor TojThread.Destroy;
begin
  FreeAndNil(FCurrentTask);
  FreeAndNil(FTaskList);
  inherited;
end;

procedure TojThread.DoHandleThreadException;
begin
  // Cancel the mouse capture
  //  if GetCapture <> 0 then SendMessage(GetCapture, WM_CANCELMODE, 0, 0);
  //  // Now actually show the exception
  //  if FException is Exception then
  //    Application.ShowException(FException)
  //  else
  //    SysUtils.ShowException(FException, nil);

  if Assigned(FOnThreadException) then
    if Assigned(FCurrentTask)
    then FOnThreadException(FCurrentTask.TaskName, FException)
    else FOnThreadException('', FException);
end;

procedure TojThread.DoProcessHandleException;
var v_handled: boolean;
begin
  v_handled:= FCurrentContext.ExceptionHandled;
  try
    //  task i thread maj¹ oddzielne zdarzenia do obslugi wyj¹tku
    //  task ma pierszenstwo
    FCurrentContext.Task.processTaskHandleExceptionEvents(FCurrentContext, v_handled);

    //  zdarzenie dla thread odpalane ZAWSZE nawet jak zdarzenie po stronie taska
    //  zwróci v_handled = TRUE
    if Assigned(FOnTaskException)
    then FOnTaskException(FCurrentContext.Task.TaskName, FCurrentContext.ExceptionObject, v_handled);
  finally
    FCurrentContext.setExceptionHandled( v_handled );
  end;
end;

procedure TojThread.DoProcessTaskEnd;
begin
  if Assigned(FCurrentTask)
  then FCurrentTask.processTaskEndEvents(FCurrentTask.currentContext);
end;

procedure TojThread.DoProcessTaskStart;
begin
  if Assigned(FCurrentTask)
  then FCurrentTask.processTaskStartEvents(FCurrentTask.currentContext);
end;

procedure TojThread.DoThreadEnd;
begin
  if Assigned(FOnThreadEnd) then FOnThreadEnd();
end;

procedure TojThread.DoThreadIdle;
begin
  if Assigned(FOnThreadIdle) then FOnThreadIdle();
end;

procedure TojThread.DoThreadStart;
begin
  if Assigned(FOnThreadStart) then FOnThreadStart();
end;

procedure TojThread.DoProcessThreadTaskEnd;
begin
  if Assigned(FOnTaskEnd) then FOnTaskEnd(FCurrentTask.TaskName, FCurrentContext.Success, FCurrentContext.ReturnValue);
  //  i inne w zaleznosci od potrzeb
  //  if Assigned(FOnTaskEndCtx) then FOnTaskEnd(FCurrentTask.currentContext);
end;

procedure TojThread.DoProcessThreadTaskStart;
begin
  if Assigned(FOnTaskStart) then FOnTaskStart(FCurrentTask.TaskName);
  //  i inne w zaleznosci od potrzeb
  //  if Assigned(FOnTaskStartCtx) then FOnTaskStart(FCurrentTask.currentContext);
end;

procedure TojThread.Execute;
const CNST_LOCAL_TIMEOUT = 50;
begin
  FIsExecuting:= TRUE;

  TRY
    ThreadStart;
    TRY

      while not self.Terminated do
      begin

        if FTaskList.AtLeast then
        begin

          while not self.Terminated AND FTaskList.AtLeast do
          begin
            FCurrentTask:= FTaskList.Pop;
            try
              //  context zwalniany przez Task-a
              FCurrentContext:= FCurrentTask.prepareContext;
              try
                FCurrentContext.connectTo(self, FCurrentTask);

                ProcessThreadTaskStart; //  zdarzenia Thread-a - start taska
                ProcessTaskStart;       //  zdarzenia Taska-a - start taska

                FCurrentTask.Execute(FCurrentContext);
                FCurrentContext.setSuccess( TRUE )

              except
                FCurrentContext.setSuccess( FALSE );
                ProcessHandleException;

                if not FCurrentContext.ExceptionHandled then
                begin
                  if FIgnoreUnhandledTaskExceptions
                  then ForwardLog('ignoring unhandled task exception', FCurrentTask.TaskName, tltDebug)
                  else raise;
                end;

              end;

            finally
              ProcessThreadTaskEnd;   //  zdarzenia Thread-a - start taska
              ProcessTaskEnd;         //  zdarzenia Taska-a - start taska
              FreeAndNil(FCurrentTask);
              FCurrentContext:= nil;
            end;

          end;

          ThreadIdle; //  wyczyscil liste tasków wiec zdarzenie
        end;

        //  self.SpinWait(CNST_LOCAL_TIMEOUT)
        Sleep(CNST_LOCAL_TIMEOUT);
      end;  //  while not self.Terminated do

    EXCEPT
      HandleThreadException;
      //  jak TaskEndCallBack lub AfterTask siê posypie to tytaj wczyscimy
      FreeAndNil(FCurrentTask);
      FCurrentContext:= nil;
    END;

  FINALLY
    ThreadEnd;
    FIsExecuting:= FALSE;
  END;

end;

procedure TojThread.ForwardLog(const LogText: string; TaskName: string; LogType: TojThreadLogType);
begin
  //  na ³atwizne,
  if Assigned(FOnTaskLogReceive)
  then self.Synchronize(
      procedure()
      begin
        FOnTaskLogReceive(TaskName, LogText, LogType);
      end
      );
end;

function TojThread.getIgnoreUnhandledTaskExceptions: boolean;
begin
  result:= FIgnoreUnhandledTaskExceptions;
end;

procedure TojThread.HandleThreadException;
begin
  // This function is virtual so you can override it
  // and add your own functionality.
  //  lokalna referencja tylko na potrzeby DoHandleThreadException
  FException:= Exception(ExceptObject);
  try
    // Don't show EAbort messages
    //  FExceptionMessage:= FException.Message;
    //  bez testu na FCurrentTask
    if not (FException is EAbort) then
    begin
      if Assigned(FOnThreadException)
      then Synchronize(DoHandleThreadException);
    end;
  finally
    FException:= nil;
  end;
end;

function TojThread.IsExecuting: boolean;
begin
  //  znaczy ze w¹tek zosta³ odpalony i wszed³ ju¿ w pêtlê
  result:= (FIsExecuting <> NULL) AND (FIsExecuting = TRUE);
end;

function TojThread.IsIdle: boolean;
begin
  //  Idle oznacza bezrobocie, czyli wszedl w petle i ma pusta liste
  //  ew. uwzglednic jeszcze FCurrentTask
  result:= (FIsExecuting <> NULL)
    AND (
      //  wszed³ w pêtlê i skonczyly mu sie taski do wykonania, czeka na nowe
      ((FIsExecuting=TRUE) AND (FCurrentTask = nil) AND (FTaskList.Count = 0))
      OR
      //  wszed³ w pêtlê Execute ale ju¿ j¹ zakonczyl (albo wlasnie opuszcza)
      //  bo wykryl Terminate lub polecial wyj¹tek
      ((FIsExecuting=FALSE) AND (FCurrentTask = nil) )  //  currentTask w sumie nas nie interesuje
        );
end;


procedure TojThread.setIgnoreUnhandledTaskExceptions(const Value: boolean);
begin
  FIgnoreUnhandledTaskExceptions:= Value;
end;

procedure TojThread.ProcessHandleException;
var v_exception: Exception;
begin
  //  task i thread maj¹ oddzielne zdarzenia do obslugi wyj¹tku
  //  wy-if-owanie jest robione w DoProcessHandleException
  v_exception:= Exception(AcquireExceptionObject);
  // Don't show EAbort messages
  if not (v_exception is EAbort) then
  begin
    FCurrentContext.setExceptionObject( v_exception );
    FCurrentContext.setExceptionHandled( FALSE );
    Synchronize(DoProcessHandleException);
  end
  else
    FreeAndNil(v_exception);
end;

procedure TojThread.ProcessTaskEnd;
begin
  if Assigned(FCurrentTask)
  then Synchronize(DoProcessTaskEnd);
end;

procedure TojThread.ProcessTaskStart;
begin
  if Assigned(FCurrentTask)
  then Synchronize(DoProcessTaskStart);
end;

procedure TojThread.ThreadEnd;
begin
  if Assigned(FOnThreadEnd) then Synchronize(DoThreadEnd);
end;

procedure TojThread.ThreadIdle;
begin
  if Assigned(FOnThreadIdle) then Synchronize(DoThreadIdle);
end;

procedure TojThread.ThreadStart;
begin
  if Assigned(FOnThreadStart) then Synchronize(DoThreadStart);
end;

procedure TojThread.ProcessThreadTaskEnd;
begin
  if Assigned(FCurrentTask) AND Assigned(FOnTaskEnd)
  then Synchronize(DoProcessThreadTaskEnd);
end;

procedure TojThread.ProcessThreadTaskStart;
begin
  //  testujemy od razu zdarzenie zeby nie synchronizowac sie na darmo
  if Assigned(FCurrentTask) AND (Assigned(FOnTaskStart))
  then Synchronize(DoProcessThreadTaskStart);
end;

{ TojThreadUtils }

procedure TojThreadUtils.AddTask(Task: TojThreadTask);
begin
  FThread.TaskList.Add(Task);
end;

constructor TojThreadUtils.Create(TaskList: TojThreadTaskList);
begin
  inherited Create;
  //  W¹tek ZAWSZE tworzony i od razu uruchamiany
  FThread:= TojThread.Create(TaskList, TRUE);
  FThread.FreeOnTerminate:= FALSE;
  //  FThread.Resume;
  FThread.Start;
end;

destructor TojThreadUtils.Destroy;
begin
  FThread.Terminate;
  //  wersja oficjalna, w sumie chyba zvbedne bo kopiuj\wklej
  FThread.WaitFor;
  FreeAndNil(FThread);

  inherited;
end;

function TojThreadUtils.getIgnoreUnhandledTaskExceptions: boolean;
begin
  result:= FThread.IgnoreUnhandledTaskExceptions;
end;

function TojThreadUtils.getOnTaskEndEvent: TojThreadTaskEndEvent;
begin
  result:= FThread.OnTaskEnd;
end;

function TojThreadUtils.getOnTaskExceptionEvent: TojThreadTaskExceptionEvent;
begin
  result:= FThread.OnTaskException;
end;

function TojThreadUtils.getOnTaskLogReceive: TojThreadTaskLogReceiveEvent;
begin
  result:= FThread.OnTaskLogReceive;
end;

function TojThreadUtils.getOnTaskStart: TojThreadTaskStartEvent;
begin
  result:= FThread.OnTaskStart;
end;

function TojThreadUtils.getOnThreadEnd: TojThreadEndEvent;
begin
  result:= FThread.OnThreadEnd;
end;

function TojThreadUtils.getOnThreadException: TojThreadExceptionEvent;
begin
  result:= FThread.OnThreadException;
end;

function TojThreadUtils.getOnThreadIdle: TojThreadIdleEvent;
begin
  result:= FThread.OnThreadIdle;
end;

function TojThreadUtils.getOnThreadStart: TojThreadStartEvent;
begin
  result:= FThread.OnThreadStart;
end;

function TojThreadUtils.IsExecuting: boolean;
begin
  result:= FThread.IsExecuting;
end;

function TojThreadUtils.IsIdle: boolean;
begin
  result:= FThread.IsIdle;
end;

procedure TojThreadUtils.setIgnoreUnhandledTaskExceptions(const Value: boolean);
begin
  FThread.IgnoreUnhandledTaskExceptions:= Value;
end;

procedure TojThreadUtils.setOnTaskEndEvent(const Value: TojThreadTaskEndEvent);
begin
  FThread.OnTaskEnd:= Value;
end;

procedure TojThreadUtils.setOnTaskExceptionEvent(const Value: TojThreadTaskExceptionEvent);
begin
  FThread.OnTaskException:= Value;
end;

procedure TojThreadUtils.setOnTaskLogReceive(const Value: TojThreadTaskLogReceiveEvent);
begin
  FThread.OnTaskLogReceive:= Value;
end;

procedure TojThreadUtils.setOnTaskStart(const Value: TojThreadTaskStartEvent);
begin
  FThread.OnTaskStart:= Value;
end;

procedure TojThreadUtils.setOnThreadEnd(const Value: TojThreadEndEvent);
begin
  FThread.OnThreadEnd:= Value;
end;

procedure TojThreadUtils.setOnThreadException(const Value: TojThreadExceptionEvent);
begin
  FThread.OnThreadException:= Value;
end;

procedure TojThreadUtils.setOnThreadIdle(const Value: TojThreadIdleEvent);
begin
  FThread.OnThreadIdle:= Value;
end;

procedure TojThreadUtils.setOnThreadStart(const Value: TojThreadStartEvent);
begin
  FThread.OnThreadStart:= Value;
end;

function TojThreadUtils.TaskCount: integer;
begin
  result:= FThread.TaskList.Count;
end;

procedure TojThreadUtils.Terminate;
begin
  FThread.Terminate;
end;

function TojThreadUtils.WaitForIdle(TimeOut: Cardinal; ProcessMessages: boolean): boolean;
var v_tick: DWORD;
const CNST_LOCAL_TIMEOUT = 25;
begin
  v_tick:= 0;
  result:= IsIdle;

  while (not result) AND ( (v_tick < TimeOut) OR (TimeOut = 0) ) do
  begin
    WaitForSingleObject(FThread.Handle, CNST_LOCAL_TIMEOUT);
    if ProcessMessages then Application.ProcessMessages;
    inc(v_tick, CNST_LOCAL_TIMEOUT);

    result:= IsIdle;
  end;

end;

function TojThreadUtils.WaitForTerm(TimeOut: Cardinal; ProcessMessages: boolean): boolean;
var v_tick: DWORD;
const CNST_LOCAL_TIMEOUT = 25;
begin
  v_tick:= 0;
  result:= FThread.Terminated AND (not IsExecuting);

  while (not result) AND ( (v_tick < TimeOut) OR (TimeOut = 0) ) do
  begin
    WaitForSingleObject(FThread.Handle, CNST_LOCAL_TIMEOUT);
    if ProcessMessages then Application.ProcessMessages;
    inc(v_tick, CNST_LOCAL_TIMEOUT);

    result:= FThread.Terminated AND (not IsExecuting);
  end;

end;

{ TojProcedureThreadTask }

constructor TojProcedureThreadTask.Create(TaskName: string; Method: TThreadProcedure; TaskEndCallBack: TojThreadTaskEndCallback);
begin
  inherited Create(TaskName);
  OnTaskEndCallback:= TaskEndCallBack;
  FMethod:= Method;
end;

procedure TojProcedureThreadTask.Execute(ctx: TojThreadTaskContext);
begin
  //  ctx.ForwardMessage('uruchamia %s z klasy %s', [self.TaskName, self.ClassType.ClassName]);
  if Assigned(FMethod) then FMethod();
  ctx.ReturnValue:= NULL;
end;

{ TojThreadTaskContext }

procedure TojThreadTaskContext.connectTo(Thread: TojThread; Task: TojThreadTask);
begin
  FThread:= Thread;
  FTask:= Task;
end;


constructor TojThreadTaskContext.Create;
begin
  inherited;
  FReturnValue:= NULL;
  FThread:= nil;
  FTask:= nil;
  FSuccess:= FALSE;
  FExceptionHandled:= FALSE;
  FExceptionObject:= nil;
end;

destructor TojThreadTaskContext.Destroy;
begin
  FreeAndNil(FExceptionObject);
  inherited;
end;

procedure TojThreadTaskContext.ForwardLog(const LogText: string; LogType: TojThreadLogType);
begin
  if Assigned(FThread)
  then FThread.ForwardLog(LogText, FTask.TaskName, LogType);
end;

procedure TojThreadTaskContext.setExceptionHandled(const Value: boolean);
begin
  if FExceptionHandled <> Value
  then FExceptionHandled:= Value;
end;

procedure TojThreadTaskContext.setExceptionObject(const Value: Exception);
begin
  if FExceptionObject <> Value then
  begin
    FreeAndNil(FExceptionObject);
    FExceptionObject:= Value;
  end;
end;

procedure TojThreadTaskContext.setSuccess(const Value: boolean);
begin
  if FSuccess <> Value then FSuccess:= Value;
end;

end.
