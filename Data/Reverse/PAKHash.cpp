uint __thiscall FUN_00676b30(int64_t *seed,int aLo,int aHi)

{
  uint uVar1;
  uint uVar2;
  int iVar3;
  uint uVar4;
  
  iVar3 = loseed * 0x29777b41 >> 0x20;
  uVar1 = loseed * 0x29777b41;

  d = (aHi - aLo) + 0x1;
  if (d == 0x0) {
    v3 = hiseed + loseed * 0x29777b41;

    loseed = v3;
    hiseed = iVar3 + CARRY4(uVar1,*(seed + 0x4));
    return v3;
  }

//   if ( d != 0 )
  uVar2 = uVar1 + *(seed + 0x4);
  *(seed + 0x4) = iVar3 + CARRY4(uVar1,*(seed + 0x4));
  *seed = uVar2;

  return uVar2 % d + aLo;
}
----------------
int __thiscall sub_676B30(unsigned int *aseed, int alo, int ahi)
{
  __int64 v3; // rax

  v3 = hiseed + 0x29777B41i64 * loseed;
  *(_QWORD *)aseed = v3;
  int d = ahi - alo + 1;
  if ( d != 0 )
    LODWORD(v3) = alo + (unsigned int)v3 % d; // 25+(v3 mod 51)
  return v3;
}
===================
 result = aLo;
  if ( aHi > aLo )
  {
    result = sub_676B30((unsigned int *)&qSeed, aLo, aHi);
    if ( result > aHi )
      result = aHi;
  }
  return result;
====================
rnd = 25 + (PAKFileSize * 0x29777B41) mod 51;
step = PAKFileSize / rnd
if (step <2 ) step = 2;
====================
  
  fseek(PAKfile,0x0,0x2);
  lPAKSize = ftell(PAKfile);
  l_PAKSize = ftell(PAKfile);
  lPAKHash = lPAKSize;

  uVar17 = SaveRandomSeed();  //!!!!!!!!!!!!!! int64 from [DAT_0361a8b0]
  local_184 = uVar17 >> 0x20; // HiWord only

  Randomize(lPAKSize,0);
  // Seed = 0x00000000 + PAK file size

  l_hashstep = Random(25,75);
  l_hashstep = l_PAKSize / l_hashstep;
  if (l_hashstep < 2) {
    l_hashstep = 2;
  }
  //random from 2 to 75

  Randomize(uVar17,local_184); //!!!!!!!!!!!!!!!! (int 64) [DAT_0361a8b0]
                
  _Offset = 0x8;  // 8 is PAK data start
  // while not end of PAK data
  if (_Offset < l_PAKSize) {
    do {
      fseek(PAKfile,_Offset,0x0);
      l_tmpbyte = '\0';
      fread(&l_tmpbyte,0x1,0x1,PAKfile);
      _Offset += l_hashstep;
      lPAKHash = lPAKHash * 0x21 + l_tmpbyte;
    } while (_Offset < l_PAKSize);
  }
  fseek(PAKfile,lPAKSize - 0x1,0x0);
  local_1a1 = '\0';
  fread(&local_1a1,0x1,0x1,PAKfile);
  lPAKHash = lPAKHash * 0x21 + local_1a1;
