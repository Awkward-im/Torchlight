{}
function TTL2SaveFile.Parse():boolean;
var
  ls:string;
  lpos,i,j,lcnt,lcnt1:integer;
begin
  result:=true;

  FStream.Position:=SizeOf(TL2SaveHeader);

  //===== Starting data =====

  FClassString :=FStream.ReadShortString();
  FDifficulty  :=TL2Difficulty(FStream.ReadDWord);
  FHardcore    :=FStream.ReadByte<>0;
  FNewGameCycle:=FStream.ReadByte;

  //??
  Unk1:=FStream.ReadDWord; // 0
Check(Unk1,'save_label_1 '+HexStr(FStream.Position,8),0);

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

  ReadKeyMappingList;

  //----- Statistic -----

  ReadStatistic();

  // for resurrection?
  FArea    :=FStream.ReadShortString(); // map (current place)
  FWaypoint:=FStream.ReadShortString(); // area (region) (at entrance?)

  //----- Unknown 1 -----
  //??
  Unk2    :=FStream.ReadDWord;  // 0 ??count of use
Check(Unk2,'save_label_2 '+HexStr(FStream.Position,8),0);
  UnkCoord:=FStream.ReadCoord; // usually [-999, -999, -999] 0xC479C000
Check(UnkCoord.X,'save coord '+HexStr(FStream.Position,8),-999);

  //----- User portal -----

  FPortalOpened:=FStream.ReadByte<>0;
  FPortalCoord :=FStream.ReadCoord();
  FPortalPlace :=FStream.ReadShortString(); // User portal location

  //??
  Unk3:=FStream.ReadDWord;
Check(Unk3,'save pre-pet '+HexStr(FStream.Position,8),1);  // usually, 1 but can be zero too

  //===== Pet Data =====

  lcnt:=FStream.ReadDWord;
  SetLength(FPetInfos,lcnt);
  for i:=0 to lcnt-1 do
    FPetInfos[i]:=ReadCharData(FStream,false,true);

  //----- Unknown 2 -----
  //??
  FUnknown2:=FStream.ReadBytes(34);
for i:=0 to 33 do Check(FUnknown2[i],'save pre-map['+HexStr(i,2)+'] '+HexStr(FStream.Position,8),0);
{
  Timon: pre-map[01]=1

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

  //----- Visited areas (like in last block) -----
  //??
  lpos:=FStream.Position;
  {}
  lcnt:=FStream.ReadDWord;    //?? active portal list
  for i:=0 to lcnt-1 do
  begin
    ls:=FStream.ReadShortString;  // area
DbgLn('save area: '+ls);
    FStream.ReadDWord; // player level
    FStream.ReadDWord; // ??additional floors? 1 stage = 0;
DbgLn('  '+HexStr(FStream.ReadDWord,8)); // ?

    lcnt1:=FStream.ReadDWord; // activated portals?
    for j:=0 to lcnt1-1 do
      Check(FStream.ReadDword,'save-area subarray '+HexStr(FStream.Position,8),0); // 0 usually
DbgLn('end area'#13#10'---------');
  end;
  {}
  FUnkn3Size:=FStream.Position-lpos;
  FStream.Position:=lpos;
  FUnknown3:=FStream.ReadBytes(FUnkn3Size);

  //===== Quests =====

  FQuests:=ReadQuests(FStream);

  //-----  Skill [learn] history (check order) -----

  lcnt :=FStream.ReadWord; // same as next history list count
  lcnt1:=FStream.ReadWord;
if lcnt<>lcnt1 then
DbgLn('skill learn count: '+HexStr(lcnt,4)+'x'+HexStr(lcnt1,4));
  SetLength(FHistory,lcnt1);
  if lcnt1>0 then
    FStream.Read(FHistory[0],lcnt1*SizeOf(TRGID));

  //----- Recipes -----

  lcnt:=FStream.ReadWord;
  SetLength(FRecipes,lcnt);
  if lcnt>0 then
    FStream.Read(FRecipes[0],lcnt*SizeOf(TRGID));

  //===== REST of file (statistic) =====

  FLastBlock:=ReadLastBlock(FStream);

end;
