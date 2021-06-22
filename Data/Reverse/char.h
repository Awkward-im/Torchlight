struct CCharacterSaveState   // 0x360 bytes
{
  void       *VFTable1;      // &off_2173798
  int        field_04;
  void       *VFTable2;      // &off_2173744 (iReadWrite::vftable) OR &off_2173784 (CCharacterSaveState::vftable)
  int        field_0C;
  int64_t    qUnkn1;         // [0x04] -1
  byte       bUnkn2;         // 0
  byte       bAlign0[7];     // Align
  int64_t    qMorphId;       // [0x08] -1
  int64_t    qId;            // [0x0A] -1
  byte       bPlayer;        // 0, or Wardrobe
  bool       bEnabled;       // 0
  byte       bUnkn41;        // 0
  byte       bUnkn42;        // 0
  byte       bCheat;         // 0
  byte       bAlign1[3];     // Align
  float      fScale;         // [0x13] 0.0
  wstring    strName;        // [0x14]
  wstring    strSuffix;      // [0x1B]
  wstring    strPlayer;      // [0x22] "PLAYER"   &unk_32D5714
  int        dAction;        // [0x29]
  int        dField_94;      //!!
  int64_t    qUnkn7_0;       // [0x2B] -1
  int64_t    qUnkn7_1;       // [0x2D] -1
  int64_t    qUnkn7_2;       // [0x2F] -1
  int        dUnkn17;        // [0x31] -1 "SEED SET FROM LOAD "
  int        dUnkn91;        // 0
  int        dUnkn92;        // 0
  float      fPosition[3];   // [0x34] Ogre::Vector3::Vector3   (Ogre::Vector3 *)
  float      fRotation[16];  // [0x37] Ogre::Matrix4::Matrix4   (Ogre::Matrix4 *)
  int64_t    qRMB1;          // [0x47] -1
  int64_t    qRMB2;          // -1
  int64_t    qLMB;           // -1
  int64_t    qAltRMB1;       // -1
  int64_t    qAltRMB2;       // -1
  int64_t    qAltLMB;        // -1
  int        dLevel;         // 0
  int        dExp;           // 0
  int        dFame;          // 0
  int        dFameExp;       // 0
  float      fHP;            // 0.0
  int        dHPBonus;       // 0
  int        dUnkn11;        // 0
  float      fMP;
  int        dMPBonus;
  int        dUnkn12;
  float      fPlayTime;
  int        dBravery;
  int        dRewardExp;
  int        dRewardFame;
  int        dStatPoints;
  int        dSkillPoints;
//  `eh vector constructor iterator'(v1 + 0x178 [0x5E], 0x1Cu, 4, wstring_new_1, wstring_free);
  wstring    strSpell1Name;  // [0x5E]
  wstring    strSpell2Name;
  wstring    strSpell3Name;
  wstring    strSpell4Name;
// end of vector
  int        dSpell1Level;
  int        dSpell2Level;
  int        dSpell3Level;
  int        dSpell4Level;
  int        dUnkn141;
  int        dUnkn142;
  int        dArmorFire;
  int        dArmorIce;
  int        dArmorElectric;
  int        dArmorPoison;
  int        dUnkn143;
  int        dStrength;
  int        dDexterity;
  int        dVitality;
  int        dFocus;
  int        dGold;
  int        dAlignment;
  float      fMorphTime;
  float      fTownTime;
  int        dUnkn15_1;      // [0x8D] -1
  int        field_238;
  CItemSaveState  *aItems;   // 0 ??array of pointers to CItemSaveSate
  int        field_240;      // [0x90] 0 - something with item?
  int        field_244;      // 0
  int        field_248;      // [0x92] 0 - something with item? *4 element index of 0x23C (count)
// `eh vector constructor iterator'(v1 + 0x24C [0x93], 0x14u, 3, sub_56FF60, sub_56FB30);
  byte       effects[3][20];
//end of vector
  int        field_288;
  int        field_28C;      // [0xA3] 0
  int        field_290;      // [0xA4] 0
  int        field_294;      // [0xA5] 0
  int        dAugmentCount;  // [0xA6] 0
  int        field_29C;      // [0xA7]
  int64_t   *aStats;         // [0xA8] 0 [ID+(??level or types)] 
  int        field_2A4;      // [0xA9] 0
  int        field_2A8;      // [0xAA] 0
  int        dStatsCount;    // [0xAB] 0
  int        field_2B0;      // [0xAC]
  int       *aStatLevels;    // [0xAD] 0
  int        field_2B8;      // [0xAE] 0
  int        field_2BC;      // [0xAF] 0
  int        field_2C0;      // [0xB0] 0
  int        field_2C4;      // [0xB1]   going to sub with skill count
  int       *aSkillLevels;      // [0xB2] 0 points to skill level array
  int        field_2CC;      // [0xB3] 0
  int        field_2D0;      // [0xB4] 0
  int        dSkillCount;    // [0xB5] 0
  int        field_2D8;      // [0xB6]
  int64_t   *aSkillIds;      // [0xB7] 0 points to skill ID array
  int        field_2E0;      // [0xB8] 0 compares with skill count
  int        field_2E4;      // [0xB9] 0
  int        field_2E8;      // [0xBA] 0 compares with skill count
  int        field_2EC;      // [0xBB]
  int64_t    qUnkn15_2;      // [0xBC] 0
  int        dUnkn15_3;      // [0xBE] 0
  bool       bHidden;        // 0
  byte       bAlign2FD[3];   // Align
  int        dUnkn3;         // [0xC0] 0
  byte       bSign1;         //
  byte       Align305[3];    // Align
  TArrayList ModList;        // [0xC2] 0 data (increment=10)
  int        field_318;      // [0xC6] 0 Buffer allocated with [0xC8] size
  int        field_31C;      // [0xC7]
  int        field_320;      // [0xC8] "Size"
  byte       bAIType;        // 0
  byte       bAlign325[3];   // Align
  int        dFace;          // [0xCA] -1
  int        dHairStyle;     // [0xCB] -1
  int        dHairColor;     // [0xCC] -1
  int        dWardrobe1;     // [0xCD] -1
  int        dWardrobe2;     // [0xCE] -1
  int        dWardrobe3;     // [0xCF] -1
  int        dWardrobe4;     // [0xD0] -1
  int        dWardrobe5;     // [0xD1] -1
  int        dWardrobe6;     // [0xD2] -1
  int        dWardrobe7;     // [0xD3] -1
  int        dWardrobe8;     // [0xD4] -1
  int        dWardrobe9;     // [0xD5] -1
  byte       bSkin;
  byte       bSign;          // 0
  byte       Reserve[6];
};
