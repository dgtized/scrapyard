package fileyard

import (
	"github.com/sirupsen/logrus"
	"gopkg.in/alecthomas/kingpin.v2"
	"os"
	"path/filepath"
	"time"
)

// Crush a yard to scrap.
func Crush(log *logrus.FieldLogger, yard *string) kingpin.Action {
	return func(_ *kingpin.ParseContext) error {
		(*log).Info("Crushing the yard to scrap!")
		return filepath.Walk(*yard, func(tarball string, info os.FileInfo, err error) error {
			if err != nil {
				(*log).Debug("Yard does not exist")
				return nil
			} else if *yard == tarball {
				// filepath.Walk also gives us the directory, ignore it.
				return nil
			}

			modtime := info.ModTime()
			log := (*log).WithFields(
				logrus.Fields{
					"modtime": modtime,
					"tarball": tarball,
				},
			)

			if modtime.Before(time.Now().AddDate(0, 0, -20)) {
				log.Info("Crushing tarball")
				return os.Remove(tarball)
			}
			log.Debug("Keeping tarball")
			return nil
		})
	}
}
