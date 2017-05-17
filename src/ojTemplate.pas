unit ojTemplate;

interface
uses classes, sysUtils;


type

  TOnTagCallback = function(p_tag_name: string):string of object;

  TojDetectTagResult = (
    dtrTagOK,  //  znalazl poprawnego taga
    dtrNoTag,  //  sparsowal ale tagow brak,

    dtrEscapedOpenBracket,
    dtrEscapedCloseBracket,

    dtrErrorNoCloseBracket,     //  szukal nawiasu zamykajacego i nie znalazl
    dtrErrorExtraCloseBracket,  //  szukal nawiasu otwierajacego, a trafil na zamykajacy
    dtrErrorExtraOpenBracket    //  szukal nawiasu zamykajacego a znalazl otwierajacy
    );

  {
    strict ok lub wyj¹tek
    force zwroc co sie udalo, bez wyj¹tku
    ignore zwroc pusty napis, bez wyj¹tku
  }

  IojTemplateConfig = interface ['{CFBC0AE8-E850-4C49-8018-5E44682211C3}']
    function getOpenBracket: char;
    procedure setOpenBracket(const Value: char);
    function getCloseBracket: char;
    procedure setCloseBracket(const Value: char);

    function putOpenBracket(const Value: char): IojTemplateConfig;
    function putCloseBracket(const Value: char): IojTemplateConfig;
    function Duplicate(): IojTemplateConfig;



    property OpenBracket: char read getOpenBracket write setOpenBracket;
    property CloseBracket: char read getCloseBracket write setCloseBracket;
  end;

  TojTemplateConfig = class(TInterfacedObject, IojTemplateConfig)
  private
    FOpenBracket: char;
    FCloseBracket: char;
    //  FHumanReadableMasks: array[TDetectTagResult] of string;
    function getOpenBracket: char;
    procedure setOpenBracket(const Value: char);
    function getCloseBracket: char;
    procedure setCloseBracket(const Value: char);
  public
    constructor Create;virtual;

    function putOpenBracket(const Value: char): IojTemplateConfig;
    function putCloseBracket(const Value: char): IojTemplateConfig;
    function Duplicate(): IojTemplateConfig;virtual;

    property OpenBracket: char read getOpenBracket write setOpenBracket;
    property CloseBracket: char read getCloseBracket write setCloseBracket;
    //  property HumanReadableMasks[TDetectTagResult]: string read getHumanReadableMasks write setHumanReadableMasks;
  end;


  TojTemplate = class(TObject)
  private
    class var FConfig: IojTemplateConfig;
  public
    class function Config: IojTemplateConfig;

  public

    function detect_tag(const p_input_string: string;
        p_start_position: integer; p_end_position: integer;
        var p_tag_start: integer; var p_tag_end: integer;
        var p_human_readable_result: string;
        p_custom_config: IojTemplateConfig = nil
        ): TojDetectTagResult;


    function Substitute(p_input_string: string; p_tag_callback: TOnTagCallback;
        p_custom_config: IojTemplateConfig = nil): string;

  end;


implementation

{ TojTemplateConfig }

constructor TojTemplateConfig.Create;
begin
  inherited;
  FOpenBracket:= '<';
  FCloseBracket:= '>';
end;

function TojTemplateConfig.Duplicate: IojTemplateConfig;
begin
  result:= TojTemplateConfig(self.ClassType.Create);
  result.OpenBracket:= self.OpenBracket;
  result.CloseBracket:= self.CloseBracket;

  //  for FHumanReadableMasks ...
end;

function TojTemplateConfig.getCloseBracket: char;
begin
  result:= FCloseBracket;
end;

function TojTemplateConfig.getOpenBracket: char;
begin
  result:= FOpenBracket;
end;

function TojTemplateConfig.putCloseBracket(const Value: char): IojTemplateConfig;
begin
  self.CloseBracket:= Value;
  result:= self;
end;

function TojTemplateConfig.putOpenBracket(const Value: char): IojTemplateConfig;
begin
  self.OpenBracket:= Value;
  result:= self;
end;

procedure TojTemplateConfig.setCloseBracket(const Value: char);
begin
  if FCloseBracket <> Value then
  begin
    FCloseBracket:= Value;
    //
  end;
end;

procedure TojTemplateConfig.setOpenBracket(const Value: char);
begin
  if FOpenBracket <> Value then
  begin
    FOpenBracket:= Value;
    //
  end;
end;


{ TojTemplate }

class function TojTemplate.Config: IojTemplateConfig;
begin
  if TojTemplate.FConfig = nil
  then TojTemplate.FConfig:= TojTemplateConfig.Create;

  result:= TojTemplate.FConfig;
end;

function TojTemplate.detect_tag(const p_input_string: string;
  p_start_position, p_end_position: integer;
  var p_tag_start, p_tag_end: integer;
  var p_human_readable_result: string;
  p_custom_config: IojTemplateConfig): TojDetectTagResult;
var v_cur_pos, v_max_pos: integer;
    v_tag_start, v_tag_end: integer;
    v_cfg: IojTemplateConfig;
