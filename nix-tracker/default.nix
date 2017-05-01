derivation {
  name = "example";
  foo = builtins.storePath ./example.txt;
}
