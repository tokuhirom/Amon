package Hello::V::MT::Context;
use Amon::V::MT::Context;
use Hello::Form;
use Hello::Form::Renderer;

sub form {
    my ($name) = @_;
    my $renderer = Hello::Form::Renderer->new();
    my $form = Hello::Form->get(
        $name => (
            request  => req(),
            renderer => $renderer,
        )
    );
    return encoded_string($form->render());
}

sub login_user { c->login_user() }

1;
