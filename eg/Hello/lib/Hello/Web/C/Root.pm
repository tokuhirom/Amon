package Hello::Web::C::Root;
use strict;
use warnings;
use Amon2::Declare;

sub index {
    my ($class, $c) = @_;

    my $login_form = $c->form('login');
    my @statuses;
    if (my $user = $c->login_user) {
        @statuses = $c->db->search(
            'status' => { user_id => $user->user_id, },
            { order_by => { 'status_id', 'DESC' } }
        );
    }
    return $c->render("index.mt", $login_form, \@statuses);
}

sub signup {
    my ($class, $c) = @_;
    my $form = $c->form('user_add');
    if ($form->submitted_and_valid) {
        $form->model->create($c->db() => 'user');
        return $c->redirect('/signup_thanks');
    }
    return $c->render("signup.mt", $form);
}

sub signup_thanks {
    my ($class, $c) = @_;
    $c->render('signup_thanks.mt');
}

sub login {
    my ($class, $c) = @_;
    my $form = $c->form('login');
    if ($form->submitted_and_valid) {
        my $user = $c->db->single(
            user => {
                email    => $form->param('email'),
                password => $form->param('password'),
            }
        );
        if ($user) {
            $c->session->set('login_user_id' => $user->user_id);
            return $c->redirect('/');
        }
    }
    $c->redirect('/?login_failed=1');
}

sub logout {
    my ($class, $c) = @_;
    $c->session->expire();
    $c->redirect('/');
}

sub post {
    my ($class, $c) = @_;
    my $user = c->login_user() or return $c->redirect('/');
    if (my $body = param_decoded('body')) {
        c->db->insert(
            'status' => {
                user_id => $user->user_id,
                body    => $body,
            },
        );
    }
    return $c->redirect('/');
}

1;
