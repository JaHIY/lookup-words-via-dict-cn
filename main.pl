#!/usr/bin/env perl

use strict;
use warnings;
use utf8::all;
use autodie;
use 5.010;

use Carp qw(croak);
use Digest::MD5 ();
use Encode qw(encode);
use Getopt::Long ();
use HTML::Parser;
use JSON ();
use LWP::UserAgent;
use Pod::Usage;
use Term::ANSIColor;
use Term::ReadLine;
use URI;
use URI::QueryParam;

my $USER_AGENT = q{Mozilla/5.0 (X11; Linux x86_64; rv:33.0) Gecko/20100101 Firefox/33.0};
my $DICT_PAGE = q{http://dict.cn/en/search/};
my $DICT_PAGE_URI = URI->new( $DICT_PAGE );
my $AJAX_PAGE = q{http://dict.cn/ajax/dictcontent.php};
my $AJAX_PAGE_URI = URI->new( $AJAX_PAGE );
my $DICT_TOKEN = q{dictcn};
my $SPACE = q{ };

sub build_url_with {
    my ( $uri, $query_params_ref ) = @_;
    my $uri_clone = $uri->clone;
    map { $uri_clone->query_param_append( $_, $query_params_ref->{$_} ) } keys %{ $query_params_ref };
    return $uri_clone;
}

sub get_json_for_definition_of {
    my ( $word ) = @_;
    my $word_token = $word . $DICT_TOKEN;
    my $user_agent = LWP::UserAgent->new( agent      => $USER_AGENT,
                                          cookie_jar => { hide_cookie2 => 1 },
                                        );
    my $page_response = $user_agent->get( build_url_with( $DICT_PAGE_URI, {
                q => encode( 'gbk', $word ),
            } ) );

    croak 'Cannot get page from dict.cn!' if not $page_response->is_success;

    my ( $dict_pagetoken ) = $page_response->content =~ m{dict_pagetoken="([^"]+)"}xms;

    $word_token .= $dict_pagetoken if defined $dict_pagetoken;

    $user_agent->default_header( ISAJAX => 'yes' );
    my $ajax_response = $user_agent->post( $AJAX_PAGE_URI, {
        q => $word,
        s => 5,
        t => Digest::MD5->new->add( encode( 'utf8', $word_token ) )->hexdigest,
    } );

    croak 'Cannot get json from dict.cn!' if not $ajax_response->is_success;

    my $dict_hash_ref = JSON->new->utf8->decode($ajax_response->content);
    return $dict_hash_ref;
}

sub color_print {
    my ( $input ) = @_;
    my $p = HTML::Parser->new(
        api_version => 3,
        handlers => {
            start => [ sub {
                    my ( $tagname ) = @_;
                    if ( $tagname eq 'i' ) {
                        print color 'italic magenta';
                    } elsif ( $tagname eq 'em' ) {
                        print color 'bold yellow';
                    } elsif ( $tagname eq 'font' ) {
                        print color 'green';
                    } elsif ( $tagname eq 'br' ) {
                        print "\n"
                    }
                }, 'tagname' ],
            end   => [ sub {
                    print color 'reset';
                }, undef ],
            text  => [ sub {
                    my ( $dtext ) = @_;
                    print $dtext;
                }, 'dtext' ],
        },
    );
    $input =~ s/\R//g;
    $p->parse( $input );
}

sub look_up {
    my ( $word ) = @_;
    my $dict_hash_ref = get_json_for_definition_of( $word );
    if ( defined $dict_hash_ref->{'e'} ) {
        print color 'bold';
        print 'Define ';
        print color 'yellow';
        print $word;
        print color 'reset';
        print color 'bold';
        print ':', "\n";
        print color 'reset';
        color_print( $dict_hash_ref->{'e'} );
        print "\n";
    }
    if ( defined $dict_hash_ref->{'s'} ) {
        print "\n";
        print color 'bold';
        print 'Examples:', "\n";
        print color 'reset';
        color_print( $dict_hash_ref->{'s'} );
    }
    if ( defined $dict_hash_ref->{'g'} ) {
        print color 'bold';
        print 'Sorry, ';
        print color 'yellow';
        print $word;
        print color 'reset';
        print color 'bold';
        print ' not found!', "\n\n";
        print 'Are you looking for:', "\n";
        print color 'reset';
        color_print( $dict_hash_ref->{'g'} );
    }
}

sub main {
    my %option_of;
    my $getopt = Getopt::Long::Parser->new;
    croak 'Cannot parse options!' if not $getopt->getoptionsfromarray(
        \@_,
        \%option_of,
        'help|h|?',
        'man',
    );
    if  ( $option_of{'help'} ) {
        pod2usage 1;
    }
    if ( $option_of{'man'} ) {
        pod2usage(-verbose => 2);
    }
    if ( @ARGV == 0 ) {
        my $term = Term::ReadLine->new('Dict.cn Console Version');
        $term->ornaments(0);
        while ( defined( my $word = $term->readline('> ') ) ) {
            look_up( $word, \%option_of );
            $term->addhistory($word);
        }
    } else {
        my ( $word ) = join $SPACE, @ARGV;
        look_up( $word );
    }
}

main( @ARGV );

__END__

=head1 NAME

lookup - lookup words via dict.cn

=head1 SYNOPSIS

lookup [options] [string ...]

Options:
    -help        print help messsge
    -man         full documentation

=head1 OPTIONS

=over

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<This program> will print the definition and examples of the word which you look up.

=cut
