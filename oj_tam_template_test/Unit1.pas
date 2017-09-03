unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, ojTemplate, Vcl.StdCtrls, ojKeyValueList,
  Vcl.ExtCtrls, Vcl.ComCtrls;

type
  TForm4 = class(TForm)
    Panel1: TPanel;
    memoSrc: TMemo;
    memoTag: TMemo;
    memoDest: TMemo;
    Panel2: TPanel;
    Label1: TLabel;
    Label2: TLabel;
    btnDetectTag: TButton;
    chCaseSensitive: TCheckBox;
    edCloseBracked: TEdit;
    edOpenBracked: TEdit;
    btnSubstituteUC: TButton;
    btnSubstituteLC: TButton;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Button1: TButton;
    procedure btnDetectTagClick(Sender: TObject);
    procedure btnSubstitute_XXX_Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form4: TForm4;

implementation

{$R *.dfm}

procedure TForm4.btnDetectTagClick(Sender: TObject);
var v_kv: IojKeyValueList;
    v_item: TojKeyValueItem;
    v_cfg: IojTemplateConfig;
begin

  memoTag.Lines.Clear;
  v_cfg:= TojTemplate.Config.Duplicate.
    putOpenBracket(edOpenBracked.Text[1]).
    putCloseBracket(edCloseBracked.Text[1]);

  v_kv:= TojTemplate.detect_tags(memoSrc.Text, chCaseSensitive.Checked, v_cfg);

  for v_item in v_kv do
    memoTag.Lines.Add(v_item.Key);
end;

procedure TForm4.btnSubstitute_XXX_Click(Sender: TObject);
var v_kv: IojKeyValueList;
    v_item: TojKeyValueItem;
    v_cfg: IojTemplateConfig;
begin
  v_cfg:= TojTemplate.Config.Duplicate.
    putOpenBracket(edOpenBracked.Text[1]).
    putCloseBracket(edCloseBracked.Text[1]);

  v_kv:= TojTemplate.detect_tags(memoSrc.Text, chCaseSensitive.Checked, v_cfg);

  for v_item in v_kv do
    if Sender = btnSubstituteUC
    then v_item.Value:= UpperCase(v_item.Key)
    else if Sender = btnSubstituteLC
    then v_item.Value:= LowerCase(v_item.Key)
    else v_item.Value:= '???????';

  memoDest.Text:= TojTemplate.Substitute(memoSrc.Text, v_kv, v_cfg)

end;

procedure TForm4.Button1Click(Sender: TObject);
var v_kv: IojKeyValueList;
    v_item: TojKeyValueItem;
    v_cfg: IojTemplateConfig;
begin
  v_cfg:= TojTemplate.Config.Duplicate.
    putOpenBracket(edOpenBracked.Text[1]).
    putCloseBracket(edCloseBracked.Text[1]);

  v_kv:= TojTemplate.detect_tags(memoSrc.Text, chCaseSensitive.Checked, v_cfg);
  for v_item in v_kv do
    v_item.Value:= UpperCase(v_item.Key);

  v_kv.ShowItems;

end;

end.
