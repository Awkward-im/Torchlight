unit TL2types;

interface

//===== basic =====

type
  TL2ID       = Int64;     // 8 bytes, presents as signed <INTEGER64> in mod sources
  TL2Float    = single;    // 4 byte
  TL2Boolean  = ByteBool;  // 1 byte
  TL2Integer  = Int32;     // 4 bytes
  TL2UInteger = UInt32;    // 4 bytes;

  // TL2ShortString = record len:Word; txt:array [0..0] of WideChar; end;
  // TL2ByteString  = record len:Byte; txt:array [0..0] of WideChar; end;

//===== complex =====

const
  TL2IdEmpty = TL2ID(-1);

type
  TL2IdList = array of TL2ID;
type
  TL2IdVal = packed record
    id   :TL2ID;
    value:TL2Integer;
  end;
  TL2IdValList = array of TL2IdVal;

type
  TL2Coord = packed record
    X: TL2Float;
    Y: TL2Float;
    Z: TL2Float;
  end;

//----- Not real TL2 types -----

type
  TL2StringList = array of string;
type
  TL2Sex = (male, female, unisex);

//----- Global savegame file structures -----

type
  TL2SaveHeader = packed record
    Sign    :DWord;      // 0x00000044 - format version
    Encoded :ByteBool;
    Checksum:Dword;
  end;
  TL2SaveFooter = packed record
    filesize:DWord;
  end;


//=====  =====

type
  TTL2Difficulty = (Casual, Normal, Veteran, Expert);


implementation


end.
