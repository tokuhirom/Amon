? my ($form, $statuses) = @_;
? extends 'base.mt';
? block title => 'amon page';
? block content => sub {

? if (defined param('login_failed')) {
<div class="error">Invalid password or e-mail.</div>
? }

? if (login_user) {
<form method="post" action="/logout" name="logout">
<input type="submit" value="logout" />
</form>
? } else {
<form method="post" action="/login" name="login">
<?= encoded_string $form->render() ?>
<input type="submit" value="login" />
</form>
<a href="/signup">signup</a>
? }

<form method="post" action="/post" name="post">
<textarea name="body"></textarea>
<input type="submit" value="post" />
<input type="submit" value="post" />
</form>

? for my $status (@$statuses) {
<pre><?= $status->body ?></pre>
? }

? };
