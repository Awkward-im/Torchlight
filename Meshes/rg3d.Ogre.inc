{}

//----- Chunk types -----

const
  M_HEADER = $1000;
  M_MESH   = $3000;
     // bool skeletallyAnimated   // important flag which affects h/w buffer policies
     // Optional M_GEOMETRY chunk
     M_SUBMESH = $4000;
         // char* materialName
         // bool useSharedVertices
         // unsigned int indexCount
         // bool indexes32Bit
         // unsigned int* faceVertexIndices (indexCount)
         // OR
         // unsigned short* faceVertexIndices (indexCount)
         // M_GEOMETRY chunk (Optional: present only if useSharedVertices = false)
         M_SUBMESH_OPERATION = $4010; // optional, trilist assumed if missing
             // unsigned short operationType
         M_SUBMESH_BONE_ASSIGNMENT = $4100;
             // Optional bone weights (repeating section)
             // unsigned int vertexIndex;
             // unsigned short boneIndex;
             // float weight;
         // Optional chunk that matches a texture name to an alias
         // a texture alias is sent to the submesh material to use this texture name
         // instead of the one in the texture unit with a matching alias name
         M_SUBMESH_TEXTURE_ALIAS = $4200; // Repeating section
             // char* aliasName;
             // char* textureName;

     M_GEOMETRY = $5000; // NB this chunk is embedded within M_MESH and M_SUBMESH
         // unsigned int vertexCount
         M_GEOMETRY_VERTEX_DECLARATION = $5100;
             M_GEOMETRY_VERTEX_ELEMENT = $5110; // Repeating section
                 // unsigned short source;   // buffer bind source
                 // unsigned short type;     // VertexElementType
                 // unsigned short semantic; // VertexElementSemantic
                 // unsigned short offset;   // start offset in buffer in bytes
                 // unsigned short index;    // index of the semantic (for colours and texture coords)
         M_GEOMETRY_VERTEX_BUFFER = $5200; // Repeating section
             // unsigned short bindIndex;    // Index to bind this buffer to
             // unsigned short vertexSize;   // Per-vertex size, must agree with declaration at this index
             M_GEOMETRY_VERTEX_BUFFER_DATA = $5210;
                 // raw buffer data
     M_MESH_SKELETON_LINK = $6000;
         // Optional link to skeleton
         // char* skeletonName           : name of .skeleton to use
     M_MESH_BONE_ASSIGNMENT = $7000;
         // Optional bone weights (repeating section)
         // unsigned int vertexIndex;
         // unsigned short boneIndex;
         // float weight;
     M_MESH_LOD_LEVEL = $8000;
         // Optional LOD information
         // string strategyName;
         // unsigned short numLevels;
         // bool manual;  (true for manual alternate meshes, false for generated)
         M_MESH_LOD_USAGE = $8100;
         // Repeating section, ordered in increasing depth
         // NB LOD 0 (full detail from 0 depth) is omitted
         // LOD value - this is a distance, a pixel count etc, based on strategy
         // float lodValue;
             M_MESH_LOD_MANUAL = $8110;
             // Required if M_MESH_LOD section manual = true
             // String manualMeshName;
             M_MESH_LOD_GENERATED = $8120;
             // Required if M_MESH_LOD section manual = false
             // Repeating section (1 per submesh)
             // unsigned int indexCount;
             // bool indexes32Bit
             // unsigned short* faceIndexes;  (indexCount)
             // OR
             // unsigned int* faceIndexes;  (indexCount)
     M_MESH_BOUNDS = $9000;
         // float minx, miny, minz
         // float maxx, maxy, maxz
         // float radius
             
     // Added By DrEvil
     // optional chunk that contains a table of submesh indexes and the names of
     // the sub-meshes.
     M_SUBMESH_NAME_TABLE = $A000;
         // Subchunks of the name table. Each chunk contains an index & string
         M_SUBMESH_NAME_TABLE_ELEMENT = $A100;
             // short index
             // char* name
     
     // Optional chunk which stores precomputed edge data                     
     M_EDGE_LISTS = $B000;
         // Each LOD has a separate edge list
         M_EDGE_LIST_LOD = $B100;
             // unsigned short lodIndex
             // bool isManual            // If manual, no edge data here, loaded from manual mesh
                 // bool isClosed
                 // unsigned long numTriangles
                 // unsigned long numEdgeGroups
                 // Triangle* triangleList
                     // unsigned long indexSet
                     // unsigned long vertexSet
                     // unsigned long vertIndex[3]
                     // unsigned long sharedVertIndex[3] 
                     // float normal[4] 

                 M_EDGE_GROUP = $B110;
                     // unsigned long vertexSet
                     // unsigned long triStart
                     // unsigned long triCount
                     // unsigned long numEdges
                     // Edge* edgeList
                         // unsigned long  triIndex[2]
                         // unsigned long  vertIndex[2]
                         // unsigned long  sharedVertIndex[2]
                         // bool degenerate

     // Optional poses section, referred to by pose keyframes
     M_POSES = $C000;
         M_POSE = $C100;
             // char* name (may be blank)
             // unsigned short target    // 0 for shared geometry, 
                                         // 1+ for submesh index + 1
             // bool includesNormals [1.8+]
             M_POSE_VERTEX = $C111;
                 // unsigned long vertexIndex
                 // float xoffset, yoffset, zoffset
                 // float xnormal, ynormal, znormal (optional, 1.8+)
     // Optional vertex animation chunk
     M_ANIMATIONS = $D000;
         M_ANIMATION = $D100;
         // char* name
         // float length
         M_ANIMATION_BASEINFO = $D105;
         // [Optional] base keyframe information (pose animation only)
         // char* baseAnimationName (blank for self)
         // float baseKeyFrameTime
 
         M_ANIMATION_TRACK = $D110;
             // unsigned short type          // 1 == morph, 2 == pose
             // unsigned short target        // 0 for shared geometry, 
                                             // 1+ for submesh index + 1
             M_ANIMATION_MORPH_KEYFRAME = $D111;
                 // float time
                 // bool includesNormals [1.8+]
                 // float x,y,z          // repeat by number of vertices in original geometry
             M_ANIMATION_POSE_KEYFRAME = $D112;
                 // float time
                 M_ANIMATION_POSE_REF = $D113; // repeat for number of referenced poses
                     // unsigned short poseIndex 
                     // float influence

     // Optional submesh extreme vertex list chink
     M_TABLE_EXTREMES = $E000;
     // unsigned short submesh_index;
     // float extremes [n_extremes][3];

