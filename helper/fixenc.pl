# Построчно приводит вывод psql к UTF-8: данные приходят в UTF-8,
# а локализованные служебные сообщения psql под Windows - в CP1251
use Encode;
binmode STDIN; binmode STDOUT; $| = 1;
while (my $line = <STDIN>) {
    my $copy = $line;
    if (eval { decode('UTF-8', $copy, Encode::FB_CROAK); 1 }) { print $line }
    else { print encode('UTF-8', decode('cp1251', $line)) }
}
