? my ($form, $statuses) = @_;
? extends 'base.mt';
? block title => 'amon page';
? block content => sub {

? if (defined param('login_failed')) {
Invalid password or e-mail.
? }

<form method="post" action="/login" name="login">
<?= $form->render() ?>
<input type="submit" value="login" />
</form>

<form method="post" action="/post" name="post">
<textarea name="body"></textarea>
<input type="submit" value="post" />
<input type="submit" value="post" />
</form>

? for my $status (@$statuses) {
<pre><?= $status->body ?></pre>
? }

? };
