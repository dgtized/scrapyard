package fileyard

import (
	"github.com/dgtized/scrapyard/internal/key"
	"github.com/sirupsen/logrus"
	"gopkg.in/alecthomas/kingpin.v2"
	"os"
)

// Junk keys in a scrapyard.
func Junk(keys *[]string, log *logrus.FieldLogger, yard *string) kingpin.Action {
	return func(_ *kingpin.ParseContext) error {
		log := (*log).WithField("keys", *keys)

		log.Info("Junking keys")
		for _, k := range *keys {
			path := key.ToPath(*yard, k, ".tgz", log)
			log.WithField("path", path).Debug("Removing key")
			if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
				return err
			}
		}
		return nil
	}
}
