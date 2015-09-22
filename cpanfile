requires "B::Deparse" => 0.61;
requires "Hook::LexWrap";
requires "LWP";
requires "LWP::UserAgent";
requires "Safe::Isa";
requires "Storable" => '2.05';
requires "strict";
requires "URI";
requires "warnings";

on 'test' => sub {
    requires "Test::Internet" => '0.05';
    requires "Test::More";
};

on 'develop' => sub {
    recommends "Test::Pod::Coverage" => '1.08';
};

