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

=head1 SYNOPSIS

In your C<dist.ini>

 [Libarchive]

=head1 DESCRIPTION

This L<Dist::Zilla> plugin overrides the built in archive builder and uses C<libarchive> via L<Archive::Libarchive>
instead.  It is different from the built in version in these ways:

=over 4

=item Predictable

The built in behavior will sometimes use L<Archive::Tar> or L<Archive::Tar::Wrapper>.  The problem with L<Archive::Tar::Wrapper>
is that it depends on the system implementation of tar, which in some cases can produce archives that are not readable by older
implementations of tar.  In particular GNU tar which is typically the default on Linux systems includes unnecessary features that
break tar on HP-UX.  (You should probably be getting off HP-UX if you are still using it in 2021 as I write this).

=item Sorted by name

The contents of the archive are sorted by name instead of being sorted by filename length.  While sorting by length makes for
a pretty display when they are unpacked, I find it harder to find stuff when the content is listed.

=item Additional formats

Because C<libarchive> supports a large number of formats, this plugin can be extended to support them as well.  Currently
there is an interface to produce C<.tar>, C<.tar.gz> and C<.zip>.  Other formats may be added in the future.

=back

=head1 PROPERTIES

=head2 format

 [Libarchive]
 format = tar.gz

Sets the output format.  The default, most common and easiest to unpack for cpan clients is C<tar.gz>.  You should consider
carefully before not using the default.  Supported formats:

=over 4

=item C<tar.gz>

=item C<tar>

=item C<zip>

=back

=head1 SEE ALSO

=over 4

=item L<Archive::Libarchive>

=item L<Dist::Zilla>

=item L<Dist::Zilla::Role::ArchiveBuilder>

=back

=cut

  with 'Dist::Zilla::Role::ArchiveBuilder';

  enum ArchiveFormat => [qw/ tar tar.gz zip /];

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
    elsif($self->format eq 'tar')
    {
      $w->set_format_pax_restricted;
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
