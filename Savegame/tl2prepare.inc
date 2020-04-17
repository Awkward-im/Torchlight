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

  WriteCharData(FStream,FCharInfo);

  //----- Keymapping -----

  WriteKeyMappingList;

  //----- Statistic -----

  WriteStatistic();

  FStream.WriteShortString(FMap);  // map
  FStream.WriteShortString(FArea); // area (region)

  //----- Unknown 1 -----
  //!!
  FStream.WriteDWord(Unk2);
  FStream.WriteCoord(UnkCoord);

  //---- User Portal ----

  FStream.WriteByte       (Ord(FPortalOpened));
  FStream.WriteCoord      (FPortalCoord);
  FStream.WriteShortString(FPortalPlace);
  //!!
  FStream.WriteDWord(Unk3);

  //===== Pet Data =====

  FStream.WriteDWord(Length(FPetInfos));
  for i:=0 to High(FPetInfos) do
    WriteCharData(FStream,FPetInfos[i]);

  //----- Unknown 2 -----
  //!!
  FStream.Write(FUnknown2^,34);

  //----- Maps -----

  WriteMapList(FStream,FMaps);

  //----- Unknown 3 -----

  FStream.Write(FUnknown3^,FUnkn3Size);

  //===== Quests =====

  FStream.WriteDWord(FQBlockSize);
  FStream.Write(FQuestBlock^,FQBlockSize);

  //----- ?? History -----

  FStream.WriteWord(Length(FHistory)); // same as next history list count
  FStream.WriteWord(Length(FHistory));
  FStream.Write(FHistory[0],Length(FHistory)*SizeOf(TL2ID));

  //----- Recipes -----

  FStream.WriteWord(Length(FRecipes));
  FStream.Write(FRecipes[0],Length(FRecipes)*SizeOf(TL2ID));

  //===== REST of file =====

  FStream.WriteDWord(FLBlockSize);
  FStream.Write(FLastBlock^,FLBlockSize);

end;
