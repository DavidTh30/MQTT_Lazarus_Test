unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Spin,
  StdCtrls, mqtt, inifiles, TypInfo, opensslsockets, simpleipc;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    ButtonConnect: TButton;
    ButtonDisconnect: TButton;
    ButtonPublish: TButton;
    ButtonSubscribe: TButton;
    ButtonUnsubscribe: TButton;
    CheckBoxDebug: TCheckBox;
    CheckBoxSSL: TCheckBox;
    ComboBoxSubs: TComboBox;
    EditHost: TEdit;
    EditRespTopic: TEdit;
    EditCorrelData: TEdit;
    EditPort: TEdit;
    EditID: TEdit;
    EditUser: TEdit;
    EditPass: TEdit;
    EditTopic: TEdit;
    EditPubTopic: TEdit;
    EditPubMessage: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    LabelQoS: TLabel;
    SpinEditQoS: TSpinEdit;
    SpinEditSubID: TSpinEdit;
    procedure Button1Click(Sender: TObject);
    procedure ButtonConnectClick(Sender: TObject);
    procedure ButtonDisconnectClick(Sender: TObject);
    procedure ButtonPublishClick(Sender: TObject);
    procedure ButtonSubscribeClick(Sender: TObject);
    procedure ButtonUnsubscribeClick(Sender: TObject);
  private

  public
    FClient: TMQTTClient;
    constructor Create(TheOwner: TComponent);
    procedure OnIdle(Sender: TObject; var Done: boolean);
    procedure log3(s:String);
    procedure SendMemMessage_(s:String);
    procedure SendMessage_(s:String);
    procedure OnDisconnect(Client: TMQTTClient);
    procedure OnConnect(Client: TMQTTClient);
    procedure OnReceive(Client: TMQTTClient; Msg: TMQTTRXData);
    procedure OnVerifySSL(Clinet: TMQTTClient; Handler: TOpenSSLSocketHandler; var Allow: Boolean);
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

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

procedure TForm1.OnDisconnect(Client: TMQTTClient);
begin
  log3('OnDisconnect');
end;

procedure TForm1.OnConnect(Client: TMQTTClient);
begin
  log3('OnConnect');
end;

procedure TForm1.OnReceive(Client: TMQTTClient; Msg: TMQTTRXData);
var
  I: Integer;
begin
  log3(Format('OnReceive: QoS %d %d %d %s = %s',
    [Msg.QoS, Msg.SubsID, Msg.ID, Msg.Topic, Msg.Message]));
  if Msg.RespTopic <> '' then
    log3(Format('           Response Topic: %s', [Msg.RespTopic]));
  if Msg.CorrelData <> '' then
    log3(Format('           Correlation Data: %s', [Msg.CorrelData]));
  with Msg.UserProps do begin
    if Count > 0 then begin
      for I := 0 to Count - 1 do begin
        log3(Format('           Prop %s: %s', [GetKey(I), GetVal(I)]));
      end;
    end;
  end;
  Application.ProcessMessages;
end;

procedure TForm1.OnVerifySSL(Clinet: TMQTTClient; Handler: TOpenSSLSocketHandler; var Allow: Boolean);
var
  C: Char;
  S: String = '';
begin
  for C in Handler.SSL.PeerFingerprint('SHA256') do begin
    S += IntToHex(Ord(C), 2);
  end;
  log3('OnVerifySSL cert fingerprint: ' + S);
  Allow := True;
end;


procedure TForm1.OnIdle(Sender: TObject; var Done: boolean);
begin

  Done := false;
end;

constructor TForm1.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);


  Application.OnIdle := @OnIdle;

  FClient := TMQTTClient.Create(Self);
  if CheckBoxDebug.Checked then FClient.OnDebug := @log3;
  FClient.OnDisconnect := @OnDisconnect;
  FClient.OnConnect := @OnConnect;
  FClient.OnVerifySSL := @OnVerifySSL;
  FClient.OnReceive := @OnReceive;

end;

procedure TForm1.Button1Click(Sender: TObject);
begin

end;

procedure TForm1.ButtonConnectClick(Sender: TObject);
var
  Res: TMQTTError;
begin
  Res := FClient.Connect(EditHost.Text, StrToIntDef(EditPort.Text, 1883),
    EditID.Text, EditUser.Text, EditPass.Text, CheckBoxSSL.Checked, False);
  if Res <> mqeNoError then
    log3(Format('connect: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
end;

procedure TForm1.ButtonDisconnectClick(Sender: TObject);
var
  Res: TMQTTError;
begin
  Res := FClient.Disconnect;
  if Res <> mqeNoError then
    log3(Format('disconnect: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
  ComboBoxSubs.Clear;
end;

procedure TForm1.ButtonPublishClick(Sender: TObject);
var
  Res: TMQTTError;
  UserProps: TMQTTUserProperties;
begin
  // set whatever props you need or leave it out and ignore this feature
  UserProps.Clear;
  UserProps.SetVal('client-software', 'prof7bit/fpc-mqtt-client');
  UserProps.SetVal('Content-Type', 'text/plain; charset=utf-8');

  Res := FClient.Publish(EditPubTopic.Text, EditPubMessage.Text, EditRespTopic.Text,
    EditCorrelData.Text, SpinEditQoS.Value, False, UserProps);

  if Res <> mqeNoError then
    log3(Format('publish: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));
end;

procedure TForm1.ButtonSubscribeClick(Sender: TObject);
var
  Res: TMQTTError;
  ID: UInt32;
begin
  ID := SpinEditSubID.Value;
  if ID > 0 then
    SpinEditSubID.Value := ID + 1;
  Res := FClient.Subscribe(EditTopic.Text, 2, ID);
  if Res <> mqeNoError then
    log3(Format('subscribe: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]))
  else begin
    ComboBoxSubs.Items.Add(EditTopic.Text);
    ComboBoxSubs.Text := EditTopic.Text;
  end;
end;

procedure TForm1.ButtonUnsubscribeClick(Sender: TObject);
var
  TopicFilter: String;
  Res: TMQTTError;
begin
  TopicFilter := ComboBoxSubs.Text;
  if Text <> '' then begin
    Res := FClient.Unsubscribe(TopicFilter);
    if ComboBoxSubs.ItemIndex >= 0 then begin
      ComboBoxSubs.Items.Delete(ComboBoxSubs.ItemIndex);
      ComboBoxSubs.ItemIndex := 0;
    end
    else
      log3(Format('unsubscribe: %s', [GetEnumName(TypeInfo(TMQTTError), Ord(Res))]));  end;
end;

end.

