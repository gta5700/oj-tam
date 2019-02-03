{
  2018-10-16 reset II
}
unit ojThreadUtils_nju;

interface
uses  Windows, classes, sysUtils, Forms, StdCtrls, Controls, Graphics, Messages,
      GraphUtil, Contnrs, DB, Variants, ExtCtrls;

type

  TojCustomThread = class;
  TojThreadTask = class;
  TojThreadTaskList = class;
  TojThreadTaskContext = class;
  TojThreadTaskContextClass = class of TojThreadTaskContext;

  TojThreadEvent = procedure of object;
  TojThreadTaskEvent = procedure(Context: TojThreadTaskContext) of object;
  TojThreadTaskExceptionEvent = procedure(Context: TojThreadTaskContext; var Handled: boolean) of object;

  TojThreadTaskMethod = procedure(Context: TojThreadTaskContext);
  TojThreadTaskProcedure = reference to procedure(Context: TojThreadTaskContext);


  TojThreadMessageType = (tmtLog, tmtDebug);
  TojThreadTaskExportMessageEvent = procedure(TaskName: string; Text: string; MessageType: TojThreadMessageType) of object;


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
  //  task jest TYLKO G£UPIM kontenerem na "dane" do przetworzenia
  //  obsluge contextu tez przebic do TojThread
  TojThreadTask = class
  private
    FTaskName: string;
    FCallbackMeth: TojThreadTaskMethod;
    FCallbackProc: TojThreadTaskProcedure;
    FOnTaskEnd: TojThreadTaskEvent;
    FOnTaskException: TojThreadTaskExceptionEvent;
    FOnTaskStart: TojThreadTaskEvent;
  protected
    procedure inner_DoTaskStart(Context: TojThreadTaskContext);virtual;
    procedure inner_DoTaskEnd(Context: TojThreadTaskContext);virtual;
    procedure inner_DoTaskHandleException(Context: TojThreadTaskContext; var Handled: boolean);virtual;
  protected
    constructor Create(TaskName: string);overload;virtual;
    constructor Create(TaskName: string; p_CallbackProc: TojThreadTaskProcedure);overload;virtual;
    constructor Create(TaskName: string; p_CallbackMeth: TojThreadTaskMethod);overload;virtual;
  public
    procedure Execute(ctx: TojThreadTaskContext);virtual;abstract;
    destructor Destroy;override;
    function getThreadTaskContextClass: TojThreadTaskContextClass;virtual;
  public
    //  konec nic wiecej nie dodawac, klasie bazowej wystarczy
    property TaskName: string read FTaskName write FTaskName;
    property OnTaskStart: TojThreadTaskEvent read FOnTaskStart write FOnTaskStart;
    property OnTaskEnd: TojThreadTaskEvent read FOnTaskEnd write FOnTaskEnd;
    property OnTaskException: TojThreadTaskExceptionEvent read FOnTaskException write FOnTaskException;
  end;
  {$endregion 'TojThreadTask'}


  {$region 'TojMethodThreadTask'}

  TojThreadTaskEx = class(TojThreadTask)
  private
    FMeth: TThreadMethod;    //  obj
    FProc: TThreadProcedure; //  ano
    FMethContext: TojThreadTaskMethod;    //  obj
    FProcContext: TojThreadTaskProcedure; //  ano
  public
    constructor Create(TaskName: string; Method: TThreadMethod; p_CallbackProc: TojThreadTaskProcedure);reintroduce;overload;virtual;
    constructor Create(TaskName: string; MethodCtx: TojThreadTaskMethod; p_CallbackProc: TojThreadTaskProcedure);reintroduce;overload;virtual;
    constructor Create(TaskName: string; Proc: TThreadProcedure; p_CallbackProc: TojThreadTaskProcedure);reintroduce;overload;virtual;
    constructor Create(TaskName: string; ProcCtx: TojThreadTaskProcedure; p_CallbackProc: TojThreadTaskProcedure);reintroduce;overload;virtual;
    procedure Execute(ctx: TojThreadTaskContext);override;
  end;

  {$endregion 'TojMethodThreadTask'}

  {$region 'TojThreadTaskContext'}
  TojThreadTaskContext = class
  private
    FTask: TojThreadTask;
    FThread: TojCustomThread;
    FExecSuccess: boolean;
    FReturnValue: Variant;
    FReturnData: Pointer;
    FExceptionObject: Exception; // kopia
    FExceptionHandled: boolean; //  jesli TRUE to byl wyj¹tek ale go utopiono
  protected
    procedure setExecSuccess(const Value: boolean);
    procedure setExceptionHandled(const Value: boolean);
    procedure setExceptionObject(const Value: Exception);
  public
    constructor Create;virtual;
    destructor Destroy;override;
    procedure ExportMessage(const Text: string; MessageType: TojThreadMessageType = tmtLog);
    function Success: boolean;

    property Task: TojThreadTask read FTask;
    property ExecSuccess: boolean read FExecSuccess;
    property ReturnValue: Variant read FReturnValue write FReturnValue;
    property ReturnData: Pointer read FReturnData write FReturnData;
    property ExceptionObject: Exception read FExceptionObject;
    property ExceptionHandled: boolean read FExceptionHandled;
  end;
  {$endregion 'TojThreadTaskContext'}



  {$region 'TojCustomThread'}

  TojCustomThread = class(TThread)
  private
    FTaskList: TojThreadTaskList;
    FCurrentContext: TojThreadTaskContext;
    FIsExecuting: Variant;
  private
    FIgnoreUnhandledTaskExceptions: boolean;
    FIgnoreUnhandledThreadExceptions: boolean;
    function getIgnoreUnhandledTaskExceptions: boolean;
    procedure setIgnoreUnhandledTaskExceptions(const Value: boolean);
    function getIgnoreUnhandledThreadExceptions: boolean;
    procedure setIgnoreUnhandledThreadExceptions(const Value: boolean);
  private
    //  zdarzenia
    FOnThreadStart: TojThreadEvent;
    FOnThreadEnd: TojThreadEvent;
    FOnThreadIdle: TojThreadEvent;
    FOnThreadException: TojThreadEvent;
    FOnThreadTaskException: TojThreadTaskExceptionEvent;

    FOnThreadTaskStart: TojThreadTaskEvent;
    FOnThreadTaskEnd: TojThreadTaskEvent;

    FOnThreadTaskExportMessage: TojThreadTaskExportMessageEvent;
  protected
    procedure Execute; override;

    //  bezparametrowe procedury zeby dzialaly z Synchronize
    procedure DoThreadStart;virtual;
    procedure DoThreadEnd;virtual;
    procedure DoThreadIdle;virtual;
    procedure DoThreadException;virtual;
    procedure DoThreadTaskStart;virtual;
    procedure DoThreadTaskEnd;virtual;
    procedure DoThreadTaskException;virtual;

    procedure DoTaskStart;virtual;
    procedure DoTaskEnd;virtual;
    procedure DoTaskException;virtual;

    procedure ThreadStart;
    procedure ThreadEnd;
    procedure ThreadIdle;
    procedure ThreadException;
    procedure ThreadTaskStart;
    procedure ThreadTaskEnd;

    procedure TaskStart;
    procedure TaskEnd;
    procedure TaskException;
  public
    constructor Create(TaskList: TojThreadTaskList; CreateSuspended: boolean = TRUE);reintroduce;virtual;
    destructor Destroy;override;
    function IsIdle: boolean;
    function IsExecuting: boolean;
    function IsWorking: boolean;
    procedure DropRemainingTasks;
    procedure ExportMessage(const Text: string; TaskName: string = ''; MessageType: TojThreadMessageType = tmtLog);
  public
    property TaskList: TojThreadTaskList read FTaskList;
    property IgnoreUnhandledTaskExceptions: boolean read getIgnoreUnhandledTaskExceptions write setIgnoreUnhandledTaskExceptions;
    property IgnoreUnhandledThreadExceptions: boolean read getIgnoreUnhandledThreadExceptions write setIgnoreUnhandledThreadExceptions;

    property OnThreadStart: TojThreadEvent read FOnThreadStart write FOnThreadStart;
    property OnThreadEnd: TojThreadEvent read FOnThreadEnd write FOnThreadEnd;
    property OnThreadIdle: TojThreadEvent read FOnThreadIdle write FOnThreadIdle;
    property OnThreadException: TojThreadEvent read FOnThreadException write FOnThreadException;

    property OnTaskStart: TojThreadTaskEvent read FOnThreadTaskStart write FOnThreadTaskStart;
    property OnTaskEnd: TojThreadTaskEvent read FOnThreadTaskEnd write FOnThreadTaskEnd;
    property OnTaskException: TojThreadTaskExceptionEvent read FOnThreadTaskException write FOnThreadTaskException;

    property OnTaskExportMessage: TojThreadTaskExportMessageEvent read FOnThreadTaskExportMessage write FOnThreadTaskExportMessage;
  end;

  {$endregion 'TojCustomThread'}


  {$region 'TojThread'}

  IojMiniThread = interface(IInterface) ['{4E0546D6-6EF7-4FF3-BBF2-5A7DB7E560C1}']
    function IsIdle: boolean;
    function IsExecuting: boolean;
    function IsWorking: boolean;
    procedure AddTask(Task: TojThreadTask);
    function WaitForIdle(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function WaitForTerm(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function TaskCount: integer;
    procedure DropRemainingTasks;
  end;

  IojThread= interface(IInterface)['{32167765-EEE2-4CDF-993F-0CCF4D00E703}']
    function getOnTaskEnd: TojThreadTaskEvent;
    function getOnTaskException: TojThreadTaskExceptionEvent;
    function getOnTaskStart: TojThreadTaskEvent;
    function getOnThreadEnd: TojThreadEvent;
    function getOnThreadException: TojThreadEvent;
    function getOnThreadIdle: TojThreadEvent;
    function getOnThreadStart: TojThreadEvent;
    function getOnThreadTaskExportMessage: TojThreadTaskExportMessageEvent;
    function getIgnoreUnhandledTaskExceptions: boolean;
    procedure setOnTaskEnd(const Value: TojThreadTaskEvent);
    procedure setOnTaskException(const Value: TojThreadTaskExceptionEvent);
    procedure setOnTaskStart(const Value: TojThreadTaskEvent);
    procedure setOnThreadEnd(const Value: TojThreadEvent);
    procedure setOnThreadException(const Value: TojThreadEvent);
    procedure setOnThreadIdle(const Value: TojThreadEvent);
    procedure setOnThreadStart(const Value: TojThreadEvent);
    procedure setOnThreadTaskExportMessage(const Value: TojThreadTaskExportMessageEvent);
    procedure setIgnoreUnhandledTaskExceptions(const Value: boolean);
    function getIgnoreUnhandledThreadExceptions: boolean;
    procedure setIgnoreUnhandledThreadExceptions(const Value: boolean);
    function IsIdle: boolean;
    function IsExecuting: boolean;
    function IsWorking: boolean;
    procedure Terminate;
    procedure AddTask(Task: TojThreadTask);
    function WaitForIdle(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function WaitForTerm(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function TaskCount: integer;
    procedure DropRemainingTasks;
    property IgnoreUnhandledTaskExceptions: boolean read getIgnoreUnhandledTaskExceptions write setIgnoreUnhandledTaskExceptions;
    property IgnoreUnhandledThreadExceptions: boolean read getIgnoreUnhandledThreadExceptions write setIgnoreUnhandledThreadExceptions;

    property OnThreadStart: TojThreadEvent read getOnThreadStart write setOnThreadStart;
    property OnThreadEnd: TojThreadEvent read getOnThreadEnd write setOnThreadEnd;
    property OnThreadIdle: TojThreadEvent read getOnThreadIdle write setOnThreadIdle;
    property OnThreadException: TojThreadEvent read getOnThreadException write setOnThreadException;

    property OnTaskStart: TojThreadTaskEvent read getOnTaskStart write setOnTaskStart;
    property OnTaskEnd: TojThreadTaskEvent read getOnTaskEnd write setOnTaskEnd;
    property OnTaskException: TojThreadTaskExceptionEvent read getOnTaskException write setOnTaskException;

    property OnTaskExportMessage: TojThreadTaskExportMessageEvent read getOnThreadTaskExportMessage write setOnThreadTaskExportMessage;
  end;

  TojThread = class(TInterfacedObject, IojMiniThread, IojThread)
  private
    FThread: TojCustomThread;
    function getIgnoreUnhandledTaskExceptions: boolean;
    procedure setIgnoreUnhandledTaskExceptions(const Value: boolean);
    function getOnThreadStart: TojThreadEvent;
    procedure setOnThreadStart(const Value: TojThreadEvent);
    function getOnThreadEnd: TojThreadEvent;
    function getOnThreadIdle: TojThreadEvent;
    procedure setOnThreadEnd(const Value: TojThreadEvent);
    procedure setOnThreadIdle(const Value: TojThreadEvent);
    function getOnThreadException: TojThreadEvent;
    procedure setOnThreadException(const Value: TojThreadEvent);
    function getOnTaskEnd: TojThreadTaskEvent;
    function getOnTaskStart: TojThreadTaskEvent;
    procedure setOnTaskEnd(const Value: TojThreadTaskEvent);
    procedure setOnTaskStart(const Value: TojThreadTaskEvent);
    function getOnTaskException: TojThreadTaskExceptionEvent;
    procedure setOnTaskException(const Value: TojThreadTaskExceptionEvent);
    function getOnThreadTaskExportMessage: TojThreadTaskExportMessageEvent;
    procedure setOnThreadTaskExportMessage(const Value: TojThreadTaskExportMessageEvent);
    function getIgnoreUnhandledThreadExceptions: boolean;
    procedure setIgnoreUnhandledThreadExceptions(const Value: boolean);
  public
    constructor Create(TaskList: TojThreadTaskList);virtual;
    destructor Destroy;override;
    function IsIdle: boolean;
    function IsExecuting: boolean;
    function IsWorking: boolean;
    procedure Terminate;
    procedure AddTask(Task: TojThreadTask);
    function WaitForIdle(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function WaitForTerm(TimeOut: Cardinal = 0; ProcessMessages: boolean = TRUE): boolean;
    function TaskCount: integer;
    procedure DropRemainingTasks;
  public
    property IgnoreUnhandledTaskExceptions: boolean read getIgnoreUnhandledTaskExceptions write setIgnoreUnhandledTaskExceptions;
    property IgnoreUnhandledThreadExceptions: boolean read getIgnoreUnhandledThreadExceptions write setIgnoreUnhandledThreadExceptions;
  public
    property OnThreadStart: TojThreadEvent read getOnThreadStart write setOnThreadStart;
    property OnThreadEnd: TojThreadEvent read getOnThreadEnd write setOnThreadEnd;
    property OnThreadIdle: TojThreadEvent read getOnThreadIdle write setOnThreadIdle;
    property OnThreadException: TojThreadEvent read getOnThreadException write setOnThreadException;

    property OnTaskStart: TojThreadTaskEvent read getOnTaskStart write setOnTaskStart;
    property OnTaskEnd: TojThreadTaskEvent read getOnTaskEnd write setOnTaskEnd;
    property OnTaskException: TojThreadTaskExceptionEvent read getOnTaskException write setOnTaskException;

    property OnTaskExportMessage: TojThreadTaskExportMessageEvent read getOnThreadTaskExportMessage write setOnThreadTaskExportMessage;
  end;

  {$endregion 'TojThread'}



implementation

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

constructor TojThreadTask.Create(TaskName: string; p_CallbackMeth: TojThreadTaskMethod);
begin
  inherited Create;
  FTaskName:= TaskName;
  FCallbackMeth:= p_CallbackMeth;
  FCallbackProc:= nil;
end;

constructor TojThreadTask.Create(TaskName: string);
begin
  inherited Create;
  FTaskName:= TaskName;
  FCallbackMeth:= nil;
  FCallbackProc:= nil;
end;

constructor TojThreadTask.Create(TaskName: string; p_CallbackProc: TojThreadTaskProcedure);
begin
  inherited Create;
  FTaskName:= TaskName;
  FCallbackMeth:= nil;
  FCallbackProc:= p_CallbackProc;
end;

destructor TojThreadTask.Destroy;
begin
  inherited;
end;

function TojThreadTask.getThreadTaskContextClass: TojThreadTaskContextClass;
begin
  result:= TojThreadTaskContext;
end;

procedure TojThreadTask.inner_DoTaskEnd(Context: TojThreadTaskContext);
begin
  if Assigned(FOnTaskEnd) then FOnTaskEnd(Context);

  //  ew. inne jesli sie pojawi¹
  if Assigned(FCallbackMeth) then FCallbackMeth(Context);
  if Assigned(FCallbackProc) then FCallbackProc(Context);
end;

procedure TojThreadTask.inner_DoTaskHandleException(Context: TojThreadTaskContext; var Handled: boolean);
begin
  if Assigned(FOnTaskException) then FOnTaskException(Context, Handled);
  //  ew. inne jesli sie pojawi¹
end;

procedure TojThreadTask.inner_DoTaskStart(Context: TojThreadTaskContext);
begin
  if Assigned(FOnTaskStart) then FOnTaskStart(Context);
  //  ew. inne jesli sie pojawi¹
end;

{ TojThreadTaskContext }

constructor TojThreadTaskContext.Create;
begin
  FTask:= nil;
  FThread:= nil;
  FExecSuccess:= FALSE;
  FReturnValue:= NULL;
  FReturnData:= nil;
  FExceptionObject:= nil;
  FExceptionHandled:= FALSE;
end;

destructor TojThreadTaskContext.Destroy;
begin
  FreeAndNil(FTask);
  FreeAndNil(FExceptionObject);
  inherited;
end;

procedure TojThreadTaskContext.ExportMessage(const Text: string; MessageType: TojThreadMessageType);
begin
  if Assigned(FThread)
  then FThread.ExportMessage(Text, FTask.TaskName, MessageType);
end;

procedure TojThreadTaskContext.setExceptionHandled(const Value: boolean);
begin
  FExceptionHandled:= Value;
end;

procedure TojThreadTaskContext.setExceptionObject(const Value: Exception);
begin
  FreeAndNil(FExceptionObject);
  if Assigned(Value)
  then FExceptionObject:= ExceptClass( Value.ClassType ).Create(Value.Message);
end;

procedure TojThreadTaskContext.setExecSuccess(const Value: boolean);
begin
  FExecSuccess:= Value;
end;

function TojThreadTaskContext.Success: boolean;
begin
  result:= FExecSuccess OR FExceptionHandled;
end;

{ TojThread }

constructor TojCustomThread.Create(TaskList: TojThreadTaskList; CreateSuspended: boolean);
begin
  if Assigned(TaskList)
  then FTaskList:= TaskList
  else FTaskList:= TojThreadTaskList.Create;

  FCurrentContext:= nil;
  FIsExecuting:= NULL;

  FIgnoreUnhandledTaskExceptions:= FALSE;
  FIgnoreUnhandledThreadExceptions:= TRUE;

  inherited Create(CreateSuspended);
end;

destructor TojCustomThread.Destroy;
begin
  FreeAndNil(FCurrentContext);  //  nadgorliwe, powinno byc nil
  FreeAndNil(FTaskList);
  inherited;
end;

procedure TojCustomThread.DoTaskEnd;
begin
  if Assigned(FCurrentContext) then FCurrentContext.Task.inner_DoTaskEnd(FCurrentContext);
end;

procedure TojCustomThread.DoTaskException;
var v_handled: boolean;
begin
  v_handled:= FCurrentContext.ExceptionHandled;

  //  task i thread maj¹ oddzielne zdarzenia do obslugi wyj¹tku
  //  task ma pierszenstwo i moze utopic wyjatek
  FCurrentContext.Task.inner_DoTaskHandleException(FCurrentContext, v_handled);
  FCurrentContext.setExceptionHandled( v_handled );

  //  zdarzenie dla thread odpalane ZAWSZE nawet jak zdarzenie po stronie taska
  //  zwróci v_handled = TRUE
  DoThreadTaskException;
end;

procedure TojCustomThread.DoTaskStart;
begin
  if Assigned(FCurrentContext) then FCurrentContext.Task.inner_DoTaskStart(FCurrentContext);
end;

procedure TojCustomThread.DoThreadEnd;
begin
  if Assigned(FOnThreadEnd) then FOnThreadEnd();
end;

procedure TojCustomThread.DoThreadException;
begin
  if Assigned(FOnThreadException) then FOnThreadException();
end;

procedure TojCustomThread.DoThreadIdle;
begin
  if Assigned(FOnThreadIdle) then FOnThreadIdle();
end;

procedure TojCustomThread.DoThreadStart;
begin
  if Assigned(FOnThreadStart) then FOnThreadStart();
end;

procedure TojCustomThread.DoThreadTaskEnd;
begin
  if Assigned(FOnThreadTaskEnd) then FOnThreadTaskEnd(FCurrentContext);
end;

procedure TojCustomThread.DoThreadTaskException;
var v_handled: boolean;
begin
  if Assigned(FOnThreadTaskException) then
  begin
    v_handled:= FCurrentContext.ExceptionHandled;
    FOnThreadTaskException(FCurrentContext, v_handled);
    FCurrentContext.setExceptionHandled(v_handled);
  end;
end;

procedure TojCustomThread.DoThreadTaskStart;
begin
  if Assigned(FOnThreadTaskStart) then FOnThreadTaskStart(FCurrentContext);
end;

procedure TojCustomThread.DropRemainingTasks;
begin
  FTaskList.Clear(TRUE);
end;

procedure TojCustomThread.Execute;
const CNST_LOCAL_TIMEOUT = 50;

function prepareContext(Task: TojThreadTask): TojThreadTaskContext;
begin
  result:= Task.getThreadTaskContextClass.Create;
  result.FTask:= Task;
  result.FThread:= self;
end;

begin
  FIsExecuting:= TRUE;

  TRY
    try
      ThreadStart;
      //  petla ¿eby wracal do przetwarzania tasków, jesli poleci topiony przez nas wyjatek
      while not self.Terminated do
      TRY

        try

          while not self.Terminated do
          begin
            {$region 'uruchamiaj task-i'}
            if FTaskList.AtLeast then
            begin
              while not self.Terminated AND FTaskList.AtLeast do
              begin
                //  my zwalniamy Context -> context zwalnia Task-a,
                FCurrentContext:= prepareContext( FTaskList.Pop );
                {$region 'obsluga task.execute'}
                try
                  try
                    ThreadTaskStart; //  zdarzenia Thread-a - start taska
                    try
                      TaskStart;     //  zdarzenia Taska-a - start taska

                      try
                        FCurrentContext.Task.Execute(FCurrentContext);
                        FCurrentContext.setExecSuccess( TRUE );
                      except
                        on E: Exception do
                        begin
                          FCurrentContext.setExecSuccess( FALSE );
                          FCurrentContext.setExceptionObject( E );
                          TaskException;
                          if not FCurrentContext.ExceptionHandled then
                          begin
                            if FIgnoreUnhandledTaskExceptions
                            then ExportMessage('ignoring unhandled TASK exception', FCurrentContext.Task.TaskName, tmtDebug)
                            else raise;
                          end;
                        end
                      end;

                    finally
                      TaskEnd;       //  zdarzenia Taska-a - koniec taska
                    end
                  finally
                    ThreadTaskEnd;   //  zdarzenia Thread-a - koniec taska
                  end
                finally
                  FreeAndNil(FCurrentContext);
                end;
                {$endregion 'obsluga task.execute'}
              end;

              //  wyczyscil liste tasków wiec zdarzenie, tylko raz dla kazdego oczyszczenia listy tasków
              ThreadIdle;
            end;

            Sleep(CNST_LOCAL_TIMEOUT);
            {$endregion 'uruchamiaj task-i'}
          end;  //  while not self.Terminated do

        except
          on E: Exception do
          begin
            ThreadException;
            raise;
          end;
        end

      EXCEPT
        on E: Exception do
        begin
          //  tytaj g³ownie lapiemy wyjatki z powstale w metodzie ThreadException :)
          if FIgnoreUnhandledThreadExceptions
          //  zaloguj ze topimy wyj¹tek i wróc do wykonywania kolejnego TASK-a
          then ExportMessage('ignoring unhandled THREAD exception, keep working -> '+E.Message, '', tmtDebug)
          //  podnosimy wyj¹tek, wyskakujemy  z pêtli i trafiamy do FINALLY
          else raise;
        end;
      END;

    finally
      ThreadEnd;
    end
  FINALLY
    FIsExecuting:= FALSE;
  END;


//  TRY
//    ThreadStart;
//    //  petla ¿eby wracal do przetwarzania tasków, jesli poleci topiony przez nas wyjatek
//    while not self.Terminated do
//      TRY
//
//        while not self.Terminated do
//        begin
//          {$region 'uruchamiaj task-i'}
//          if FTaskList.AtLeast then
//          begin
//
//            while not self.Terminated AND FTaskList.AtLeast do
//            begin
//              //  my zwalniamy Context -> context zwalnia Task-a,
//              FCurrentContext:= prepareContext( FTaskList.Pop );
//              {$region 'obsluga task.execute'}
//              try
//                ThreadTaskStart; //  zdarzenia Thread-a - start taska
//                try
//                  TaskStart;     //  zdarzenia Taska-a - start taska
//                  try
//                    try
//                      FCurrentContext.Task.Execute(FCurrentContext);
//                      FCurrentContext.setExecSuccess( TRUE );
//                    except
//                      on E: Exception do
//                      begin
//                        FCurrentContext.setExecSuccess( FALSE );
//                        FCurrentContext.setExceptionObject( E );
//                        TaskException;
//                        if not FCurrentContext.ExceptionHandled then
//                        begin
//                          if FIgnoreUnhandledTaskExceptions
//                          then ExportMessage('ignoring unhandled TASK exception', FCurrentContext.Task.TaskName, tmtDebug)
//                          else raise;
//                        end;
//                      end;
//                    end;
//                  finally
//                    TaskEnd;       //  zdarzenia Taska-a - koniec taska
//                  end
//                finally
//                  ThreadTaskEnd;   //  zdarzenia Thread-a - koniec taska
//                end
//              finally
//                FreeAndNil(FCurrentContext);
//              end;
//              {$endregion 'obsluga task.execute'}
//            end;
//
//            ThreadIdle; //  wyczyscil liste tasków wiec zdarzenie
//          end;
//
//          Sleep(CNST_LOCAL_TIMEOUT);
//          {$endregion 'uruchamiaj task-i'}
//        end;  //  while not self.Terminated do
//
//      EXCEPT
//        on E: Exception do
//        begin
//          ThreadException;
//          //  jak TaskEndCallBack lub AfterTask siê posypie to tutaj wczyscimy
//          //  FreeAndNil(FCurrentContext);
//          if FIgnoreUnhandledThreadExceptions
//          then ExportMessage('ignoring unhandled THREAD exception, keep working -> '+E.Message, '', tmtDebug)
//          else raise;  //  podnosimy wyj¹tek, i trafiamy do FINALLY
//        end;
//      END;
//
//  FINALLY
//    ThreadEnd;
//    FIsExecuting:= FALSE;
//  END;



//  TRY
//    ThreadStart;
//    TRY
//
//      while not self.Terminated do
//      begin
//
//        if FTaskList.AtLeast then
//        begin
//
//          while not self.Terminated AND FTaskList.AtLeast do
//          begin
//            FCurrentContext:= prepareContext( FTaskList.Pop );
//            try
//              //  my zwalniamy Context -> context zwalnia Task-a,
//              try
//                ThreadTaskStart; //  zdarzenia Thread-a - start taska
//                TaskStart;       //  zdarzenia Taska-a - start taska
//                FCurrentContext.Task.Execute(FCurrentContext);
//                FCurrentContext.setExecSuccess( TRUE );
//              except
//                on E: Exception do
//                begin
//                  FCurrentContext.setExecSuccess( FALSE );
//                  FCurrentContext.setExceptionObject( E );
//                  TaskException;
//
//                  if not FCurrentContext.ExceptionHandled then
//                  begin
//                    if FIgnoreUnhandledTaskExceptions
//                    then ExportMessage('ignoring unhandled task exception', FCurrentContext.Task.TaskName, tmtDebug)
//                    else raise;
//                  end;
//                end;
//              end;
//
//            finally
//              TaskEnd;         //  zdarzenia Taska-a - koniec taska
//              ThreadTaskEnd;   //  zdarzenia Thread-a - koniec taska
//              FreeAndNil(FCurrentContext);
//            end;
//          end;
//
//          ThreadIdle; //  wyczyscil liste tasków wiec zdarzenie
//        end;
//
//        Sleep(CNST_LOCAL_TIMEOUT);
//      end;  //  while not self.Terminated do
//
//    EXCEPT
//      ThreadException;
//      //  jak TaskEndCallBack lub AfterTask siê posypie to tytaj wczyscimy
//      FreeAndNil(FCurrentContext);
//    END;
//
//  FINALLY
//    ThreadEnd;
//    FIsExecuting:= FALSE;
//  END;

end;

procedure TojCustomThread.ExportMessage(const Text: string; TaskName: string; MessageType: TojThreadMessageType);
begin
  if Assigned(FOnThreadTaskExportMessage)
  then self.Synchronize(
      procedure()
      begin
        FOnThreadTaskExportMessage(TaskName, Text, MessageType);
      end
      );
end;

function TojCustomThread.getIgnoreUnhandledTaskExceptions: boolean;
begin
  result:= FIgnoreUnhandledTaskExceptions;
end;

function TojCustomThread.getIgnoreUnhandledThreadExceptions: boolean;
begin
  result:= FIgnoreUnhandledThreadExceptions;
end;

function TojCustomThread.IsExecuting: boolean;
begin
  //  znaczy ze w¹tek zosta³ odpalony i wszed³ ju¿ w pêtlê
  result:= (FIsExecuting <> NULL) AND (FIsExecuting = TRUE);
end;

function TojCustomThread.IsIdle: boolean;
var v_current_task: TObject;
begin
  //  w sumie context bez taska nie istnieje
  if Assigned(FCurrentContext)
  then v_current_task:= FCurrentContext.Task
  else v_current_task:= nil;

  //  Idle oznacza bezrobocie, czyli wszedl w petle i ma pusta liste
  //  ew. uwzglednic jeszcze FCurrentTask
  result:= (FIsExecuting <> NULL)
    AND (
      //  wszed³ w pêtlê i skonczyly mu sie taski do wykonania, czeka na nowe
      ((FIsExecuting=TRUE) AND (v_current_task = nil) AND (FTaskList.Count = 0))
      OR
      //  wszed³ w pêtlê Execute ale ju¿ j¹ zakonczyl (albo wlasnie opuszcza)
      //  bo wykryl Terminate lub polecial wyj¹tek
      ((FIsExecuting=FALSE) AND (v_current_task = nil) )  //  currentTask w sumie nas nie interesuje
        );

end;

function TojCustomThread.IsWorking: boolean;
begin
  //  pracuje, przetwarza dane
  result:= Assigned(FCurrentContext);
end;

procedure TojCustomThread.setIgnoreUnhandledTaskExceptions(const Value: boolean);
begin
  FIgnoreUnhandledTaskExceptions:= Value;
end;

procedure TojCustomThread.setIgnoreUnhandledThreadExceptions(const Value: boolean);
begin
  FIgnoreUnhandledThreadExceptions:= Value;
end;

procedure TojCustomThread.TaskEnd;
begin
  if Assigned(FCurrentContext) then Synchronize(DoTaskEnd);
end;

procedure TojCustomThread.TaskException;
var v_exception: Exception;
begin
  v_exception:= Exception(ExceptObject);
  // Don't show EAbort messages
  if not (v_exception is EAbort) AND Assigned(FCurrentContext)
  then Synchronize(DoTaskException);
end;

procedure TojCustomThread.TaskStart;
begin
  if Assigned(FCurrentContext) then Synchronize(DoTaskStart);
end;

procedure TojCustomThread.ThreadEnd;
begin
  if Assigned(FOnThreadEnd) then Synchronize(DoThreadEnd);
end;

procedure TojCustomThread.ThreadException;
var v_exception: Exception;
begin
  // This function is virtual so you can override it
  // and add your own functionality.
  //  lokalna referencja tylko na potrzeby DoHandleThreadException
  v_exception:= Exception(ExceptObject);
  try
    // Don't show EAbort messages
    if not (v_exception is EAbort) then
    begin
      if Assigned(FOnThreadException)
      then Synchronize(DoThreadException);
    end;
  finally
    //  v_exception:= nil;  // ??
  end;
end;

procedure TojCustomThread.ThreadIdle;
begin
  if Assigned(FOnThreadIdle) then Synchronize(DoThreadIdle);
end;

procedure TojCustomThread.ThreadStart;
begin
  if Assigned(FOnThreadStart) then Synchronize(DoThreadStart);
end;

procedure TojCustomThread.ThreadTaskEnd;
begin
  //  testujemy od razu zdarzenie zeby nie synchronizowac sie na darmo
  if Assigned(FCurrentContext) AND (Assigned(FOnThreadTaskEnd))
  then Synchronize(DoThreadTaskEnd);
end;

procedure TojCustomThread.ThreadTaskStart;
begin
  //  testujemy od razu zdarzenie zeby nie synchronizowac sie na darmo
  if Assigned(FCurrentContext) AND (Assigned(FOnThreadTaskStart))
  then Synchronize(DoThreadTaskStart);
end;

{ TojMethodThreadTask }

constructor TojThreadTaskEx.Create(TaskName: string; Method: TThreadMethod; p_CallbackProc: TojThreadTaskProcedure);
begin
  inherited Create(TaskName, p_CallbackProc);
  FMeth:= Method;
  FProc:= nil;
  FMethContext:= nil;
  FProcContext:= nil;
end;

constructor TojThreadTaskEx.Create(TaskName: string; MethodCtx: TojThreadTaskMethod; p_CallbackProc: TojThreadTaskProcedure);
begin
  inherited Create(TaskName, p_CallbackProc);
  FMeth:= nil;
  FProc:= nil;
  FMethContext:= MethodCtx;
  FProcContext:= nil;
end;

constructor TojThreadTaskEx.Create(TaskName: string; Proc: TThreadProcedure; p_CallbackProc: TojThreadTaskProcedure);
begin
  inherited Create(TaskName, p_CallbackProc);
  FMeth:= nil;
  FProc:= Proc;
  FMethContext:= nil;
  FProcContext:= nil;
end;

constructor TojThreadTaskEx.Create(TaskName: string; ProcCtx, p_CallbackProc: TojThreadTaskProcedure);
begin
  inherited Create(TaskName, p_CallbackProc);
  FMeth:= nil;
  FProc:= nil;
  FMethContext:= nil;
  FProcContext:= ProcCtx;
end;

procedure TojThreadTaskEx.Execute(ctx: TojThreadTaskContext);
begin
  //  odpalamay TYLKO jedn¹ bo nie gwarantujemy kolejnosci wykonania
  if Assigned(FMeth) then FMeth()
  else if Assigned(FProc) then FProc()
  else if Assigned(FMethContext) then FMethContext(ctx)
  else if Assigned(FProcContext) then FProcContext(ctx);
end;

{ TojThread }

procedure TojThread.AddTask(Task: TojThreadTask);
begin
  FThread.TaskList.Add(Task);
end;

constructor TojThread.Create(TaskList: TojThreadTaskList);
begin
  inherited Create;
  //  W¹tek ZAWSZE tworzony i od razu uruchamiany
  FThread:= TojCustomThread.Create(TaskList, TRUE);
  FThread.FreeOnTerminate:= FALSE;
  //  FThread.Resume;
  FThread.Start;
end;

destructor TojThread.Destroy;
begin
  FThread.Terminate;
  //  wersja oficjalna, w sumie chyba zvbedne bo kopiuj\wklej
  FThread.WaitFor;
  FreeAndNil(FThread);

  inherited;
end;

procedure TojThread.DropRemainingTasks;
begin
  FThread.DropRemainingTasks;
end;

function TojThread.getIgnoreUnhandledTaskExceptions: boolean;
begin
  result:= FThread.IgnoreUnhandledTaskExceptions;
end;

function TojThread.getIgnoreUnhandledThreadExceptions: boolean;
begin
  result:= FThread.IgnoreUnhandledThreadExceptions;
end;

function TojThread.getOnTaskEnd: TojThreadTaskEvent;
begin
  result:= FThread.OnTaskEnd;
end;

function TojThread.getOnTaskException: TojThreadTaskExceptionEvent;
begin
  result:= FThread.OnTaskException;
end;

function TojThread.getOnTaskStart: TojThreadTaskEvent;
begin
  result:= FThread.OnTaskStart;
end;

function TojThread.getOnThreadEnd: TojThreadEvent;
begin
  result:= FThread.OnThreadEnd;
end;

function TojThread.getOnThreadException: TojThreadEvent;
begin
  result:= FThread.OnThreadException;
end;

function TojThread.getOnThreadIdle: TojThreadEvent;
begin
  result:= FThread.OnThreadIdle;
end;

function TojThread.getOnThreadStart: TojThreadEvent;
begin
  result:= FThread.OnThreadStart;
end;

function TojThread.getOnThreadTaskExportMessage: TojThreadTaskExportMessageEvent;
begin
  result:= FThread.OnTaskExportMessage;
end;

function TojThread.IsExecuting: boolean;
begin
  result:= FThread.IsExecuting;
end;

function TojThread.IsIdle: boolean;
begin
  result:= FThread.IsIdle;
end;

function TojThread.IsWorking: boolean;
begin
  result:= FThread.IsWorking;
end;

procedure TojThread.setIgnoreUnhandledTaskExceptions(const Value: boolean);
begin
  FThread.IgnoreUnhandledTaskExceptions:= Value;
end;

procedure TojThread.setIgnoreUnhandledThreadExceptions(const Value: boolean);
begin
  FThread.IgnoreUnhandledThreadExceptions:= Value;
end;

procedure TojThread.setOnTaskEnd(const Value: TojThreadTaskEvent);
begin
  FThread.OnTaskEnd:= Value;
end;

procedure TojThread.setOnTaskException(const Value: TojThreadTaskExceptionEvent);
begin
  FThread.OnTaskException:= Value;
end;

procedure TojThread.setOnTaskStart(const Value: TojThreadTaskEvent);
begin
  FThread.OnTaskStart:= Value;
end;

procedure TojThread.setOnThreadEnd(const Value: TojThreadEvent);
begin
  FThread.OnThreadEnd:= Value;
end;

procedure TojThread.setOnThreadException(const Value: TojThreadEvent);
begin
  FThread.OnThreadException:= Value;
end;

procedure TojThread.setOnThreadIdle(const Value: TojThreadEvent);
begin
  FThread.OnThreadIdle:= Value;
end;

procedure TojThread.setOnThreadStart(const Value: TojThreadEvent);
begin
  FThread.OnThreadStart:= Value;
end;

procedure TojThread.setOnThreadTaskExportMessage(const Value: TojThreadTaskExportMessageEvent);
begin
  FThread.OnTaskExportMessage:= Value;
end;

function TojThread.TaskCount: integer;
begin
  result:= FThread.TaskList.Count;
end;

procedure TojThread.Terminate;
begin
  FThread.Terminate;
end;

function TojThread.WaitForIdle(TimeOut: Cardinal; ProcessMessages: boolean): boolean;
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

function TojThread.WaitForTerm(TimeOut: Cardinal; ProcessMessages: boolean): boolean;
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

end.
