(*
  2017-03-xx reset
  2017-10-xx reset
*)
unit ojThreadUtils;

interface
uses  Windows, classes, sysUtils, Forms, StdCtrls, Controls, Graphics, messages,
      GraphUtil, Contnrs, DB, Variants, ExtCtrls;


type

  TojThreadTask = class;
  TojThreadTaskList = class;
  TojThreadTaskContext = class;
  TojThread = class;


  TojThreadEvent = TNotifyEvent;
  TojThreadExportMessageEvent = procedure(Sender: TObject; const TextMessage: string; IsPublic: boolean) of object;
  TojThreadExceptionEvent = procedure(Sender: TObject; E:Exception) of object;
  TojThreadTaskProcessExceptionEvent = procedure(Sender: TojThreadTaskContext; E:Exception; var Handled: boolean) of object;

  TojThreadTaskEvent = procedure(Sender: TojThreadTaskContext)of object;


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
    FOnTaskStart: TojThreadTaskEvent;
    FOnTaskEnd: TojThreadTaskEvent;
    FOnTaskException: TojThreadTaskProcessExceptionEvent;
  protected
    //  te sa synchronizowane przez watek
    procedure DoTaskStartEvents(ctx: TojThreadTaskContext);virtual;
    procedure DoTaskEndEvents(ctx: TojThreadTaskContext);virtual;
    procedure DoTaskHandleExceptionEvents(ctx: TojThreadTaskContext; E:Exception; var Handled: boolean);virtual;
  public
    procedure Execute(ctx: TojThreadTaskContext);virtual;abstract;
    constructor Create(TaskName: string);overload;virtual;
  public
    property TaskName: string read FTaskName write FTaskName;
  public
    property OnTaskStart: TojThreadTaskEvent read FOnTaskStart write FOnTaskStart;
    property OnTaskEnd: TojThreadTaskEvent read FOnTaskEnd write FOnTaskEnd;
    property OnTaskException: TojThreadTaskProcessExceptionEvent read FOnTaskException write FOnTaskException;
  end;

  {$endregion 'TojThreadTask'}

  {$region 'TojTestThreadTask'}

  TojTestThreadTask = class(TojThreadTask)
  private
    FSleep: Cardinal;
    FExceptionChance: byte;
  public
    constructor Create(TaskName: string; p_SleepMiliSec: Cardinal; p_ExceptionChance: byte);reintroduce;virtual;
    procedure Execute(ctx: TojThreadTaskContext);override;
  end;

  {$endregion 'TojTestThreadTask'}


  {$region 'TojThreadTaskContext'}


  TojThreadTaskContext = class
  private
    FTask: TojThreadTask;
    FThread: TojThread;
    FReturnValue: Variant;
    FSuccess: boolean;

    FExceptionHandled: boolean;
    FExceptionClass: ExceptClass;
    FExceptionMessage: string;
  protected
    procedure setSuccess(const Value: boolean);
    procedure setExceptionClass(const Value: ExceptClass);
    procedure setExceptionMessage(const Value: string);
    procedure setExceptionHandled(const Value: boolean);
  public
    constructor Create(Thread: TojThread; Task: TojThreadTask);virtual;
    destructor Destroy;override;
    procedure ExportMesasge(const TextMessage: string; IsPublic: boolean);
  public
    property Task: TojThreadTask read FTask;
    property Success: boolean read FSuccess;
    property ReturnValue: Variant read FReturnValue write FReturnValue;

    property ExceptionHandled: boolean read FExceptionHandled;
    property ExceptionClass: ExceptClass read FExceptionClass;
    property ExceptionMessage: string read FExceptionMessage;
  end;


  {$endregion 'TojThreadTaskContext'}


  {$region 'TojThread'}

  TojThread = class(TThread)
  private
    FTaskList: TojThreadTaskList;
    FCurrentContext: TojThreadTaskContext;
    FIsExecuting: Variant;
    FIgnoreUnhandledTaskExceptions: boolean;
    //  do obs³ugi wyj¹tków przez HandleThreadException i  HandleThreadTaskException
    FThreadException: Exception;
    //  dla interfejsu
    function getIgnoreUnhandledTaskExceptions: boolean;
    procedure setIgnoreUnhandledTaskExceptions(const Value: boolean);
  private
    FOnThreadStart: TojThreadEvent;
    FOnThreadEnd: TojThreadEvent;
    FOnThreadIdle: TojThreadEvent;
    FOnThreadException: TojThreadExceptionEvent;
    FOnThreadTaskException: TojThreadTaskProcessExceptionEvent;

    FOnThreadTaskStart: TojThreadEvent;
    FOnThreadTaskEnd: TojThreadEvent;

    FOnThreadExportMessage: TojThreadExportMessageEvent;
  protected
    procedure Execute; override;

    //  dla Thread-a, bezparametrowe procedury zeby dzialaly z Synchronize
    procedure DoThreadStart;virtual;
    procedure DoThreadEnd;virtual;
    procedure DoThreadIdle;virtual;
    procedure DoThreadTaskStart;virtual;
    procedure DoThreadTaskEnd;virtual;
    procedure DoHandleThreadException;virtual;
    //  dla Task-a, bezparametrowe procedury zeby dzialaly z Synchronize
    procedure DoTaskStart;virtual;
    procedure DoTaskEnd;virtual;
    //  mix Thread i Task-a
    procedure DoHandleThreadTaskException;virtual;

    //  g³owne zdarzenia po stronie Thread-a
    //  metody do odpalania wlasciwej obslugi poprzez synchronize
    procedure ThreadStart;
    procedure ThreadEnd;
    procedure ThreadIdle;
    procedure ThreadTaskStart;
    procedure ThreadTaskEnd;
    procedure HandleThreadException;virtual;
    //  g³owne zdarzenie po stronie Task-a
    //  metody do odpalania wlasciwej obslugi poprzez synchronize
    procedure TaskStart;
    procedure TaskEnd;
    //  mix Thread i Task-a
    procedure HandleThreadTaskException;

    procedure ExportMesasge(const TextMessage: string; IsPublic: boolean);
  public
    constructor Create(TaskList: TojThreadTaskList; CreateSuspended: boolean = TRUE);reintroduce;virtual;
    destructor Destroy;override;
    function IsIdle: boolean;
    function IsExecuting: boolean;
  public
    property TaskList: TojThreadTaskList read FTaskList;
    property IgnoreUnhandledTaskExceptions: boolean read getIgnoreUnhandledTaskExceptions write setIgnoreUnhandledTaskExceptions;

    property OnThreadStart: TojThreadEvent read FOnThreadStart write FOnThreadStart;
    property OnThreadEnd: TojThreadEvent read FOnThreadEnd write FOnThreadEnd;
    property OnThreadIdle: TojThreadEvent read FOnThreadIdle write FOnThreadIdle;
    property OnThreadException: TojThreadExceptionEvent read FOnThreadException write FOnThreadException;
    property OnThreadTaskException: TojThreadTaskProcessExceptionEvent read FOnThreadTaskException write FOnThreadTaskException;
    property OnTaskStart: TojThreadEvent read FOnThreadTaskStart write FOnThreadTaskStart;
    property OnTaskEnd: TojThreadEvent read FOnThreadTaskEnd write FOnThreadTaskEnd;
    property OnThreadExportMesasge: TojThreadExportMessageEvent read FOnThreadExportMessage write FOnThreadExportMessage;
  end;

  {$endregion 'TojThread'}


