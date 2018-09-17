package fileyard

import (
	"github.com/dgtized/scrapyard/internal/key"
	"github.com/dgtized/scrapyard/internal/pack"
	"github.com/sirupsen/logrus"
	"gopkg.in/alecthomas/kingpin.v2"
)

// Store paths in a scrapyard.
func Store(k *string, log *logrus.FieldLogger, paths *[]string, yard *string) kingpin.Action {
	return func(_ *kingpin.ParseContext) error {
		log := (*log).WithFields(
			logrus.Fields{
				"key":   *k,
				"paths": *paths,
			},
		)

		log.Info("Storing keys")
		keyPath := key.ToPath(*yard, *k, ".tgz", log)
		return pack.Save(log, keyPath, *paths)
	}
}
