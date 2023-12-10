{ self, lib, utils }: {
  testFillList = {
    expr = utils.general.fillList [ "example" "net" ] 2 null;
    expected = [ null null "example" "net" ];
  };
  testRecursiveUpdateLists = {
    expr = utils.general.recursiveUpdateLists [
      {
        a = null;
      }
      {
        a = { dog = "animal"; };
        d = { a1 = [ "pine" ]; };
      }
      {
        c = 1234;
      }
      {
        a = { cat = null; };
        d = { a1 = [ "apple" ]; };
      }
    ];
    expected = {
      a = { cat = null; };
      c = 1234;
      d = {
        a1 = [ "pine" "apple" ];
      };
    };
  };
}