implementation
uses dateUtils, types, dialogs, math;

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

//function TojThreadTaskList.PopPreview: TojThreadTask;
//begin
//  LockList;
//  try
//    if FList.Count > 0
//    then result:= TojThreadTask(FList.First)
//    else result:= nil;
//  finally
//    UnlockList;
//  end;
//end;

procedure TojThreadTaskList.UnlockList;
begin
  LeaveCriticalSection(FLock);
end;

{ TojThreadTask }

constructor TojThreadTask.Create(TaskName: string);
begin
  inherited Create;
  FTaskName:= TaskName;
  //  FOnTaskStart:= nil;
  //  FOnTaskEnd:= nil;
  //  FOnTaskException:= nil;
end;

procedure TojThreadTask.DoTaskEndEvents(ctx: TojThreadTaskContext);
begin
  if Assigned(FOnTaskEnd) then FOnTaskEnd(ctx);
end;

procedure TojThreadTask.DoTaskHandleExceptionEvents(ctx: TojThreadTaskContext; E:Exception;  var Handled: boolean);
begin
  if Assigned(FOnTaskException) then FOnTaskException(ctx, E, Handled);
end;

procedure TojThreadTask.DoTaskStartEvents(ctx: TojThreadTaskContext);
begin
  if Assigned(FOnTaskStart) then FOnTaskStart(ctx);
