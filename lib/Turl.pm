package Turl;

use v5.36;
use warnings;

require Exporter;
our @ISA = qw( Exporter );

our @EXPORT_OK = qw( test_GET test_ew_GET test_NYI );

use LWP::UserAgent;

my $ua = LWP::UserAgent->new(
    ssl_opts => {
        verify_hostname => 0,
    },
);

sub _test_res ($res, @args) {
    my ($opt) = grep { ref } @args;
    $opt //= {};

    my $success = 0;
    my $extra = "";
    if (defined $opt->{expected_status}) {
        if ($res->code == $opt->{expected_status}) {
            $success = 1;
        }
        else {
            $extra = "expected $opt->{expected_status}, but got ".$res->code;
        }
    }
    else {
        if ($res->is_success) {
            $success = 1;
        }
        else {
            $extra = "expected success, but got ".$res->status_line;
        }
    }

    if ($opt->{response_matches}) {
        my $predicate = $opt->{response_matches};
        my ($ok, $details) = $predicate->($res);
        if (!$ok) {
            $success = 0;
            $extra .= ", " if $extra;
            $extra .= $details // "response does not match the given predicate";
        }
    }

    my $suffix = "";
    if ($success) {
        print "✅ ";
    } else {
        print "💥";
    }
    $suffix = " [$extra]" if $extra;
    my @msg = grep { !ref } @args;
    print " ", @msg, $suffix, "\n";

    if ($opt->{print}) {
        print $res->as_string;
    }
}

sub _rewrite_url ($url) {
    my $uri = URI->new($url);

    my $host = $uri->host;
    $uri->host("127.0.0.1");

    return ($host, "$uri");
}

sub test_GET ($url, @args) {
    my ($opt) = grep { ref } @args;
    my ($host, $uri) = _rewrite_url($url);

    my $req = HTTP::Request->new("GET", $uri, [
        Host => $host,
        @{ $opt->{headers} // [] },
    ]);

    my $res = $ua->request($req);

    _test_res($res, @args);
}

sub test_ew_GET ($cluster, $ns, $deploy, $url, @args) {
    my ($opt) = grep { ref } @args;
    my @headers;
    if (defined $opt->{headers}) {
        my @h = @{ $opt->{headers} };
        while (@h) {
            my ($key, $value) = splice @h, 0, 2;
            push @headers, "-H$key:$value";
        }
    }

    my ($out, $err) = $cluster->exec({
        namespace => $ns,
        target    => "deploy/$deploy",
        container => "curl",
        command   => [ "curl", "-s", "-k", "-v", $url, @headers ],
    });

    my $comb = $err.$out;
    if ($comb !~ m{\bHTTP/}) {
        my @msg = grep { !ref } @args;
        print "💥 ", @msg, "[$comb]\n";
        return;
    }

    my $res_str = '';
    my @lines = split /\n/, $err.$out;
    for (@lines) {
        next unless s/^< //;
        $res_str .= "$_\n";
    }

    my $res = HTTP::Response->parse($res_str);
    _test_res($res, @args);
}

sub test_NYI (@msg) {
    print "🚫", " ", @msg, " (not implemented)\n";
}

1;