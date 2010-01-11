package Hello::Web::C::Root;
use Amon::Web::C;

sub index {
    my $login_form = c->form('login');
    my @statuses;
    if (my $user = c->login_user) {
        @statuses = db->search(
            'status' => { user_id => $user->user_id, },
            { order_by => { 'status_id', 'DESC' } }
        );
    }
    render("index.mt", $login_form, \@statuses);
}

sub signup {
    my $form = c->form('user_add');
    if ($form->submitted_and_valid) {
        $form->model->create(db() => 'user');
        return redirect('/signup_thanks');
    }
    return render("signup.mt", $form);
}

sub signup_thanks { render('signup_thanks.mt') }

sub login {
    my $form = c->form('login');
    if ($form->submitted_and_valid) {
        my $user = db->single(
            user => {
                email    => $form->param('email'),
                password => $form->param('password'),
            }
        );
        if ($user) {
            c->session->set('login_user_id' => $user->user_id);
            return redirect('/');
        }
    }
    redirect('/?login_failed=1');
}

sub logout {
    c->session->expire();
    redirect('/');
}

sub post {
    my $user = c->login_user() or return redirect('/');
    if (my $body = param_decoded('body')) {
        db->insert(
            'status' => {
                user_id => $user->user_id,
                body    => $body,
            },
        );
    }
    return redirect('/');
}

1;
