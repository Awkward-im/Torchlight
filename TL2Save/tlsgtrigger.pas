unit TLSGTrigger;

interface

uses
  Classes,
  rgstream,
  rgglobal;

type
  // record with fixed size 136 bytes
  TTL2Trigger = packed record
    flags1   :array [0..3] of Byte;
    flags2   :array [0..3] of Byte;
    f1      :TRGFloat; // 0x08
    f2      :TRGFloat; // 0x0C
    f3      :TRGFloat; // 0x10
    f4      :TRGFloat; // 0x14
    // fixed size block
    // real name finished by #00
    atype   :array [0..21] of WideChar; // 0x18
    // 0x34
{
    valf1   :RGFloat; // 0x34
    valf2   :RGFloat; // 0x38
    valf3   :RGFloat; // 0x3C
    valf_1  :RGFloat; // 0x40 maybe not
}
    // 0x44
    val_f1  :TRGFloat; // 0x44
    val_f2  :TRGFloat; // 0x48
    val_f3  :TRGFloat; // 0x4C
    val1_f1 :TRGFloat; // 0x50
    val1_f2 :TRGFloat; // 0x54
    val1_f3 :TRGFloat; // 0x58
    val1_f4 :TRGFloat; // 0x5C
    parentid:TRGID;    // 0x60
    unknown :TRGID;    // 0x68
    id      :TRGID;    // 0x70
    posx    :TRGFloat; // 0x78
    posy    :TRGFloat; // 0x7C
    posz    :TRGFloat; // 0x80
    val_i1  :Word;    // 0x84
    val_i2  :Word;    // 0x86
  end;

  TTL1Trigger = packed record
    val_i1  :Word;
    val_i2  :Word;
    val1_f1 :TRGFloat;
    val1_f2 :TRGFloat;
    val1_f3 :TRGFloat;
    val1_f4 :TRGFloat; // 0
    parentid:TRGID;
    id      :TRGID;
    unknown :TRGID;    // 0
    posx    :TRGFloat;
    posy    :TRGFloat;
    posz    :TRGFloat;
    b       :Byte;
    val_f1  :TRGFloat;
  end;

  TTLTriggerList = array of TTL2Trigger;

function ReadTriggerList(AStream:TStream; aVersion:integer):TTLTriggerList;


implementation


function ReadTriggerList(AStream:TStream; aVersion:integer):TTLTriggerList;
var
  i,lcnt:integer;
begin
  lcnt:=AStream.ReadDWord;
  SetLength(result,lcnt);

  if lcnt>0 then
    if aVersion>=tlsaveTL2Minimal then
      AStream.Read(result,lcnt*SizeOf(TTL2Trigger))
    else
    begin
      for i:=0 to lcnt-1 do
      begin
        AStream.ReadShortString;
        AStream.Read(result[i],SizeOf(TTL1Trigger));
      end;
    end;
end;

end.
