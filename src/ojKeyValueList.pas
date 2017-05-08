//  2016-04-06
//    + innerGetItemByKeyEx
//  2016-08-11
//    + usuniecie FAutoExpand, jest SaveValues
//    + poprawki w Add() AddOrSet()
//  2016-11-18
//    + Stuff[] klucz jako Variant + automatycznie tworzenie Itemsow
//    + alias TojKeyValueList = TojKeyValueList;
//    + alias IojKeyValueList = IojKeyVariantList;
//    + Enumeratory ;

//  moze wywalic SafeValue[] i zostawic tylko Stuff[]???????
//  wywalone SafeValue i wyciecie KeyObject i keyInterface
//  function ValueDef(Key: string; ValueDefault: Variant): Variant;

unit ojKeyValueList;

interface
uses
  Classes, Contnrs, Variants, SysUtils, DB, Dialogs;


type
  TojCustomKeyValueList = class;
  TojCustomKeyValueItem = class;
  TojCustomKeyValueItemClass = class of TojCustomKeyValueItem;
  TojCustomKeyValueEnumerator = class;

  TojKeyValueList = class;

  TojCustomKeyValueItem = class(TObject)
  private
    FKey: string;
  public
    constructor Create(Key: string);virtual;
    function ValueAsString: string;virtual;
  public
    property Key: string read FKey write FKey;
  end;

  TojKeyValueItem = class(TojCustomKeyValueItem)
  private
    FValue: Variant;
  public
    constructor Create(Key: string);overload;override;
    constructor Create(Key: string; Value: Variant);reintroduce;overload;virtual;
    function ValueAsString: string;override;
  public
    property Value: Variant read FValue write FValue;
  end;


  TojCustomKeyValueEnumerator = class
  private
    FList: TojCustomKeyValueList;
    FCurrentPos: integer;
    function getCurrent: TojCustomKeyValueItem;
  public
    constructor Create(p_List: TojCustomKeyValueList);
    function MoveNext: boolean;
    property Current: TojCustomKeyValueItem read getCurrent;
  end;

  TojKeyValueEnumerator = class(TojCustomKeyValueEnumerator)
  private
    function getCurrent: TojKeyValueItem;
  public
    property Current: TojKeyValueItem read getCurrent;
  end;



  IojCustomKeyValueList = interface(IInterface)['{7F3D82F8-DC5E-4DA0-AA67-F3EACBE6E728}']
    function getCaseSensitive: boolean;
    procedure Clear;
    function Count: integer;
    function KeyExist(Key: string): boolean;
    procedure DeleteKey(Key: string);
    function KeyList(p_Separator: string = ','): string;
    function ValueList(p_Separator: string = ','): string;
    function KeyValueList(p_Separator: string = ','): string;

    //  duplicate()

    function getEnumerator: TojCustomKeyValueEnumerator;
    property CaseSensitive: boolean read getCaseSensitive;
  end;

  TojCustomKeyValueList = class(TInterfacedObject, IojCustomKeyValueList)
  private
    a_KV: TObjectList;
    FCaseSensitive: boolean;
    function getItems(Index: integer): TojCustomKeyValueItem;
    function getItemsByKey(Key: string): TojCustomKeyValueItem;
    function getCaseSensitive: boolean;
  protected
    property KV_list: TObjectList read a_KV;

    property Items[Index: integer]: TojCustomKeyValueItem read getItems;
    property ItemsByKey[Key: string]: TojCustomKeyValueItem read getItemsByKey;

    function IndexOf(Key: string): integer;
    function IndexFor(Key: string): integer;

    function getKeyValueItemClass: TojCustomKeyValueItemClass; virtual;
    function createNewItem(Key: string): TojCustomKeyValueItem; virtual;

    //  2 bazowo - unikalno - wyjatkowe
    //  zwroc item na podstawie klucza lub wyjatek jesli brak
    function innerGetItemByKey(Key: string): TojCustomKeyValueItem; virtual;
    //  dodaj item na podstawie klucza lub wyjatek jesli istnieje
    function innerAddNewItem(Key: string): TojCustomKeyValueItem; virtual;
    //  zwroc item jesli istnieje lub dodaj i zwroc nowo utworzony
    function innerGetItemByKeyEx(Key: string): TojCustomKeyValueItem; virtual;
  public
    constructor Create(p_CaseSensitive: boolean = FALSE);virtual;
    destructor Destroy;override;
    function Count: integer;
    function KeyExist(Key: string): boolean;
    procedure Clear;
    procedure DeleteKey(Key: string);

    function KeyList(p_Separator: string = ','): string;
    function ValueList(p_Separator: string = ','): string;
    function KeyValueList(p_Separator: string = ','): string;

    function getEnumerator: TojCustomKeyValueEnumerator;
    property CaseSensitive: boolean read getCaseSensitive;
  end;




  IojKeyValueList = interface(IojCustomKeyValueList) ['{35091D92-6124-45E1-B915-A7744E31B036}']
    function getValue(Key: string): Variant;
    procedure setValue(Key: string; const Value: Variant);
    function getStuff(Key: Variant): Variant;
    procedure setStuff(Key: Variant; const Value: Variant);

    function getEnumerator: TojKeyValueEnumerator;

    function Add(Key: string; Value: Variant): TojKeyValueList;
    function AddOrSet(Key: string; Value: Variant): TojKeyValueList;
    function ValueDef(Key: string; ValueDefault: Variant): Variant;

    property Values[Key: string]: Variant read getValue write setValue;default;
    property Stuff[Key: Variant]: Variant read getStuff write setStuff;
  end;


  TojKeyValueList = class(TojCustomKeyValueList, IojKeyValueList)
  private
    function getValue(Key: string): Variant;
    procedure setValue(Key: string; const Value: Variant);
    function getStuff(Key: Variant): Variant;
    procedure setStuff(Key: Variant; const Value: Variant);
  protected
    function getKeyValueItemClass: TojCustomKeyValueItemClass;override;
  public
    constructor Create(p_Key: string; p_Value: Variant; p_CaseSensitive: boolean = FALSE);reintroduce;overload;virtual;

    function getEnumerator: TojKeyValueEnumerator;

    function Add(Key: string; Value: Variant): TojKeyValueList;
    function AddOrSet(Key: string; Value: Variant): TojKeyValueList;
    function ValueDef(Key: string; ValueDefault: Variant): Variant;

    property Values[Key: string]: Variant read getValue write setValue;default;
    property Stuff[Key: Variant]: Variant read getStuff write setStuff;
  end;


