package Hello::Web::C::Root;
use strict;
use warnings;

sub index {
    my ($class, $c) = @_;
    my @entries = $c->db->search(
        entry => {}, {limit => 10, offset => 0, order_by => {'entry_id' => 'DESC'}}
    );
    return $c->render(
        "index.tt" => {
            entries => \@entries,
        }
    );
}

sub post {
    my ($class, $c) = @_;
    if (my $body = $c->req->param('body')) {
        $c->db->insert(
            entry => {
                body => $body,
            },
        );
    }
    return $c->redirect('/');
}

1;
