package fileyard

import (
	"github.com/dgtized/scrapyard/internal/key"
	"github.com/dgtized/scrapyard/internal/pack"
	"github.com/sirupsen/logrus"
	"gopkg.in/alecthomas/kingpin.v2"
	"os"
	"path/filepath"
	"time"
)

// Search for paths in a scrapyard.
func Search(keys *[]string, log *logrus.FieldLogger, paths *[]string, yard *string) kingpin.Action {
	return func(_ *kingpin.ParseContext) error {
		log := (*log).WithFields(
			logrus.Fields{
				"keys":  *keys,
				"paths": *paths,
			},
		)

		log.Info("Searching for keys")
		for _, k := range *keys {
			path := key.ToPath(*yard, k, "*", log)
			glob, errGlob := filepath.Glob(path)
			if errGlob != nil {
				return errGlob
			}
			if len(glob) == 0 {
				continue
			}

			var (
				latestCache string
				latestTime  time.Time

				scanLog = log.WithFields(
					logrus.Fields{
						"glob": glob,
						"path": path,
					},
				)
			)

			scanLog.Debug("Scanning")
			for _, cache := range glob {
				cacheInfo, err := os.Stat(cache)
				if err != nil {
					return err
				}
				if modTime := cacheInfo.ModTime(); modTime.After(latestTime) {
					latestCache = cache
					latestTime = modTime
				}
			}
			return pack.Restore(scanLog, latestCache, *paths)
		}

		log.Info("Unable to find key(s)")
		return nil
	}
}
