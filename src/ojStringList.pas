unit ojStringList;

//  dodac CaseSensitive
//  dodac LowerCaseAll
//  dodac UpperCaseAll

interface
uses classes, SysUtils, System.Generics.Collections;


type
  TojStringListObject = class;
  TojStringListIterator = class;

  IojStringList = interface ['{5F2BD251-14B2-4753-BAAE-DFCFCE45E31A}']
    function refCount: Integer;
    function Copy: IojStringList;
    procedure Clear;

    procedure Add(const Value: string);overload;
    procedure Add(const Values: array of string); overload;
    procedure AddList(const Values: string; Separator: string = ',');overload;

    procedure Insert(Index: Integer; const Value: string);overload;
    procedure Insert(Index: Integer; const Values: array of string); overload;
    procedure InsertList(Index: Integer; const Values: string; p_Separator: string = ',');overload;

    procedure Remove(Value: string);
    function IndexOf(Value: string): integer;

    function First: string;
    function Last: string;
    function Count: integer;
    function IsEmpty: boolean;
    function Contain(Value: string): boolean;
    function Min: string;
    function Max: string;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;
    //  nie ma quotowania
    function AsList(Separator: string = ','): string;
    //  function AsPgArray(): string;
    function ToString: string;

    function getEnumerator(): TojStringListIterator;

    function getItems(Index: integer): string;
    procedure setItems(Index: integer; const Value: string);
    property Items[Index: integer]: string read getItems write setItems;default;
  end;

  TojStringListObject = class(TInterfacedObject, IojStringList)
  protected
    class var FInstCount: integer;
  public
    function InstCount: integer;
  protected
    FData: TList<string>;
    function refCount: Integer;
  private
    function getItems(Index: integer): string;
    procedure setItems(Index: integer; const Value: string);
  protected
    function Copy: IojStringList; virtual;
    procedure Clear; virtual;
    procedure Add(const Value: string);overload;
    procedure Add(const Values: array of string); overload;
    procedure AddList(const Values: string; Separator: string = ',');overload;

    procedure Insert(Index: integer; const Value: string); overload;
    procedure Insert(Index: Integer; const Values: array of string); overload;
    procedure InsertList(Index: Integer; const Values: string; Separator: string = ',');overload;

    procedure Remove(Value: string);
    function IndexOf(Value: string): integer;

    function First: string;
    function Last: string;
    function Count: integer;
    function IsEmpty: boolean;
    function Contain(Value: string): boolean;
    function Min: string;
    function Max: string;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;
    function AsList(Separator: string = ','): string;
    //  function AsPgArray(): string;

    function GetEnumerator(): TojStringListIterator;
  public
    constructor Create; virtual;
    destructor Destroy;override;
    function ToString: string;override;

    property Items[Index: integer]: string read getItems write setItems;default;
  end;


  TojStringListIterator = class
  private
    function getCurrent: string;
  protected
    FData: TojStringListObject;
    FIndex: integer;
  public
    constructor Create(StringListObject: TojStringListObject);
    destructor Destroy;override;
    function  MoveNext: boolean;
    property Current: string read getCurrent;
  end;


  TojStringList = record
  private
    RAW: string;
    FData: IojStringList;
    function getItems(Index: integer): string;
    procedure setItems(Index: integer; const Value: string);
  public
    function checkData: IojStringList;
    function getData: IojStringList;
    procedure buildRAW;
  public
    procedure Clear;
    procedure Add(const Value: string);overload;
    procedure Add(const Values: array of string); overload;
    procedure AddList(const Values: string; Separator: string = ',');overload;

    procedure Insert(Index: integer; const Value: string); overload;
    procedure Insert(Index: Integer; const Values: array of string); overload;
    procedure InsertList(Index: Integer; const Values: string; Separator: string = ',');overload;

    procedure Remove(Value: string);
    function IndexOf(Value: string): integer;

    function First: string;
    function Last: string;
    function Count: integer;
    function IsEmpty: boolean;
    function Contain(Value: string): boolean;
    function Min: string;
    function Max: string;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;
    function AsList(Separator: string = ','): string;
    //  function AsPgArray(): string;
    function ToString: string;

    function getEnumerator(): TojStringListIterator;

    property Items[Index: integer]: string read getItems write setItems;default;
  public
    //  IMPLICIT -> v_atr:=  a;   EXPLICIT -> v_atr:=  string(a);
    class operator Implicit(a: TojStringList): string;
    class operator Implicit(a: string): TojStringList;

    class operator Add(a: TojStringList; b: string): TojStringList;
    class operator Add(a: string; b: TojStringList): TojStringList;

    class operator Add(a: TojStringList; b: TojStringList): TojStringList;

    //    class operator Subtract(a: TojInt64; b: TojInt64) : TojInt64;
    class operator Equal(a: TojStringList; b: TojStringList):boolean;
    class operator NotEqual(a: TojStringList; b: TojStringList):boolean;
  end;

