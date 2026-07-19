unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, mosquitto,
  ctypes, simpleipc;

type

  { TForm1 }

  TForm1 = class(TForm)
    Cmd_Subscribe: TButton;
    Cmd_Connect: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    Cmd_Disconnect: TButton;
    Label3: TLabel;
    Label4: TLabel;
    MQTT_HOST_: TEdit;
    MQTT_PORT_: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    MQTT_Subscribe: TEdit;
    procedure Cmd_DisconnectClick(Sender: TObject);
    procedure Cmd_SubscribeClick(Sender: TObject);
    procedure Cmd_ConnectClick(Sender: TObject);
  private

  public
    procedure SendMessage_(s:String);
  end;

const
  //MQTT_HOST = 'localhost';
  MQTT_PORT = 1883;
  MQTT_HOST = 'test.mosquitto.org';

var
  Form1: TForm1;
  major, minor, revision: cint;
  mq: Pmosquitto;

implementation

{$R *.lfm}

{ TForm1 }
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

procedure mqtt_on_log(mosq: Pmosquitto; obj: pointer; level: cint; const str: pchar); cdecl;
//var
//  HexResult: string;
begin
  if form1.CheckBox1.Checked then
  begin
    form1.Memo1.Append('mqtt_on_log: '+ str);
    //HexResult:=IntToStr(sizeof(mosq));
    //if mosq<> nil then
    //HexResult:=IntToStr(Length(mosq^));
    //SetLength(HexResult, Length(Tmosquitto(mosq)) * 2);
    //BinToHex(@mosq[0], PChar(HexResult), Length(Tmosquitto(mosq)));
    //form1.Memo1.Append('Hex: '+ HexResult);
    //form1.Memo1.Append('chr: '+ chr(Tmosquitto(mosq^)[0]));
    //form1.Memo1.Append('Length: '+ HexResult);
  end;
end;

procedure mqtt_on_message(mosq: Pmosquitto; obj: pointer; const message: Pmosquitto_message); cdecl;
var
  msg: ansistring;
begin
  msg:='';
  with message^ do
  begin
      { Note that MQTT messages can be binary, but for this test case
        we just assume they're printable text }
      SetLength(msg,payloadlen);
      if payload <> nil then
      begin
        Move(payload^,msg[1],payloadlen);
        if form1.CheckBox2.Checked then form1.Memo1.Append('Topic: ['+topic+'] - Message: ['+msg+']');
        form1.SendMessage_(topic+'/'+msg);
      end;
  end;
end;

procedure TForm1.Cmd_ConnectClick(Sender: TObject);
{ Here we really just use libmosquitto's C API directly, so see its documentation. }
begin
  if mosquitto_lib_init <> MOSQ_ERR_SUCCESS then
  begin
      Memo1.Append('mosquitto_lib_init = Failed.');
      //halt(1);
      exit;
  end;
  mosquitto_lib_version(@major,@minor,@revision);

  Cmd_Connect.Enabled:=false;

  Memo1.Append('Running against libmosquitto '+major.ToString+'.'+minor.ToString+'.'+revision.ToString);

  mq:=mosquitto_new(nil, true, nil);
  if assigned(mq) then
    begin
      mosquitto_log_callback_set(mq, @mqtt_on_log);
      mosquitto_message_callback_set(mq, @mqtt_on_message);

      mosquitto_connect(mq, PChar(MQTT_HOST_.Text), StrToInt(MQTT_PORT_.Text), 60);

    end
  else
  begin
    form1.Memo1.Append('ERROR: Cannot create a mosquitto instance.');
    mosquitto_lib_cleanup;
    form1.Memo1.Append('mosquitto_lib_cleanup');
    Cmd_Connect.Enabled:=true;
    Cmd_Subscribe.Enabled:=true;
  end;

end;

procedure TForm1.Cmd_SubscribeClick(Sender: TObject);
begin
  Cmd_Subscribe.Enabled:=false;
  if assigned(mq) then
    begin
      mosquitto_subscribe(mq, nil, PChar(MQTT_Subscribe.Text), 1);

      while mosquitto_loop(mq, 100, 1) = MOSQ_ERR_SUCCESS do
      begin
          { This should ideally handle some keypress or something... }
          Application.ProcessMessages;
          if CheckBox3.Checked then break;
      end;

      mosquitto_disconnect(mq);
      mosquitto_destroy(mq);
      mq:=nil;

      mosquitto_lib_cleanup;
      form1.Memo1.Append('mosquitto_lib_cleanup');
      Cmd_Connect.Enabled:=true;
      Cmd_Subscribe.Enabled:=true;
    end
  else
  begin
    form1.Memo1.Append('ERROR: Cannot create a mosquitto instance.');
    mosquitto_lib_cleanup;
    form1.Memo1.Append('mosquitto_lib_cleanup');
    Cmd_Connect.Enabled:=true;
    Cmd_Subscribe.Enabled:=true;
  end;
end;

procedure TForm1.Cmd_DisconnectClick(Sender: TObject);
begin
  mosquitto_disconnect(mq);
  mosquitto_destroy(mq);
  mq:=nil;
  mosquitto_lib_cleanup;
  form1.Memo1.Append('mosquitto_lib_cleanup');
  Cmd_Connect.Enabled:=true;
  Cmd_Subscribe.Enabled:=true;
end;

end.