const
  ChunkNames: array of record
    id  : word;
    name: string;
  end = (
    (id:$1000; name:'M_HEADER'),
    (id:$3000; name:'M_MESH'),
    (id:$4000; name:'M_SUBMESH'),
    (id:$4010; name:'M_SUBMESH_OPERATION'),
    (id:$4100; name:'M_SUBMESH_BONE_ASSIGNMENT'),
    (id:$4200; name:'M_SUBMESH_TEXTURE_ALIAS'),
    (id:$5000; name:'M_GEOMETRY'),
    (id:$5100; name:'M_GEOMETRY_VERTEX_DECLARATION'),
    (id:$5110; name:'M_GEOMETRY_VERTEX_ELEMENT'),
    (id:$5200; name:'M_GEOMETRY_VERTEX_BUFFER'),
    (id:$5210; name:'M_GEOMETRY_VERTEX_BUFFER_DATA'),
    (id:$6000; name:'M_MESH_SKELETON_LINK'),
    (id:$7000; name:'M_MESH_BONE_ASSIGNMENT'),
    (id:$8000; name:'M_MESH_LOD_LEVEL'),
    (id:$8100; name:'M_MESH_LOD_USAGE'),
    (id:$8110; name:'M_MESH_LOD_MANUAL'),
    (id:$8120; name:'M_MESH_LOD_GENERATED'),
    (id:$9000; name:'M_MESH_BOUNDS'),
    (id:$A000; name:'M_SUBMESH_NAME_TABLE'),
    (id:$A100; name:'M_SUBMESH_NAME_TABLE_ELEMENT'),
    (id:$B000; name:'M_EDGE_LISTS'),
    (id:$B100; name:'M_EDGE_LIST_LOD'),
    (id:$B110; name:'M_EDGE_GROUP'),
    (id:$C000; name:'M_POSES'),
    (id:$C100; name:'M_POSE'),
    (id:$C111; name:'M_POSE_VERTEX'),
    (id:$D000; name:'M_ANIMATIONS'),
    (id:$D100; name:'M_ANIMATION'),
    (id:$D105; name:'M_ANIMATION_BASEINFO'),
    (id:$D110; name:'M_ANIMATION_TRACK'),
    (id:$D111; name:'M_ANIMATION_MORPH_KEYFRAME'),
    (id:$D112; name:'M_ANIMATION_POSE_KEYFRAME'),
    (id:$D113; name:'M_ANIMATION_POSE_REF'),
    (id:$E000; name:'M_TABLE_EXTREMES')
  );

