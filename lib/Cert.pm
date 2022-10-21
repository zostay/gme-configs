package Cert;

use v5.36;
use warnings;
use experimental 'try';
no warnings 'experimental';

require Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    create_x509_key_and_cert
    make_tls_secret
    make_tls_secret_if_needed
);

use IPC::Run qw( run );

sub create_x509_key_and_cert ($opt) {
    my $name = $opt->{name} // "secret";
    my $key_name = $opt->{key_name} // "$name.key";
    my $crt_name = $opt->{crt_name} // "$name.crt";
    my $host = $opt->{host} // "www.example.com";
    my $subject = $opt->{subject} // "/CN=$host";
    my $days = $opt->{days} // 365;
    my $cipher = $opt->{cipher} // 'rsa:2048';

    my ($out, $err) = run([
        qw( openssl req -x509 -nodes ),
        '-days', $days,
        '-newkey', $cipher,
        '-keyout', $key_name,
        '-out', $crt_name,
        '-subj', $subject,
    ]) or die qq[failed to create key and certificate for "$subject"];

    return {
        key_name => $key_name,
        crt_name => $crt_name,
    };
}

sub make_tls_secret ($opt) {
    my $cluster = $opt->{cluster} // die "cluster is required";
    my $name = $opt->{name} // "secret";
    my $namespace = $opt->{namespace};
    my $host = $opt->{host};

    my $cluster_name = $cluster->name;
    my $result = create_x509_key_and_cert({
        name => "$cluster_name-$namespace-$name",
        host => $host,
    });

    $cluster->create_secret({
        namespace => $namespace,
        name      => $name,
        tls       => {
            key  => $result->{key_name},
            cert => $result->{crt_name},
        }
    });
}

sub make_tls_secret_if_needed ($opt) {
    my $cluster = $opt->{cluster} // die "cluster is required";
    my $name = $opt->{name} // "secret";
    my $namespace = $opt->{namespace};
    my $host = $opt->{host};

    my $secret;
    try {
        $secret = $cluster->get({
            kind      => "secret",
            name      => $name,
            namespace => $namespace,
        });
    }
    catch ($x) {
        make_tls_secret($opt) if $x =~ /failed to get secret/;
    }


}

1;