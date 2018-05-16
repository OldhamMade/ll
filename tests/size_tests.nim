# source is included since we're not exporting
# anything to be used by other libs/packages
include ll

import unittest


type
  Comparison = object
    value: int64
    expected: string


suite "size display tests":

  test "it displays correctly for default format":
    let
      tests = [
        Comparison(value: 1, expected: "1"),
        Comparison(value: 123, expected: "123"),
        Comparison(value: 12345, expected: "12345"),
        Comparison(value: 123456789, expected: "123456789"),
      ]

    for test in tests:
      let
        entry = Entry(size: test.value)
        result = formatSize(entry, DisplaySize.default)

      check:
        result == test.expected

  test "it displays correctly for human format":
    let
      tests = [
        Comparison(value: 1, expected: "1"),
        Comparison(value: 12, expected: "12"),
        Comparison(value: 123, expected: "123"),
        Comparison(value: 1000, expected: "1000"),
        Comparison(value: 1024, expected: "1.0K"),
        Comparison(value: 1234, expected: "1.2K"),
        Comparison(value: 12345, expected: "12K"),
        Comparison(value: 516526, expected: "504K"),
        Comparison(value: 123456789, expected: "118M"),
        Comparison(value: 445566778899, expected: "415G"),
        Comparison(value: 33445566778899, expected: "30T"),
        Comparison(value: 2233445566778899, expected: "2P"),
        Comparison(value: 112233445566778899, expected: "100P"),
      ]

    for test in tests:
      let
        entry = Entry(size: test.value)
        result = formatSize(entry, DisplaySize.human)

      check:
        result == test.expected