implementation
uses strUtils;

{ TojStringList }

procedure TojStringList.Add(const Value: string);
begin
  checkData.Add(Value);
  buildRAW;
end;

function TojStringList.checkData: IojStringList;
begin
  //  wersja gdy chcemy zmienic dane
  if (FData = nil)
  then FData:= TojStringListObject.Create

  else if FData.refCount > 1
  then FData:= FData.Copy;

  result:= FData;
end;

procedure TojStringList.Clear;
begin
  checkData.Clear;
  buildRAW;
end;

function TojStringList.Contain(Value: string): boolean;
begin
  result:= getData.Contain(Value);
end;

function TojStringList.Count: integer;
begin
  result:= getData.Count;
end;

procedure TojStringList.Delete(Index: integer);
begin
  checkData.Delete(Index);
  buildRAW;
end;

class operator TojStringList.Equal(a, b: TojStringList): boolean;
begin
  //  albo zrobic petle zeby nie generowal pelnej listy
  result:= (a.FData = b.FData)
      OR (a.AsList = b.AsList);
end;

function TojStringList.First: string;
begin
  result:= getData.First;
end;

function TojStringList.getData: IojStringList;
begin
  // wersja gdy chcemy tylko czytac dane
  if (FData = nil)
  then FData:= TojStringListObject.Create;

  result:= FData;
end;

function TojStringList.getEnumerator: TojStringListIterator;
begin
  result:= checkData.getEnumerator;
end;

function TojStringList.getItems(Index: integer): string;
begin
  result:= getData[Index];
end;

class operator TojStringList.Implicit(a: TojStringList): string;
begin
  result:= a.AsList();
end;

class operator TojStringList.Implicit(a: string): TojStringList;
begin
  result.Clear;
  result.Add(a);
end;

function TojStringList.IndexOf(Value: string): integer;
begin
  result:= getData.IndexOf(Value);
end;

procedure TojStringList.InsertList(Index: Integer; const Values: string; Separator: string);
begin
  checkData.InsertList(Index, Values, Separator);
  buildRAW;
end;

function TojStringList.IsEmpty: boolean;
begin
  result:= getData.IsEmpty;
end;

procedure TojStringList.Insert(Index: Integer; const Values: array of string);
begin
  checkData.Insert(Index, Values);
  buildRAW;
end;

procedure TojStringList.Insert(Index: integer; const Value: string);
begin
  checkData.Insert(Index, Value);
  buildRAW;
end;

function TojStringList.Last: string;
begin
  result:= getData.Last;
end;

function TojStringList.Max: string;
begin
  result:= getData.Max;
end;

function TojStringList.Min: string;
begin
  result:= getData.Min;
end;

class operator TojStringList.NotEqual(a, b: TojStringList): boolean;
begin
  result:= (a.AsList() <> b.AsList());
end;

procedure TojStringList.Remove(Value: string);
begin
  checkData.Remove(Value);
  buildRAW;
end;

procedure TojStringList.RemoveDuplicates;
begin
  checkData.RemoveDuplicates;
  buildRAW;
end;

procedure TojStringList.setItems(Index: integer; const Value: string);
begin
  checkData[Index]:= Value;
end;

procedure TojStringList.Add(const Values: array of string);
begin
  checkData.Add(Values);
  buildRAW;
end;

procedure TojStringList.AddList(const Values: string; Separator: string);
begin
  checkData.AddList(Values, Separator);
  buildRAW;
end;

function TojStringList.AsList(Separator: string): string;
begin
  result:= getData.AsList(Separator);
end;

//function TojStringList.AsPgArray: string;
//begin
//  result:= getData.AsPgArray;
//end;

procedure TojStringList.buildRAW;
begin
  RAW:= AsList();
end;

procedure TojStringList.Sort;
begin
  checkData.Sort;
  buildRAW;
end;

function TojStringList.ToString: string;
begin
  result:= getData.ToString;
end;

class operator TojStringList.Add(a: TojStringList; b: string): TojStringList;
begin
  result:= a;
  result.Add(b);
end;

class operator TojStringList.Add(a: string; b: TojStringList): TojStringList;
begin
  result:= b;
  result.Insert(0, a);
end;

class operator TojStringList.Add(a, b: TojStringList): TojStringList;
begin
  result:= a;
  result.Add(b.AsList);
end;

{ TojStringListObject }

procedure TojStringListObject.Add(const Value: string);
begin
  FData.Add(Value);
end;

procedure TojStringListObject.Add(const Values: array of string);
begin
  FData.AddRange(Values);
end;

procedure TojStringListObject.AddList(const Values: string; Separator: string);
begin
  self.InsertList(Count, Values, Separator);
end;

function TojStringListObject.AsList(Separator: string): string;
var v_item: string;
begin
  result:= '';

  for v_item in FData do
    result:= result + v_item + Separator;

  if result <> ''
  then result:= System.Copy(result, 1, Length(result) - Length(Separator));

