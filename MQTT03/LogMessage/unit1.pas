unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, simpleipc, Forms, Controls, Graphics, Dialogs, uCmdBox;

type

  { TForm1 }

  TForm1 = class(TForm)
    CmdBox1: TCmdBox;
    SimpleIPCServer1: TSimpleIPCServer;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure SimpleIPCServer1MessageQueued(Sender: TObject);
  private
  procedure OnIdle(Sender: TObject; var Done: boolean);
  public

  end;

var
  Form1: TForm1;
  i:integer;
  Message_: array[0..20] of string;
  Position_:integer;

implementation

{$R *.lfm}

{ TForm1 }
procedure TForm1.OnIdle(Sender: TObject; var Done: boolean);
var
  i:integer;
begin

  //CmdBox1.Writeln(#27#10#196);
  //CmdBox1.TextColors(clRed,clBlue);
  //CmdBox1.Write('Processing ['+IntToStr(50)+'%]'#13);

  CmdBox1.TextColor(clWhite);
  for i:= low(Message_) to High(Message_) do
  begin
    CmdBox1.OutX:=1;
    CmdBox1.OutY:=i;
    CmdBox1.ClearLine;
    CmdBox1.OutX:=1;
    CmdBox1.OutY:=i;
    CmdBox1.Write(''+ Message_[i]+'');
  end;

  Form1.Refresh;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i:integer;
begin
  Application.OnIdle := @OnIdle;
  SimpleIPCServer1.ServerID:='MessageLogConsole20';
  SimpleIPCServer1.Global:=true;
  SimpleIPCServer1.StartServer;

  Position_:=0;
  for i:= low(Message_) to High(Message_) do
  begin
    Message_[i]:='';
  end;
end;

procedure TForm1.SimpleIPCServer1MessageQueued(Sender: TObject);
var
  i:integer;
  s:string;
begin
  SimpleIPCServer1.ReadMessage;
  s:=SimpleIPCServer1.StringMessage;

  if (Upcase(s)='CLEAR') or (Upcase(s)='CLEAN') then
  begin
    for i:= low(Message_) to High(Message_) do
    begin
      Message_[i]:='';
    end;
    Position_:=low(Message_);
    //CmdBox1.Clear;
  end;

  if Position_>High(Message_) then
  begin
    for i:= low(Message_) to High(Message_)-1 do
    begin
      Message_[i]:=Message_[i+1];
      if (Upcase(s)='CLEAR') or (Upcase(s)='CLEAN') then Message_[i]:='';
    end;
    Position_:=High(Message_);
    Message_[Position_]:='';
  end;

  if not((Upcase(s)='CLEAR') or (Upcase(s)='CLEAN')) then
  begin
    Message_[Position_]:=s;
    Position_:=Position_+1;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SimpleIPCServer1.StopServer;
end;

end.

