unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, mosquitto,
  ctypes, mqttclass, simpleipc;

type
  TMyMQTTConnection = class(TMQTTConnection)
    procedure MyOnMessage(const payload: Pmosquitto_message);
  end;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Cmd_Connect: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    Label3: TLabel;
    MQTT_HOST_: TEdit;
    MQTT_PORT_: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Cmd_ConnectClick(Sender: TObject);
  private

  public
    procedure log3(s:String);
    procedure SendMemMessage_(s:String);
    procedure SendMessage_(s:String);
  end;

var
  Form1: TForm1;
  mqtt: TMyMQTTConnection;
  config: TMQTTConfig;

implementation

{$R *.lfm}

procedure TForm1.log3(s:String);
var
  IPCClient: TSimpleIPCClient;
  CandidateIDs: array[0..3] of string;// Or array of string for older FPC versions
  SrvID: string;
begin

  // List of IDs you expect or want to test for
  //CandidateIDs := ['ServerOne', 'ServerTwo', 'AppInstance_123', 'MyServerID'];
  CandidateIDs[0]:='MessageLogConsole20';
  CandidateIDs[1]:='MessageLogConsole50';
  CandidateIDs[2]:='MessageLogConsole100';
  CandidateIDs[3]:='MessageLogConsole200';

  IPCClient := TSimpleIPCClient.Create(nil);
  try
    for SrvID in CandidateIDs do
    begin
      IPCClient.ServerID := SrvID;
      //IPCClient.Global := True; // Match the Global setting of your servers

      if IPCClient.ServerRunning then
      begin
        IPCClient.Active:=true;
        IPCClient.Connect;
        IPCClient.SendStringMessage(s);
        break;
      end;
    end;
  finally
    IPCClient.Disconnect;
    IPCClient.Active:=false;
    IPCClient.Free;
  end;

end;

procedure TForm1.SendMemMessage_(s:String);
var
  IPCClient: TSimpleIPCClient;
  CandidateIDs: array[0..3] of string;// Or array of string for older FPC versions
  SrvID: string;
begin

  // List of IDs you expect or want to test for
  //CandidateIDs := ['ServerOne', 'ServerTwo', 'AppInstance_123', 'MyServerID'];
  CandidateIDs[0]:='MemoryUse5';
  CandidateIDs[1]:='MemoryUse10';
  CandidateIDs[2]:='MemoryUse15';
  CandidateIDs[3]:='MemoryUse20';

  IPCClient := TSimpleIPCClient.Create(nil);
  try
    for SrvID in CandidateIDs do
    begin
      IPCClient.ServerID := SrvID;
      //IPCClient.Global := True; // Match the Global setting of your servers

      if IPCClient.ServerRunning then
      begin
        IPCClient.Active:=true;
        IPCClient.Connect;
        IPCClient.SendStringMessage(s);
        break;
      end;
    end;
  finally
    IPCClient.Disconnect;
    IPCClient.Active:=false;
    IPCClient.Free;
  end;

end;

procedure TForm1.SendMessage_(s:String);
var
  IPCClient: TSimpleIPCClient;
  CandidateIDs: array[0..3] of string;// Or array of string for older FPC versions
  SrvID: string;
begin

  // List of IDs you expect or want to test for
  //CandidateIDs := ['ServerOne', 'ServerTwo', 'AppInstance_123', 'MyServerID'];
  CandidateIDs[0]:='TreeView';
  CandidateIDs[1]:='TreeView';
  CandidateIDs[2]:='TreeView';
  CandidateIDs[3]:='TreeView';

  IPCClient := TSimpleIPCClient.Create(nil);
  try
    for SrvID in CandidateIDs do
    begin
      IPCClient.ServerID := SrvID;
      //IPCClient.Global := True; // Match the Global setting of your servers

      if IPCClient.ServerRunning then
      begin
        IPCClient.Active:=true;
        IPCClient.Connect;
        IPCClient.SendStringMessage(s);
        break;
      end;
    end;
  finally
    IPCClient.Disconnect;
    IPCClient.Active:=false;
    IPCClient.Free;
  end;

end;

procedure TMyMQTTConnection.MyOnMessage(const payload: Pmosquitto_message);
var
  msg: ansistring;
begin
  msg:='';
  with payload^ do
    begin
      { Note that MQTT messages can be binary, but for this test case we just
        assume they're printable text, as a test }
      SetLength(msg,payloadlen);
      Move(payload^,msg[1],payloadlen);
      form1.Memo1.Append('Topic: ['+topic+'] - Message: ['+msg+']');
    end;
end;

{ TForm1 }

procedure TForm1.Cmd_ConnectClick(Sender: TObject);
begin
  FillChar(config, sizeof(config), 0);
  config.client_id:='0';
  with config do
  begin
    port:=StrToInt(MQTT_PORT_.Text);
    hostname:=MQTT_HOST_.Text;
    keepalives:=60;
  end;

  { use MOSQ_LOG_NODEBUG to disable debug logging }
  mqtt:=TMyMQTTConnection.Create('TEST',config,MOSQ_LOG_ALL);
  try
    { This could also go to a custom constructor of the class,
      for more complicated setups. }
    mqtt.OnMessage:=@mqtt.MyOnMessage;

    mqtt.Connect;
    mqtt.Subscribe('home/#',0); { Subscribe to all topics }
    form1.Memo1.Append('Readln()');
  except
  end;

end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  log3('clear');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
   mqtt.Free;
end;

end.