(**
 * Vertex element type, used to identify the base types of the vertex contents
 *
 * @note VET_SHORT1, VET_SHORT3, VET_USHORT1 and VET_USHORT3 should never be used
 * because they aren't supported on any known hardware - they are unaligned as their size
 * is not a multiple of 4 bytes. Therefore drivers usually must add padding on upload.
 *)
const
  VET_FLOAT1       =  0;
  VET_FLOAT2       =  1;
  VET_FLOAT3       =  2;
  VET_FLOAT4       =  3;
  /// alias to more specific colour type - use the current rendersystem's colour packing
  VET_COLOUR       =  4;  ///< @deprecated use VET_UBYTE4_NORM
  VET_SHORT1       =  5;  ///< @deprecated not supported on D3D9
  VET_SHORT2       =  6;
  VET_SHORT3       =  7;  ///< @deprecated not supported on D3D9 and D3D11
  VET_SHORT4       =  8;
  VET_UBYTE4       =  9;

  VET_COLOUR_ARGB  = 10;  /// < @deprecated use VET_UBYTE4_NORM. D3D style compact colour
  VET_COLOUR_ABGR  = 11;  /// < @deprecated use VET_UBYTE4_NORM. GL  style compact colour

  // the following are not universally supported on all hardware:
  VET_DOUBLE1      = 12;
  VET_DOUBLE2      = 13;
  VET_DOUBLE3      = 14;
  VET_DOUBLE4      = 15;
  VET_USHORT1      = 16;  ///< @deprecated not supported on D3D9
  VET_USHORT2      = 17;
  VET_USHORT3      = 18;  ///< @deprecated not supported on D3D9 and D3D11
  VET_USHORT4      = 19;
  VET_INT1         = 20;
  VET_INT2         = 21;
  VET_INT3         = 22;
  VET_INT4         = 23;
  VET_UINT1        = 24;
  VET_UINT2        = 25;
  VET_UINT3        = 26;
  VET_UINT4        = 27;
  VET_BYTE4        = 28;  /// signed bytes
  VET_BYTE4_NORM   = 29;  /// signed bytes    (normalized to -1..1)
  VET_UBYTE4_NORM  = 30;  /// unsigned bytes  (normalized to 0..1)
  VET_SHORT2_NORM  = 31;  /// signed shorts   (normalized to -1..1)
  VET_SHORT4_NORM  = 32;
  VET_USHORT2_NORM = 33;  /// unsigned shorts (normalized to 0..1)
  VET_USHORT4_NORM = 34;
  VET_INT_10_10_10_2_NORM = 35; ///< signed int (normalized to 0..1)
  VET_HALF1        = 36;  ///< not supported on D3D9
  VET_HALF2        = 37;
  VET_HALF3        = 38;  ///< not supported on D3D9 and D3D11
  VET_HALF4        = 39;

const
  /// Vertex element semantics, used to identify the meaning of vertex buffer contents
  /// (note - the first value VES_POSITION is 1)
//  TVertexElementSemantic = (
  VES_POSITION            = 1;  /// Position, 3 reals per vertex VET_FLOAT3
  VES_BLEND_WEIGHTS       = 2;  /// Blending weights
  VES_BLEND_INDICES       = 3;  /// Blending indices
  VES_NORMAL              = 4;  /// Normal, 3 reals per vertex VET_FLOAT3
  VES_DIFFUSE             = 5;  /// Diffuse colours VET_UBYTE4
  VES_SPECULAR            = 6;  /// Specular colours
  VES_TEXTURE_COORDINATES = 7;  /// Texture coordinates
  VES_BINORMAL            = 8;  /// Binormal (Y axis if normal is Z)
  VES_TANGENT             = 9;  /// Tangent  (X axis if normal is Z)
  // my custom
  VES_UNKNOWN             = 0;
  VES_TEXTURE             = VES_TEXTURE_COORDINATES;

const
  VES_COLOUR  = VES_DIFFUSE;
  VES_COLOUR2 = VES_SPECULAR;
  /// The  number of VertexElementSemantic elements  
  VES_COUNT = 9;

