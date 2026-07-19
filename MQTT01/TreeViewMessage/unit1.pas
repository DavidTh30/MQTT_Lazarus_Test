unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls,
  StrUtils, Unit2, simpleipc, Types;

type

  { TForm1 }

  TForm1 = class(TForm)
    CheckBox1: TCheckBox;
    Cmd_ClearTextBox: TButton;
    Cmd_ClearTextBox1: TButton;
    Cmd_ClearTextBox2: TButton;
    ComboBox1: TComboBox;
    Edit2: TEdit;
    Label4: TLabel;
    Memo1: TMemo;
    SimpleIPCServer1: TSimpleIPCServer;
    TreeView1: TTreeView;
    procedure Cmd_ClearTextBox1Click(Sender: TObject);
    procedure Cmd_ClearTextBox2Click(Sender: TObject);
    procedure Cmd_ClearTextBoxClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure SimpleIPCServer1MessageQueued(Sender: TObject);
    procedure TreeView1SelectionChanged(Sender: TObject);
  private

  public
    constructor Create(TheOwner: TComponent); override;
    procedure ClearTree();
    procedure FreeTree();
    procedure CreateTree(s_:string);
    procedure SendMessage_(s:String);
  end;

var
  Form1: TForm1;
  Message_: array[0..20] of string;

implementation

{$R *.lfm}
procedure TForm1.SendMessage_(s:String);
var
  IPCClient: TSimpleIPCClient;
  CandidateIDs: array[0..3] of string;// Or array of string for older FPC versions
  SrvID: string;
begin
  if not CheckBox1.Checked then exit;
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

procedure TForm1.CreateTree(s_:string);
var
  P_TempoData: P_TRecordData;
  TextPath: String;
  S_Step:string;
  i:integer;
  h:integer;
  l:integer;
  TargetNode: TTreeNode;
  StepNode: TTreeNode;
  s:string;
  Words: TStringArray;
begin
  TextPath := s_;
  Words:=TextPath.Split(ComboBox1.Text);

  TargetNode := TreeView1.Items.FindNodeWithTextPath(s_);

  if TargetNode <> nil then
  begin
    SendMessage_({$I %LINE%}+' case found path!');
    ////TargetNode.ExpandParents;
    ////TargetNode.Selected := True;
    ////TreeView1.SetFocus;
    //h:=high(TextPath.Split(ComboBox1.Text));
    //l:=low(TextPath.Split(ComboBox1.Text));
    //if (TargetNode.Data <> nil) then
    //begin
    //  P_TempoData:=TargetNode.Data;
    //  Dispose(P_TempoData);
    //  TargetNode.Data:=nil;
    //end;
    //
    //New(P_TempoData);
    //P_TempoData^.CustomName := ComboBox2.Text;
    //P_TempoData^.CustomID := StrToInt(edit4.Text);
    //TargetNode.Data:= P_TempoData;
    SendMessage_({$I %LINE%}+' Succeed!');
  end;

  if TargetNode = nil then
  begin
    SendMessage_({$I %LINE%}+' case path not found!');
    h:=high(TextPath.Split(ComboBox1.Text));
    l:=low(TextPath.Split(ComboBox1.Text));
    //log2({$I %LINENUM%},' h= '+h.ToString);
    //log2({$I %LINENUM%},' l='+ l.ToString);
    i:=l;
    S_Step:='';
    StepNode:=nil;
    for s in TextPath.Split(ComboBox1.Text) do       //PathDelim
    begin
      S_Step:=S_Step+s;
      SendMessage_({$I %LINE%}+' S_Step: '+S_Step);
      TargetNode := TreeView1.Items.FindNodeWithTextPath(S_Step);
      if TargetNode <> nil then
      begin
        SendMessage_({$I %LINE%}+' Found!');
        StepNode:= TargetNode;
        if (i+1) = h then
        begin
          if (TargetNode.Data <> nil) then
          begin
            P_TempoData:=TargetNode.Data;
            Dispose(P_TempoData);
            TargetNode.Data:=nil;
          end;
          New(P_TempoData);
          P_TempoData^.Name_ := s;
          P_TempoData^.Str_ := Words[h]; //ComboBox2.Text;
          //P_TempoData^.Suffix := 'byte';
          SendMessage_({$I %LINE%}+' Add data to node');
          TargetNode.Data:= P_TempoData;
          SendMessage_({$I %LINE%}+' Break!');
          break;
        end;
      end;
      if TargetNode = nil then
      begin
        SendMessage_({$I %LINE%}+' Not found!');
        if i=h then
        begin
          StepNode:=TreeView1.Items.AddChild(StepNode, s);
          SendMessage_({$I %LINE%}+' Creat node only');
          SendMessage_({$I %LINE%}+' Succeed!');
          break;
        end;
        if i<>h then
        begin
          if (i+1) = h then
          begin
            New(P_TempoData);
            P_TempoData^.Name_ := s;
            P_TempoData^.Str_ := Words[h]; //ComboBox2.Text;
            //P_TempoData^.Suffix := 'byte';
            StepNode:=TreeView1.Items.AddChildObject(StepNode, s, P_TempoData);
            SendMessage_({$I %LINE%}+' Creat node + add data');
            SendMessage_({$I %LINE%}+' Succeed!');
            break;
          end;
          if (h=0) then
          begin
            StepNode:=TreeView1.Items.AddChild(StepNode, s);
            SendMessage_({$I %LINE%}+' Creat node only');
            SendMessage_({$I %LINE%}+' Succeed!');
            break;
          end;
          if ((i+1)<>h) then
          begin
            StepNode:=TreeView1.Items.AddChild(StepNode, s);
            SendMessage_({$I %LINE%}+' Creat node only');
            SendMessage_({$I %LINE%}+' Succeed!')
          end;
        end;
      end;
      i:=i+1;
      S_Step:=S_Step+'/';
    end;
  end;

