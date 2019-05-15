unit ojValueList;

interface
uses classes, SysUtils, System.Generics.Collections;


type
  TojVariantListObject = class;
  TojVariantListIterator = class;
  TojVariantType = (ovtUnknown, ovtNull, ovtString, ovtInteger, ovtFloat, ovtBoolean, ovtDate, ovtDateTime);

  IojVariantList = interface['{28431968-3797-4BBD-BEE9-3732CD1069DC}']
    function refCount: Integer;
    function Copy: IojVariantList;
    procedure Clear;

    procedure Add(const Value: Variant);overload;
    procedure Add(const Values: array of Variant); overload;

    procedure Insert(Index: Integer; const Value: Variant);overload;
    procedure Insert(Index: Integer; const Values: array of Variant); overload;

    procedure Remove(Value: Variant);
    function IndexOf(Value: Variant): integer;

    function First: Variant;
    function Last: Variant;
    function Count: integer;
    function IsEmpty: boolean;
    function Contain(Value: Variant): boolean;
    function Min: Variant;
    function Max: Variant;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;

    function AsList(Separator: string = ','): string;
    function AsPgArray(pg_item_type: string=''): string;
    function ToString: string;

    function getEnumerator(): TojVariantListIterator;

    function getItems(Index: integer): Variant;
    procedure setItems(Index: integer; const Value: Variant);
    property Items[Index: integer]: Variant read getItems write setItems;default;
  end;

  TojVariantListObject = class(TInterfacedObject, IojVariantList)
  protected
    class var FInstCount: integer;
  public
    Function InstCount: integer;
  protected
    FData: TList<Variant>;
    function refCount: Integer;
  private
    function getItems(Index: integer): Variant;
    procedure setItems(Index: integer; const Value: Variant);
  protected
    function Copy: IojVariantList; virtual;
    procedure Clear; virtual;
    procedure Add(const Value: Variant);overload;
    procedure Add(const Values: array of Variant); overload;

    procedure Insert(Index: integer; const Value: Variant); overload;
    procedure Insert(Index: Integer; const Values: array of Variant); overload;

    procedure Remove(Value: Variant);
    function IndexOf(Value: Variant): integer;

    function First: Variant;
    function Last: Variant;
    function Count: integer;
    function IsEmpty: boolean;
    function Contain(Value: Variant): boolean;
    function Min: Variant;
    function Max: Variant;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;
    function AsList(Separator: string = ','): string;
    function AsPgArray(pg_item_type: string=''): string;

    function GetEnumerator(): TojVariantListIterator;
  public
    constructor Create; virtual;
    destructor Destroy;override;
    function ToString: string;override;

    property Items[Index: integer]: Variant read getItems write setItems;default;
  end;


  TojVariantListIterator = class
  private
    function getCurrent: Variant;
  protected
    FData: TojVariantListObject;
    FIndex: integer;
  public
    constructor Create(VariantListObject: TojVariantListObject);
    destructor Destroy;override;
    function  MoveNext: boolean;
    property Current: Variant read getCurrent;
  end;


  TojVariantList = record
  private
    RAW: string;
    FData: IojVariantList;
    function getItems(Index: integer): Variant;
    procedure setItems(Index: integer; const Value: Variant);
  public
    function checkData: IojVariantList;
    function getData: IojVariantList;
    procedure buildRAW;
  public
    procedure Clear;
    procedure Add(const Value: Variant);overload;
    procedure Add(const Values: array of Variant); overload;
    //  procedure Add(const Values: string; Separator: string = ',');overload;

    procedure Insert(Index: integer; const Value: Variant); overload;
    procedure Insert(Index: Integer; const Values: array of Variant); overload;
    //  procedure Insert(Index: Integer; const Values: string; Separator: string = ',');overload;

    procedure Remove(Value: Variant);
    function IndexOf(Value: Variant): integer;

    function First: Variant;
    function Last: Variant;
    function Count: integer;
    function IsEmpty: boolean;
    function Contain(Value: Variant): boolean;
    function Min: Variant;
    function Max: Variant;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;
    function AsList(Separator: string = ','): string;
    function AsPgArray(pg_item_type: string=''): string;
    function ToString: string;

    function getEnumerator(): TojVariantListIterator;

    property Items[Index: integer]: Variant read getItems write setItems;default;
