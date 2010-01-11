package Hello::Form;
use strict;
use warnings;
use HTML::Shakan::Declare;

form 'user_add' => (
    EmailField(
        name     => 'email',
        required => 1,
    ),
    TextField(
        name     => 'nick',
        required => 1,
    ),
    PasswordField(
        name     => 'password',
        required => 1,
    ),
);

form 'login' => (
    EmailField(
        name     => 'email',
        required => 1,
    ),
    PasswordField(
        name     => 'password',
        required => 1,
    ),
);

1;
