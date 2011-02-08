package App::commandlinefu;
use strict;
use 5.008_001;

use Mouse;
use Furl;

our $VERSION = '0.01';

with 'MouseX::Getopt';

has 'no-color' => (
    traits  => [ 'Getopt' ],
    reader => 'no_color',
    isa => 'Bool',
    cmd_aliases => 'n',
    default => undef,
    required => 0,
);

has 'page' => (
    traits => [ 'Getopt' ],
    is => 'ro',
    isa => 'Int',
    cmd_aliases => 'p',
    default => 0,
    required => 0,
);

has '_query' => (
    accessor => 'query',
    isa => 'Str',
);

has '_ua' => (
    accessor => 'ua',
    isa => 'Furl',
    lazy_build => 1,
);

sub _build__ua {
    Furl->new(
        agent => __PACKAGE__ . $VERSION,
        timeout => 10,
    );
}

sub BUILD {
    my $self = shift;

    no strict 'refs';
    *{__PACKAGE__ . '::_print_command'} = defined $self->no_color
        ? \&_print_command_nocolor : \&_print_command_color;
}

__PACKAGE__->meta->make_immutable;

no Mouse;

use Carp;
use Encode;
use JSON::XS;
use URI::Escape;
use MIME::Base64;
use Term::ANSIColor qw(:constants);

sub run {
    my ($self, $query) = @_;
    my $command_set;

    if (defined $query) {
        $self->query($query);
        $command_set = 'matching';
    } else {
        $command_set = 'browse';
    }

    my $url = $self->_api_url($command_set);

    my $res = $self->ua->get($url);
    unless ($res->is_success) {
        Carp::croak("Can't download $url ", $res->status_line);
    }

    my $content = decode_utf8($res->content);

    my $command_infos_ref = $self->_parse_response(\$content);
    for my $command_info (@{$command_infos_ref}) {
        $self->_print_command($command_info);
    }
}

sub _print_command_color {
    my ($self, $command_info) = @_;

    print BRIGHT_BLUE "# ";
    print encode_utf8($command_info->{summary});
    print encode_utf8(" [votes=" . encode_utf8($command_info->{votes}) . "]\n");
    print RESET;

    if (defined $self->query) {
        my $query = $self->query;
        my $colored_query = YELLOW . $query . RESET;
        $command_info->{command} =~ s/$query/$colored_query/g;
    }
    print encode_utf8($command_info->{command}), "\n\n";
}

sub _print_command_nocolor {
    my ($self, $command_info) = @_;

    my $str = "# " . $command_info->{summary};
    $str .= " [votes=" . encode_utf8($command_info->{votes}) . "]\n";
    $str .= $command_info->{command} . "\n\n";

    print encode_utf8($str);
}

sub _parse_response {
    my ($self, $content_ref) = @_;
    return decode_json(${$content_ref});
}

sub _api_url {
    my ($self, $command_set) = @_;
    my $format = 'json';

    my $base = 'http://www.commandlinefu.com/commands';
    my $path;
    if ($command_set eq 'browse') {
        $path = "browse/sort-by-votes";
    } else {
        $path = 'matching/' . uri_escape($self->query);
        $path .= '/' . uri_escape( encode_base64($self->query, '') );
    }

    $path .= "/$format/" . $self->page;

    my $url = "${base}/$path";
    return $url;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

App::commandlinefu - Client of commandlinefu in Perl Language

=head1 SYNOPSIS

  use App::commandlinefu;

=head1 DESCRIPTION

App::commandlinefu is

=head1 AUTHOR

Syohei YOSHIDA E<lt>syohex@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2011- Syohei YOSHIDA

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

Originl command: L<http://d.hatena.ne.jp/t9md/20101112/1289573697>

=cut