implementation
uses math, strUtils, TypInfo;

function VarIsPusty(Value: Variant): boolean;
begin
  result:= VarIsNull(Value) OR VarIsClear(Value) OR VarIsEmpty(Value);
end;


{ TojCustomKeyValueItem }

constructor TojCustomKeyValueItem.Create(Key: string);
begin
  inherited Create;
  FKey:= Key;
end;

function TojCustomKeyValueItem.ValueAsString: string;
begin
  result:= '';
end;

{ TojKeyValueItem }

constructor TojKeyValueItem.Create(Key: string; Value: Variant);
begin
  //  inherited Create(Key);
  Create(Key);  //  zenby zainicjowac FValue
  FValue:= Value;
end;

constructor TojKeyValueItem.Create(Key: string);
begin
  inherited Create(Key);
  FValue:= NULL;
end;

function TojKeyValueItem.ValueAsString: string;
begin
  if VarIsPusty(FValue)
  then result:= 'NULL'
  else result:= VarToStr(self.FValue);
end;


procedure TojCustomKeyValueList.Clear;
begin
  KV_list.Clear;  
end;

function TojCustomKeyValueList.Count: integer;
begin
  result:= KV_list.Count;
end;

constructor TojCustomKeyValueList.Create(p_CaseSensitive: boolean);
begin
  inherited Create;
  FCaseSensitive:= p_CaseSensitive;
  a_KV:= TObjectList.Create(TRUE);
end;

function TojCustomKeyValueList.createNewItem(Key: string): TojCustomKeyValueItem;
begin
  result:= getKeyValueItemClass.Create(Key);
end;

procedure TojCustomKeyValueList.DeleteKey(Key: string);
var v_index: integer;
begin
  v_index:= IndexOf(Key);
  if v_index>=0
  then KV_list.Delete(v_index);   
end;

destructor TojCustomKeyValueList.Destroy;
begin
  FreeAndNil(a_KV);
  inherited;
end;

