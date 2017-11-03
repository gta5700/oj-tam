{
  2017-10-31  - START

  2017-11-03  -  Attach(Data, Code: Pointer) / DeAttach(Data, Code: Pointer)
}
unit ojMultiEvent;

interface
uses classes, sysUtils, variants;


type

  TojCustomMultiEventClass = class of TojCustomMultiEvent;
  TojCustomMultiEvent = class(TObject)
  private
    FObservers: TList;
    FParams: array of Variant;  //  TValue
  protected
    function FindObserver(Observer: TMethod): integer;
    function getObserver(Index: integer): TMethod;
    procedure Broadcast(Observer: TMethod);overload;virtual;

    procedure paramsClear;
    function paramsCount: integer;
    function paramsAdd(Value: Variant): integer;
    function paramsValue(Index: Integer): Variant;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Attach(Observer: TMethod); overload;
    procedure DeAttach(Observer: TMethod); overload;
    procedure Attach(Data, Code: Pointer); overload;
    procedure DeAttach(Data, Code: Pointer); overload;
    procedure Broadcast;overload;
    function ObserverCount: integer;
  end;

  TojNotifyMultiEvent = class(TojCustomMultiEvent)
  protected
    procedure Broadcast(Observer: TMethod);override;
  public
    procedure Attach(Observer: TNotifyEvent);
    procedure DeAttach(Observer: TNotifyEvent);
    procedure Broadcast(Sender: TObject);overload;
  end;

implementation


{ TojCustomMultiEvent }

procedure TojCustomMultiEvent.Attach(Observer: TMethod);
var v_index: integer;
begin
  v_index:= FindObserver(Observer) * 2;
  if v_index >= 0 then Exit;

  FObservers.Add(Observer.Code);
  FObservers.Add(Observer.Data);
end;

procedure TojCustomMultiEvent.Attach(Data, Code: Pointer);
var v_method: TMethod;
begin
  v_method.Code:= Code;
  v_method.Data:= Data;
  Attach(v_method);
end;

procedure TojCustomMultiEvent.Broadcast;
var i: integer;
    v_method: TMethod;
begin
  for i:= 0 to ObserverCount-1 do
  begin
    v_method:= getObserver(i);
    Broadcast(v_method);
  end;
end;

procedure TojCustomMultiEvent.Broadcast(Observer: TMethod);
begin
  if (Observer.Code = nil) OR (Observer.Data = nil)
  then raise Exception.Create('TojCustomMultiEvent.Broadcast -> Observer is nil');
end;

constructor TojCustomMultiEvent.Create;
begin
  inherited;
  FObservers:= TList.Create;
  FParams:= nil;
end;

procedure TojCustomMultiEvent.DeAttach(Observer: TMethod);
var v_index: integer;
begin
  v_index:= FindObserver(Observer) * 2;
  if v_index < 0 then Exit;

  FObservers.Delete(v_index); // code
  FObservers.Delete(v_index); // data
end;

procedure TojCustomMultiEvent.DeAttach(Data, Code: Pointer);
var v_method: TMethod;
begin
  v_method.Code:= Code;
  v_method.Data:= Data;
  DeAttach(v_method);
end;

destructor TojCustomMultiEvent.Destroy;
begin
  FreeAndNil(FObservers);
  paramsClear;
  inherited;
end;

function TojCustomMultiEvent.FindObserver(Observer: TMethod): integer;
var i: integer;
    v_method: PMethod;
begin
  result:= -1;
  for i:= 0 to (FObservers.Count div 2)-1 do
  begin
    v_method:= FObservers.List[i*2];
    if v_method^ = Observer then
    begin
      result:= i;
      Exit;
    end;
  end;

end;

function TojCustomMultiEvent.getObserver(Index: integer): TMethod;
begin
  result.Code:= FObservers[Index*2]; // code
  result.Data:= FObservers[Index*2 + 1]; // data
end;

function TojCustomMultiEvent.ObserverCount: integer;
begin
  result:= (FObservers.Count div 2);
end;

function TojCustomMultiEvent.paramsAdd(Value: Variant): integer;
begin
  result:= 1+Length(FParams);
  SetLength(FParams, result);
  FParams[result-1]:= Value;
end;

procedure TojCustomMultiEvent.paramsClear;
begin
  SetLength(FParams, 0);  //  po co?
  FParams:= nil;
end;

function TojCustomMultiEvent.paramsCount: integer;
begin
  if FParams = nil
  then result:= 0
  else result:= Length(FParams);
end;

function TojCustomMultiEvent.paramsValue(Index: Integer): Variant;
begin
  result:= FParams[Index];
end;

{ TojNotifyMultiEvent }

procedure TojNotifyMultiEvent.Attach(Observer: TNotifyEvent);
begin
  inherited Attach(TMethod(Observer));
end;

procedure TojNotifyMultiEvent.Broadcast(Sender: TObject);
begin
  paramsClear;
  paramsAdd( NativeUInt(Sender) );
  inherited Broadcast;
end;

procedure TojNotifyMultiEvent.Broadcast(Observer: TMethod);
var v_sender: TObject;
begin
  inherited;
  v_sender:= TObject(NativeUInt(paramsValue(0)));
  TNotifyEvent(Observer)(v_sender);
end;

procedure TojNotifyMultiEvent.DeAttach(Observer: TNotifyEvent);
begin
  inherited DeAttach(TMethod(Observer));
end;

end.
