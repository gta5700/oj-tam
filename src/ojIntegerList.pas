unit ojIntegerList;

interface
uses classes, SysUtils, System.Generics.Collections;


type
  TojIntegerListObject = class;

  IojIntegerList = Interface['{4E99D5CA-5A94-443D-B47A-51AD166BB3A6}']
    function refCount: Integer;
    function Copy: IojIntegerList;
    procedure Clear;

    procedure Add(const Value: Int64);overload;
    procedure Add(const Values: array of Int64); overload;
    procedure Add(const Values: string; Separator: string = ',');overload;

    procedure Insert(Index: Integer; const Value: Int64);overload;
    procedure Insert(Index: Integer; const Values: array of Int64); overload;
    procedure Insert(Index: Integer; const Values: string; Separator: string = ',');overload;

    procedure Remove(Value: Int64);
    function IndexOf(Value: Int64): integer;

    function First: Int64;
    function Last: Int64;
    function Count: integer;
    function Contain(Value: Int64): boolean;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;

    function AsList(Separator: string = ','): string;
    function AsPgArray(): string;

    //    function EnumBy():boolean;
  end;

  TojIntegerListObject = class(TInterfacedObject, IojIntegerList)
  protected
    FData: TList<Int64>;
    function refCount: Integer;
  protected
    function Copy: IojIntegerList; virtual;
    procedure Clear; virtual;
    procedure Add(const Value: Int64);overload;
    procedure Add(const Values: array of Int64); overload;
    procedure Add(const Values: string; Separator: string = ',');overload;

    procedure Insert(Index: integer; const Value: Int64); overload;
    procedure Insert(Index: Integer; const Values: array of Int64); overload;
    procedure Insert(Index: Integer; const Values: string; Separator: string = ',');overload;

    procedure Remove(Value: Int64);
    function IndexOf(Value: Int64): integer;

    function First: Int64;
    function Last: Int64;
    function Count: integer;
    function Contain(Value: Int64): boolean;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;
    function AsList(Separator: string = ','): string;
    function AsPgArray(): string;

  public
    constructor Create; virtual;
    destructor Destroy;override;
  end;


  TojIntegerList = record
  private
    RAW: string;
    FData: IojIntegerList;
  public
    function checkData: IojIntegerList;
    function getData: IojIntegerList;
    procedure buildRAW;
  public
    procedure Clear;
    procedure Add(const Value: Int64);overload;
    procedure Add(const Values: array of int64); overload;
    procedure Add(const Values: string; Separator: string = ',');overload;

    procedure Insert(Index: integer; const Value: Int64); overload;
    procedure Insert(Index: Integer; const Values: array of Int64); overload;
    procedure Insert(Index: Integer; const Values: string; Separator: string = ',');overload;

    procedure Remove(Value: Int64);
    function IndexOf(Value: Int64): integer;

    function First: Int64;
    function Last: Int64;
    function Count: integer;
    function Contain(Value: Int64): boolean;

    procedure RemoveDuplicates;
    procedure Delete(Index: integer);

    procedure Sort;
    function AsList(Separator: string = ','): string;
    function AsPgArray(): string;
  public
    //  IMPLICIT -> v_atr:=  a;   EXPLICIT -> v_atr:=  string(a);
    class operator Implicit(a: TojIntegerList): string;
    class operator Implicit(a: string): TojIntegerList;

    class operator Add(a: TojIntegerList; b: Int64): TojIntegerList;
    class operator Add(a: Int64; b: TojIntegerList): TojIntegerList;

    class operator Add(a: TojIntegerList; b: TojIntegerList): TojIntegerList;

    //    class operator Subtract(a: TojInt64; b: TojInt64) : TojInt64;
    class operator Equal(a: TojIntegerList; b: TojIntegerList):boolean;
    //    class operator NotEqual(a: TojIntegerList; b: TojIntegerList):boolean;
  end;

implementation

{ TojIntegerList }

procedure TojIntegerList.Add(const Value: Int64);
begin
  checkData.Add(Value);
  buildRAW;
end;

function TojIntegerList.checkData: IojIntegerList;
begin
  //  wersja gdy chcemy zmienic dane
  if (FData = nil)
  then FData:= TojIntegerListObject.Create

  else if FData.refCount > 1
  then FData:= FData.Copy;

  result:= FData;
end;

procedure TojIntegerList.Clear;
begin
  checkData.Clear;
  buildRAW;
end;

function TojIntegerList.Contain(Value: Int64): boolean;
begin
  result:= getData.Contain(Value);
end;

function TojIntegerList.Count: integer;
begin
  result:= getData.Count;
end;

procedure TojIntegerList.Delete(Index: integer);
begin
  checkData.Delete(Index);
  buildRAW;
end;

class operator TojIntegerList.Equal(a, b: TojIntegerList): boolean;
begin
  //  albo zrobic petle zeby nie generowal pelnej listy
  result:= (a.FData = b.FData)
      OR (a.AsList = b.AsList);
end;

function TojIntegerList.First: Int64;
begin
  result:= getData.First;
end;

function TojIntegerList.getData: IojIntegerList;
begin
  // wersja gdy chcemy tylko czytac dane
  if (FData = nil)
  then FData:= TojIntegerListObject.Create;

  result:= FData;
end;

class operator TojIntegerList.Implicit(a: TojIntegerList): string;
begin
  result:= a.AsList();
end;

class operator TojIntegerList.Implicit(a: string): TojIntegerList;
begin
  //  result:= self;
  result.Clear;
  result.Add(a);
