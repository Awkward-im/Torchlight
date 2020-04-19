{
  Quests Done crosses with Statistic Block!!!

QUESTS = lists all quests
QUESTSHOWACTIVE = Shows all the players active quests
QUESTSCOMPLETE = Lists all the quests complete

QUESTACTIVE questName = sets a quest to active
QUESTCOMPLETE questName = sets a quest to complete
QUESTRESET questName = resets a quest to not be active or complete

}
unit TL2Quest;

interface

uses
  Classes,
  TL2Types,
  TL2Base,
  TL2Common,
  TL2Stream;


type
  TTL2QuestData = record
    id  :TL2ID;
    q1  :TL2ID;
    d1  :TL2Integer;
    d2  :TL2Integer;
    len :integer;
    data:PByte;
  end;
  TTL2QuestList = array of TTL2QuestData;

type
  TTL2Quest = class(TL2BaseClass)
  private
//    FMode:TTL2ParseType;

    FQuestsDone  :TL2IdList;
    FQuestsUnDone:TTL2QuestList;

    function GetQuestsDoneNum  :integer;
    function GetQuestsUnDoneNum:integer;
  public
    constructor Create;
    destructor  Destroy; override;

    procedure LoadFromStream(AStream: TTL2Stream);
    procedure SaveToStream  (AStream: TTL2Stream);

    property QuestsDoneNum  :integer read GetQuestsDoneNum;
    property QuestsUnDoneNum:integer read GetQuestsUnDoneNum;
  end;


function ReadQuests(AStream:TTL2Stream; amode:TTL2ParseType):TTL2Quest;


implementation


constructor TTL2Quest.Create;
begin
  inherited;

end;

destructor TTL2Quest.Destroy;
var
  i:integer;
begin
  SetLength(FQuestsDone,0);

  for i:=0 to High(FQuestsUnDone) do
    FreeMem(FQuestsUnDone[i].data);
  SetLength(FQuestsUnDone,0);

  inherited;
end;

//----- Property methods -----

function TTL2Quest.GetQuestsDoneNum:integer;
begin
  result:=Length(FQuestsDone);
end;

function TTL2Quest.GetQuestsUnDoneNum:integer;
begin
  result:=Length(FQuestsUnDone);
end;

//----- Save / load -----

procedure TTL2Quest.LoadFromStream(AStream: TTL2Stream);
var
  i,lcnt:integer;
  loffset:integer;
begin
  FromStream(AStream);
{$IFDEF DEBUG}
  ToFile('quests.dmp');
{$ENDIF}

  //--- Finished quests

  FQuestsDone:=AStream.ReadIdList;

  //--- Active quests

  lcnt:=AStream.ReadDWord;
  SetLength(FQuestsUnDone,lcnt);
  for i:=0 to lcnt-1 do
  begin
    loffset:=AStream.ReadDWord; // Offset to next quest from quests block start
    with FQuestsUnDone[i] do
    begin
      id:=TL2ID(AStream.ReadQWord);
      q1:=TL2ID(Check(AStream.ReadQWord,'quest_8_'+HexStr(AStream.Position,8),QWord(TL2IdEmpty)));
      d1:=AStream.ReadDWord;
      d2:=TL2Integer(Check(AStream.ReadDWord,'quest_4_'+HexStr(AStream.Position,8),$FFFFFFFF));

      len :=(FDataOffset+loffset)-AStream.Position;
      data:=AStream.ReadBytes(len);
    end;
  end;

// if not sure, uncomment this line
//  AStream.Position:=FDataOffset+FDataSize;
end;

procedure TTL2Quest.SaveToStream(AStream: TTL2Stream);
var
  i:integer;
begin
  if not FChanged then
  begin
    if ToStream(AStream) then exit;
  end;

  AStream.WriteDWord(0); // reserve place for size

  FDataOffset:=AStream.Position;

  //--- Finished quests

  AStream.WriteIdList(FQuestsDone);

  //--- Active quests

  AStream.WriteDWord(Length(FQuestsUnDone));
  for i:=0 to High(FQuestsUnDone) do
  begin
    with FQuestsUnDone[i] do
    begin
      AStream.WriteDWord(AStream.Position-FDataOffset+len+SizeOf(QWord)*2+SizeOf(DWord)*2);
      AStream.WriteQWord(QWord(id));
      AStream.WriteQWord(QWord(q1));
      AStream.WriteDWord(d1);
      AStream.WriteDWord(d2);
      AStream.Write(data^,len);
    end;
  end;

  //--- Update data size and internal buffer

  FDataSize:=AStream.Position-FDataOffset;
  AStream.Position:=FDataOffset-SizeOf(DWord);
  AStream.WriteDWord (FDataSize);
  ReallocMem  (FData ,FDataSize);
  AStream.Read(FData^,FDataSize);

  FChanged:=false;
end;

(*
    [+0]1b=1 => [+12] have dialogs?
    [+1]1b=? => [6][A][C] "a2-Find_Djinni"
    =1: [6]=1; [8]=1 not always
    [+2]4b=? non-zero usually
    7 - [E=1 usually]

    [+6]4b=?
    [+A]2b=?
    [+C]2b=?
    [+E]4b=? 0 usually. can be 1
    [+12]=cnt [PASSIVE] "dialog count" (words) addr. cnt+words+16 = next quest
    [+16??]
    if [e]=1 and [12]=0 =>$16(22) from [E]
    // GLOBAL_TRILLBOT:
+0  01
+1  01
+2  0F 00 00 00
+6  00 00 00 00
+A  00 00
+C  00 00
+E  01 00 00 00
+12 00 00
+14 00 00 00 00
+18 05 00 00 00 - max parts?
    01
    01
    01 00 00 00
    01 00 00 00  
    ---
    06 00 00 00
    ID=TRILLBOT ARM (QUEST ITEM)
    00 00 00 00
    00
    01          - found?
    01 00 00 00 - amount?
    00 00 00 00
    ---
    07 00 00 00
    ...
    0A 00 00 00
    ID
    00 00 00 00
    00 00 00 00
    00 00 00 00
*)

function ReadQuests(AStream:TTL2Stream; amode:TTL2ParseType):TTL2Quest;
begin
  result:=TTL2Quest.Create;
//  result.FMode:=amode;
  result.LoadFromStream(AStream);
end;

end.
