unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  strutils, simpleipc, MQTT,
  syncobjs, // TCriticalSection
  fptimer;

type TembeddedAppStates = (
                           CONNECT,
                           WAIT_CONNECT,
                           RUNNING,
                           FAILING
                          );

type

  { TForm1 }

  TForm1 = class(TForm)
    Cmd_Connect: TButton;
    Cmd_Disconnect: TButton;
    Button3: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Cmd_ConnectClick(Sender: TObject);
    procedure Cmd_DisconnectClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    MQTTClient: TMQTTClient;
    SyncCode:   TCriticalSection;
    TimerTick: TFPTimer;
    cnt:      integer;

    // Unsafe events! Called from MQTT thread (TMQTTReadThread)
    procedure OnConnAck(Sender: TObject; ReturnCode: integer);
    procedure OnPingResp(Sender: TObject);
    procedure OnSubAck(Sender: TObject; MessageID: integer; GrantedQoS: integer);
    procedure OnUnSubAck(Sender: TObject);
    procedure OnPublish(Sender: TObject; topic, payload: ansistring; isRetain: boolean);

    procedure OnTimerTick(Sender: TObject);
  public
    terminate: boolean;
    constructor Create(TheOwner: TComponent); override;
    procedure WriteHelp;
    procedure OnIdle(Sender: TObject; var Done: boolean);
    procedure SendMessage_(s:String);
    procedure log3(s:String);
    procedure SendMemMessage_(s:String);
  end;

const
  pubTimerInterval = 60*10; // 60 - 1 minute
  pingTimerInterval = 10*10; // 10 - ping every 10 sec

var
  Form1: TForm1;
  msg : TMQTTMessage;
  ack : TMQTTMessageAck;
  IPC_ServerOnline:boolean;
  MQTT_Server: string;
  MQTT_Topic:string;

implementation

{$R *.lfm}

{old: const
  { ^C }
  //ContrBreakSIG = ^C; // yes, its valid string! (OMG!)
  //ContrBreakSIG = #$03;
}

function NewTimer(Intr: integer; Proc: TNotifyEvent; AEnable: boolean = false): TFPTimer;
begin
  Result := TFPTimer.Create(nil);
  Result.UseTimerThread:=false;
  Result.Interval := Intr;
  Result.OnTimer := Proc;
  Result.Enabled := AEnable;
end;

{ TForm1 }

procedure TForm1.OnConnAck(Sender: TObject; ReturnCode: integer);
begin
  SyncCode.Enter;
  log3('ConnAck');
  SyncCode.Leave;
end;

procedure TForm1.OnPingResp(Sender: TObject);
begin
  SyncCode.Enter;
  log3('PingResp');
  SyncCode.Leave;
end;

procedure TForm1.OnSubAck(Sender: TObject; MessageID: integer; GrantedQoS: integer);
begin
  SyncCode.Enter;
  log3('SubAck');
  SyncCode.Leave;
end;

procedure TForm1.OnUnSubAck(Sender: TObject);
begin
  SyncCode.Enter;
  log3('UnSubAck');
  SyncCode.Leave;
end;

procedure TForm1.OnPublish(Sender: TObject; topic, payload: ansistring;
  isRetain: boolean);
begin
  SyncCode.Enter;
  if (CheckBox2.Checked) then log3('Publish'+ ' topic='+ topic+ ' payload='+ payload);
  SendMessage_(topic+'/'+payload);
  SyncCode.Leave;
end;

procedure TForm1.OnTimerTick(Sender: TObject);
begin
  SyncCode.Enter;
  cnt := cnt + 1;
  log3('Tick. N='+IntToStr(cnt));
  MQTTClient.PingReq;
  MQTTClient.Publish('Test', IntToStr(cnt));
  SyncCode.Leave;
end;

