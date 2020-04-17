{}
function TTL2SaveFile.Parse(amode:TTL2ParseType):boolean;
var
  lpos1,lpos,i,j,lcnt,lcnt1:integer;
begin
  result:=true;

  FStream.Position:=SizeOf(TL2SaveHeader);

  //===== Starting data =====

  FClassString :=FStream.ReadShortString();
  FDifficulty  :=TTL2Difficulty(FStream.ReadDWord);
  FHardcore    :=FStream.ReadByte<>0;
  FNewGameCycle:=FStream.ReadByte;

  //!!
  Unk1:=Check(FStream.ReadDWord,'save_label_1',0); // 0

  FGameTime:=FStream.ReadFloat; // game time (hh.mm)

  //----- Movies -----

  FMovies:=FStream.ReadIdValList;

  //----- Mod lists -----

  ReadModList(FBoundMods);          // DumpModList('Bound mods'        ,FBoundMods);
  ReadModList(FRecentModHistory);   // DumpModList('Recent mod history',FRecentModHistory);
  ReadModList(FFullModHistory);     // DumpModList('Full mod history'  ,FFullModHistory);

  //===== Character Data =====

  FCharInfo:=ReadCharData(FStream,amode,'mainchar');

  //----- Keymapping -----

  ReadKeyMappingList;  // DumpKeyMapping;

  //----- Statistic -----

  ReadStatistic(); // DumpStatistic;

  // for resurrection?
  FMap :=FStream.ReadShortString(); // map (current place)
  FArea:=FStream.ReadShortString(); // area (region) (at entrance?)

  //----- Unknown 1 -----

  //!!
  Unk2    :=Check(FStream.ReadDWord,'save_label_2',0); // 0
  UnkCoord:=FStream.ReadCoord; // usually [-999, -999, -999]

  //----- User portal -----

  FPortalOpened:=FStream.ReadByte<>0;
  FPortalCoord :=FStream.ReadCoord();
  FPortalPlace :=FStream.ReadShortString(); // User portal location

  //!!
  Unk3:=Check(FStream.ReadDWord,'pre-pet',1);  // usually, 1 but can be zero too

  //===== Pet Data =====

  lcnt:=FStream.ReadDWord;  // 1 (2 if BiA cative)
  SetLength(FPetInfos,lcnt);
  for i:=0 to lcnt-1 do
    FPetInfos[i]:=ReadCharData(FStream,amode,'petinfo'+HexStr(i,2));

  //----- Unknown 2 -----

  if amode in [ptLite, ptStandard] then
  begin
    FUnknown2:=FStream.ReadBytes(34);
  end
  else
  begin
    Check(FStream.ReadDWord,'pre-map 1',0);
    Check(FStream.ReadDWord,'pre-map 2',0);
    Check(FStream.ReadDWord,'pre-map 3',0);
    Check(FStream.ReadDWord,'pre-map 4',0);
    Check(FStream.ReadDWord,'pre-map 5',0);
    Check(FStream.ReadDWord,'pre-map 6',0);
    Check(FStream.ReadDWord,'pre-map 7',0);
    Check(FStream.ReadDWord,'pre-map 7',0);
    Check(FStream.ReadWord ,'pre-map 8',0);
  end;

  //----- Maps -----

  FMaps:=ReadMapList(FStream);

  //----- Unknown 3 -----

  lpos:=FStream.Position;

  lcnt:=FStream.ReadDWord;
  for i:=0 to lcnt-1 do
  begin
    FStream.ReadShortString;  // area
    FStream.ReadDWord;        //
    FStream.ReadDWord;        //
    FStream.ReadDWord;        // 27684953

    lcnt1:=FStream.ReadDWord;
    for j:=0 to lcnt1-1 do
      FStream.ReadDword;
  end;
  
  FUnkn3Size:=FStream.Position-lpos;
  FStream.Position:=lpos;
  FUnknown3:=FStream.ReadBytes(FUnkn3Size);

  //===== Quests =====

  FQBlockSize:=FStream.ReadDWord;

  if amode=ptLite then
  begin
    FQuestBlock:=FStream.ReadBytes(FQBlockSize);
  end
  else
  begin
    lpos1:=FStream.Position;
    lpos :=FStream.Position+FQBlockSize;

    // full quest list (sidequests?)
    FStream.ReadIdList;

    // quests progress
    lcnt:=FStream.ReadDWord;  // 13
    for i:=0 to lcnt-1 do
    begin
      lcnt1:=FStream.ReadDWord; // Offset to next quest from quests block start
      FStream.ReadQWord;  // E36A01E3Ae3EBEEF "MEDIA\QUESTS\TL2MAINQUEST\ACT3\A3A3-TOWNARRIVAL.DAT 
      Check(FStream.ReadQWord,'quest_8',qword($FFFFFFFFFFFFFFFF));  // FF
      FStream.ReadDWord;  // 29C4F73E
      Check(FStream.ReadDWord,'quest_4',$FFFFFFFF);  // FF

      FStream.Position:=lpos1+lcnt1;
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
    end;

    FStream.Position:=lpos;
  end; // quest block

  //----- ?? Skill [??learn] history (check order) -----

  lcnt :=FStream.ReadWord; // same as next history list count
  lcnt1:=FStream.ReadWord;
  SetLength(FHistory,lcnt1);
  if lcnt1>0 then
    FStream.Read(FHistory[0],lcnt1*SizeOf(TL2ID));

  //----- Recipes -----

  lcnt:=FStream.ReadWord;
  SetLength(FRecipes,lcnt);
  if lcnt>0 then
    FStream.Read(FRecipes[0],lcnt*SizeOf(TL2ID));

  //===== REST of file (statistic??) =====

  FLBlockSize:=FStream.ReadDWord;
  if (FStream.Position+FLBlockSize)<>(FStream.Size-4) then writeln('Something wrong!!');

  if amode=ptLite then
  begin
    FLastBlock:=FStream.ReadBytes(FLBlockSize);
  end
  else
  begin
    Check(FStream.ReadDWord,'last block 1',1);

    FStream.ReadDWord; // 3DF65D40 = 0.12
    FStream.ReadDword; // 40
    FStream.ReadDWord; // 3DF65D40 = 0.12
    FStream.ReadDWord; // 0x##40

    FStream.ReadByte;  // 0

    // ?? mobs
    lcnt:=FStream.ReadDWord;
    FStream.Seek(lcnt*40,soCurrent);
{
    8b - mob id (media/units/monsters)
    4b - x?
    4b - y?
    4b - ?
    4b - 
    4b - 
    4b - ?
    4b - 
    2b
    2b
}

    // ?? items
    lcnt:=FStream.ReadDWord;
    FStream.Seek(lcnt*24,soCurrent);
{
    8b - item id (media\units\items)
    4b - 
    4b - 
    4b - [0]
    4b - amount?
}

    // ?? skills
    lcnt:=FStream.ReadDWord;
    FStream.Seek(lcnt*17,soCurrent);
{
    8b - skill id (media\skills)
    4b - 
    4b - 
    1b - 
}

    // ??
    lcnt:=FStream.ReadDWord;
    FStream.Seek(lcnt*31,soCurrent);
{
    4b - 131.87
    4b - ?
    4b - ?
    4b - ?
    1b - [0]
    4b - 
    1b
    4b
    4b
    1b
}

    //----- ?? Area (teleports? time on map?) -----
    // usually, count and titles are the same

    lcnt:=FStream.ReadDWord;
    for i:=0 to lcnt-1 do
    begin
      FStream.ReadShortString;
      FStream.ReadDWord;
    end;

    lcnt:=FStream.ReadDWord;
    for i:=0 to lcnt-1 do
    begin
      FStream.ReadShortString;
      FStream.ReadDWord;
    end;

    //----- ?? Unknown -----

    //?? byte, word, dword (word+word), word
    FStream.ReadDword; // 03 00 00 00  | 01 00 00 18
    FStream.ReadDWord; // 00 00 00 06  | 00 00 00 00
    FStream.ReadByte;  // 00           | 00

    //----- ?? Mob stat -----

    FStream.ReadIdValList;

    Check(FStream.ReadDWord,'pre-end',0);

    FStream.ReadShortString; // player name
    FStream.ReadShortString; // class
    FStream.ReadShortString; // Pet class
  end; // last block

end;