end;

//function TojStringListObject.AsPgArray: string;
//begin
//  // Null if empty???
//  //  wasy czy kwadraty
//  result:= 'ARRAY['+ AsList+']';
//end;

procedure TojStringListObject.Clear;
begin
  FData.Clear;
end;

function TojStringListObject.Contain(Value: string): boolean;
begin
  result:= FData.Contains(Value);
end;

function TojStringListObject.Copy: IojStringList;
var v_obj: TojStringListObject;
begin
  v_obj:= TojStringListObject.Create;
  try
    v_obj.FData.AddRange(self.FData);
    result:= v_obj;
  except
    FreeAndNil(v_obj);
    raise;
  end;

end;

function TojStringListObject.Count: integer;
begin
  result:= FData.Count;
end;

constructor TojStringListObject.Create;
begin
  inherited;
  FData:= TList<string>.Create();

  Inc(TojStringListObject.FInstCount);
end;


procedure TojStringListObject.Delete(Index: integer);
begin
  FData.Delete(Index);
end;

destructor TojStringListObject.Destroy;
begin
  FreeAndNil(FData);
  inherited;
  Dec(TojStringListObject.FInstCount);
end;

function TojStringListObject.getEnumerator: TojStringListIterator;
begin
  result:= TojStringListIterator.Create(self);
end;

function TojStringListObject.First: string;
begin
  result:= FData.First;
end;

function TojStringListObject.getItems(Index: integer): string;
begin
  result:= FData[Index];
end;

function TojStringListObject.IndexOf(Value: string): integer;
begin
  result:= FData.IndexOf(Value);
end;

procedure TojStringListObject.Insert(Index: Integer; const Values: array of string);
begin
  FData.InsertRange(Index, Values);
end;

procedure TojStringListObject.Insert(Index: integer; const Value: string);
begin
  FData.Insert(Index, Value);
end;

function TojStringListObject.Last: string;
begin
  result:= FData.Last;
end;

function TojStringListObject.Max: string;
var v_item: string;
begin
  if self.IsEmpty
  then raise Exception.Create(' TojStringListObject.Max -> IsEmpty');

  result:= First;
  for v_item in self.FData do
    if v_item > result
    then result:= v_item
end;

function TojStringListObject.Min: string;
var v_item: string;
begin
  if self.IsEmpty
  then raise Exception.Create(' TojStringListObject.Min -> IsEmpty');

  result:= First;
  for v_item in self.FData do
    if v_item < result
    then result:= v_item;

end;

function TojStringListObject.refCount: Integer;
begin
  result:= (inherited refCount);
end;

procedure TojStringListObject.Remove(Value: string);
begin
  FData.Remove(Value);
end;

procedure TojStringListObject.RemoveDuplicates;
var i, j: integer;
    v_value: string;
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

procedure TojStringListObject.setItems(Index: integer; const Value: string);
begin
  FData[Index]:= Value;
end;

procedure TojStringListObject.Sort;
begin
  FData.Sort;
end;

function TojStringListObject.ToString: string;
begin
  result:= format('%d: [%s]', [self.Count, self.AsList]);
end;

procedure TojStringListObject.InsertList(Index: Integer; const Values: string; Separator: string);
var v_pos, v_length: integer;
    v_item: string;
    v_to_split: string;
    v_result_items: integer;
    v_result: array of string;
begin
  v_result_items:= 0;
  v_length:= Length(Separator);
  v_to_split:= Values.Trim;

  v_pos:= v_to_split.IndexOf(Separator, 0);
  while v_pos >= 0 do
  begin
    v_item:= v_to_split.Substring(0, v_pos);

    Inc(v_result_items);
    SetLength(v_result, v_result_items);
    v_result[v_result_items-1]:= v_item;

    v_to_split:= v_to_split.Substring(v_pos + v_length);
    v_pos:= v_to_split.IndexOf(Separator, 0);
  end;

  if (v_to_split <> '') then
  begin
    Inc(v_result_items);
    SetLength(v_result, v_result_items);
    v_result[v_result_items-1]:= v_to_split;
  end;

  self.Insert(Index, v_result);
end;

function TojStringListObject.InstCount: integer;
begin
  result:= TojStringListObject.FInstCount;
end;

function TojStringListObject.IsEmpty: boolean;
begin
  result:= (FData.Count = 0);
end;

{ TojStringListIterator }

constructor TojStringListIterator.Create(StringListObject: TojStringListObject);
begin
  inherited Create;
  FIndex:= -1;
  FData:= StringListObject;
end;

destructor TojStringListIterator.Destroy;
begin
  inherited;
end;

function TojStringListIterator.getCurrent: string;
begin
  result:= FData[FIndex];
end;

function TojStringListIterator.MoveNext: boolean;
begin
  Inc(FIndex);
  result:= (FIndex < FData.Count);
end;

initialization
  TojStringListObject.FInstCount:= 0;

end.
