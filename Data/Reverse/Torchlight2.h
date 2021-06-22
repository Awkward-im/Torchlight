/* 9 */
struct TArrayList
{
  void *data;
  int length;
  int capacity;
  int increment;
};

/* 10 */
struct wstring
{
  int field_0;
  int field_4;
  int field_8;
  int field_C;
  int field_10;
  int length;
  int field_18;
};

/* 13 */
struct CDataValue
{
  void *VFTable;
  int field_4;
  int val_lo;  // or text length
  int val_hi;  // or text
  int taghash;
  int type;
};

/* 14 */
struct CDataGroup   // 0x48
{
  void *VFTable;
  int field_4;
  int NameHash;     // default = -1
  int field_C;
  int field_10;
  int field_14;
  int field_18;
  int field_1C;
  TArrayList Values; // incr = 20 
  TArrayList Groups; // incr = 10
  void *arr_data;
  int arr_size;
};

struct CBinaryStyle
{
  void *VFTable;
  int field_4;
  wstring *file;
};

struct CModManager     // 0x90
{
  void *VFTable;
  int field_4;
  TArrayList field_8;  // ??
  TArrayList field_18; // ?
  TArrayList field_28;
  int field_38;        // bool
  int field_3C;        // bool
  bool field_40;       // bool = all ok?
  bool field_41;
  __int16 field_42;    // align
  wstring field_44;
  int field_60;
  wstring field_64;
  TArrayList Mods;     // <CMod *>
};

struct __unaligned __declspec(align(1)) CPackageCreator
{
  void *VFTable;
  int field_4;
  bool field_8;
  bool field_9; // "devbuild.txt" is not exists
};

/* 11 */
struct CModRequirement
{
  wstring m_strName;
  __unaligned __declspec(align(1)) int64_t m_iGuidUnique;
  int m_iVersion;
};

/* 12 */
struct __unaligned __declspec(align(1)) CMod
{
  void *VFTable;
  int field_4;
  CMod *ParentMod;
  wstring m_strModFileName;
  wstring m_strName;
  wstring m_strAuthor;
  wstring m_strWebURL;
  wstring m_strDownloadURL;
  wstring m_strDescription;
  wstring m_strModPackFilePath;
  wstring m_strPathWithRawAssets;
  int field_EC;                   // align?
  int64_t m_iUniqueGuid;
  int64_t m_iRequirementsHash;
  __int16 m_iVersion;
  __int16 m_iGameVersion[4];
  __int16 field_10A;              // align?
  int m_iFlags;
  int m_iPakFileStart;
  int m_iManifestFileStart;
  TArrayList m_DeletedFiles; // std::wstring
  TArrayList m_Requirements; // CModRequirement
  bool m_bActivated;
};

struct CPackageFile   // 0x88
{
  void *VFTable;
  int field_4;
  int time_lo;        // argument
  int time_hi;        // argument
  wstring dir;        // argument
  wstring name;       // argument
  wstring nameWide;
  int dPaKOffset;     // PAK position
  int size;           // argument
  int type;           // argument, lower byte
  int CRC;            // argument
  int field_74;       // 0 class?
  // 0x74 is 0x60 bytes wchar buffer:
  // 0x0-?, 0x04-namewide, 0x20-dir, 0x3C-name, 0x58-filesize, 0x5C-size too
  int field_78;       // 0
  int field_7C;       // ??
  int field_80;       // 0
  bool notdeleted;    // 0
};

/* 15 */
struct __unaligned __declspec(align(4)) CPackageManifest
{
  void *VFTable;
  int field_4;
  TArrayList files;        // CPackageFile, increment = 30.000
  int field_18;            // 0
  int field_1C;
  int field_20;            // 0  class with 2C field or size
  int field_24;            // 0
  int field_28;            // 0
  int total;               // 0
  TArrayList _mod_handles; // increment = 2 ??
  TArrayList _pak_offsets; // increment = 2
  char *comp_buf;          // compressed data buff, NULL
  int comp_size;           // 0
  char _no_devbuild_file;  // 1
  char _checkonly;         // 0
  __int16 field_5A;        // align?
  int ManVersion;
  int64_t Hash;            // -1
  int field_68;            // 0
  int field_6C;
  int field_70;            // 0
  int field_74;            // 0
  int field_78;            // 0
};

struct CPackageManager     // 0x2C
{
  void *VFTable;
  int field_4;
  CPackageManifest * manifest;
  int field_C[8];
//  FILE * file;
};

struct CSettings
{
  void * field_120;
};

struct CMovie
{
  void *VFTable;
  int field_4;
  wstring Name;            // [0x02]
  wstring DisplayName;     // [0x09]
  wstring Path;            // [0x10]
  int     Loops;           // [0x17] bool
  int     MaxPlays;        // [0x18]
  int     field_64;
  int64_t Guid;            // [0x1A]
  int     ProgressIndex;   // [0x1C]
};

struct CMasterResourceManager  // minimum 300 bytes)
{
  // [0x2F] 188, [0x33] 204, [0x37] 220, - TArrayList with step=10

  [0x23] (0x8C) CPackageManager
  [0x25] (0x94) CModManager
  bool (0x98) 0
  bool (0x99) 1
};
