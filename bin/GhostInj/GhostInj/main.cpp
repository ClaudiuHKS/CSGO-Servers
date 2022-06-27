
#include < windows.h >
#include < stdio.h >

static bool constexpr __forceinline dataCmp ( unsigned char * pData,
											  unsigned char * pMask,
											  char * pszMask ) noexcept
{
	for ( ; *pszMask; ++pszMask, ++pData, ++pMask )
	{
		if ( *pszMask == 'x' && *pData != *pMask )
		{
			return { };
		}
	}

	return !*pszMask;
}

static unsigned long constexpr __forceinline memFind ( unsigned char * pAddr,
													   unsigned long Size,
													   unsigned char * pMask,
													   char * pszMask ) noexcept
{
	for ( unsigned long Iter = { }; Iter < Size; Iter++ )
	{
		if ( ::dataCmp ( pAddr + Iter, pMask, pszMask ) )
		{
			return Iter;
		}
	}

	return { };
}

int __stdcall DllMain ( ::HINSTANCE__ *, unsigned long Reason, void * ) noexcept
{
	if ( Reason == 1UL )
	{
		::_iobuf * pFile = ::fopen ( "bin\\inputsystem.dll", "r+b" );

		if ( !pFile )
		{
			return 1I32;
		}

		::fseek ( pFile, { }, 2I32 );
		int Size = ( ( int ) ( ::ftell ( pFile ) ) );
		::rewind ( pFile );

		char * pszBuffer = ( ( char * ) ( ::malloc ( Size ) ) );

		if ( !pszBuffer )
		{
			::fclose ( pFile );

			return 1I32;
		}

		int Max = ( ( int ) ( ::fread ( pszBuffer,
										1UI32,
										( ( unsigned int ) ( Size ) ),
										pFile ) ) );

		unsigned long Addr = ::memFind ( ( ( unsigned char * ) ( pszBuffer ) ),
										 ( ( unsigned long ) ( Size ) ),
										 ( ( unsigned char * ) ( "\x83\x3D\x00\x00\x00\x00\x00\x57\x8B\xF9\x74\x05" ) ),
										 "xx?????xxxxx" ) + 290UL;

		if ( !Addr )
		{
			::fclose ( pFile );
			::free ( pszBuffer );

			return 1I32;
		}

		for ( int Iter = { }; Iter < 5I32; Iter++ )
			( ( ( unsigned char * ) ( pszBuffer ) ) [ Addr + Iter ] ) = 144I32;

		::fseek ( pFile, { }, { } );
		::fwrite ( pszBuffer, ( ( unsigned int ) ( Max ) ), 1UI32, pFile );
		::fclose ( pFile );
		::free ( pszBuffer );
	}

	return 1I32;
}
