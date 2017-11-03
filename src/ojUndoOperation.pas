//  2017-10-23
//    + start
//
//
unit ojUndoOperation;

interface
uses  classes, rtti, variants;


type

  IojUndoOperation = interface ['{78A0FF26-6AE0-4A0A-B7DF-798F09219DB0}']
    function CanUndo: boolean;
    function CanRedo: boolean;
    procedure Undo;
    procedure Redo;
  end;


  TojCustomUndoOperation = class(TInterfacedObject, IojUndoOperation)
  protected
    procedure DoUndo; virtual;
    procedure DoRedo; virtual;
    constructor Create;virtual;
  public
    function CanUndo: boolean; virtual;
    function CanRedo: boolean; virtual;
    procedure Undo;
    procedure Redo;
  end;

  TojUndoPropertyOperation = class(TojCustomUndoOperation)
  protected
    FRTTI: TRttiContext;
    FObject: TObject;
    FNewValue: TValue;
    FOldValue: TValue;
    FRttiPropery: TRttiProperty;
    procedure DoUndo; override;
    procedure DoRedo; override;
  public
    constructor Create(p_Object: TObject; p_PropertyName: string; p_NewValue: Variant);reintroduce; overload; virtual;
    constructor Create(p_Object: TObject; p_PropertyName: TRttiProperty; p_NewValue: Variant);reintroduce; overload; virtual;
    destructor Destroy;override;
  end;


implementation

{ TojCustomUndoOperation }

function TojCustomUndoOperation.CanRedo: boolean;
begin
  result:= TRUE;
end;

function TojCustomUndoOperation.CanUndo: boolean;
begin
  result:= TRUE;
end;

constructor TojCustomUndoOperation.Create;
begin
  inherited Create;
end;

procedure TojCustomUndoOperation.DoRedo;
begin
end;

procedure TojCustomUndoOperation.DoUndo;
begin
end;

procedure TojCustomUndoOperation.Redo;
begin
  if CanRedo then DoRedo;
end;

procedure TojCustomUndoOperation.Undo;
begin
  if CanUndo then DoUndo;
end;

{ TojRttiUndoOperation }

constructor TojUndoPropertyOperation.Create(p_Object: TObject; p_PropertyName: string; p_NewValue: Variant);
begin
  inherited Create;
  FObject:= p_Object;

  FNewValue:= TValue.FromVariant(p_NewValue);
  FOldValue:= TValue.FromVariant(NULL);

  FRTTI:= TRttiContext.Create;
  FRttiPropery:= FRTTI.GetType(FObject.ClassType).GetProperty(p_PropertyName);

  FOldValue:= FRttiPropery.GetValue(FObject);
  DoRedo;
end;

constructor TojUndoPropertyOperation.Create(p_Object: TObject; p_PropertyName: TRttiProperty; p_NewValue: Variant);
begin
  inherited Create;
  FObject:= p_Object;

  FNewValue:= TValue.FromVariant(p_NewValue);
  FOldValue:= TValue.FromVariant(NULL);

  FRTTI:= TRttiContext.Create;
  FRttiPropery:= p_PropertyName;

  FOldValue:= FRttiPropery.GetValue(FObject);
  DoRedo;
end;

destructor TojUndoPropertyOperation.Destroy;
begin
  FRTTI.Free;
  inherited;
end;

procedure TojUndoPropertyOperation.DoRedo;
begin
  FRttiPropery.SetValue(FObject, FNewValue);
end;

procedure TojUndoPropertyOperation.DoUndo;
begin
  FRttiPropery.SetValue(FObject, FOldValue);
end;

end.