//  public
//    //  IMPLICIT -> v_atr:=  a;   EXPLICIT -> v_atr:=  string(a);
//    class operator Implicit(a: TojVariantList): string;
//    class operator Implicit(a: string): TojVariantList;
//
//    class operator Add(a: TojVariantList; b: Int64): TojVariantList;
//    class operator Add(a: Int64; b: TojVariantList): TojVariantList;
//
//    class operator Add(a: TojVariantList; b: TojVariantList): TojVariantList;
//
//    //    class operator Subtract(a: TojInt64; b: TojInt64) : TojInt64;
//    class operator Equal(a: TojVariantList; b: TojVariantList):boolean;
//    class operator NotEqual(a: TojVariantList; b: TojVariantList):boolean;
  end;

  function VarIsPusty(Value: Variant): boolean;
  function VariantType(Value: Variant): TojVariantType;
  function VarToStrPretty(Value: Variant): string;

implementation
uses math, Variants, strUtils, dateUtils;


{ TojVariantList }


function VarIsPusty(Value: Variant): boolean;
begin
  result:= VarIsNull(Value) OR VarIsClear(Value) OR VarIsEmpty(Value);
end;

function VarIsBoolean(const V: Variant): Boolean;
begin
  result:= FindVarData(V)^.VType in [varBoolean];
end;

function VarIsDate(const V: Variant): Boolean;
begin
  result:= FindVarData(V)^.VType in [varDate];
end;


function VariantType(Value: Variant): TojVariantType;
begin
  if VarIsPusty(Value)
  then result:= ovtNull

  else if VarIsStr(Value)
  then result:= ovtString

  else if VarIsOrdinal(Value)
  then if VarIsBoolean(Value)
       then result:= ovtBoolean
       else result:= ovtInteger

  else if VarIsFloat(Value)
       then if VarIsDate(Value)
            then if TimeOf(RoundTo(Value, -8)) = 0.0
                 then result:= ovtDate
                 else result:= ovtDateTime
            else result:= ovtFloat

  else result:= ovtUnknown;
end;

function VarToStrPretty(Value: Variant): string;
var v_fs: TFormatSettings;
const bool_cast: array [boolean] of string = ('false', 'true');
begin
  v_fs:= TFormatSettings.Create(1033);
  case VariantType(Value) of
    ovtUnknown: result:= VarToStr(Value);
    ovtNull: result:= 'null';
    ovtString: result:= VarToStr(Value);
    ovtInteger: result:= VarToStr(Value);
    ovtFloat: result:= FloatToStr(Value, v_fs);
    ovtBoolean: result:= bool_cast[ (Value=TRUE) ];
    ovtDate: result:= FormatDateTime('yyyy-mm-dd', VarToDateTime(Value));
    ovtDateTime: result:= FormatDateTime('yyyy-mm-dd hh:nn:ss', VarToDateTime(Value));
  end;
end;

procedure TojVariantList.Add(const Value: Variant);
begin
  checkData.Add(Value);
  buildRAW;
end;

function TojVariantList.checkData: IojVariantList;
begin
  //  wersja gdy chcemy zmienic dane
  if (FData = nil)
  then FData:= TojVariantListObject.Create

  else if FData.refCount > 1
  then FData:= FData.Copy;

  result:= FData;
end;

procedure TojVariantList.Clear;
begin
  checkData.Clear;
  buildRAW;
end;

function TojVariantList.Contain(Value: Variant): boolean;
begin
  result:= getData.Contain(Value);
end;

function TojVariantList.Count: integer;
begin
  result:= getData.Count;
end;

procedure TojVariantList.Delete(Index: integer);
begin
  checkData.Delete(Index);
  buildRAW;
end;

//class operator TojVariantList.Equal(a, b: TojVariantList): boolean;
//begin
//  //  albo zrobic petle zeby nie generowal pelnej listy
//  result:= (a.FData = b.FData)
//      OR (a.AsList = b.AsList);
//end;

function TojVariantList.First: Variant;
begin
  result:= getData.First;
end;

function TojVariantList.getData: IojVariantList;
begin
  // wersja gdy chcemy tylko czytac dane
  if (FData = nil)
  then FData:= TojVariantListObject.Create;

  result:= FData;
end;

function TojVariantList.getEnumerator: TojVariantListIterator;
begin
  result:= checkData.getEnumerator;
end;

function TojVariantList.getItems(Index: integer): Variant;
begin
  result:= getData[Index];
end;

//class operator TojVariantList.Implicit(a: TojVariantList): string;
//begin
//  result:= a.AsList();
//end;
//
//class operator TojVariantList.Implicit(a: string): TojVariantList;
//begin
//  result.Clear;
//  result.Add(a);
//end;

