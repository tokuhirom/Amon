? my $form = shift;
? extends 'base.mt';
? block title => 'amon page';
? block content => sub {

<? if ($form->submitted && $form->has_error) { ?>
<ul class="error">
?  for my $err ($form->get_error_messages()) {
<li><?= $err ?></li>
? }
</ul>
<? } ?>
<h2 class="ttlLv2">Signup</h2>
<form method="post" action="/signup">
<?= encoded_string $form->render() ?>
<input type="submit" value="register" />
</form>

? };
