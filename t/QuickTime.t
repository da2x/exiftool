# Before "make install", this script should be runnable with "make test".
# After "make install" it should work as "perl t/QuickTime.t".

BEGIN {
    $| = 1; print "1..12\n"; $Image::ExifTool::configFile = '';
    require './t/TestLib.pm'; t::TestLib->import();
}
END {print "not ok 1\n" unless $loaded;}

# test 1: Load the module(s)
use Image::ExifTool 'ImageInfo';
use Image::ExifTool::QuickTime;
$loaded = 1;
print "ok 1\n";

my $testname = 'QuickTime';
my $testnum = 1;

# tests 2-3: Extract information from QuickTime.mov and QuickTime.m4a
{
    my $ext;
    foreach $ext (qw(mov m4a)) {
        ++$testnum;
        my $exifTool = new Image::ExifTool;
        my $info = $exifTool->ImageInfo("t/images/QuickTime.$ext");
        print 'not ' unless check($exifTool, $info, $testname, $testnum);
        print "ok $testnum\n";
    }
}

# tests 4-5: Try writing XMP to the different file formats
{
    my $ext;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(SavePath => 1); # to save group 5 names
    $exifTool->SetNewValue('XMP:Title' => 'x');
    $exifTool->SetNewValue('TrackCreateDate' => '2000:01:02 03:04:05');
    $exifTool->SetNewValue('Track1:TrackModifyDate' => '2013:11:04 10:32:15');
    foreach $ext (qw(mov m4a)) {
        ++$testnum;
        unless (eval { require Time::Local }) {
            print "ok $testnum # skip Requires Time::Local\n";
            next;
        }
        my $testfile = "t/${testname}_${testnum}_failed.$ext";
        unlink $testfile;
        my $rtnVal = $exifTool->WriteInfo("t/images/QuickTime.$ext", $testfile);
        my $info = $exifTool->ImageInfo($testfile, 'title', 'time:all');
        if (check($exifTool, $info, $testname, $testnum, undef, 5)) {
            unlink $testfile;
        } else {
            print 'not ';
        }
        print "ok $testnum\n";
    }
}

# test 6: Write video rotation
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    $exifTool->SetNewValue('Rotation' => '270');
    my $testfile = "t/${testname}_${testnum}_failed.mov";
    unlink $testfile;
    my $rtnVal = $exifTool->WriteInfo('t/images/QuickTime.mov', $testfile);
    my $info = $exifTool->ImageInfo($testfile, 'Rotation', 'MatrixStructure');
    if (check($exifTool, $info, $testname, $testnum)) {
        unlink $testfile;
    } else {
        print 'not ';
    }
    print "ok $testnum\n";
}

# test 7: Add a bunch of new tags
{
    ++$testnum;
    my $exifTool = new Image::ExifTool;
    my @writeInfo = (
        ['QuickTime:Artist' => 'me'],
        ['QuickTime:Model' => 'model'],
        ['UserData:Genre' => 'rock' ],
        ['UserData:Album' => 'albumA' ],
        ['ItemList:Album' => 'albumB' ],
        ['QuickTime:Comment-fra-FR' => 'fr comment' ],
    );
    print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum, 't/images/QuickTime.mov', 1);
    print "ok $testnum\n";
}

# test 8-9: Delete everything then add back a tag
{
    my $ext;
    my $exifTool = new Image::ExifTool;
    my @writeInfo = (
        ['all' => undef],
        ['artist' => 'me'],
    );
    my @extract = ('QuickTime:all', 'XMP:all');
    foreach $ext (qw(mov m4a)) {
        ++$testnum;
        print 'not ' unless writeCheck(\@writeInfo, $testname, $testnum, "t/images/QuickTime.$ext", \@extract);
        print "ok $testnum\n";
    }
}

# tests 10-12: HEIC write tests
{
    ++$testnum;
    my $testfile = "t/${testname}_${testnum}_failed.heic";
    unlink $testfile;
    my $exifTool = new Image::ExifTool;
    $exifTool->Options(Composite => 0);
    $exifTool->SetNewValue('XMP-dc:Title' => 'a title');
    writeInfo($exifTool, 't/images/QuickTime.heic', $testfile);
    my $info = $exifTool->ImageInfo($testfile, '-file:all');
    unless (check($exifTool, $info, $testname, $testnum)) {
        print 'not ';
    }
    print "ok $testnum\n";

    ++$testnum;
    my $testfile2 = "t/${testname}_${testnum}_failed.heic";
    unlink $testfile2;
    $exifTool->SetNewValue();
    $exifTool->SetNewValue('XMP:all' => undef);
    $exifTool->SetNewValue('EXIF:Artist' => 'an artist');
    writeInfo($exifTool, $testfile, $testfile2);
    $info = $exifTool->ImageInfo($testfile2, '-file:all');
    if (check($exifTool, $info, $testname, $testnum)) {
        unlink $testfile;
    } else {
        print 'not ';
    }
    print "ok $testnum\n";

    ++$testnum;
    $testfile = "t/${testname}_${testnum}_failed.heic";
    unlink $testfile;
    Image::ExifTool::AddUserDefinedTags('Image::ExifTool::XMP::dc', test => {} );
    $exifTool->SetNewValue();
    $exifTool->SetNewValue('EXIF:all' => undef);
    $exifTool->SetNewValue('EXIF:UserComment' => 'a comment');
    $exifTool->SetNewValue('XMP:Subject' => 'a subject');
    $exifTool->SetNewValue('XMP:Subject' => 'another subject');
    writeInfo($exifTool, $testfile2, $testfile);
    $info = $exifTool->ImageInfo($testfile, '-file:all');
    if (check($exifTool, $info, $testname, $testnum)) {
        unlink $testfile;
        unlink $testfile2;
    } else {
        print 'not ';
    }
    print "ok $testnum\n";
}


# end
