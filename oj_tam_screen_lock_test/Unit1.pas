unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
{$R *.dfm}

uses ojScreenLock;

procedure TForm1.Button1Click(Sender: TObject);
var v_lock: IojScreenLock;
begin

  v_lock:= TojScreenLock.getLock();
  v_lock.Params.CloseOnALT_F4:= TRUE;

  v_lock.Text:= 'Lorem ipsum <dolor> sit <<amet>>, '+
      'consectetur adipisicing elit, sed do eiusmod '+
      'tempor incididunt ut <labore> et dolore magna '+
      'aliqua. Ut enim ad minim veniam, quis nostrud '+
      'exercitation ullamco laboris nisi ut aliquip ex ea '+
      'commodo consequat. Duis aute irure dolor in '+
      'reprehenderit in voluptate velit esse cillum '+
      'dolore eu fugiat nulla pariatur. <Excepteur> '+
      'sint occaecat cupidatat non proident, sunt in '+
      'culpa qui <officia> deserunt mollit anim id est '+
      'laborum. ';

  v_lock.Caption:= 'Task 01';
  v_lock.execThreadTask(
    procedure
    begin
      Sleep(2500);
    end);

  v_lock.Caption:= 'Task 02';
  v_lock.execThreadTask(
    procedure
    begin
      Sleep(2500);
      TThread.Synchronize(TThread.CurrentThread,
        procedure
        begin
          ShowMEssage('skonczyl "Task 02"');
        end);
    end);


  v_lock.Caption:= 'Task 03';
  v_lock.Params.GradientProfile:= gpError;
  v_lock.execThreadTask(
    procedure
    begin
      Sleep(5000);
      Sleep(1000);
      Sleep(2000);
    end);

end;

end.