function TojVariantList.IndexOf(Value: Variant): integer;
begin
  result:= getData.IndexOf(Value);
end;

//procedure TojVariantList.Insert(Index: Integer; const Values: string; Separator: string);
//begin
//  checkData.Insert(Index, Values, Separator);
//  buildRAW;
//end;

function TojVariantList.IsEmpty: boolean;
begin
  result:= getData.IsEmpty;
end;

procedure TojVariantList.Insert(Index: Integer; const Values: array of Variant);
begin
  checkData.Insert(Index, Values);
  buildRAW;
end;

procedure TojVariantList.Insert(Index: integer; const Value: Variant);
begin
  checkData.Insert(Index, Value);
  buildRAW;
end;

function TojVariantList.Last: Variant;
begin
  result:= getData.Last;
end;

function TojVariantList.Max: Variant;
begin
  result:= getData.Max;
end;

function TojVariantList.Min: Variant;
begin
  result:= getData.Min;
end;

//class operator TojVariantList.NotEqual(a, b: TojVariantList): boolean;
//begin
//  result:= (a.AsList() <> b.AsList());
//end;

procedure TojVariantList.Remove(Value: Variant);
begin
  checkData.Remove(Value);
  buildRAW;
end;

procedure TojVariantList.RemoveDuplicates;
begin
  checkData.RemoveDuplicates;
  buildRAW;
end;

procedure TojVariantList.setItems(Index: integer; const Value: Variant);
begin
  checkData[Index]:= Value;
end;

procedure TojVariantList.Add(const Values: array of Variant);
begin
  checkData.Add(Values);
  buildRAW;
end;

//procedure TojVariantList.Add(const Values: string; Separator: string);
//begin
//  checkData.Add(Values, Separator);
//  buildRAW;
//end;

function TojVariantList.AsList(Separator: string): string;
begin
  result:= getData.AsList(Separator);
end;

function TojVariantList.AsPgArray(pg_item_type: string): string;
begin
  result:= getData.AsPgArray(pg_item_type);
end;

procedure TojVariantList.buildRAW;
begin
  RAW:= AsList();
end;

procedure TojVariantList.Sort;
begin
  checkData.Sort;
  buildRAW;
end;

function TojVariantList.ToString: string;
begin
  result:= getData.ToString;
end;

//class operator TojVariantList.Add(a: TojVariantList; b: Int64): TojVariantList;
//begin
//  result:= a;
//  result.Add(b);
//end;
//
//class operator TojVariantList.Add(a: Int64; b: TojVariantList): TojVariantList;
//begin
//  result:= b;
//  result.Insert(0, a);
//end;
//
//class operator TojVariantList.Add(a, b: TojVariantList): TojVariantList;
//begin
//  result:= a;
//  result.Add(b.AsList);
//end;

{ TojVariantListObject }

procedure TojVariantListObject.Add(const Value: Variant);
begin
  FData.Add(Value);
end;

procedure TojVariantListObject.Add(const Values: array of Variant);
begin
  FData.AddRange(Values);
end;

function TojVariantListObject.AsList(Separator: string): string;
var v_item: Variant;
begin
  result:= '';
  for v_item in FData do
    result:= result + VarToStrPretty(v_item) + Separator;

  if result <> ''
  then result:= System.Copy(result, 1, Length(result) - Length(Separator));
end;

function TojVariantListObject.AsPgArray(pg_item_type: string): string;
var v_item: Variant;
    v_vt: TojVariantType;
begin
  result:= '';
  for v_item in self.FData do
  begin
    v_vt:= VariantType(v_item);

    //  TODO

  end;

  if pg_item_type = ''
  then result:= format('{%s}', [result])
  else result:= format('CAST(''{%s}'' AS %s)', [result, pg_item_type]);
end;

procedure TojVariantListObject.Clear;
begin
  FData.Clear;
end;

function TojVariantListObject.Contain(Value: Variant): boolean;
begin
  result:= FData.Contains(Value);
end;

function TojVariantListObject.Copy: IojVariantList;
var v_obj: TojVariantListObject;
begin
  v_obj:= TojVariantListObject.Create;
  try
    v_obj.FData.AddRange(self.FData);
    result:= v_obj;
  except
    FreeAndNil(v_obj);
    raise;
  end;

end;

function TojVariantListObject.Count: integer;
begin
  result:= FData.Count;
end;

constructor TojVariantListObject.Create;
begin
  inherited;
  FData:= TList<Variant>.Create();

  Inc(TojVariantListObject.FInstCount);
