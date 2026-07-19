unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, MQTT,
  laz_synapse, strutils, simpleipc;

type TembeddedAppStates = (
                           CONNECT,
                           WAIT_CONNECT,
                           RUNNING,
                           FAILING
                          );

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
  private
    MQTTClient: TMQTTClient;
    pingCounter : integer;
    pingTimer : integer;
    state : TembeddedAppStates;
    message : ansistring;
    pubTimer : integer;
    connectTimer : integer;
  public
    terminate: boolean;
    constructor Create(TheOwner: TComponent); override;
    procedure OnIdle(Sender: TObject; var Done: boolean);
    procedure SendMessage_(s:String);
    procedure log3(s:String);
    procedure SendMemMessage_(s:String);
  end;

const
  pubTimerInterval = 60*10; // 60 - 1 minute
  pingTimerInterval = 10*10; // 10 - ping every 10 sec
  MQTT_Server = 'test.mosquitto.org'; //'192.168.1.19';
  MQTT_Topic = '/jack/says';
  //MQTT_Server = '192.168.0.26';

var
  Form1: TForm1;
  msg : TMQTTMessage;
  ack : TMQTTMessageAck;
  IPC_ServerOnline:boolean;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.OnIdle(Sender: TObject; var Done: boolean);
begin
  if CheckBox1.Checked then
  if (MQTTClient <> nil) then
  log3({$i %LINE%} +' MQTTClient Connected:'+ MQTTClient.isConnected.ToInteger.ToString);

        //while not terminate do
        if (MQTTClient <> nil) then
        begin
          case state of
            CONNECT :
                      begin
                        // Connect to MQTT server
                        log3({$i %LINE%} +' CONNECT');
                        pingCounter := 0;
                        pingTimer := 0;
                        pubTimer := 0;
                        connectTimer := 0;
                        MQTTClient.Connect;
                        state := WAIT_CONNECT;
                      end;
            WAIT_CONNECT :
                           begin
                             // Can only move to RUNNING state on recieving ConnAck
                             log3({$i %LINE%} +' WAIT_CONNECT');
                             connectTimer := connectTimer + 1;
                             if connectTimer > 300 then
                               begin
                                 Writeln('embeddedApp: Error: ConnAck time out.');
                                 state := FAILING;
                               end;
                           end;
            RUNNING :
                      begin
                        // Publish stuff
                        if CheckBox2.Checked then log3({$i %LINE%} +' RUNNING');
                        if pubTimer mod pubTimerInterval = 0 then
                          begin
                            if not MQTTClient.Publish(MQTT_Topic, message) then
                              begin
                                writeln ('embeddedApp: Error: Publish Failed.');
                                state := FAILING;
                              end;
                          end;
                        pubTimer := pubTimer + 1;

                        // Ping the MQTT server occasionally
                        if (pingTimer mod 100) = 0 then
                          begin
                            // Time to PING !
                            if not MQTTClient.PingReq then
                              begin
                                log3('embeddedApp: Error: PingReq Failed.');
                                state := FAILING;
                              end;
                            pingCounter := pingCounter + 1;
                            // Check that pings are being answered
                            if pingCounter > 3 then
                              begin
                                log3('embeddedApp: Error: Ping timeout.');
                                state := FAILING;
                              end;
                          end;
                        pingTimer := pingTimer + 1;
                      end;
            FAILING :
                      begin
                        log3({$i %LINE%} +' FAILING');
                        MQTTClient.ForceDisconnect;
                        state := CONNECT;
                      end;
          end;

          // Read incomming MQTT messages.
          repeat
            msg := MQTTClient.getMessage;
            if Assigned(msg) then
              begin
                log3('getMessage: ' + msg.topic + ' Payload: ' + msg.payload);

                if msg.PayLoad = 'stop' then
                  terminate := true;

                // Important to free messages here.
                msg.free;
              end;
          until not Assigned(msg);

          // Read incomming MQTT message acknowledgments
          repeat
            ack := MQTTClient.getMessageAck;
            if Assigned(ack) then
              begin
                case ack.messageType of
                  CONNACK :
                            begin
                              log3({$i %LINE%} +' Connect Acknowledgment ');
                              if ack.returnCode = 0 then
                                begin
                                  // Make subscriptions
                                  MQTTClient.Subscribe(MQTT_Topic);
                                  // Enter the running state
                                  state := RUNNING;
                                end
                              else
                                state := FAILING;
                            end;
                  PINGRESP :
                             begin
                               log3({$i %LINE%} +' PING Response ');
                               // Reset ping counter to indicate all is OK.
                               pingCounter := 0;
                             end;
                  SUBACK :
                           begin
                             log3('SUBACK: ');
                             log3(ack.messageId.ToString);
                             log3(', ');
                             log3('qos: '+ack.qos.ToString);
                           end;
                  UNSUBACK :
                             begin
                               log3('UNSUBACK: ');
                               log3(ack.messageId.ToString);
                             end;
                end;
              end;
            // Important to free messages here.
            ack.free;
          until not Assigned(ack);

          // Main application loop must call this else we leak threads!
          CheckSynchronize;

          // Yawn.
          //sleep(100);
          Application.ProcessMessages;
        end;


  form1.Refresh;
end;

constructor TForm1.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
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

procedure TForm1.Button1Click(Sender: TObject);
begin
  log3('embeddedApp MQTT Client.');
  state := CONNECT;
  message := 'All work and no play makes Jack a dull boy. All work and no play makes Jack a dull boy.';
  MQTTClient := TMQTTClient.Create(MQTT_Server, 1883);

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if (MQTTClient <> nil) then
  begin
    MQTTClient.ForceDisconnect;
    FreeAndNil(MQTTClient);

  end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  log3('clean');
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if (MQTTClient <> nil) then
  begin
    MQTTClient.ForceDisconnect;
    FreeAndNil(MQTTClient);

  end;
end;

end.