const
/// The rendering operation type to perform
//   TOperationType = (
    /// A list of points, 1 vertex per point
    OT_POINT_LIST     = 1;
    /// A list of lines, 2 vertices per line
    OT_LINE_LIST      = 2;
    /// A strip of connected lines, 1 vertex per line plus 1 start vertex
    OT_LINE_STRIP     = 3;
    /// A list of triangles , 3 vertices per triangle
    OT_TRIANGLE_LIST  = 4;
    /// A strip of triangles, 3 vertices for the first triangle, and 1 per triangle after that
    OT_TRIANGLE_STRIP = 5;
    /// A fan of triangles  , 3 vertices for the first triangle, and 1 per triangle after that
    OT_TRIANGLE_FAN   = 6;
{
    /// Patch control point operations, used with tessellation stages
    OT_PATCH_1_CONTROL_POINT    = 7,
    OT_PATCH_2_CONTROL_POINT    = 8,
    OT_PATCH_3_CONTROL_POINT    = 9,
    OT_PATCH_4_CONTROL_POINT    = 10,
    OT_PATCH_5_CONTROL_POINT    = 11,
    OT_PATCH_6_CONTROL_POINT    = 12,
    OT_PATCH_7_CONTROL_POINT    = 13,
    OT_PATCH_8_CONTROL_POINT    = 14,
    OT_PATCH_9_CONTROL_POINT    = 15,
    OT_PATCH_10_CONTROL_POINT   = 16,
    OT_PATCH_11_CONTROL_POINT   = 17,
    OT_PATCH_12_CONTROL_POINT   = 18,
    OT_PATCH_13_CONTROL_POINT   = 19,
    OT_PATCH_14_CONTROL_POINT   = 20,
    OT_PATCH_15_CONTROL_POINT   = 21,
    OT_PATCH_16_CONTROL_POINT   = 22,
    OT_PATCH_17_CONTROL_POINT   = 23,
    OT_PATCH_18_CONTROL_POINT   = 24,
    OT_PATCH_19_CONTROL_POINT   = 25,
    OT_PATCH_20_CONTROL_POINT   = 26,
    OT_PATCH_21_CONTROL_POINT   = 27,
    OT_PATCH_22_CONTROL_POINT   = 28,
    OT_PATCH_23_CONTROL_POINT   = 29,
    OT_PATCH_24_CONTROL_POINT   = 30,
    OT_PATCH_25_CONTROL_POINT   = 31,
    OT_PATCH_26_CONTROL_POINT   = 32,
    OT_PATCH_27_CONTROL_POINT   = 33,
    OT_PATCH_28_CONTROL_POINT   = 34,
    OT_PATCH_29_CONTROL_POINT   = 35,
    OT_PATCH_30_CONTROL_POINT   = 36,
    OT_PATCH_31_CONTROL_POINT   = 37,
    OT_PATCH_32_CONTROL_POINT   = 38
}

const
  // max valid base OT_ = (1 << 6) - 1
  /// Mark that the index buffer contains adjacency information
  OT_DETAIL_ADJACENCY_BIT = 1 shl 6;
  /// like OT_POINT_LIST but with adjacency information for the geometry shader
  OT_LINE_LIST_ADJ        = OT_LINE_LIST      or OT_DETAIL_ADJACENCY_BIT;
  /// like OT_LINE_STRIP but with adjacency information for the geometry shader
  OT_LINE_STRIP_ADJ       = OT_LINE_STRIP     or OT_DETAIL_ADJACENCY_BIT;
  /// like OT_TRIANGLE_LIST but with adjacency information for the geometry shader
  OT_TRIANGLE_LIST_ADJ    = OT_TRIANGLE_LIST  or OT_DETAIL_ADJACENCY_BIT;
  /// like OT_TRIANGLE_STRIP but with adjacency information for the geometry shader
  OT_TRIANGLE_STRIP_ADJ   = OT_TRIANGLE_STRIP or OT_DETAIL_ADJACENCY_BIT;

const
  VESData: array [1..VES_COUNT] of record
    code  :integer;
    name  :string;
