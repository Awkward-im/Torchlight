{}
function TTLSaveFile.Prepare:boolean;
var
  i:integer;
begin
  // if not parsed then error

  result:=true;

  if FVersion>=tlsaveTL2Minimal then
    FStream.Position:=SizeOf(TL2SaveHeader)
  else
    FStream.Position:=4;

  //===== Starting data =====

  FStream.WriteShortString(FClassString);
  FStream.WriteDword(DWord(FDifficulty));
  FStream.WriteByte(Ord(FHardcore));
  FStream.WriteDWord(FNewGameCycle);
  FStream.WriteByte(Ord(FRetired));

  if FVersion>=tlsaveTL2Minimal then
    FStream.WriteFloat(FGameTime);

  //----- Movies -----

  if FVersion>=tlsaveTL2Minimal then
    FStream.WriteIdValList(FMovies);

  //----- Mod lists -----

  if FVersion>=tlsaveTL2ModBind then
  begin
    WriteModList(FBoundMods);
    WriteModList(FRecentModHistory);
    WriteModList(FFullModHistory);
  end;

  //===== Character Data =====

  FCharInfo.SaveToStream(FStream, FVersion);

  //----- Keymapping -----

  WriteKeyMappingList;

  //----- Statistic -----

  WriteStatistic();

  FStream.WriteShortString(FArea);     // map
  FStream.WriteShortString(FWaypoint); // area (region)

  //----- Unknown 1 -----
  //!!
  FStream.WriteDWord(Unk2);

  if FVersion>=tlsaveTL2Minimal then
    FStream.WriteCoord(UnkCoord);

  //---- User Portal ----

  FStream.WriteByte       (Byte(FPortalOpened) and 1);
  FStream.WriteCoord      (FPortalCoord);
  FStream.WriteShortString(FPortalPlace);
  //!!
  FStream.WriteDWord(Unk3);

  //===== Pet Data =====

  FStream.WriteDWord(Length(FPetInfos));
  for i:=0 to High(FPetInfos) do
    FPetInfos[i].SaveToStream(FStream, FVersion);

  //----- Unknown 2 -----
  //!!
  FStream.Write(FUnknown2^,34);

  //----- Maps -----

  WriteMapList(FStream,FMaps, FVersion);

  //----- Unknown 3 -----
(*
  //----- Visited areas (like in last block) -----
  //??
  lpos:=FStream.Position;
  {}
  lcnt:=FStream.ReadDWord;             //?? active portal list
  for i:=0 to lcnt-1 do
  begin
    ls:=FStream.ReadShortString;       // area
    DbgLn('save area: '+ls);
    FStream.ReadDWord;                 // player level
    FStream.ReadDWord;                 // ??additional floors? 1 stage = 0;
    DbgLn('  '+HexStr(FStream.ReadDWord,8)); // ?

    lcnt1:=FStream.ReadDWord;          // activated portals?
    for j:=0 to lcnt1-1 do
      Check(FStream.ReadDword,'save-area subarray '+HexStr(FStream.Position,8),0); // 0 usually
    DbgLn('end area'#13#10'---------');
  end;
*)
  //!!
  FStream.Write(FUnknown3^,FUnkn3Size);

  //----- Cinematic -----

  if FVersion<tlsaveTL2Minimal then
    FStream.WriteShortStringList(FCinematics);

  //===== Quests =====

  FQuests.SaveToStream(FStream, FVersion);

  if FVersion>=tlsaveTL2Minimal then
  begin
    //----- ?? History -----

    FStream.WriteWord(Length(FHistory)); // same as next history list count
    FStream.WriteWord(Length(FHistory));
    if Length(FHistory)>0 then
      FStream.Write(FHistory[0],Length(FHistory)*SizeOf(TRGID));

    //----- Recipes -----

    FStream.WriteWord(Length(FRecipes));
    if Length(FRecipes)>0 then
      FStream.Write(FRecipes[0],Length(FRecipes)*SizeOf(TRGID));

    //===== REST of file =====

    FLastBlock.SaveToStream(FStream, FVersion);
  end;
end;
