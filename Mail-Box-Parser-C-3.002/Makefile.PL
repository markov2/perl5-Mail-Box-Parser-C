use ExtUtils::MakeMaker;

WriteMakefile
 ( NAME          => 'Mail::Box::Parser::C'
 , VERSION_FROM  => 'C.pm'
 , PREREQ_PM     => { }
 , ABSTRACT      => 'C parser for Mail::Box'
 , AUTHOR        => 'Mark Overmeer'
);