end;


procedure TojVariantListObject.Delete(Index: integer);
begin
  FData.Delete(Index);
end;

destructor TojVariantListObject.Destroy;
begin
  FreeAndNil(FData);
  inherited;
  Dec(TojVariantListObject.FInstCount);
end;

function TojVariantListObject.getEnumerator: TojVariantListIterator;
begin
  result:= TojVariantListIterator.Create(self);
end;

function TojVariantListObject.First: Variant;
begin
  result:= FData.First;
end;

function TojVariantListObject.getItems(Index: integer): Variant;
begin
  result:= FData[Index];
end;

function TojVariantListObject.IndexOf(Value: Variant): integer;
begin
  result:= FData.IndexOf(Value);
end;

procedure TojVariantListObject.Insert(Index: Integer; const Values: array of Variant);
begin
  FData.InsertRange(Index, Values);
end;

procedure TojVariantListObject.Insert(Index: integer; const Value: Variant);
begin
  FData.Insert(Index, Value);
end;

function TojVariantListObject.Last: Variant;
begin
  result:= FData.Last;
end;

function TojVariantListObject.Max: Variant;
var v_item: Variant;
begin
  if self.IsEmpty then
  begin
    result:= NULL;
    Exit;
  end;

  result:= First;
  for v_item in self.FData do
    if v_item > result
    then result:= v_item;

end;

function TojVariantListObject.Min: Variant;
var v_item: Variant;
begin
  if self.IsEmpty then
  begin
    result:= NULL;
    Exit;
  end;

  result:= First;
  for v_item in self.FData do
    if v_item < result
    then result:= v_item;
end;

function TojVariantListObject.refCount: Integer;
begin
  result:= (inherited refCount);
end;

procedure TojVariantListObject.Remove(Value: Variant);
begin
  FData.Remove(Value);
end;

procedure TojVariantListObject.RemoveDuplicates;
var i, j: integer;
    v_value: Int64;
begin
  i:= 0;
  while i < FData.Count do
  begin
    v_value:= FData[i];

    j:= i+1;
    while j < FData.Count do
    begin
      if FData[j] = v_value
      then FData.Delete(j)
      else inc(j);
    end;

    inc(i);
  end;
end;

procedure TojVariantListObject.setItems(Index: integer; const Value: Variant);
begin
  FData[Index]:= Value;
end;

procedure TojVariantListObject.Sort;
begin
  FData.Sort;
end;

function TojVariantListObject.ToString: string;
begin
  result:= format('%d: [%s]', [self.Count, self.AsList]);
end;

//procedure TojVariantListObject.Insert(Index: Integer; const Values: string; Separator: string);
//var v_pos, v_length: integer;
//    v_item: string;
//    v_to_split: string;
//    v_result_items: integer;
//    v_result: array of Variant;
//begin
//  v_result_items:= 0;
//  v_length:= Length(Separator);
//  v_to_split:= Values.Trim;
//
//  v_pos:= v_to_split.IndexOf(Separator, 0);
//  while v_pos >= 0 do
//  begin
//    v_item:= v_to_split.Substring(0, v_pos);
//
//    Inc(v_result_items);
//    SetLength(v_result, v_result_items);
//    v_result[v_result_items-1]:= StrToInt64(v_item);
//
//    v_to_split:= v_to_split.Substring(v_pos + v_length);
//    v_pos:= v_to_split.IndexOf(Separator, 0);
//  end;
//
//  if (v_to_split <> '') then
//  begin
//    Inc(v_result_items);
//    SetLength(v_result, v_result_items);
//    v_result[v_result_items-1]:= StrToInt64(v_to_split);
//  end;
//
//  self.Insert(Index, v_result);
//end;

function TojVariantListObject.InstCount: integer;
begin
  result:= TojVariantListObject.FInstCount;
end;

function TojVariantListObject.IsEmpty: boolean;
begin
  result:= (FData.Count = 0);
end;

{ TojVariantListIterator }

constructor TojVariantListIterator.Create(VariantListObject: TojVariantListObject);
begin
  inherited Create;
  FIndex:= -1;
  FData:= VariantListObject;
end;

destructor TojVariantListIterator.Destroy;
begin
  inherited;
end;

function TojVariantListIterator.getCurrent: Variant;
begin
  result:= FData[FIndex];
end;

function TojVariantListIterator.MoveNext: boolean;
begin
  Inc(FIndex);
  result:= (FIndex < FData.Count);
end;

initialization
  TojVariantListObject.FInstCount:= 0;

end.