procedure TForm1.OnIdle(Sender: TObject; var Done: boolean);
begin


  ////todo: wait 'OnConnAck'
  //Sleep(100);

  if (MQTTClient <> nil) then
  if not MQTTClient.isConnected then
  begin
    log3('connect FAIL');
    exit;
  end;

  //try
    if (MQTTClient <> nil) then
    if (MQTTClient.isConnected) then
    //while (MQTTClient.isConnected) do
    begin
      if CheckBox1.Checked then
      log3({$i %LINE%} +' MQTTClient Connected:'+ MQTTClient.isConnected.ToInteger.ToString);
      // wait other thread
      //CheckSynchronize(100);

      //old: Check for ctrl-c
      {if KeyPressed then          //  <--- CRT function to test key press
        if ReadKey = ContrBreakSIG then      // read the key pressed
        begin
          writeln('Ctrl-C pressed.');
          Terminate;
        end;}
    end;

  //      //while not terminate do
  //      if (MQTTClient <> nil) then
  //      begin
  //        case state of
  //          CONNECT :
  //                    begin
  //                      // Connect to MQTT server
  //                      log3({$i %LINE%} +' CONNECT');
  //                      pingCounter := 0;
  //                      pingTimer := 0;
  //                      pubTimer := 0;
  //                      connectTimer := 0;
  //                      MQTTClient.Connect;
  //                      state := WAIT_CONNECT;
  //                    end;
  //          WAIT_CONNECT :
  //                         begin
  //                           // Can only move to RUNNING state on recieving ConnAck
  //                           log3({$i %LINE%} +' WAIT_CONNECT');
  //                           connectTimer := connectTimer + 1;
  //                           if connectTimer > 300 then
  //                             begin
  //                               log3('embeddedApp: Error: ConnAck time out.');
  //                               state := FAILING;
  //                             end;
  //                         end;
  //          RUNNING :
  //                    begin
  //                      // Publish stuff
  //                      if CheckBox2.Checked then log3({$i %LINE%} +' RUNNING');
  //                      if pubTimer mod pubTimerInterval = 0 then
  //                        begin
  //                          if not MQTTClient.Publish(MQTT_Topic, message) then
  //                            begin
  //                              log3('embeddedApp: Error: Publish Failed.');
  //                              state := FAILING;
  //                            end;
  //                        end;
  //                      pubTimer := pubTimer + 1;
  //
  //                      // Ping the MQTT server occasionally
  //                      if (pingTimer mod 100) = 0 then
  //                        begin
  //                          // Time to PING !
  //                          if not MQTTClient.PingReq then
  //                            begin
  //                              log3('embeddedApp: Error: PingReq Failed.');
  //                              state := FAILING;
  //                            end;
  //                          pingCounter := pingCounter + 1;
  //                          // Check that pings are being answered
  //                          if pingCounter > 3 then
  //                            begin
  //                              log3('embeddedApp: Error: Ping timeout.');
  //                              state := FAILING;
  //                            end;
  //                        end;
  //                      pingTimer := pingTimer + 1;
  //                    end;
  //          FAILING :
  //                    begin
  //                      log3({$i %LINE%} +' FAILING');
  //                      MQTTClient.ForceDisconnect;
  //                      state := CONNECT;
  //                      //Cmd_Connect.Enabled:=true;
  //                    end;
  //        end;
  //
  //        // Read incomming MQTT messages.
  //        repeat
  //          msg := MQTTClient.getMessage;
  //          if Assigned(msg) then
  //            begin
  //              //log3('getMessage: ' + msg.topic + ' Payload: ' + msg.payload);
  //              SendMessage_(msg.topic+'/'+msg.payload);
  //              if msg.PayLoad = 'stop' then
  //                terminate := true;
  //
  //              // Important to free messages here.
  //              msg.free;
  //            end;
  //        until not Assigned(msg);
  //
  //        // Read incomming MQTT message acknowledgments
  //        repeat
  //          ack := MQTTClient.getMessageAck;
  //          if Assigned(ack) then
  //            begin
  //              case ack.messageType of
  //                CONNACK :
  //                          begin
  //                            log3({$i %LINE%} +' Connect Acknowledgment ');
  //                            if ack.returnCode = 0 then
  //                              begin
  //                                // Make subscriptions
  //                                MQTTClient.Subscribe(MQTT_Topic);
  //                                // Enter the running state
  //                                state := RUNNING;
  //                              end
  //                            else
  //                              state := FAILING;
  //                          end;
  //                PINGRESP :
  //                           begin
  //                             log3({$i %LINE%} +' PING Response ');
  //                             // Reset ping counter to indicate all is OK.
  //                             pingCounter := 0;
  //                           end;
  //                SUBACK :
  //                         begin
  //                           log3('SUBACK: ');
  //                           log3(ack.messageId.ToString);
  //                           log3(', ');
  //                           log3('qos: '+ack.qos.ToString);
  //                         end;
  //                UNSUBACK :
  //                           begin
  //                             log3('UNSUBACK: ');
  //                             log3(ack.messageId.ToString);
  //                           end;
  //              end;
  //            end;
  //          // Important to free messages here.
  //          ack.free;
  //        until not Assigned(ack);
  //
  //        // Main application loop must call this else we leak threads!
  //        CheckSynchronize;
  //
  //        // Yawn.
  //        sleep(100);
  //        //Application.ProcessMessages;
  //      end;
  //finally
  //end;


  //form1.Refresh;
  Done := false;
end;

procedure TForm1.WriteHelp;
begin
  { add your help code here }
  //writeln('Usage: ', ExeName, ' -h');
end;

constructor TForm1.Create(TheOwner: TComponent);
var
  ErrorMsg: string;
begin
  inherited Create(TheOwner);

  // quick check parameters
  //ErrorMsg := CheckOptions('h', 'help');
  if ErrorMsg <> '' then
  begin
    //ShowException(Exception.Create(ErrorMsg));
    halt;
    Exit;
  end;

  //// parse parameters
  //if HasOption('h', 'help') then
  //begin
  //  WriteHelp;
  //  halt;
  //  Exit;
  //end;

  MQTT_Server := Edit1.Text; //'test.mosquitto.org'; //'192.168.1.19';
  MQTT_Topic := Edit2.Text; //'home/#'; //'/jack/says';
  //MQTT_Server := '192.168.0.26';

  Application.OnIdle := @OnIdle;