//    attrib:string;
//    node  :string;
  end = (
    (code: VES_POSITION           ; name: 'VES_POSITION'           {; attrib: 'positions'       ; node: 'position'       }),
    (code: VES_BLEND_WEIGHTS      ; name: 'VES_BLEND_WEIGHTS'      {; attrib: ''                ; node: ''               }),
    (code: VES_BLEND_INDICES      ; name: 'VES_BLEND_INDICES'      {; attrib: ''                ; node: ''               }),
    (code: VES_NORMAL             ; name: 'VES_NORMAL'             {; attrib: 'normals'         ; node: 'normal'         }),
    (code: VES_DIFFUSE            ; name: 'VES_DIFFUSE'            {; attrib: 'colours_diffuse' ; node: 'colour_diffuse' }),
    (code: VES_SPECULAR           ; name: 'VES_SPECULAR'           {; attrib: 'colours_specular'; node: 'colour_specular'}),
    (code: VES_TEXTURE_COORDINATES; name: 'VES_TEXTURE_COORDINATES'{; attrib: 'texcoords'       ; node: 'texcoord'       }),
    (code: VES_BINORMAL           ; name: 'VES_BINORMAL'           {; attrib: 'binormals'       ; node: 'binormal'       }),
    (code: VES_TANGENT            ; name: 'VES_TANGENT'            {; attrib: 'tangents'        ; node: 'tangent'        })
  );

const
  VETData:array [0..39] of record
    code :integer;
    size :integer;
    count:integer;
    base :integer;
    name :string;
  end = (
    (code: VET_FLOAT1      ; size:  4; count: 1; base: VET_FLOAT1      ; name: 'VET_FLOAT1'),
    (code: VET_FLOAT2      ; size:  8; count: 2; base: VET_FLOAT1      ; name: 'VET_FLOAT2'),
    (code: VET_FLOAT3      ; size: 12; count: 3; base: VET_FLOAT1      ; name: 'VET_FLOAT3'),
    (code: VET_FLOAT4      ; size: 16; count: 4; base: VET_FLOAT1      ; name: 'VET_FLOAT4'),
    (code: VET_COLOUR      ; size:  4; count: 4; base: VET_UBYTE4_NORM ; name: 'VET_COLOUR'),
    (code: VET_SHORT1      ; size:  2; count: 1; base: VET_SHORT1      ; name: 'VET_SHORT1'),
    (code: VET_SHORT2      ; size:  4; count: 2; base: VET_SHORT1      ; name: 'VET_SHORT2'),
    (code: VET_SHORT3      ; size:  6; count: 3; base: VET_SHORT1      ; name: 'VET_SHORT3'),
    (code: VET_SHORT4      ; size:  8; count: 4; base: VET_SHORT1      ; name: 'VET_SHORT4'),
    (code: VET_UBYTE4      ; size:  4; count: 4; base: VET_UBYTE4      ; name: 'VET_UBYTE4'),
    (code: VET_COLOUR_ARGB ; size:  4; count: 4; base: VET_UBYTE4_NORM ; name: 'VET_COLOUR_ARGB'),
    (code: VET_COLOUR_ABGR ; size:  4; count: 4; base: VET_UBYTE4_NORM ; name: 'VET_COLOUR_ABGR'),
    (code: VET_DOUBLE1     ; size:  8; count: 1; base: VET_DOUBLE1     ; name: 'VET_DOUBLE1'),
    (code: VET_DOUBLE2     ; size: 16; count: 2; base: VET_DOUBLE1     ; name: 'VET_DOUBLE2'),
    (code: VET_DOUBLE3     ; size: 24; count: 3; base: VET_DOUBLE1     ; name: 'VET_DOUBLE3'),
    (code: VET_DOUBLE4     ; size: 32; count: 4; base: VET_DOUBLE1     ; name: 'VET_DOUBLE4'),
    (code: VET_USHORT1     ; size:  2; count: 1; base: VET_USHORT1     ; name: 'VET_USHORT1'),
    (code: VET_USHORT2     ; size:  4; count: 2; base: VET_USHORT1     ; name: 'VET_USHORT2'),
    (code: VET_USHORT3     ; size:  6; count: 3; base: VET_USHORT1     ; name: 'VET_USHORT3'),
    (code: VET_USHORT4     ; size:  8; count: 4; base: VET_USHORT1     ; name: 'VET_USHORT4'),
    (code: VET_INT1        ; size:  4; count: 1; base: VET_INT1        ; name: 'VET_INT1'),
    (code: VET_INT2        ; size:  8; count: 2; base: VET_INT1        ; name: 'VET_INT2'),
    (code: VET_INT3        ; size: 12; count: 3; base: VET_INT1        ; name: 'VET_INT3'),
    (code: VET_INT4        ; size: 16; count: 4; base: VET_INT1        ; name: 'VET_INT4'),
    (code: VET_UINT1       ; size:  4; count: 1; base: VET_UINT1       ; name: 'VET_UINT1'),
    (code: VET_UINT2       ; size:  8; count: 2; base: VET_UINT1       ; name: 'VET_UINT2'),
    (code: VET_UINT3       ; size: 12; count: 3; base: VET_UINT1       ; name: 'VET_UINT3'),
    (code: VET_UINT4       ; size: 16; count: 4; base: VET_UINT1       ; name: 'VET_UINT4'),
    (code: VET_BYTE4       ; size:  4; count: 4; base: VET_BYTE4       ; name: 'VET_BYTE4'),
    (code: VET_BYTE4_NORM  ; size:  4; count: 4; base: VET_BYTE4_NORM  ; name: 'VET_BYTE4_NORM'),
    (code: VET_UBYTE4_NORM ; size:  4; count: 4; base: VET_UBYTE4_NORM ; name: 'VET_UBYTE4_NORM'),
    (code: VET_SHORT2_NORM ; size:  4; count: 2; base: VET_SHORT2_NORM ; name: 'VET_SHORT2_NORM'),
    (code: VET_SHORT4_NORM ; size:  8; count: 2; base: VET_SHORT2_NORM ; name: 'VET_SHORT4_NORM'),
    (code: VET_USHORT2_NORM; size:  4; count: 2; base: VET_USHORT2_NORM; name: 'VET_USHORT2_NORM'),
    (code: VET_USHORT4_NORM; size:  8; count: 4; base: VET_USHORT2_NORM; name: 'VET_USHORT4_NORM'),
    (code: VET_INT_10_10_10_2_NORM; size: 4; count: 4; base: VET_INT_10_10_10_2_NORM; name: 'VET_INT_10_10_10_2_NORM'),
    (code: VET_HALF1       ; size:  2; count: 1; base: VET_HALF1       ; name: 'VET_HALF1'),
    (code: VET_HALF2       ; size:  4; count: 2; base: VET_HALF1       ; name: 'VET_HALF2'),
    (code: VET_HALF3       ; size:  6; count: 3; base: VET_HALF1       ; name: 'VET_HALF3'),
    (code: VET_HALF4       ; size:  8; count: 4; base: VET_HALF1       ; name: 'VET_HALF4')
  );

