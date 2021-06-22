struct CItemSaveState           // 0x238 bytes
{
  void       *VFTable;
  int        field_04;
  void       *VFTable2;
  wstring    strName;           // [0x03]
  wstring    strPrefix;         // [0x0A]
  wstring    strSuffix;         // [0x11]
  int        dUnkn2_5;          // [0x18] 0
  int        field_64;                                    
  int64_t    qUnkn1_1;          // [0x1A] -1
  int64_t    qUnkn1_2;          // [0x1C] -1
  int64_t    qUnkn2_2;          // [0x1E] -1
  int64_t    qUnkn1_3;          // [0x20] -1
  byte       bUnkn2_1;          // 0
  byte       bAlign89[3];
  CCharacterSaveState * vChar;
  int64_t    qUnkn2_3;
  int64_t    qUnkn2_4;          // [0x26] -1 aSGVer >= 0x2E
  int        dStashPosition;    // [0x28] -1 
  byte       bFlag_1;           // 0  "Equipped"
  byte       bFlag_2;           // 0  "Enabled"
  byte       bFlag_3;           // 0
  byte       bFlag_4;
  int64_t    qId;               // [0x2A] -1
  int        dStackSize;
  int        dEnchantmentCount; // 0
  int        dSocketCount;
  byte       bFlag_6;           // 0 "Keep after activation"
  byte       bFlag_7;           // 0 "Recognized"
  __int16    wAlignBE;
  int        dWeaponDamage;     // [0x30] -1
  int        dArmor;            // [0x31] -1
  int        dArmorType         // [0x32] -1
  float      fPosition1[3];     // [0x33] Ogre::Vector3::Vector3
  float      fPosition2[3];     // [0x36] Ogre::Vector3::Vector3
  float      fRotation[16];     // [0x39] Ogre::Matrix4::Matrix4
//  `eh vector constructor iterator'(v1 + 0x49, 0x14u, 3, sub_56FF60, sub_56FB30);
  byte       effects[3][20];    // [0x49]
// end of vector
  int        field_160;
  int        field_164;         // [0x59] 0 ??Socketables TArrayList (Item list)
  int        field_168;         // [0x5A] 0
  int        field_16C;         // [0x5B] 0
  int        field_170;         // [0x5C] 0
  int        field_174;
// Unkn6 start
  int        field_178;         // [0x5E] 0    >
  int        field_17C;         // [0x5F] 0    *
  int        field_180;         // [0x60] 0
  int        field_184;         // [0x61] 0    *
  int        field_188;
  int        field_18C;         // [0x63] 0
  int        field_190;         // [0x64] 0
  int        field_194;         // [0x65] 0
  int        field_198;         // [0x66] 0
  int        field_19C;
  int        field_1A0;         // [0x68] 0
  int        field_1A4;         // [0x69] 0
  int        field_1A8;         // [0x6A] 0
  int        field_1AC;         // [0x6B] 0
// Unkn 6 end
  int        field_1B0;
  int        field_1B4;         // [0x6D] 0
  int        field_1B8;         // [0x6E] 0
  int        field_1BC;         // [0x6F] 0
  int        field_1C0;         // [0x70] 0
  int        field_1C4;
  int        field_1C8;         // [0x72] 0
  int        field_1CC;         // [0x73] 0
  int        field_1D0;         // [0x74] 0
  int        field_1D4;         // [0x75] 0
// Stats
  int        field_1D8;
  int        field_1DC;         // [0x77] 0
  int        field_1E0;         // [0x78] 0
  int        field_1E4;         // [0x79] 0
  int        field_1E8;         // [0x7A] 0
  int        field_1EC;         // [0x7B] 0 \  like TArrayList
  int        field_1F0;         // [0x7C] 0 |  float array
  int        field_1F4;         // [0x7D] 0 /
  int        dUnkn4;            // [0x7E] 0 ?? float array size
  int        dLevel;            // [0x7F] 0 ??????
  int64_t    qUnkn5_1;
  int        dUnkn5_2;
  byte       bFlag_5;           // "Visible" 1
  byte       bAlign20D[3];
  int        field_210;         // [0x84] 0
  int        field_214;
  int        field_218;
  byte       field_21C;         // [byte_2889C7C] ?? SGver
  byte       field_21D;         // ??Sign
  __int16    wAlign21E;
  TArrayList aModList;          // [0x88] 0 increment=10
  int        field_230;         // [0x8C] 0
  int        field_234;         // [0x8D] 0 (temporary) Parent item?
};
