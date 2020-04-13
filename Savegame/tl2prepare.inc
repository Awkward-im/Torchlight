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

  FStream.Write(FUnknown1^,35);
{
  FStream.WriteDWord(Unk2);

  FStream.WriteFloat(-999);
  FStream.WriteFloat(-999);
  FStream.WriteFloat(-999);
  
  // 15 bytes
  FStream.WriteDWord(0);
  FStream.WriteDWord(0);
  FStream.WriteDWord(0);
  FStream.WriteWord(0);
  FStream.WriteByte(0);

  FStream.WriteDWord(1);
}
  //===== Pet Data =====

  FStream.WriteDWord(Length(FPetInfos));
  for i:=0 to High(FPetInfos) do
    WriteCharData(FStream,FPetInfos[i]);

  //----- Unknown 2 -----

  FStream.Write(FUnknown2^,34);

  //----- Maps -----

  WriteMapList(FStream,FMaps);

  //----- Unknown 3 -----

  FStream.Write(FUnknown3^,FUnkn3Size);

  //===== Quests =====

  FStream.Write(FQuestBlock^,FQBlockSize);

  //----- ?? History -----

  FStream.WriteWord(High(FHistory)); // same as next history list count
  // Skill using history?
  FStream.WriteIdList(FHistory);

  //----- Recipes -----

  FStream.WriteIdList(FRecipes);

  //===== REST of file =====

  FStream.Write(FLastBlock^,FLBlockSize);

end;