end;

function TojIntegerList.IndexOf(Value: Int64): integer;
begin
  result:= getData.IndexOf(Value);
end;

procedure TojIntegerList.Insert(Index: Integer; const Values: string; Separator: string);
begin
  checkData.Insert(Index, Values, Separator);
  buildRAW;
end;

procedure TojIntegerList.Insert(Index: Integer; const Values: array of Int64);
begin
  checkData.Insert(Index, Values);
  buildRAW;
end;

procedure TojIntegerList.Insert(Index: integer; const Value: Int64);
begin
  checkData.Insert(Index, Value);
  buildRAW;
end;

function TojIntegerList.Last: Int64;
begin
  result:= getData.Last;
end;

procedure TojIntegerList.Remove(Value: Int64);
begin
  checkData.Remove(Value);
  buildRAW;
end;

procedure TojIntegerList.RemoveDuplicates;
begin
  checkData.RemoveDuplicates;
  buildRAW;
end;

procedure TojIntegerList.Add(const Values: array of Int64);
begin
  checkData.Add(Values);
  buildRAW;
end;

procedure TojIntegerList.Add(const Values: string; Separator: string);
begin
  checkData.Add(Values, Separator);
  buildRAW;
end;

function TojIntegerList.AsList(Separator: string): string;
begin
  result:= getData.AsList(Separator);
end;

function TojIntegerList.AsPgArray: string;
begin
  result:= getData.AsPgArray;
end;

procedure TojIntegerList.buildRAW;
begin
  RAW:= AsList();
end;

procedure TojIntegerList.Sort;
begin
  checkData.Sort;
  buildRAW;
end;

class operator TojIntegerList.Add(a: TojIntegerList; b: Int64): TojIntegerList;
begin
  result:= a;
  result.Add(b);
end;

class operator TojIntegerList.Add(a: Int64; b: TojIntegerList): TojIntegerList;
begin
  result:= b;
  result.Insert(0, a);
end;

class operator TojIntegerList.Add(a, b: TojIntegerList): TojIntegerList;
begin
  result:= a;
  result.Add(b.AsList);
end;

{ TojIntegerListObject }

procedure TojIntegerListObject.Add(const Value: Int64);
begin
  FData.Add(Value);
end;

procedure TojIntegerListObject.Add(const Values: array of Int64);
begin
  FData.AddRange(Values);
end;

procedure TojIntegerListObject.Add(const Values: string; Separator: string);
begin
  self.Insert(Count, Values, Separator);
end;

function TojIntegerListObject.AsList(Separator: string): string;
var v_item: Int64;
begin
  result:= '';

  for v_item in FData do
    result:= result + IntToStr(v_item) + Separator;

  if result <> ''
  then result:= System.Copy(result, 1, Length(result) - Length(Separator));

end;

function TojIntegerListObject.AsPgArray: string;
begin
  // Null if empty???
  //  wasy czy kwadraty
  result:= 'ARRAY['+ AsList+']';
end;

procedure TojIntegerListObject.Clear;
begin
  FData.Clear;
end;

function TojIntegerListObject.Contain(Value: Int64): boolean;
begin
  result:= FData.Contains(Value);
end;

function TojIntegerListObject.Copy: IojIntegerList;
var v_obj: TojIntegerListObject;
begin
  v_obj:= TojIntegerListObject.Create;
  try
    v_obj.FData.AddRange(self.FData);
    result:= v_obj;
  except
    FreeAndNil(v_obj);
    raise;
  end;

end;

function TojIntegerListObject.Count: integer;
begin
  result:= FData.Count;
end;

constructor TojIntegerListObject.Create;
begin
  inherited;
  FData:= TList<Int64>.Create();
end;


procedure TojIntegerListObject.Delete(Index: integer);
begin
  FData.Delete(Index);
end;

destructor TojIntegerListObject.Destroy;
begin
  FreeAndNil(FData);
  inherited;
end;

function TojIntegerListObject.First: Int64;
begin
  result:= FData.First;
end;

function TojIntegerListObject.IndexOf(Value: Int64): integer;
begin
  result:= FData.IndexOf(Value);
end;

procedure TojIntegerListObject.Insert(Index: Integer; const Values: array of Int64);
begin
  FData.InsertRange(Index, Values);
end;

procedure TojIntegerListObject.Insert(Index: integer; const Value: Int64);
begin
  FData.Insert(Index, Value);
end;

function TojIntegerListObject.Last: Int64;
begin
  result:= FData.Last;
end;

function TojIntegerListObject.refCount: Integer;
begin
  result:= (inherited refCount);
end;

procedure TojIntegerListObject.Remove(Value: Int64);
begin
  FData.Remove(Value);
end;

procedure TojIntegerListObject.RemoveDuplicates;
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

procedure TojIntegerListObject.Sort;
begin
  FData.Sort;
end;

procedure TojIntegerListObject.Insert(Index: Integer; const Values: string; Separator: string);
var v_pos, v_length: integer;
    v_item: string;
    v_to_split: string;
    v_result_items: integer;
    v_result: array of Int64;
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
    v_result[v_result_items-1]:= StrToInt64(v_item);

    v_to_split:= v_to_split.Substring(v_pos + v_length);
    v_pos:= v_to_split.IndexOf(Separator, 0);
  end;

  if (v_to_split <> '') then
  begin
    Inc(v_result_items);
    SetLength(v_result, v_result_items);
    v_result[v_result_items-1]:= StrToInt64(v_to_split);
  end;

  self.Insert(Index, v_result);
end;

end.
