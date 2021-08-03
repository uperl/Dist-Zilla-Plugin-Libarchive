use strict;
use warnings;
use 5.020;

package Dist::Zilla::Plugin::Libarchive {

  use Moose;
  use Archive::Libarchive qw( ARCHIVE_WARN );
  use Path::Tiny ();
  use Moose::Util::TypeConstraints;
  use namespace::autoclean;
  use experimental qw( signatures postderef );

  # ABSTRACT: Create dist archives using Archive::Libarchive

  with 'Dist::Zilla::Role::ArchiveBuilder';

  enum ArchiveFormat => [qw/ tar.gz zip /];

  has format => (
    is       => 'ro',
    isa      => 'ArchiveFormat',
    required => 1,
    default  => 'tar.gz',
  );

  sub _check_ret ($self, $ret)
  {
    if($ret == ARCHIVE_WARN)
    {
      $self->log($ret->error_string);
    }
    elsif($ret < ARCHIVE_WARN)
    {
      $self->log_fatal($ret->error_string);
    }
  }

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

    my $ret = $w->open_filename("$archive_path");
    $self->_check_ret($ret);

    my %dirs;

    my $e = Archive::Libarchive::Entry->new;

    my $time = time;
    foreach my $distfile (sort $self->zilla->files->@*)
    {
      {
        my @parts = split /\//, $distfile->name;
        pop @parts;

        my $dir = '';
        foreach my $part ('', @parts)
        {
          $dir .= "/$part";
          next if $dirs{$dir};
          $dirs{$dir} = 1;

          $e->set_pathname($basedir->child($dir));
          $e->set_size(0);
          $e->set_filetype('dir');
          $e->set_perm( oct('0755') );
          $e->set_mtime($time);

          $ret = $w->write_header($e);
          $self->_check_ret($ret);
        }
      }

      $e->set_pathname($basedir->child($distfile->name));
      $e->set_size(-s $built_in->child($distfile->name));
      $e->set_filetype('reg');
      $e->set_perm( oct('0644') );
      $e->set_mtime($time);

      $ret = $w->write_header($e);
      $self->_check_ret($ret);

      my $content = $built_in->child($distfile->name)->slurp_raw;
      $ret = $w->write_data(\$content);
      $self->_check_ret($ret);
    }

    $w->close;
    $self->_check_ret($ret);

    $self->log("writing archive to $archive_path");
    return $archive_path;
  }

  __PACKAGE__->meta->make_immutable;
}

1;


