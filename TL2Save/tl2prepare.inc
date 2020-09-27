{}
function TTL2SaveFile.Prepare:boolean;
var
  i:integer;
begin
  // if not parsed then error

  result:=true;

  FStream.Position:=SizeOf(TL2SaveHeader); //!!

  FStream.WriteShortString(FClassString);
  FStream.WriteDword(DWord(FDifficulty));
  FStream.WriteByte(Ord(FHardcore));
  FStream.WriteByte(FNewGameCycle);
  //!!
  FStream.WriteDWord(Unk1);

  FStream.WriteFloat(FGameTime);

  //----- Movies -----

  FStream.WriteIdValList(FMovies);

  //----- Mod lists -----

  WriteModList(FBoundMods);
  WriteModList(FRecentModHistory);
  WriteModList(FFullModHistory);

  //===== Character Data =====

  FCharInfo.SaveToStream(FStream);
  //----- Keymapping -----

  WriteKeyMappingList;

  //----- Statistic -----

  WriteStatistic();

  FStream.WriteShortString(FArea);     // map
  FStream.WriteShortString(FWaypoint); // area (region)

  //----- Unknown 1 -----
  //!!
  FStream.WriteDWord(Unk2);
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
    FPetInfos[i].SaveToStream(FStream);

  //----- Unknown 2 -----
  //!!
    FStream.Write(FUnknown2^,34);

  //----- Maps -----

  WriteMapList(FStream,FMaps);

  //----- Unknown 3 -----
  //!!
  FStream.Write(FUnknown3^,FUnkn3Size);

  //===== Quests =====

  FQuests.SaveToStream(FStream);

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

  FLastBlock.SaveToStream(FStream);

end;
