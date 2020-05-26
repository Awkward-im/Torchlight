{}
function TTL2SaveFile.Parse():boolean;
var
  lpos,i,j,lcnt,lcnt1:integer;
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
  FCharInfo:=ReadCharData(FStream,true);
{
  GetTL2Class(FCharInfo.ClassId,lmod,lname);
  if lname<>FClassString then ; //!!error
}

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
    FPetInfos[i]:=ReadCharData(FStream,false,true);
  //----- Unknown 2 -----
  FUnknown2:=FStream.ReadBytes(34);
{
    Check(FStream.ReadDWord,'pre-map 1',0);
    Check(FStream.ReadDWord,'pre-map 2',0);
    Check(FStream.ReadDWord,'pre-map 3',0);
    Check(FStream.ReadDWord,'pre-map 4',0);
    Check(FStream.ReadDWord,'pre-map 5',0);
    Check(FStream.ReadDWord,'pre-map 6',0);
    Check(FStream.ReadDWord,'pre-map 7',0);
    Check(FStream.ReadDWord,'pre-map 7',0);
    Check(FStream.ReadWord ,'pre-map 8',0);
}

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

  FQuests:=ReadQuests(FStream);

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

  FLastBlock:=ReadLastBlock(FStream);

end;