end;

{ TojThread }

constructor TojThread.Create(TaskList: TojThreadTaskList; CreateSuspended: boolean);
begin
  if Assigned(TaskList)
  then FTaskList:= TaskList
  else FTaskList:= TojThreadTaskList.Create;

  FCurrentContext:= nil;
  FIsExecuting:= NULL;
  FIgnoreUnhandledTaskExceptions:= FALSE;
  FThreadException:= nil;

  inherited Create(CreateSuspended);

//  if not CreateSuspended then
//    Start;  //  resume
end;

destructor TojThread.Destroy;
begin
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

  if Assigned(FOnThreadException) then FOnThreadException(nil, FThreadException);
end;

procedure TojThread.DoHandleThreadTaskException;
var v_handled: boolean;
begin
  v_handled:= FCurrentContext.ExceptionHandled;
  try
    //  task i thread maj¹ oddzielne zdarzenia do obslugi wyj¹tku
    //  task ma pierszenstwo
    FCurrentContext.Task.DoTaskHandleExceptionEvents(FCurrentContext, FThreadException, v_handled);

    //  zdarzenie dla thread odpalane ZAWSZE nawet jak zdarzenie po stronie taska
    //  zwróci v_handled = TRUE
    if Assigned(FOnThreadTaskException)
    then FOnThreadTaskException(FCurrentContext, FThreadException, v_handled);
  finally
    FCurrentContext.setExceptionHandled( v_handled );
  end;

end;

procedure TojThread.DoTaskEnd;
begin
  if Assigned(FCurrentContext) then FCurrentContext.Task.DoTaskEndEvents(FCurrentContext);
end;

procedure TojThread.DoTaskStart;
begin
  if Assigned(FCurrentContext) then FCurrentContext.Task.DoTaskStartEvents(FCurrentContext);
end;

procedure TojThread.DoThreadEnd;
begin
  if Assigned(FOnThreadEnd) then FOnThreadEnd(nil);
end;

procedure TojThread.DoThreadIdle;
begin
  if Assigned(FOnThreadIdle) then FOnThreadIdle(nil);
end;

procedure TojThread.DoThreadStart;
begin
  if Assigned(FOnThreadStart) then FOnThreadStart(nil);
end;

procedure TojThread.DoThreadTaskEnd;
begin
  if Assigned(FOnThreadTaskEnd) AND Assigned(FCurrentContext) then FOnThreadTaskEnd(FCurrentContext);
end;

procedure TojThread.DoThreadTaskStart;
begin
  if Assigned(FOnThreadTaskStart) AND Assigned(FCurrentContext) then FOnThreadTaskStart(FCurrentContext);
end;

