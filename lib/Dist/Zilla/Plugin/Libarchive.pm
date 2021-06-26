use strict;
use warnings;
use 5.020;

package Dist::Zilla::Plugin::Libarchive {

  use Moose;
  use Archive::Libarchive;
  use Path::Tiny ();
  use Moose::Util::TypeConstraints;
  use namespace::autoclean;
  use experimental qw( signatures );

  # ABSTRACT: Create dist archives using Archive::Libarchive

  with 'Dist::Zilla::Role::ArchiveBuilder';

  enum ArchiveFormat => [qw/ tar.gz zip /];

  has format => (
    is       => 'ro',
    isa      => 'ArchiveFormat',
    required => 1,
    default  => 'tar.gz',
  );

  sub build_archive ($self, $archive_basename, $built_in, $basedir)
  {
    my $w = Archive::Libarchive::ArchiveWrite->new;

    my $archive_path = Path::Tiny->new(join '.', $archive_basename, $self->format);

    if($self->format eq 'tar.gz')
    {
      $w->set_format_pax_restricted;
      $w->add_filter_gzip;
    }
    elsif($self->format eq 'zip')
    {
      $w->set_format_zip;
    }
    $w->open_filename("$archive_path");

    my $time = time;
    foreach my $distfile ($self->zilla->files->@*)
    {
      my $e = Archive::Libarchive::Entry->new;
      $e->set_pathname($basedir->child($distfile->name));
      $e->set_size(-s $built_in->child($distfile->name));
      $e->set_filetype('reg');
      $e->set_perm( oct('0644') );
      $e->set_mtime($time);
      $w->write_header($e);
      my $content = $built_in->child($distfile->name)->slurp_raw;
      $w->write_data(\$content);
    }

    $w->close;

    return $archive_path;
  }

  __PACKAGE__->meta->make_immutable;
}

1;


