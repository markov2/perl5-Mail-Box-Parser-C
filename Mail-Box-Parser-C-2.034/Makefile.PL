use ExtUtils::MakeMaker;

WriteMakefile
 ( NAME          => 'Mail::Box::Parser::C'
 , VERSION_FROM  => 'C.pm'
 , PREREQ_PM     =>
    { 'Mail::Box'  => 2.032
    }
 , ABSTRACT      => 'C parser for Mail::Box'
 , AUTHOR        => 'Mark Overmeer'
);