end;

procedure TForm1.FreeTree();
var
  CurrentNode: TTreeNode;
  P_TempoData: P_TRecordData;
begin
  CurrentNode := TreeView1.Items.GetFirstNode;

  while CurrentNode <> nil do
  begin
    if CurrentNode.Data = nil then SendMessage_({$I %LINE%}+' ['+CurrentNode.Text+']: nil');
    if CurrentNode.Data <> nil then
    begin
      SendMessage_({$I %LINE%}+' ['+CurrentNode.Text+']: Free memory');
      P_TempoData:=CurrentNode.Data;
      Dispose(P_TempoData);
      CurrentNode.Data:=nil;
    end;
    CurrentNode := CurrentNode.GetNext;
  end;
end;

procedure TForm1.ClearTree();
var
  CurrentNode: TTreeNode;
  P_TempoData: P_TRecordData;
begin
CurrentNode := TreeView1.Items.GetFirstNode;

  while CurrentNode <> nil do
  begin
    if CurrentNode.Data <> nil then
    begin
      P_TempoData:=CurrentNode.Data;
      Dispose(P_TempoData);
      CurrentNode.Data:=nil;
    end;
    CurrentNode := CurrentNode.GetNext;
  end;

  TreeView1.Items.Clear
end;

function GetTextPath__(TargetNode: TTreeNode; const PathDelim_:string = '/'): string;
var
  CurrentNode: TTreeNode;
  s:string = '';
begin

  if (TargetNode <> nil) then
  begin
    CurrentNode:=TargetNode;
    s:=CurrentNode.Text;
    CurrentNode:=CurrentNode.Parent;
    while CurrentNode <> nil do
    begin
      s:=CurrentNode.Text+PathDelim_+s;
      CurrentNode:=CurrentNode.Parent;
    end;
  end;

 Result:=s;

end;

function FindNodeWithPath_(ATreeView: TTreeView; TextPath: String; const PathDelim_:string = '/'): TTreeNode;
var
  s: String;
begin
  Result := nil;
  for s in TextPath.Split(PathDelim_) do
  begin
    if (Result = nil) then
    begin
      if s = '' then Result := ATreeView.Items.FindTopLvlNode(PathDelim_)
      else Result := ATreeView.Items.FindTopLvlNode(s);
    end
    else
    begin
      Result.Expanded := true;
      Result := Result.FindNode(s);
    end;
  end;
end;

procedure TForm1.Cmd_ClearTextBoxClick(Sender: TObject);
begin
  Memo_.Clear;
  SendMessage_('clear');
  //CreateTree('root');
  //CreateTree('root\sub01');
  //CreateTree('root\sub01\sub');
end;

procedure TForm1.Cmd_ClearTextBox2Click(Sender: TObject);
begin
  FreeTree();
end;

procedure TForm1.Cmd_ClearTextBox1Click(Sender: TObject);
begin
  ClearTree();
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  CurrentNode: TTreeNode;
  P_TempoData: P_TRecordData;
begin

  CurrentNode := TreeView1.Items.GetFirstNode;

  while CurrentNode <> nil do
  begin
    if CurrentNode.Data <> nil then
    begin
      P_TempoData:=CurrentNode.Data;
      Dispose(P_TempoData);
      CurrentNode.Data:=nil;
    end;
    CurrentNode := CurrentNode.GetNext;
  end;
  SimpleIPCServer1.StopServer;
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
    ClearTree();
  end;

  if (Upcase(s)='FREE') then
  begin
    FreeTree();
  end;

  //Message_[3]:=s;

  if not((Upcase(s)='CLEAR') or (Upcase(s)='CLEAN') or (Upcase(s)='FREE')) then
  begin
    CreateTree(s);
  end;
end;

procedure TForm1.TreeView1SelectionChanged(Sender: TObject);
begin
  if (Treeview1.Selected <> nil) then
  if (Treeview1.Selected.Data <> nil) then
  begin
    //if GetTypeKind(Treeview1.Selected.Data) = GetTypeKind(P_TRecordData) then  log2({$I %LINENUM%},' Type: P_TRecordData');
    ////if GetTypeKind(Treeview1.Selected.Data) = GetTypeKind(TRecordData) then  log2({$I %LINENUM%},' Type: TRecordData');
    log2({$I %LINENUM%},' Name_: '+P_TRecordData(Treeview1.Selected.Data)^.Name_ );
    log2({$I %LINENUM%},' Str_: '+P_TRecordData(Treeview1.Selected.Data)^.Str_ );
    //log2({$I %LINENUM%},' Suffix: '+P_TRecordData(Treeview1.Selected.Data)^.Suffix);
  end
  else
  begin
    log2({$I %LINENUM%},' Empty Data');
  end;

  if(Treeview1.Selected <> nil) then Edit2.Text  := GetTextPath__(Treeview1.Selected,ComboBox1.Text);
  if(Treeview1.Selected = nil) then Edit2.Text  := '';

end;

constructor TForm1.Create(TheOwner: TComponent);
var
  i:integer;
begin
  inherited Create(TheOwner);
  Memo_:=Memo1;

  MyData.Name_ := 'Test';
  MyData.Str_ := 'Hello';
  MyData.Int_ := 123;

  SimpleIPCServer1.ServerID:='TreeView';
  SimpleIPCServer1.Global:=true;
  SimpleIPCServer1.StartServer;

  for i:= low(Message_) to High(Message_) do
  begin
    Message_[i]:='';
  end;

  //showmessage('TForm1.Create');
end;

end.

