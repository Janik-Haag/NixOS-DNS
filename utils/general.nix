# General are functions not really specific to NixOS-DNS that might be worth up-streaming in the nixpkgs lib.
{ lib, utils }:
{
  /*
    Function that merges sets the same as `lib.recursiveUpdate`.
    But if a value is a list it merges the list instead of overwriting it.
    Stolen from [here](https://stackoverflow.com/questions/54504685/nix-function-to-merge-attributes-records-recursively-and-concatenate-arrays)

    Type:
      utils.general.recursiveUpdateLists :: [ Attr ] -> Attr
  */
  recursiveUpdateLists =
    # List of sets to merge
    attrList:
    let
      f =
        attrPath:
        builtins.zipAttrsWith (
          n: values:
          if lib.tail values == [ ] then
            lib.head values
          else if lib.all lib.isList values then
            lib.unique (lib.concatLists values)
          else if lib.all lib.isAttrs values then
            f (lib.attrPath ++ [ n ]) values
          else
            lib.last values
        );
    in
    f [ ] attrList;

  /*
    Prepends a list with a specific value X amount of times
    For example say we have `[ "my" "fancy" "example" "com" ]`
    And `[ "example" "com" ]` but want to compare them, then
    we can use this function like this:
    ```nix
    let
      lenSub = (builtins.length [ "my" "fancy" "example" "com" ]);
      lenBase = (builtins.length [ "example" "com" ]);
    in
      fillList subDomain (lenBase - lenSub) null
    ```
    which will result in:
    [ null null "example" "com" ]

    Type:
      utils.general.recursiveUpdateLists :: [ Any ] -> Int -> [ Any ]
  */
  fillList =
    # list to prepend
    list:
    # how often
    amount:
    # with what
    value:
    ((lib.replicate amount value) ++ list);
}
