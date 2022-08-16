module Example exposing (..)

import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)


suite : Test
suite =
    test "2 + 2 is equals to 4" <|
        \_ -> Expect.equal 4 (2 + 2)
