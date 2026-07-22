unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, StrUtils, ComCtrls;
procedure log2(LINENUM_: integer; message_: string);
function FindNodeByPath(ATreeView: TTreeView; APath, ADelimiter: string): TTreeNode;

type
  P_TclassData = ^TclassData;
  TclassData = class
    Name_: string;
    Prefix: string;
    Str_: string;
    Int_: Integer;
    Suffix: string;
  end;

type
  P_TRecordData = ^TRecordData;
  TRecordData = record
    Name_: string;
    Prefix: string;
    Str_: string;
    Int_: Integer;
    Suffix: string;
  end;

type
  Unit_ = class(TForm)
  private

  public
    procedure Button2Click(Sender: TObject);
  end;

var
  Memo_:TMemo;
  MyData: TRecordData;

implementation

procedure log2(LINENUM_: integer; message_: string);
begin
  Memo_.Append(LINENUM_.ToString+message_);
end;

procedure Unit_.Button2Click(Sender: TObject);
begin

end;

function FindNodeByPath(ATreeView: TTreeView; APath, ADelimiter: string): TTreeNode;
var
  i: Integer;
  PathList: TStringList;
  FoundNode, CurrentNode: TTreeNode;
begin
  Result := nil;
  PathList := TStringList.Create;
  try
    PathList.Delimiter := ADelimiter[1];
    PathList.StrictDelimiter := True;
    PathList.DelimitedText := APath;

    CurrentNode := nil;
    FoundNode := ATreeView.Items.GetFirstNode;

    for i := 0 to PathList.Count - 1 do
    begin
      // Search for the node at the current level
      //FoundNode := ATreeView.Items.FindNode(CurrentNode, PathList[i]);
      //FoundNode := FoundNode.FindNode(PathList[i]);
      if FoundNode = nil then
        Break; // Node not found, stop searching

      CurrentNode := FoundNode;
      Result := CurrentNode;
    end;
  finally
    PathList.Free;
  end;
end;


end.

