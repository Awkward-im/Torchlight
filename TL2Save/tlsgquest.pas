{
  Quests Done crosses with Statistic Block!!!

QUESTS = lists all quests
QUESTSHOWACTIVE = Shows all the players active quests
QUESTSCOMPLETE = Lists all the quests complete

QUESTACTIVE questName = sets a quest to active
QUESTCOMPLETE questName = sets a quest to complete
QUESTRESET questName = resets a quest to not be active or complete

}
unit TLSGQuest;

interface

uses
  Classes,
  rgglobal,
  TLSGBase,
  TL2Common,
  rgstream;


type
  TTLQuestData = record
    id  :TRGID;                        // TL2
    name:string;                       // TL1
    q1  :TRGID;
    d1  :TRGInteger;
    d2  :TRGInteger;
    len :integer;
    data:PByte;

    ofs :integer;
  end;
  TTLQuestList = array of TTLQuestData;

type
  TTLQuest = class(TLSGBaseClass)
  private
    procedure InternalClear;

  public
    constructor Create;
    destructor  Destroy; override;

    procedure Clear; override;

    procedure LoadFromStream(AStream: TStream; aVersion:integer); override;
    procedure SaveToStream  (AStream: TStream; aVersion:integer); override;

  private
    FQuestsDone  :TL2IdList;
    FQuestsUnDone:TTLQuestList;

    function GetQuestsDoneNum  :integer;
    function GetQuestsUnDoneNum:integer;
  public
    property QuestsDoneNum  :integer read GetQuestsDoneNum;
    property QuestsUnDoneNum:integer read GetQuestsUnDoneNum;

    property QuestsDone  :TL2IdList    read FQuestsDone;
    property QuestsUnDone:TTLQuestList read FQuestsUnDone;
  end;


function ReadQuests(AStream:TStream; aVersion:integer):TTLQuest;


implementation


constructor TTLQuest.Create;
begin
  inherited;

  DataType:=dtQuest;
end;

destructor TTLQuest.Destroy;
begin
  InternalClear;

  inherited;
end;

procedure TTLQuest.InternalClear;
var
  i:integer;
begin
  SetLength(FQuestsDone,0);

  for i:=0 to High(FQuestsUnDone) do
    FreeMem(FQuestsUnDone[i].data);
  SetLength(FQuestsUnDone,0);
end;

procedure TTLQuest.Clear;
begin
  InternalClear;

  inherited;
end;

//----- Property methods -----

function TTLQuest.GetQuestsDoneNum:integer;
begin
  result:=Length(FQuestsDone);
end;

function TTLQuest.GetQuestsUnDoneNum:integer;
begin
  result:=Length(FQuestsUnDone);
end;

//----- Save / load -----

procedure TTLQuest.LoadFromStream(AStream: TStream; aVersion:integer);
var
  i,lcnt:integer;
  loffset,lbase:cardinal;
begin
  if aVersion>=tlsaveTL2Minimal then
    DataSize:=AStream.ReadDWord;

  DataOffset:=AStream.Position;

  //--- Finished quests

  if aVersion>=tlsaveTL2Minimal then
    FQuestsDone:=AStream.ReadIdList;

  //--- Active quests

  // Offset to next quest is from quests block (TL2) or file (TL1) start
  if aVersion>=tlsaveTL2Minimal then
    lbase:=DataOffset
  else
    lbase:=0;

  lcnt:=AStream.ReadDWord;
  SetLength(FQuestsUnDone,lcnt);
  for i:=0 to lcnt-1 do
  begin
    loffset:=AStream.ReadDWord;
    with FQuestsUnDone[i] do
    begin
      ofs:=AStream.Position;

      if aVersion>=tlsaveTL2Minimal then
        id:=TRGID(AStream.ReadQWord)
      else
      begin
        name:=AStream.ReadShortString;
      end;
      q1:=TRGID(Check(AStream.ReadQWord,'quest_8_'+HexStr(AStream.Position,8),QWord(RGIdEmpty)));
      d1:=integer(AStream.ReadDWord);
      d2:=TRGInteger(Check(AStream.ReadDWord,'quest_4_'+HexStr(AStream.Position,8),$FFFFFFFF));

      len:=(lbase+loffset)-AStream.Position;

      data:=AStream.ReadBytes(len);
    end;
  end;

  LoadBlock(AStream);
end;

procedure TTLQuest.SaveToStream(AStream: TStream; aVersion:integer);
var
  lbase,lpos:cardinal;
  i:integer;
begin
  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteDWord(DataSize);

  if not Changed then
  begin
    SaveBlock(AStream);
    exit;
  end;

  DataOffset:=AStream.Position;

  //--- Finished quests

  if aVersion>=tlsaveTL2Minimal then
    AStream.WriteIdList(FQuestsDone);

  //--- Active quests

  // Offset to next quest is from quests block (TL2) or file (TL1) start
  if aVersion>=tlsaveTL2Minimal then
    lbase:=DataOffset
  else
    lbase:=0;

  AStream.WriteDWord(Length(FQuestsUnDone));
  for i:=0 to High(FQuestsUnDone) do
  begin
    with FQuestsUnDone[i] do
    begin
      lpos:=AStream.Position;
      AStream.WriteDWord(0);

      if aVersion>=tlsaveTL2Minimal then
        AStream.WriteQWord(QWord(id))
      else
        AStream.WriteShortString(name);

      AStream.WriteQWord(QWord(q1));
      AStream.WriteDWord(DWord(d1));
      AStream.WriteDWord(DWord(d2));
      AStream.Write(data^,len);

      AStream.WriteDWordAt(AStream.Position-lbase,lpos);
    end;
  end;

  //--- Update data size and internal buffer

  LoadBlock(AStream);

  if aVersion>=tlsaveTL2Minimal then
    FixSize(AStream);
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

function ReadQuests(AStream:TStream; aVersion:integer):TTLQuest;
begin
  result:=TTLQuest.Create;
  try
    result.LoadFromStream(AStream, aVersion);
  except
    AStream.Position:=result.DataOffset+result.DataSize;
  end;
end;

end.