function TojCustomKeyValueList.getCaseSensitive: boolean;
begin
  result:= FCaseSensitive;
end;

function TojCustomKeyValueList.getEnumerator: TojCustomKeyValueEnumerator;
begin
  result:= TojCustomKeyValueEnumerator.Create(self);
end;

function TojCustomKeyValueList.getItems(Index: integer): TojCustomKeyValueItem;
begin
  result:= TojCustomKeyValueItem(KV_list[Index]);
end;

function TojCustomKeyValueList.getItemsByKey(Key: string): TojCustomKeyValueItem;
begin
  result:= innerGetItemByKey(Key);
end;

function TojCustomKeyValueList.getKeyValueItemClass: TojCustomKeyValueItemClass;
begin
  result:= TojCustomKeyValueItem;
end;

function TojCustomKeyValueList.IndexFor(Key: string): integer;
var v_left, v_right, v_div: integer;
begin
  result:= 0;
  if self.Count = 0 then Exit;

  if self.CaseSensitive then
    BEGIN
      v_left:= 0;
      v_right:= self.Count-1;
      while v_left < v_right do
      begin
        v_div:= (v_left + v_right) div 2;

        if CompareStr(Items[v_div].Key, Key) < 0
        then v_left:= v_div + 1
        else v_right:= v_div;
      end;

      if CompareStr(Items[v_left].Key, Key) <= 0
      then result:= v_left + 1
      else result:= v_left;

    END
  else
    BEGIN
      v_left:= 0;
      v_right:= self.Count-1;
      while v_left < v_right do
      begin
        v_div:= (v_left + v_right) div 2;

        if CompareText(Items[v_div].Key, Key) < 0
        then v_left:= v_div + 1
        else v_right:= v_div;
      end;

      if CompareText(Items[v_left].Key, Key) <= 0
      then result:= v_left + 1
      else result:= v_left;    
    END;

end;

function TojCustomKeyValueList.IndexOf(Key: string): integer;
var v_left, v_right, v_div: integer;
begin
  result:= -1;
  if self.Count = 0 then Exit;

  if self.CaseSensitive then
    BEGIN
      v_left:= 0;
      v_right:= self.Count-1;
      while v_left < v_right do
      begin
        v_div:= (v_left + v_right) div 2;

        if CompareStr(Items[v_div].Key, Key) < 0
        then v_left:= v_div + 1
        else v_right:= v_div;
      end;

      if CompareStr(Items[v_left].Key, Key) = 0
      then result:= v_left
      else result:= -1;

    END
  else
    BEGIN
      v_left:= 0;
      v_right:= self.Count-1;
      while v_left < v_right do
      begin
        v_div:= (v_left + v_right) div 2;

        if CompareText(Items[v_div].Key, Key) < 0
        then v_left:= v_div + 1
        else v_right:= v_div;
      end;

      if CompareText(Items[v_left].Key, Key) = 0
      then result:= v_left
      else result:= -1;    
    END;

end;

function TojCustomKeyValueList.innerGetItemByKey(Key: string): TojCustomKeyValueItem;
var v_index: integer;
begin
  v_index:= IndexOf(Key);

  if v_index >= 0
  then result:= self.Items[v_index]
  else
    raise Exception.CreateFmt('TojCustomKeyValueList.innerGetItemByKey -> brak klucza: %s', [Key]);

end;

function TojCustomKeyValueList.innerAddNewItem(Key: string): TojCustomKeyValueItem;
var v_index: integer;
begin
  v_index:= IndexOf(Key);
  if v_index < 0 then
  begin
    result:= createNewItem(Key);

    v_index:= IndexFor(Key);
    if v_index < self.Count
    then KV_list.Insert(v_index, result)
    else KV_list.Add(result);
  end
  else
                              [Key]);
end;

function TojCustomKeyValueList.innerGetItemByKeyEx(Key: string): TojCustomKeyValueItem;
var v_index: integer;
begin
  v_index:= IndexOf(Key);

  if v_index < 0
  then result:= innerAddNewItem(Key)
  else result:= self.Items[v_index];
end;

function TojCustomKeyValueList.KeyExist(Key: string): boolean;
begin
  result:= IndexOf(Key) >= 0;  
end;