const
  OTData: array [1..6] of record
    code:integer;
    name:string;
  end = (
    (code: OT_POINT_LIST    ; name: 'OT_POINT_LIST'    ),
    (code: OT_LINE_LIST     ; name: 'OT_LINE_LIST'     ),
    (code: OT_LINE_STRIP    ; name: 'OT_LINE_STRIP'    ),
    (code: OT_TRIANGLE_LIST ; name: 'OT_TRIANGLE_LIST' ),
    (code: OT_TRIANGLE_STRIP; name: 'OT_TRIANGLE_STRIP'),
    (code: OT_TRIANGLE_FAN  ; name: 'OT_TRIANGLE_FAN'  )
  );

const
  FileVersions : array of record
    ver : integer;
    sign: string;
  end = (
    (ver: 10; sign:'[MeshSerializer_v1.10]' ), // deprecated
    (ver: 20; sign:'[MeshSerializer_v1.20]' ), // deprecated
    (ver: 30; sign:'[MeshSerializer_v1.30]' ),
    (ver: 40; sign:'[MeshSerializer_v1.40]' ), // TL1 / TL2
    (ver: 41; sign:'[MeshSerializer_v1.41]' ), // TL2
    (ver: 80; sign:'[MeshSerializer_v1.8]'  ),
    (ver: 90; sign:'[MeshSerializer_v1.9]'  ), // Hob
    (ver: 91; sign:'[MeshSerializer_v1.9_o]'), // Hob
    (ver: 99; sign:'[MeshSerializer_Runic]' ), // RG/RGO
    (ver:100; sign:'[MeshSerializer_v1.100]')
  );

const    
  TexCoordDimName:array [0..3] of string = ('u', 'v', 'w', 'x');

type
  TOgreChunk = packed record
    _type:word;
    _len :dword;
  end;
