struct CSave
{
// [0x00B]  ?

  TArrayList Mods; // [0x3C] (0xF0)

// [0x05C] wstring  (empty)

// [0x148] wstring  SG filename

// [0x1B4] function?

  dword    unk3;                // [0x243]
  wstring user portal place    // [0x244]
  float[3] portal coords?      // [0x24B] 
  float[3] -999 coords;         // [0x24E]
  dword    unk2;                // [0x251]
  wstring  strWaipoint;         // [0x252]
  dword    statTotalTime;       // [0x25B]
  dword    statGold;            // [0x25C]
  dword    statUnknown;         // [0x25D]
  dword    statSteps;           // [0x25E]
  dword    statQuests;          // [0x25F]
  dword    statDeaths;          // [0x260]
  dword    statMonsters;        // [0x261]
  dword    statChampions;       // [0x262]
  dword    statSkills;          // [0x263]
  dword    statTreasures;       // [0x264]
  dword    statTraps;           // [0x265]
  dword    statBroken;          // [0x266]
  dword    statPotions;         // [0x267]
  dword    statPortals;         // [0x268]
  dword    statFish;            // [0x269]
  dword    statGambled;         // [0x26A]
  dword    statTransmuted;      // [0x26B]
  dword    statEnchanted;       // [0x26C]
  dword    statDmgTaken;        // [0x26D]
  dword    statDmgDealt;        // [0x26E]
  dword    statLevelTime;       // [0x26F]
  dword    statExploded;        // [0x270]

// [0x27D] (0x9F4)

// [0x2A8] \ array of 12 F-Key IDs
// [0x2A9] /

// [0x2C0]\  array of 12 alt-F-Key IDs
// [0x2C1]/

// [0x423] float Unk17
// [0x424] float Unk91

// [0x5D0]

// [0x6DE] wstring *?Area (hash?)

// [0x6E2] byte     difficulty
// [0x6E3] byte     difficulty

// [0x6F5] (0x1BD4) dword ng
// [0x6FE] float    time

--------
// [0x23D] (0x8F4) - map-related

// [0x2B4]

// [0x2E8] (0xBA0) dword  ng
// [0x2E9] (0xBA4) byte   unk1
//    (0xBA5) byte   hardcore
// (0xBA7) byte[34] after pet (FUnknown2)
// (0xBC9)

// [0x2F3] (0xBCC) TArrayList?
// [0x2F4] (0xBD0)
// [0x2F5] (0xBD4)

// [0x346] (0xD18)
// [0x347] (0xD1C)
// [0x348] (0xD20)
};
