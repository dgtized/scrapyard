package main

import (
	"github.com/dgtized/scrapyard/internal/fileyard"
	"github.com/dgtized/scrapyard/internal/parser"
	"github.com/sirupsen/logrus"
	"gopkg.in/alecthomas/kingpin.v2"
	"os"
)

func main() {
	var (
		yard string

		log logrus.FieldLogger = &logrus.Logger{
			Formatter: &logrus.TextFormatter{
				DisableLevelTruncation: true,
				FullTimestamp:          true,
			},
			Out: os.Stdout,
		}
	)

	app := scrapyard(&log, &yard)

	crush(&app, &log, &yard)
	junk(&app, &log, &yard)
	search(&app, &log, &yard)
	store(&app, &log, &yard)

	kingpin.MustParse(app.Parse(os.Args[1:]))
}

func initialize(log *logrus.FieldLogger, verbose *bool, yard *string) kingpin.Action {
	return func(_ *kingpin.ParseContext) error {
		if *verbose {
			(*log).(*logrus.Logger).Level = logrus.DebugLevel
		} else {
			(*log).(*logrus.Logger).Level = logrus.WarnLevel
		}
		*log = (*log).WithField("yard", *yard)

		(*log).Info("Creating scrapyard if it doesn't exist")
		return os.MkdirAll(*yard, os.ModePerm)
	}
}

func scrapyard(log *logrus.FieldLogger, yard *string) kingpin.Application {
	var verbose bool

	app := kingpin.
		New("scrapyard", "Simple caching tool for faster CI builds").
		Action(initialize(log, &verbose, yard))
	app.
		Flag("verbose", "").
		Short('v').
		BoolVar(&verbose)
	app.
		Flag("yard", "The directory the scrapyard is stored in.").
		Short('y').
		Default("/tmp/scrapyard").
		StringVar(yard)

	return *app
}

func crush(app *kingpin.Application, log *logrus.FieldLogger, yard *string) {
	app.
		Command("crush", "Crush a yard to scrap").
		Action(fileyard.Crush(log, yard))
}

func junk(app *kingpin.Application, log *logrus.FieldLogger, yard *string) {
	var keys []string

	command := app.
		Command("junk", "Junk keys in a scrapyard").
		Action(fileyard.Junk(&keys, log, yard))
	parser.CsvVar(
		&keys,
		command.
			Flag("keys", "Keys to junk in the scrapyard").
			Short('k').
			Required(),
	)
}

func search(app *kingpin.Application, log *logrus.FieldLogger, yard *string) {
	var (
		keys  []string
		paths []string
	)

	command := app.
		Command("search", "Search for paths in a scrapyard").
		Action(fileyard.Search(&keys, log, &paths, yard))
	parser.CsvVar(
		&keys,
		command.
			Flag("keys", "Keys to search in order of preference the scrapyard").
			Short('k').
			Required(),
	)
	parser.CsvVar(
		&paths,
		command.
			Flag("paths", "Paths to search in the scrapyard").
			Short('p').
			Required(),
	)
}

func store(app *kingpin.Application, log *logrus.FieldLogger, yard *string) {
	var (
		key   string
		paths []string
	)

	command := app.
		Command("store", "Store paths in a scrapyard").
		Action(fileyard.Store(&key, log, &paths, yard))
	command.
		Flag("key", "Key to store in the scrapyard").
		Short('k').
		Required().
		StringVar(&key)
	parser.CsvVar(
		&paths,
		command.
			Flag("paths", "Paths to store in the scrapyard").
			Short('p').
			Required(),
	)
}