procedure TojThread.Execute;
const CNST_LOCAL_TIMEOUT = 50;
begin
  FIsExecuting:= TRUE;

  TRY
    TRY
      ThreadStart;
      while not self.Terminated do
      begin

        if FTaskList.AtLeast then
        begin

          //  przetwarzaj Task-i
          while not self.Terminated AND FTaskList.AtLeast do
          begin

            //  utworz kontekst do obs³ugi nastepnego Task-a,
            //  od tej chwili kontekst odpowiada za jego posprzatanie
            FCurrentContext:= TojThreadTaskContext.Create(self, FTaskList.Pop);
            TRY
              try
                try
                  ThreadTaskStart;
                  TaskStart;

                  FCurrentContext.Task.Execute(FCurrentContext);
                  FCurrentContext.setSuccess( TRUE );
                except
                  FCurrentContext.setSuccess( FALSE );
                  HandleThreadTaskException;

                  if not FCurrentContext.ExceptionHandled then
                  begin
                    if FIgnoreUnhandledTaskExceptions
                    then ExportMesasge('ignoring unhandled task exception: ' +  FCurrentContext.Task.TaskName, TRUE)
                    else raise;
                  end;

                end;

              finally
                //  zdarzenia Thread-a - koniec taska, w kontekscie info czy babolem czy OK
                ThreadTaskEnd;
                //  zdarzenia Task-a - koniec taska, w kontekscie info czy babolem czy OK
                TaskEnd;
              end;
            FINALLY
              //  oddzielne finally na wypadek baboli w zdarzeniach obslugi konca Taska
              FreeAndNil(FCurrentContext);
            END;

          end;

          // Task-i siê skoñczyly, wiez zdarzenia
          ThreadIdle;
        end;

        // Task-i siê skoñczyly, przysypia czekajac na nowe
        Sleep(CNST_LOCAL_TIMEOUT);
      end;  //  while not self.Terminated do

    EXCEPT
      //  jakis nieznany \ nieobsluzony wyj¹tek,
      HandleThreadException;
      raise;
    END;

  FINALLY
    ThreadEnd;
    FIsExecuting:= FALSE;
  END;

  EXIT;
{
  TRY
    ThreadStart;
    TRY

      while not self.Terminated do
      begin

        if FTaskList.AtLeast then
        begin

          while not self.Terminated AND FTaskList.AtLeast do
          begin

            FCurrentContext:= TojThreadTaskContext.Create(self, FTaskList.Pop);
            TRY
              try
                try
                  ProcessThreadTaskStart; //  zdarzenia Thread-a - start taska
                  ProcessTaskStart;       //  zdarzenia Taska-a - start taska

                  FCurrentContext.Task.Execute(FCurrentContext);
                  FCurrentContext.setSuccess( TRUE );
                except
                  FCurrentContext.setSuccess( FALSE );
                  ProcessHandleTaskException;

                  if not FCurrentContext.ExceptionHandled then
                  begin
                    if FIgnoreUnhandledTaskExceptions
                    then ForwardLog('ignoring unhandled task exception', FCurrentContext.Task.TaskName, tltDebug)
                    else raise;
                  end;
                end;

              finally
                ProcessThreadTaskEnd;   //  zdarzenia Thread-a - koniec taska
                ProcessTaskEnd;         //  zdarzenia Taska-a - koniec taska
              end;
            FINALLY
              //  oddzielne finally na wypadek baboli w zdarzeniach obslugi konca Taska
              FreeAndNil(FCurrentContext);
            END;
          end;

          ThreadIdle; //  wyczyscil liste tasków wiec zdarzenie
        end;

        Sleep(CNST_LOCAL_TIMEOUT);
      end;  //  while not self.Terminated do

    EXCEPT
      HandleThreadException;
      //  jak TaskEndCallBack lub AfterTask siê posypie to tytaj wczyscimy
      //  FreeAndNil(FCurrentTask);
      //  FCurrentContext:= nil;
      //  nie ma prawa sie pojawic bo zwalnianie FCurrentContext jest niezaleznym finally
      FreeandNil(FCurrentContext);
    END;

  FINALLY
    ThreadEnd;
    FIsExecuting:= FALSE;
  END;

}
end;

