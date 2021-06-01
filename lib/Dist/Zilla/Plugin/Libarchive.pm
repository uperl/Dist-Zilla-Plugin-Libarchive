use strict;
use warnings;
use 5.014

package Dist::Zilla::Plugin::Libarchive {

  use Moose;
  use namespace::autoclean;

  # ABSTRACT: Create dist archives using Archive::Libarchive

  __PACKAGE__->meta->make_immutable;
}

1;


