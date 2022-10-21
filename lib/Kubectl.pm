package Kubectl;

use v5.36;
use warnings;
use feature 'try';
no warnings 'experimental';

require Exporter;
our @ISA = qw( Exporter );

our @EXPORT_OK = qw( MgmtCluster Cluster1 Cluster2 );

use FindBin;
use IPC::Run qw( run );
use JSON qw( decode_json );

sub cluster ($class, $cluster) {
    return bless { cluster => $cluster }, $class;
}

use constant MgmtCluster => __PACKAGE__->cluster("mgmt-cluster");
use constant Cluster1 => __PACKAGE__->cluster("cluster-1");
use constant Cluster2 => __PACKAGE__->cluster("cluster-2");

sub name ($self) {
    return $self->{cluster};
}

sub context ($self) {
    return "kind-$self->{cluster}";
}

sub _run ($self, @args) {
    my ($out, $err);
    run([
        "kubectl",
        "--context", "kind-$self->{cluster}",
        @args,
    ], '<', \undef, '>', \$out, '2>', \$err);

    die qq[failed to run: `kubectl --context kind-$self->{cluster} @args`: $@]
        if $@;

    return ($out, $err);
}

sub apply ($self, $filename) {
    try {
        my ($out, $err) = $self->_run(
            "apply",
            "-f", "$FindBin::Bin/$filename",
        );

        $out =~ s/^(?=.)/🔌 /xmsg;
        $err =~ s/^(?=.)/‼️ /xmsg;

        print $out;
        print $err;
    }
    catch ($x) {
        die qq[failed to apply resources found in "$FindBin::Bin/$filename" to cluster "$self->{cluster}" with context "kind-$self->{cluster}": $x];
    };
}

sub remove_one ($self, $opt) {
    my $kind = $opt->{kind} // die 'kind is required';
    my $name = $opt->{name} // die 'name is required';

    try {
        my ($out, $err) = $self->_run(
            "delete", $kind,
            (defined $opt->{namespace} ? ("-n", $opt->{namespace}) : ()),
            $name,
        );

        $out =~ s/^(?=.)/🧹 /xmsg;
        $err =~ s/^(?=.)/‼️ /xmsg;

        print $out;
        print $err;
    }
    catch ($x) {
        my $ns = "";
        $ns = " ($opt->{namespace})" if defined $opt->{namespace};
        die qq[failed to delete resource "$name" $ns from cluster "$self->{cluster}" with context "kind-$self->{cluster}": $x];
    }
}

sub remove ($self, $arg) {
    if (ref $arg) {
        return $self->remove_one($arg);
    }
    else {
        return $self->remove_by_file($arg);
    }
}

sub remove_by_file ($self, $filename) {
    try {
        my ($out, $err) = $self->_run(
            "delete",
            "-f", "$FindBin::Bin/$filename"
        );

        $out =~ s/^(?=.)/🧹 /xmsg;
        $err =~ s/^(?=.)/‼️ /xmsg;

        print $out;
        print $err;
    }
    catch ($x) {
        die qq[failed to delete resources found in  "$FindBin::Bin/$filename" to cluster "$self->{cluster}" with context "kind-$self->{cluster}": $x];
    }
}

sub exec ($self, $opt) {
    my ($out, $err);
    try {
        ($out, $err) = $self->_run(
            "exec", "-t",
            (defined $opt->{namespace} ? ("-n", $opt->{namespace}) : ()),
            $opt->{target},
            (defined $opt->{container} ? ("-c", $opt->{container}) : ()),
            "--",
            $opt->{command}->@*,
        );
    }
    catch ($x) {
        die qq[failed to exec: $x];
    }

    return ($out, $err);
}

sub create_secret ($self, $opt) {
    my $kind = "tls"; # there could be others in the future
    my $tls = $opt->{tls} // die "tls is required";
    my $key = $tls->{key} // die "tls key is required";
    my $crt = $tls->{cert} // die "tls cert is required";
    my $name = $opt->{name} // die "secret name is required";

    try {
        $self->_run(
            "create", "secret", $kind, $name,
            (defined $opt->{namespace} ? ("-n", $opt->{namespace}) : ()),
            "--key", $key,
            "--cert", $crt,
        );
    }
    catch ($x) {
        die qq[failed to create $kind secret "$name": $x];
    }
}

sub get ($self, $opt)  {
    my $kind = $opt->{kind} // die "kind is required";
    my $name = $opt->{name} // die "name is reuqired";

    my $parsed_out;
    try {
        my ($out, $err) = $self->_run(
            "get", $kind, $name,
            (defined $opt->{namespace} ? ("-n", $opt->{namespace}) : ()),
           "-ojson",
        );

        $parsed_out = decode_json($out);
    }
    catch ($x) {
        die qq[failed to get $kind "$name": $x];
    }

    return $parsed_out;
}

1;