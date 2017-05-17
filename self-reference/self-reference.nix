with import <nixpkgs> {};

substituteAll {
  src = ./self-reference.txt;
  foo = hello;
}
