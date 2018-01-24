use v6.c;
module Algorithm::GooglePolylineEncoding:ver<0.0.1>:auth<simon.proctor@gmail.com> {

    class PosPair {
        has Real $.lat where -90 .. 90;
        has Real $.lon where -180 .. 180;

        method Hash {
            return { :lat($.lat), :lon($.lon) };
        }
    }
    
    multi sub encode-number ( Real $value is copy where * < 0 ) returns Str is export {
        $value = round( $value * 1e5 );
        $value = $value +< 1;
        $value = $value +& 0xffffffff;
        
        $value = +^ $value;
        $value = $value +& 0xffffffff;
        
        return encode-shifted( $value );
    }
    
    multi sub encode-number ( Real $value is copy ) returns Str is export {
        $value = round( $value * 1e5 );
        $value = $value +< 1;            
        $value = $value +& 0xffffffff;
        
        return encode-shifted( $value );
    }
    
    sub encode-shifted ( Int $value is copy ) returns Str {
        
        my $bin = $value.base(2);
        
        unless $bin.chars %% 5 {
            $bin = '0' x ( 5 - $bin.chars % 5 ) ~ $bin;
        }
        
        my @chunks = $bin.comb( /\d ** 5/ ).reverse.map( *.parse-base(2) );
        
        @chunks[0..*-2].map( { $_ = $_ +| 0x20 } );
        
        return @chunks.map( { $_ + 63 } ).map( { chr( $_ ) } ).join("");
    }

    multi sub encode-polyline( @pairs where { $_.all ~~ PosPair } ) returns Str is export {
        my ( $cur-lat, $cur-lon ) = ( 0,0 );
        my @list = ();
        
        for @pairs -> $pair {
            @list.push( encode-number( $pair.lat - $cur-lat ) );
            @list.push( encode-number( $pair.lon - $cur-lon ) );
            ( $cur-lat, $cur-lon ) = ( $pair.lat, $pair.lon );        
        }
        
        return @list.join();
    }
    
    multi sub encode-polyline( @pairs where { $_.all ~~ Hash } ) returns Str is export {
        encode-polyline( @pairs.map( -> %p { PosPair.new( |%p ) } ).Array );
    }

    multi sub encode-polyline( **@pairs where { $_.all ~~ Hash } ) returns Str is export {
        encode-polyline( @pairs.map( -> %p { PosPair.new( |%p ) } ).Array );
    }
    
    multi sub encode-polyline( *@points where { $_.all ~~ Real && $_.elems %% 2 } ) returns Str is export {
        encode-polyline( @points.map( -> $la,$lo { PosPair.new( :lat($la), :lon($lo) ) } ).Array );
    }

    multi sub decode-polyline( Str $encoded is copy ) returns Array is export {
        my ( $lat, $lon ) = ( 0, 0 );
        my @out = [];
        
        my @values = $encoded.comb(/ .*?(.) <?{ $/[0] ~~ any( (63..92).map( *.chr ) ); }> /).map( &decode-str );
        
        for @values -> $dlat, $dlon {
            @out.push( PosPair.new( :lat($lat+$dlat), :lon($lon+$dlon) ).Hash );
            ($lat,$lon) = ( $lat + $dlat, $lon + $dlon );
        }
        
        return @out;
    }

    sub decode-str( Str $encoded is copy ) returns Real {
        my $value = ( $encoded.comb().reverse.map( *.ord - 63 ).map( * +& 0x1f ).map( *.base(2) ).map( { '0' x ( $_.chars %% 5 ?? 0 !! 5 - $_.chars % 5 ) ~ $_ } ).join() ).parse-base(2);
        $value = +^ $value if $value +& 1;
        $value = $value +> 1;
        $value = $value / 1e5;        
        return $value;
    }
}


=begin pod

=head1 NAME

Algorithm::GooglePolylineEncoding - blah blah blah

=head1 SYNOPSIS

    use Algorithm::GooglePolylineEncoding;


=head1 DESCRIPTION

Algorithm::GooglePolylineEncoding is ...

https://developers.google.com/maps/documentation/utilities/polylinealgorithm

=head1 AUTHOR

Simon Proctor <simon.proctor@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2018 Simon Proctor

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
