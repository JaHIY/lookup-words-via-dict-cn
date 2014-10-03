#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use autodie;
use 5.010;

use Carp;
use Digest::MD5;
use Encode;
use Getopt::Long;
use JSON;
use LWP::UserAgent;
use Pod::Usage;
use Readonly;
use Term::ANSIColor;
use Term::ReadLine;

Readonly my $USER_AGENT => q{Mozilla/5.0 (X11; Linux x86_64; rv:33.0) Gecko/20100101 Firefox/33.0};
Readonly my $DICT_PAGE => q{http://dict.cn/en/search/?q=};
Readonly my $AJAX_PAGE => q{http://dict.cn/ajax/dictcontent.php};
Readonly my $DICT_TOKEN => q{dictcn};
Readonly my $SPACE => q{ };

sub get_json_for_definition_of {
    my ( $word ) = @_;
    my $word_token = $word.$DICT_TOKEN;
    my $user_agent = LWP::UserAgent->new( agent      => $USER_AGENT,
                                          cookie_jar => { hide_cookie2 => 1 },
                                        );
    my $page_response = $user_agent->get( ${DICT_PAGE}.${word} );
    if ( $page_response->is_success ) {
         my ( $dict_pagetoken ) = $page_response->content =~ m{dict_pagetoken="([^"]+)"}xms;
         if ( defined $dict_pagetoken ) {
             $word_token .= $dict_pagetoken;
         }
         #say $word_token;
         $user_agent->default_header( ISAJAX => q{yes} );
         my $ajax_response = $user_agent->post( $AJAX_PAGE,
                                                { q => $word,
                                                  s => 5,
                                                  t => Digest::MD5->new->add($word_token)->hexdigest,
                                                }
                                              );
        #print $ajax_response->request->as_string;
        #print $ajax_response->headers_as_string;
        if ( $ajax_response->is_success ) {
            #say $ajax_response->content;
            my $dict_hash_ref = JSON->new->utf8->decode($ajax_response->content);
            return $dict_hash_ref;
        }
        else {
            croak 'Cannot get json from dict.cn!';
        }
    }
}

sub color_print {
    my ( $original_input ) = @_;
    my $input = encode 'utf-8', $original_input;
    pos $input = 0;
    while ( pos $input < length $input ) {
        if ( $input =~ m{\G<i>}gcxms ) {
            print color 'italic magenta';
        }
        elsif ( $input =~ m{\G<em>}gcxms ) {
            print color 'bold yellow';
        }
        elsif ( $input =~ m{\G<font[^>]*>}gcxms ) {
            print color 'green';
        }
        elsif ( $input =~ m{\G<br[[:space:]]/>}gcxms ) {
            print "\n";
        }
        elsif ( $input =~ m{\G</[^>]+>}gcxms ) {
            print color 'reset';
        }
        elsif ( $input =~ m{\G<[^>]+>}gcxms ) {
            next;
        }
        elsif ( $input =~ m{\G\n+}gcxms ) {
            next;
        }
        elsif ( $input =~ m{\G&nbsp;}gcxms ) {
            print $SPACE;
        }
        else {
            print substr($input, pos($input), 1);
            pos $input += 1;
            #croak 'Cannot match anyting!';
        }
    }
    if ($input !~ m{<br[[:space:]]/>[[:space:]]*\z}xms) {
        print "\n";
    }
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
        print ' not found!', "\n";
        print 'Are you looking for:', "\n";
        print color 'reset';
        color_print( $dict_hash_ref->{'g'} );
    }
}

sub main {
    my %option_of;
    GetOptions( 'help|h|?' => \$option_of{'help'},
                'man'      => \$option_of{'man'},
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

main;

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
