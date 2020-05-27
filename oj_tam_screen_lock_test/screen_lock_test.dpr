program screen_lock_test;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  ojScreenLock in '..\src\ojScreenLock.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown:= TRUE;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
