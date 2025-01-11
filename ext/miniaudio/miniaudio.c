#define MINIAUDIO_IMPLEMENTATION
#ifdef __APPLE__
#define MA_NO_RUNTIME_LINKING
#endif
// We can't define STB_VORBIS_NO_STDIO because ma requires it.
#include "stb_vorbis.c"
#include "ma_with_config.h"