begin
  result:= dtrNoTag;
  v_cur_pos:= p_start_position;
  v_max_pos:= p_end_position;
  v_tag_start:= 0;
  v_tag_end:= 0;
  if p_custom_config = nil
  then v_cfg:= TojTemplate.Config
  else v_cfg:= p_custom_config;

  //  szukanie poczatku TAG-a
  while (v_cur_pos <= v_max_pos) do
    if (p_input_string[v_cur_pos] = v_cfg.OpenBracket) then
    begin
      //  znalazl nawias otwieraj¹cy ale eskejpowaany
      if (v_cur_pos < v_max_pos) AND (p_input_string[v_cur_pos+1] = v_cfg.OpenBracket) then
        begin
          result:= dtrEscapedOpenBracket;
          p_tag_start:= v_cur_pos;
          p_tag_end:= v_cur_pos+1;
          EXIT;
        end
      else
        begin
          v_tag_start:= v_cur_pos;
          Break;
        end;
    end
    else if (p_input_string[v_cur_pos] = v_cfg.CloseBracket) then
    begin
      //  akceptujemy TYLKO wyeskejpowane naawiasy zamykajace
      if (v_cur_pos < v_max_pos) AND (p_input_string[v_cur_pos+1] = v_cfg.CloseBracket) then
        begin
        begin
          result:= dtrEscapedCloseBracket;
          p_tag_start:= v_cur_pos;
          p_tag_end:= v_cur_pos+1;
          EXIT;
        end
        end
      else
        begin
          result:= dtrErrorExtraCloseBracket;
          p_human_readable_result:= Format('niepoprawny nawias zamykajacy na pozycji: %d', [v_cur_pos]);
          Exit;
        end;
    end
    else
      inc(v_cur_pos);

  //  szukanie konca TAG-a
  if v_tag_start > 0 then
  begin
    v_cur_pos:= v_tag_start + 1;
    while (v_cur_pos <= v_max_pos) do
      if (p_input_string[v_cur_pos] = v_cfg.CloseBracket) then
      begin
        //  NAZWA TAGA NIE MOZE ZAWIERAC CNST_CLOSE_BRACKET nawet eskejpowanego
        //  pierwsze trafienie to Zawsze koniec taga
        v_tag_end:= v_cur_pos;
        Break;
      end
      else if (p_input_string[v_cur_pos] = v_cfg.OpenBracket) then
      begin
        //  akceptujemy TYLKO wyeskejpowane naawiasy otwierjace??
        //  NIE NAZWA TAGA NIE MOZE ZAWIERAC CNST_OPEN_BRACKET oraz CNST_CLOSE_BRACKET
        result:= dtrErrorExtraOpenBracket;
        p_human_readable_result:= Format('niepoprawny nawias otwieraj¹cy na pozycji: %d', [v_cur_pos]);
        Exit;
      end
      else
        inc(v_cur_pos);

    if v_tag_end = 0 then
    begin
      result:= dtrErrorNoCloseBracket;
      p_human_readable_result:= Format('brak nawiasu zamykajacego dla otwarcia z pozycji %d', [v_tag_start]);
      Exit;
    end;
  end;

  if (v_tag_start > 0) AND (v_tag_start <= v_tag_end) then
  begin
    result:= dtrTagOK;
    p_human_readable_result:= Format('znalaz³ tag %s na pozycji (%d, %d)',
                       [Copy(p_input_string, v_tag_start, v_tag_end - v_tag_start+1),
                        v_tag_start, v_tag_end]);
    p_tag_start:= v_tag_start;
    p_tag_end:= v_tag_end;
  end;

end;

function TojTemplate.Substitute(p_input_string: string;
  p_tag_callback: TOnTagCallback; p_custom_config: IojTemplateConfig): string;
var v_tag_name, v_tag_value: string;
    v_start_pos, v_max_pos: integer;
    v_tag_start, v_tag_end: integer;
    v_rav_start: integer;
    v_mesg: string;
    v_dtr: TojDetectTagResult;
    v_cfg: IojTemplateConfig;
begin
  result:= '';
  v_mesg:= '';
  v_rav_start:= 1;
  v_start_pos:= 1;
  v_max_pos:= Length(p_input_string);

  if p_custom_config = nil
  then v_cfg:= TojTemplate.Config
  else v_cfg:= p_custom_config;

  repeat
    v_dtr:= detect_tag(p_input_string, v_start_pos, v_max_pos, v_tag_start, v_tag_end,
                       v_mesg, v_cfg);

    if v_dtr in [dtrErrorNoCloseBracket, dtrErrorExtraCloseBracket, dtrErrorExtraOpenBracket] then
    begin
      //  result:= result + ' B£¥D: ' + v_mesg;
      raise Exception.Create('TojTemplate.Substitute -> '+v_mesg);
      Exit;
    end;

    if v_dtr = dtrTagOK then
    begin
      v_tag_name:= Copy(p_input_string, v_tag_start, v_tag_end - v_tag_start+1);
      v_tag_value:= p_tag_callback(v_tag_name);

      result:= result +
               Copy(p_input_string, v_rav_start, v_tag_start - v_rav_start) +
               v_tag_value;

      v_start_pos:= v_tag_end + 1;
      v_rav_start:= v_tag_end + 1;
    end;

    if v_dtr = dtrEscapedOpenBracket then
    begin
      result:= result +
               Copy(p_input_string, v_rav_start, v_tag_start - v_rav_start) +
               v_cfg.OpenBracket;

      v_start_pos:= v_tag_end + 1;
      v_rav_start:= v_tag_end + 1;
    end;

    if v_dtr = dtrEscapedCloseBracket then
    begin
      result:= result +
               Copy(p_input_string, v_rav_start, v_tag_start - v_rav_start) +
               v_cfg.CloseBracket;

      v_start_pos:= v_tag_end + 1;
      v_rav_start:= v_tag_end + 1;
    end;

  until v_dtr = dtrNoTag;

  //  to co zostalo,
  result:= result +
           Copy(p_input_string, v_rav_start, v_max_pos - v_rav_start + 1);

end;

initialization
  TojTemplate.FConfig:= nil;
finalization
  TojTemplate.FConfig:= nil;
end.
