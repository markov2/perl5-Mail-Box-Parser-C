use ExtUtils::MakeMaker;

WriteMakefile
 ( NAME          => 'Mail::Box::Parser::C'
 , VERSION_FROM  => 'C.pm'
 , PREREQ_PM     =>
     { Test::More => 0.47
     , Mail::Box  => 2.050
     }
 , ABSTRACT      => 'C parser for Mail::Box'
 , AUTHOR        => 'Mark Overmeer'
);