function TojCustomKeyValueList.KeyList(p_Separator: string): string;
var i: integer;
begin
  result:= '';
  if a_KV.Count = 0 then Exit;

  for i:= 0 to a_KV.Count-1 do
    result:= result + p_Separator + Items[i].Key;

  result:= Copy(result, Length(p_Separator)+1, Length(result));  
end;

function TojCustomKeyValueList.KeyValueList(p_Separator: string): string;
var i: integer;
begin
  result:= '';
  if a_KV.Count = 0 then Exit;

  for i:= 0 to a_KV.Count-1 do
    result:= result + p_Separator +
        Items[i].Key + ' = ' + Items[i].ValueAsString;

  result:= Copy(result, Length(p_Separator)+1, Length(result));
end;

function TojCustomKeyValueList.ValueList(p_Separator: string): string;
var i: integer;
begin
  result:= '';
  if a_KV.Count = 0 then Exit;

  for i:= 0 to a_KV.Count-1 do
    result:= result + p_Separator + Items[i].ValueAsString;

  result:= Copy(result, Length(p_Separator)+1, Length(result));  
end;

{ TojKeyValueList }

function TojKeyValueList.Add(Key: string; Value: Variant): TojKeyValueList;
begin
  //  dodajemy nowy lub wyjatek jesli istniejee
  TojKeyValueItem(self.innerAddNewItem(Key)).Value:= Value;
  result:= self;
end;

function TojKeyValueList.AddOrSet(Key: string; Value: Variant): TojKeyValueList;
begin
  TojKeyValueItem(self.innerGetItemByKeyEx(Key)).Value:= Value;
  result:= self;
end;

constructor TojKeyValueList.Create(p_Key: string; p_Value: Variant; p_CaseSensitive: boolean);
begin
  inherited Create(p_CaseSensitive);
  Add(p_Key, p_Key);
end;

function TojKeyValueList.getEnumerator: TojKeyValueEnumerator;
begin
  result:= TojKeyValueEnumerator.Create(self);
end;

function TojKeyValueList.getKeyValueItemClass: TojCustomKeyValueItemClass;
begin
  result:= TojKeyValueItem;
end;

function TojKeyValueList.getStuff(Key: Variant): Variant;
var v_index: integer;
begin
  //  result:= TojKeyValueItem(innerGetItemByKeyEx( VarToStrDef(Key, '') )).Value;
  v_index:= IndexOf(VarToStrDef(Key, ''));
  if v_index < 0
  then result:= NULL
  else result:= TojKeyValueItem( self.Items[v_index] ).Value;
end;

function TojKeyValueList.getValue(Key: string): Variant;
begin
  //  odczytaj lub wyjatek
  result:= TojKeyValueItem(self.innerGetItemByKey(Key)).Value;
end;

procedure TojKeyValueList.setStuff(Key: Variant; const Value: Variant);
begin
  TojKeyValueItem(self.innerGetItemByKeyEx( VarToStrDef(Key, '') )).Value:= Value;
end;

procedure TojKeyValueList.setValue(Key: string; const Value: Variant);
begin
  //  ustawiaamy wartosc, wiec jak nie ma klucza to tworzymy automatek
  TojKeyValueItem(self.innerGetItemByKeyEx(Key)).Value:= Value;
end;


function TojKeyValueList.ValueDef(Key: string; ValueDefault: Variant): Variant;
var v_index: integer;
begin
  v_index:= self.IndexOf(Key);

  if v_index < 0
  then result:= ValueDefault
  else
  begin
    result:= TojKeyValueItem( self.Items[v_index] ).Value;
    if VarIsPusty(result)
    then result:= ValueDefault;
  end;

end;

constructor TojCustomKeyValueEnumerator.Create(p_List: TojCustomKeyValueList);
begin
  inherited Create;
  FList:= p_List;
  FCurrentPos:= -1;
end;

function TojCustomKeyValueEnumerator.getCurrent: TojCustomKeyValueItem;
begin
  result:= FList.Items[FCurrentPos];
end;

function TojCustomKeyValueEnumerator.MoveNext: boolean;
begin
  inc(FCurrentPos);
  result:= (FCurrentPos < FList.Count);
end;

{ TojKeyValueEnumerator }

function TojKeyValueEnumerator.getCurrent: TojKeyValueItem;
begin
  result:= FList.Items[FCurrentPos] as TojKeyValueItem;
end;

end.