procedure TojThread.ExportMesasge(const TextMessage: string; IsPublic: boolean);
begin
  //  na ³atwizne,
  if Assigned(FOnThreadExportMessage)
  then self.Synchronize(
      procedure()
      begin
        FOnThreadExportMessage(nil, TextMessage, IsPublic);
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

  FThreadException:= Exception(ExceptObject);
  try
    // Don't show EAbort messages
    if not (FThreadException is EAbort) then
    begin
      if Assigned(FOnThreadException)
      then Synchronize(DoHandleThreadException);
    end;
  finally
    FThreadException:= nil;
  end;
end;

procedure TojThread.HandleThreadTaskException;
begin
  //  task i thread maj¹ oddzielne zdarzenia do obslugi wyj¹tku
  //  wy-if-owanie jest robione w DoHandleThreadTaskException

  //  nie sprawdzamy czy jest kontekst??
  FThreadException:= Exception(ExceptObject);
  try
    // Don't show EAbort messages
    if not (FThreadException is EAbort) then
    begin
      //  kontekst dostanei tylko klase wyj¹tku i message
      FCurrentContext.setExceptionClass( ExceptClass( FThreadException.ClassType) );
      FCurrentContext.setExceptionMessage( FThreadException.Message );
      FCurrentContext.setExceptionHandled(FALSE);
      Synchronize(DoHandleThreadTaskException);
    end;
  finally
    FThreadException:= nil;
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
      ((FIsExecuting=TRUE) AND (FCurrentContext = nil) AND (FTaskList.Count = 0))
      OR
      //  wszed³ w pêtlê Execute ale ju¿ j¹ zakonczyl (albo wlasnie opuszcza)
      //  bo wykryl Terminate lub polecial wyj¹tek
      ((FIsExecuting=FALSE) AND (FCurrentContext = nil) )  //  currentTask w sumie nas nie interesuje
        );
end;

procedure TojThread.setIgnoreUnhandledTaskExceptions(const Value: boolean);
begin
  FIgnoreUnhandledTaskExceptions:= Value;
end;

procedure TojThread.TaskEnd;
begin
  if Assigned(FCurrentContext) then Synchronize(DoTaskEnd);
end;

procedure TojThread.TaskStart;
begin
  if Assigned(FCurrentContext) then Synchronize(DoTaskStart);
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

procedure TojThread.ThreadTaskEnd;
begin
  if Assigned(FOnThreadTaskEnd) AND Assigned(FCurrentContext) then Synchronize(DoThreadTaskEnd);
end;

procedure TojThread.ThreadTaskStart;
begin
  if Assigned(FOnThreadTaskStart) AND Assigned(FCurrentContext) then Synchronize(DoThreadTaskStart);
end;

{ TojThreadTaskContext }

constructor TojThreadTaskContext.Create(Thread: TojThread; Task: TojThreadTask);
begin
  inherited Create;
  FTask:= Task;
  FThread:= Thread;
  FReturnValue:= NULL;
  FSuccess:= FALSE;
  FExceptionHandled:= FALSE;
  FExceptionClass:= nil;
  FExceptionMessage:= '';
end;

destructor TojThreadTaskContext.Destroy;
begin
  FreeAndNil(FTask);
  inherited;
end;

procedure TojThreadTaskContext.ExportMesasge(const TextMessage: string; IsPublic: boolean);
begin
  if Assigned(FThread) then FThread.ExportMesasge(TextMessage, IsPublic);
end;

procedure TojThreadTaskContext.setExceptionClass(const Value: ExceptClass);
begin
  FExceptionClass:= Value;
end;

procedure TojThreadTaskContext.setExceptionHandled(const Value: boolean);
begin
  FExceptionHandled:= Value;
end;

procedure TojThreadTaskContext.setExceptionMessage(const Value: string);
begin
  FExceptionMessage:= Value;
end;

procedure TojThreadTaskContext.setSuccess(const Value: boolean);
begin
  FSuccess:= Value;
end;

{ TojTestThreadTask }

constructor TojTestThreadTask.Create(TaskName: string; p_SleepMiliSec: Cardinal; p_ExceptionChance: byte);
begin
  inherited Create(TaskName);
  FSleep:= p_SleepMiliSec;
  FExceptionChance:= p_ExceptionChance;
end;

procedure TojTestThreadTask.Execute(ctx: TojThreadTaskContext);
begin
  Sleep(FSleep);
  if (FExceptionChance > 0) then
  begin
    if FExceptionChance >= 100
    then raise Exception.Create('TojTestThreadTask.Execute -> ExceptionChance = 100%');

    if RandomRange(1, 99) <= FExceptionChance
    then raise Exception.CreateFmt('TojTestThreadTask.Execute -> ExceptionChance = %d%%', [FExceptionChance]);
  end;

end;

end.
