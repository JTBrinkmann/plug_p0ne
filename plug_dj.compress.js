window.compressor = {
	_keyStr: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",
	compressToBase64: function( e )
	{
		var t = "",
			n, r, i, s, o, u, a, f = 0;
		e = this.compress( e );
		while ( f < e.length * 2 ) f % 2 == 0 ? ( n = e.charCodeAt( f / 2 ) >> 8, r = e.charCodeAt( f / 2 ) & 255, f / 2 + 1 < e.length ? i = e.charCodeAt( f / 2 + 1 ) >> 8 : i = NaN ) : ( n = e.charCodeAt( ( f - 1 ) / 2 ) & 255, ( f + 1 ) / 2 < e.length ? ( r = e.charCodeAt( ( f + 1 ) / 2 ) >> 8, i = e.charCodeAt( ( f + 1 ) / 2 ) & 255 ) : r = i = NaN ), f += 3, s = n >> 2, o = ( n & 3 ) << 4 | r >> 4, u = ( r & 15 ) << 2 | i >> 6, a = i & 63, isNaN( r ) ? u = a = 64 : isNaN( i ) && ( a = 64 ), t = t + this._keyStr.charAt( s ) + this._keyStr.charAt( o ) + this._keyStr.charAt( u ) + this._keyStr.charAt( a );
		return t
	},
	decompressFromBase64: function( e )
	{
		var t = "",
			n = 0,
			r, i, s, o, u, a, f, l, c = 0;
		e = e.replace( /[^A-Za-z0-9\+\/\=]/g, "" );
		while ( c < e.length ) u = this._keyStr.indexOf( e.charAt( c++ ) ), a = this._keyStr.indexOf( e.charAt( c++ ) ), f = this._keyStr.indexOf( e.charAt( c++ ) ), l = this._keyStr.indexOf( e.charAt( c++ ) ), i = u << 2 | a >> 4, s = ( a & 15 ) << 4 | f >> 2, o = ( f & 3 ) << 6 | l, n % 2 == 0 ? ( r = i << 8, flush = !0, f != 64 && ( t += String.fromCharCode( r | s ), flush = !1 ), l != 64 && ( r = o << 8, flush = !0 ) ) : ( t += String.fromCharCode( r | i ), flush = !1, f != 64 && ( r = s << 8, flush = !0 ), l != 64 && ( t += String.fromCharCode( r | o ), flush = !1 ) ), n += 3;
		return this.decompress( t )
	},
	compressToUTF16: function( e )
	{
		var t = "",
			n, r, i, s = 0;
		e = this.compress( e );
		for ( n = 0; n < e.length; n++ )
		{
			r = e.charCodeAt( n );
			switch ( s++ )
			{
				case 0:
					t += String.fromCharCode( ( r >> 1 ) + 32 ), i = ( r & 1 ) << 14;
					break;
				case 1:
					t += String.fromCharCode( i + ( r >> 2 ) + 32 ), i = ( r & 3 ) << 13;
					break;
				case 2:
					t += String.fromCharCode( i + ( r >> 3 ) + 32 ), i = ( r & 7 ) << 12;
					break;
				case 3:
					t += String.fromCharCode( i + ( r >> 4 ) + 32 ), i = ( r & 15 ) << 11;
					break;
				case 4:
					t += String.fromCharCode( i + ( r >> 5 ) + 32 ), i = ( r & 31 ) << 10;
					break;
				case 5:
					t += String.fromCharCode( i + ( r >> 6 ) + 32 ), i = ( r & 63 ) << 9;
					break;
				case 6:
					t += String.fromCharCode( i + ( r >> 7 ) + 32 ), i = ( r & 127 ) << 8;
					break;
				case 7:
					t += String.fromCharCode( i + ( r >> 8 ) + 32 ), i = ( r & 255 ) << 7;
					break;
				case 8:
					t += String.fromCharCode( i + ( r >> 9 ) + 32 ), i = ( r & 511 ) << 6;
					break;
				case 9:
					t += String.fromCharCode( i + ( r >> 10 ) + 32 ), i = ( r & 1023 ) << 5;
					break;
				case 10:
					t += String.fromCharCode( i + ( r >> 11 ) + 32 ), i = ( r & 2047 ) << 4;
					break;
				case 11:
					t += String.fromCharCode( i + ( r >> 12 ) + 32 ), i = ( r & 4095 ) << 3;
					break;
				case 12:
					t += String.fromCharCode( i + ( r >> 13 ) + 32 ), i = ( r & 8191 ) << 2;
					break;
				case 13:
					t += String.fromCharCode( i + ( r >> 14 ) + 32 ), i = ( r & 16383 ) << 1;
					break;
				case 14:
					t += String.fromCharCode( i + ( r >> 15 ) + 32, ( r & 32767 ) + 32 ), s = 0
			}
		}
		return t + String.fromCharCode( i + 32 )
	},
	decompressFromUTF16: function( e )
	{
		var t = "",
			n, r, i = 0,
			s = 0;
		while ( s < e.length )
		{
			r = e.charCodeAt( s ) - 32;
			switch ( i++ )
			{
				case 0:
					n = r << 1;
					break;
				case 1:
					t += String.fromCharCode( n | r >> 14 ), n = ( r & 16383 ) << 2;
					break;
				case 2:
					t += String.fromCharCode( n | r >> 13 ), n = ( r & 8191 ) << 3;
					break;
				case 3:
					t += String.fromCharCode( n | r >> 12 ), n = ( r & 4095 ) << 4;
					break;
				case 4:
					t += String.fromCharCode( n | r >> 11 ), n = ( r & 2047 ) << 5;
					break;
				case 5:
					t += String.fromCharCode( n | r >> 10 ), n = ( r & 1023 ) << 6;
					break;
				case 6:
					t += String.fromCharCode( n | r >> 9 ), n = ( r & 511 ) << 7;
					break;
				case 7:
					t += String.fromCharCode( n | r >> 8 ), n = ( r & 255 ) << 8;
					break;
				case 8:
					t += String.fromCharCode( n | r >> 7 ), n = ( r & 127 ) << 9;
					break;
				case 9:
					t += String.fromCharCode( n | r >> 6 ), n = ( r & 63 ) << 10;
					break;
				case 10:
					t += String.fromCharCode( n | r >> 5 ), n = ( r & 31 ) << 11;
					break;
				case 11:
					t += String.fromCharCode( n | r >> 4 ), n = ( r & 15 ) << 12;
					break;
				case 12:
					t += String.fromCharCode( n | r >> 3 ), n = ( r & 7 ) << 13;
					break;
				case 13:
					t += String.fromCharCode( n | r >> 2 ), n = ( r & 3 ) << 14;
					break;
				case 14:
					t += String.fromCharCode( n | r >> 1 ), n = ( r & 1 ) << 15;
					break;
				case 15:
					t += String.fromCharCode( n | r ), i = 0
			}
			s++
		}
		return this.decompress( t )
	},
	compress: function( e )
	{
		var t, n, r = {},
			i = {},
			s = "",
			o = "",
			u = "",
			a = 2,
			f = 3,
			l = 2,
			c = "",
			h = "",
			p = 0,
			d = 0,
			v;
		for ( v = 0; v < e.length; v += 1 )
		{
			s = e.charAt( v ), r.hasOwnProperty( s ) || ( r[ s ] = f++, i[ s ] = !0 ), o = u + s;
			if ( r.hasOwnProperty( o ) ) u = o;
			else
			{
				if ( i.hasOwnProperty( u ) )
				{
					if ( u.charCodeAt( 0 ) < 256 )
					{
						for ( t = 0; t < l; t++ ) p <<= 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++;
						n = u.charCodeAt( 0 );
						for ( t = 0; t < 8; t++ ) p = p << 1 | n & 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n >>= 1
					}
					else
					{
						n = 1;
						for ( t = 0; t < l; t++ ) p = p << 1 | n, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n = 0;
						n = u.charCodeAt( 0 );
						for ( t = 0; t < 16; t++ ) p = p << 1 | n & 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n >>= 1
					}
					a--, a == 0 && ( a = Math.pow( 2, l ), l++ ), delete i[ u ]
				}
				else
				{
					n = r[ u ];
					for ( t = 0; t < l; t++ ) p = p << 1 | n & 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n >>= 1
				}
				a--, a == 0 && ( a = Math.pow( 2, l ), l++ ), r[ o ] = f++, u = String( s )
			}
		}
		if ( u !== "" )
		{
			if ( i.hasOwnProperty( u ) )
			{
				if ( u.charCodeAt( 0 ) < 256 )
				{
					for ( t = 0; t < l; t++ ) p <<= 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++;
					n = u.charCodeAt( 0 );
					for ( t = 0; t < 8; t++ ) p = p << 1 | n & 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n >>= 1
				}
				else
				{
					n = 1;
					for ( t = 0; t < l; t++ ) p = p << 1 | n, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n = 0;
					n = u.charCodeAt( 0 );
					for ( t = 0; t < 16; t++ ) p = p << 1 | n & 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n >>= 1
				}
				a--, a == 0 && ( a = Math.pow( 2, l ), l++ ), delete i[ u ]
			}
			else
			{
				n = r[ u ];
				for ( t = 0; t < l; t++ ) p = p << 1 | n & 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n >>= 1
			}
			a--, a == 0 && ( a = Math.pow( 2, l ), l++ )
		}
		n = 2;
		for ( t = 0; t < l; t++ ) p = p << 1 | n & 1, d == 15 ? ( d = 0, h += String.fromCharCode( p ), p = 0 ) : d++, n >>= 1;
		for ( ;; )
		{
			p <<= 1;
			if ( d == 15 )
			{
				h += String.fromCharCode( p );
				break
			}
			d++
		}
		return h
	},
	decompress: function( e )
	{
		var t = [],
			n, r = 4,
			i = 4,
			s = 3,
			o = "",
			u = "",
			a, f, l, c, h, p, d, v = 0,
			m, g = {
				string: e,
				val: e.charCodeAt( 0 ),
				position: 32768,
				index: 1
			};
		for ( a = 0; a < 3; a += 1 ) t[ a ] = a;
		l = 0, h = Math.pow( 2, 2 ), p = 1;
		while ( p != h ) c = g.val & g.position, g.position >>= 1, g.position == 0 && ( g.position = 32768, g.val = g.string.charCodeAt( g.index++ ) ), l |= ( c > 0 ? 1 : 0 ) * p, p <<= 1;
		switch ( n = l )
		{
			case 0:
				l = 0, h = Math.pow( 2, 8 ), p = 1;
				while ( p != h ) c = g.val & g.position, g.position >>= 1, g.position == 0 && ( g.position = 32768, g.val = g.string.charCodeAt( g.index++ ) ), l |= ( c > 0 ? 1 : 0 ) * p, p <<= 1;
				d = String.fromCharCode( l );
				break;
			case 1:
				l = 0, h = Math.pow( 2, 16 ), p = 1;
				while ( p != h ) c = g.val & g.position, g.position >>= 1, g.position == 0 && ( g.position = 32768, g.val = g.string.charCodeAt( g.index++ ) ), l |= ( c > 0 ? 1 : 0 ) * p, p <<= 1;
				d = String.fromCharCode( l );
				break;
			case 2:
				return ""
		}
		t[ 3 ] = d, f = u = d;
		for ( ;; )
		{
			l = 0, h = Math.pow( 2, s ), p = 1;
			while ( p != h ) c = g.val & g.position, g.position >>= 1, g.position == 0 && ( g.position = 32768, g.val = g.string.charCodeAt( g.index++ ) ), l |= ( c > 0 ? 1 : 0 ) * p, p <<= 1;
			switch ( d = l )
			{
				case 0:
					if ( v++ > 1e4 ) return "Error";
					l = 0, h = Math.pow( 2, 8 ), p = 1;
					while ( p != h ) c = g.val & g.position, g.position >>= 1, g.position == 0 && ( g.position = 32768, g.val = g.string.charCodeAt( g.index++ ) ), l |= ( c > 0 ? 1 : 0 ) * p, p <<= 1;
					t[ i++ ] = String.fromCharCode( l ), d = i - 1, r--;
					break;
				case 1:
					l = 0, h = Math.pow( 2, 16 ), p = 1;
					while ( p != h ) c = g.val & g.position, g.position >>= 1, g.position == 0 && ( g.position = 32768, g.val = g.string.charCodeAt( g.index++ ) ), l |= ( c > 0 ? 1 : 0 ) * p, p <<= 1;
					t[ i++ ] = String.fromCharCode( l ), d = i - 1, r--;
					break;
				case 2:
					return u
			}
			r == 0 && ( r = Math.pow( 2, s ), s++ );
			if ( t[ d ] ) o = t[ d ];
			else
			{
				if ( d !== i ) return null;
				o = f + f.charAt( 0 )
			}
			u += o, t[ i++ ] = f + o.charAt( 0 ), r--, f = o, r == 0 && ( r = Math.pow( 2, s ), s++ )
		}
		return u
	}
};
$(window).trigger("compressorLoaded").trigger("decompressorLoaded")