end;

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
    IPC_ServerOnline:=false;
    for SrvID in CandidateIDs do
    begin
      IPCClient.ServerID := SrvID;
      //IPCClient.Global := True; // Match the Global setting of your servers

      if IPCClient.ServerRunning then
      begin
        IPCClient.Active:=true;
        IPCClient.Connect;
        IPC_ServerOnline:=true;
        IPCClient.SendStringMessage(s);
        break;
      end;
    end;
  finally
    IPCClient.Disconnect;
    IPCClient.Active:=false;
    IPCClient.Free;
  end;
  if IPC_ServerOnline then
  begin
    //Label1.Caption:={$i %LINE%}+ ': '+'Connect';
    //Shape1.Brush.Color:=clGreen;
  end;
  if not IPC_ServerOnline then
  begin
    //Label1.Caption:={$i %LINE%}+ ': '+'Disonnect';
    //Shape1.Brush.Color:=clSilver;
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
    IPC_ServerOnline:=false;
    for SrvID in CandidateIDs do
    begin
      IPCClient.ServerID := SrvID;
      //IPCClient.Global := True; // Match the Global setting of your servers

      if IPCClient.ServerRunning then
      begin
        IPCClient.Active:=true;
        IPCClient.Connect;
        IPC_ServerOnline:=true;
        IPCClient.SendStringMessage(s);
        break;
      end;
    end;
  finally
    IPCClient.Disconnect;
    IPCClient.Active:=false;
    IPCClient.Free;
  end;
  if IPC_ServerOnline then
  begin
    //Label1.Caption:={$i %LINE%}+ ': '+'Connect';
    //Shape1.Brush.Color:=clGreen;
  end;
  if not IPC_ServerOnline then
  begin
    //Label1.Caption:={$i %LINE%}+ ': '+'Disonnect';
    //Shape1.Brush.Color:=clSilver;
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
    IPC_ServerOnline:=false;
    for SrvID in CandidateIDs do
    begin
      IPCClient.ServerID := SrvID;
      //IPCClient.Global := True; // Match the Global setting of your servers

      if IPCClient.ServerRunning then
      begin
        IPCClient.Active:=true;
        IPCClient.Connect;
        IPC_ServerOnline:=true;
        IPCClient.SendStringMessage(s);
        break;
      end;
    end;
  finally
    IPCClient.Disconnect;
    IPCClient.Active:=false;
    IPCClient.Free;
  end;
  if IPC_ServerOnline then
  begin
    //Label1.Caption:={$i %LINE%}+ ': '+'Connect';
    //Shape1.Brush.Color:=clGreen;
  end;
  if not IPC_ServerOnline then
  begin
    //Label1.Caption:={$i %LINE%}+ ': '+'Disonnect';
    //Shape1.Brush.Color:=clSilver;
  end;
end;

procedure TForm1.Cmd_ConnectClick(Sender: TObject);
begin
  log3('Connect MQTT Client.');

  Cmd_Connect.Enabled:=false;

  MQTT_Server := Edit1.Text; //'test.mosquitto.org'; //'192.168.1.19';
  MQTT_Topic := Edit2.Text; //'home/#'; //'/jack/says';
  //MQTT_Server := '192.168.0.26';

  SyncCode := TCriticalSection.Create();

  MQTTClient := TMQTTClient.Create(MQTT_Server, StrToInt(Edit3.Text));
  MQTTClient.OnConnAck := @OnConnAck;
  MQTTClient.OnPingResp := @OnPingResp;
  MQTTClient.OnPublish := @OnPublish;
  MQTTClient.OnSubAck := @OnSubAck;

  MQTTClient.Connect();

  Sleep(1000);

  if (MQTTClient <> nil) then
    if (MQTTClient.isConnected) then
      MQTTClient.Subscribe(MQTT_Topic);

  cnt := 0;
  TimerTick := NewTimer(5000, @OnTimerTick, true);

end;

procedure TForm1.Cmd_DisconnectClick(Sender: TObject);
begin
  if (MQTTClient <> nil) then
  begin
    MQTTClient.Unsubscribe(MQTT_Topic);
    MQTTClient.Disconnect;
    Sleep(100);
    MQTTClient.ForceDisconnect;

    FreeAndNil(TimerTick);
    FreeAndNil(MQTTClient);
    FreeAndNil(SyncCode);
    //Sleep(2000); // wait thread dies

  end;
  Cmd_Connect.Enabled:=true;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  log3('clean');
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if (MQTTClient <> nil) then
  begin
    MQTTClient.Unsubscribe(MQTT_Topic);
    MQTTClient.Disconnect;
    Sleep(100);
    MQTTClient.ForceDisconnect;

    FreeAndNil(TimerTick);
    FreeAndNil(MQTTClient);
    FreeAndNil(SyncCode);
    Sleep(2000); // wait thread dies

  end;
end;

end.

