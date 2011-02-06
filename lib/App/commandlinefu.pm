package App::commandlinefu;
use strict;
use 5.008_001;

use Mouse;
use Furl;

our $VERSION = '0.01';

with 'MouseX::Getopt';

has 'n|no-color' => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
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

has '_print_command' => (
    is => 'rw',
    isa => 'CodeRef',
);

sub BUILD {
    my $self = shift;

    my $print_func = defined $self->n
        ? &_print_command_nocolor : &_print_command_color;

    $self->_print_command( $print_func );
}

__PACKAGE__->meta->make_immutable;

no Mouse;

use Carp;
use Encode;
use JSON::XS;
use MIME::Base64;
use Term::ANSIColor qw(:constants);

sub run {
    my ($self, $query) = @_;

    _validate($query);
    $self->query($query);

    my $url = $self->_api_url($query);

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

    my $colored_query = YELLOW . $self->query . RESET;
    $command_info->{command} =~ s/$self->query/$colored_query/g;
    print encode_utf8($command_info->{command}), "\n\n";
}

sub _print_command_nocolor {
    my ($self, $command_info) = @_;

    my $str = "# " . $command_info->{summary};
    $str .= " [votes=" . encode_utf8($command_info->{votes}) . "]\n";
    $str .= "# " . $command_info->{summary};
    $str .= $command_info->{command} . "\n\n";

    print encode_utf8($str);
}

sub _validate {
    my $query = shift;

    unless (defined $query) {
        Carp::croak("Usage $0 search_command\n");
    }
}

sub _parse_response {
    my ($self, $content_ref) = @_;
    return decode_json(${$content_ref});
}

sub _api_url {
    my ($self, $query) = @_;
    my $base = 'http://www.commandlinefu.com/commands/matching';
    my $base64 = encode_base64($query, '');

    return "${base}/${query}/${base64}/json";
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
