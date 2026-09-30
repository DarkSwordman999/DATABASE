# Построчно приводит вывод psql к UTF-8: данные приходят в UTF-8,
# а локализованные служебные сообщения psql под Windows - в CP1251.
# В строках, где встречаются обе кодировки (КОНТЕКСТ, ПОДРОБНОСТИ), корректные
# двухбайтовые последовательности UTF-8 сохраняются, остальные байты считаются CP1251.
use Encode;
binmode STDIN; binmode STDOUT; $| = 1;
while (my $line = <STDIN>) {
    my $copy = $line;
    if (eval { decode('UTF-8', $copy, Encode::FB_CROAK); 1 }) { print $line; next }
    $line =~ s{([\xC2-\xDF][\x80-\xBF])|([\x80-\xFF])}
              {defined $1 ? $1 : encode('UTF-8', decode('cp1251', $2))}ge;
    print $line;
}
