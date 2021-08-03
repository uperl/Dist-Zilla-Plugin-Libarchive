use Test2::V0 -no_srand => 1;
use Test::DZil;
use Archive::Tar;
use Dist::Zilla::Plugin::Libarchive;
use Path::Tiny qw( path );
use experimental qw( postderef signatures );

$Dist::Zilla::Plugin::Libarchive::VERBOSE = 1;

foreach my $format (qw( tar tar.gz ))
{

  my $dir_check = sub ($name) {
    return object {
      call [ isa => 'Archive::Tar::File' ] => T();
      call name => $name;
      call mode => oct('0755');
      call size => 0;
      call uid  => 0;
      call gid  => 0;
      call type => Archive::Tar::DIR();
    };
  };

  my $file_check = sub ($name, $content=undef) {
    return object {
      call [ isa => 'Archive::Tar::File' ] => T();
      call name => $name;
      call mode => oct('0644');
      call uid  => 0;
      call gid  => 0;
      call type => Archive::Tar::FILE();
      if($content)
      {
        call has_content => T();
        call get_content => $content;
        call size => length $content;
      }
      else
      {
        call size => match qr/^[1-9][0-9]+$/;
      }
    };
  };

  subtest "format = $format" => sub {

    my $tzil = Builder->from_config({
      dist_root => 'corpus/dist/DZT',
    }, {
      add_files => {
        'source/dist.ini' => simple_ini({
            version   => '0.01',
            name      => 'Foo-Bar-Baz',
          },
          'GatherDir',
          ['Libarchive', => { format => $format }],
        ),
      },
    });

    my $tarball = $tzil->build_archive;

    note $_ for $tzil->log_messages->@*;

    is(
      $tarball,
      object {
        call [ isa => 'Path::Tiny' ] => T();
        call stringify => "Foo-Bar-Baz-0.01.$format";
      },
      'path is good',
    );

    is(
      Archive::Tar->new,
      object {
        call [ isa => 'Archive::Tar' ] => T();
        call [ read => "$tarball" ] => T();
        call_list get_files => [
          $dir_check->('Foo-Bar-Baz-0.01/'),
          $file_check->('Foo-Bar-Baz-0.01/dist.ini'),
          $dir_check->('Foo-Bar-Baz-0.01/lib/'),
          $dir_check->('Foo-Bar-Baz-0.01/lib/Foo/'),
          $dir_check->('Foo-Bar-Baz-0.01/lib/Foo/Bar/'),
          $file_check->('Foo-Bar-Baz-0.01/lib/Foo/Bar/ALongerOne.pm', path("corpus/dist/DZT/lib/Foo/Bar/ALongerOne.pm")->slurp_raw),
          $file_check->('Foo-Bar-Baz-0.01/lib/Foo/Bar/Baz.pm', path("corpus/dist/DZT/lib/Foo/Bar/Baz.pm")->slurp_raw),
        ];
      },
      'archive is good',
    );

    unlink $tarball;
  };

}

subtest 'zip' => sub {

  skip_all 'Test requires Archive::Zip'
    unless eval { require Archive::Zip; 1 };

  my $tzil = Builder->from_config({
    dist_root => 'corpus/dist/DZT',
  }, {
    add_files => {
      'source/dist.ini' => simple_ini({
          version   => '0.01',
          name      => 'Foo-Bar-Baz',
        },
        'GatherDir',
        ['Libarchive', => { format => 'zip' }],
      ),
    },
  });

  my $zipfile = $tzil->build_archive;

  note $_ for $tzil->log_messages->@*;

  is(
    $zipfile,
    object {
      call [ isa => 'Path::Tiny' ] => T();
      call stringify => "Foo-Bar-Baz-0.01.zip";
    },
    'path is good',
  );

  my $dir_check = sub ($name) {
    return object {
      call fileName => $name;
      # TODO: Note that the return value has more than just the file permissions, so you will have to mask off the lowest bits for comparisons
      #call unixFileAttributes => oct('0755');
      call isDirectory => T();
    };
  };

  my $file_check = sub ($name, $content=undef) {
    return object {
      call fileName => $name;
      #call unixFileAttributes => oct('0644');
      call isDirectory => F();
      if($content) {
        call contents => $content;
      }
    };
  };

  is(
    Archive::Zip->new,
    object {
      call [ read => "$zipfile" ] => Archive::Zip::AZ_OK();
      call_list members => [
        $dir_check->('Foo-Bar-Baz-0.01/'),
        $file_check->('Foo-Bar-Baz-0.01/dist.ini'),
        $dir_check->('Foo-Bar-Baz-0.01/lib/'),
        $dir_check->('Foo-Bar-Baz-0.01/lib/Foo/'),
        $dir_check->('Foo-Bar-Baz-0.01/lib/Foo/Bar/'),
        $file_check->('Foo-Bar-Baz-0.01/lib/Foo/Bar/ALongerOne.pm', path("corpus/dist/DZT/lib/Foo/Bar/ALongerOne.pm")->slurp_raw),
        $file_check->('Foo-Bar-Baz-0.01/lib/Foo/Bar/Baz.pm', path("corpus/dist/DZT/lib/Foo/Bar/Baz.pm")->slurp_raw),
      ];
    },
    'archive is good',
  );

  unlink $zipfile;

};

done_testing;
