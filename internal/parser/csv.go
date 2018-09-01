package parser

import (
	"fmt"
	"gopkg.in/alecthomas/kingpin.v2"
	"strings"
)

type csvValue struct {
	values *[]string
}

func (c csvValue) Get() interface{} {
	return c.values
}

// IsCumulative allows repeated flags.
// Without this, only one flag will work.
func (c csvValue) IsCumulative() bool {
	return true
}

func (c *csvValue) Set(value string) error {
	*c.values = append(*c.values, strings.Split(value, ",")...)

	return nil
}

func (c csvValue) String() string {
	return fmt.Sprintf("%v", c.values)
}

// CsvVar is a custom parser for strings variables
// It's effectively `kingpin.StringsVar` with support for comma-separated values.
//
// For example, if you have a flag `foo`,
// it will parse `--foo bar --foo baz,qux --foo gar` to `[bar baz qux gar]`.
func CsvVar(target *[]string, s kingpin.Settings) {
	s.SetValue(&csvValue{values: target})
}
