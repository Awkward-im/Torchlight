  lsize = ostream_tell(v2[2] + 8, &v13);
  v5 = *(lsize + 8); // [Size+8]
  v6 = *lsize + v5 == 0;     //
  v7 = *lsize + v5;  // [size]+[size+8] ??
  hash = 0x202A;
  ofs = 0;
  if ( !v6 )
  {
    do
    {
      istream_seek(v2[2], ofs, 0);
      v10 = v2[2];
      lbyte = 0;
      istream_read(v10, &lbyte, 1);
      ofs += step;
      hash = lbyte + 33 * hash;
    }
    while ( ofs < v7 );
  }
  istream_seek(v2[2], 0, 2);